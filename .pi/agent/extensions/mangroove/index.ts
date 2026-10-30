import { spawnSync } from "node:child_process";
import { randomUUID } from "node:crypto";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { BorderedLoader, convertToLlm, getMarkdownTheme, type ExtensionAPI, type ExtensionCommandContext, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Container, Markdown, Text, truncateToWidth } from "@earendil-works/pi-tui";
import { DEFAULT_INSTRUCTION, FLOW, LINEAGE, MAX_BYTES, RESULT, ancestorRefs, cleanName, costLabel, getLineage, label, loadSessions, loadSubscriptions, readSnapshot, sapReport, snapshot, usageCost, type Flow, type Lineage, type Ref, type Snapshot } from "./core.ts";

type PendingDive = { token: string; source: Ref; leafId: string; name: string; lineage: Omit<Lineage, "sessionId">; initialized?: string };
type RuntimeState = { busy?: { token: string; kind: "dive" | "distill"; transferring: boolean }; pending?: PendingDive };
// Session replacement reloads extension modules. Only this short-lived, plain-data
// handoff survives the reload; durable state belongs to the child JSONL, not globals.
const runtimeKey = Symbol.for("personal.mangroove.runtime.v1");
const shared: RuntimeState = Reflect.get(globalThis, runtimeKey) ?? {};
Reflect.set(globalThis, runtimeKey, shared);

function currentSnapshot(ctx: ExtensionContext): Snapshot {
  const file = ctx.sessionManager.getSessionFile();
  const header = ctx.sessionManager.getHeader();
  if (!file || !header) throw new Error("This command requires a persistent session.");
  return snapshot(file, header, ctx.sessionManager.getEntries());
}

function requireIdle(ctx: ExtensionContext): void {
  if (!ctx.isIdle() || ctx.hasPendingMessages()) throw new Error("Wait until the agent and its message queue are idle.");
}

function acquire(kind: "dive" | "distill"): string {
  if (shared.busy) throw new Error(`/${shared.busy.kind} is already in progress.`);
  const token = randomUUID();
  shared.busy = { token, kind, transferring: false };
  return token;
}

function release(token?: string): void {
  if (shared.pending?.token === token) delete shared.pending;
  if (shared.busy?.token === token) delete shared.busy;
}

async function editExternally(ctx: ExtensionCommandContext, editor: string, text: string): Promise<{ code: number | null; text?: string; error?: string }> {
  const directory = await mkdtemp(join(tmpdir(), "pi-distill-"));
  const file = join(directory, "report.md");
  try {
    await writeFile(file, text, { mode: 0o600 });
    const result = await ctx.ui.custom<{ code: number | null; error?: string }>((tui, _theme, _keys, done) => {
      tui.stop();
      let result: { code: number | null; error?: string };
      try {
        process.stdout.write("\x1b[2J\x1b[H");
        // $EDITOR is trusted shell configuration and may include flags. The file
        // path is a positional argument, never interpolated into shell syntax.
        const child = spawnSync("/bin/sh", ["-c", `exec ${editor} "$1"`, "distill-editor", file], {
          cwd: ctx.cwd, stdio: "inherit", env: process.env,
        });
        result = { code: child.status, error: child.error?.message ?? (child.signal ? `Editor terminated by ${child.signal}` : undefined) };
      } finally {
        tui.start();
        tui.requestRender(true);
      }
      done(result!);
      return { render: () => [], invalidate() {} };
    });
    const data = await readFile(file);
    if (data.length > MAX_BYTES) return { ...result, error: "Edited report exceeds 2 MiB." };
    if (data.includes(0)) return { ...result, error: "Edited report contains binary data." };
    return { ...result, text: new TextDecoder("utf-8", { fatal: true }).decode(data) };
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

export default function mangroove(pi: ExtensionAPI) {
  let live = false;
  let controller: AbortController | undefined;

  const showAncestors = async (ctx: ExtensionContext) => {
    if (ctx.mode !== "tui") return;
    const refs = await ancestorRefs(currentSnapshot(ctx));
    if (!live) return;
    if (!refs.length) { ctx.ui.setWidget("dive-ancestors", undefined); return; }
    ctx.ui.setWidget("dive-ancestors", (_tui, theme) => ({
      render: width => [truncateToWidth(theme.fg("dim", refs.map(label).join(" → ")), width)],
      invalidate() {},
    }), { placement: "aboveEditor" });
  };

  pi.registerEntryRenderer<Flow>(FLOW, (entry, { expanded }, theme) => {
    const flow = entry.data;
    if (!flow) return new Text("distill: missing flow data", 0, 0);
    const status = flow.kind === "draft" ? flow.stopReason ?? "draft" : flow.status ?? "review";
    const cost = flow.kind === "draft" ? ` · ${costLabel(usageCost(flow.usage))}` : "";
    const box = new Container();
    box.addChild(new Text(theme.fg("dim", `distill ${flow.requestId.slice(0, 8)} → ${label(flow.target)} · ${status}${cost}`), 0, 0));
    if (expanded) {
      const content = flow.kind === "draft"
        ? `### Instructions\n${flow.instructions ?? ""}\n\n### Generated report\n${flow.text ?? ""}`
        : `### Edited report\n${flow.editedText ?? ""}`;
      box.addChild(new Markdown(content, 0, 0, getMarkdownTheme()));
      if (flow.error) box.addChild(new Text(theme.fg("error", flow.error), 0, 0));
    }
    return box;
  });

  pi.registerMessageRenderer<{ source: Ref; requestId: string }>(RESULT, (message, _options, theme) => {
    const box = new Container();
    const name = message.details?.source ? label(message.details.source) : "child";
    box.addChild(new Text(theme.fg("accent", `Result from ${name}`), 0, 0));
    box.addChild(new Markdown(typeof message.content === "string" ? message.content : "", 0, 0, getMarkdownTheme()));
    return box;
  });

  pi.on("session_start", async (event, ctx) => {
    live = true;
    const pending = shared.pending;
    const current = ctx.sessionManager;
    // A fresh runtime has the only valid pi API for naming/initializing the clone.
    if (event.reason === "fork" && pending && current.getSessionId() !== pending.source.id
      && resolve(current.getHeader()?.parentSession ?? "") === pending.source.file
      && current.getBranch().some(entry => entry.id === pending.leafId)) {
      pi.setSessionName(pending.name);
      pi.appendEntry<Lineage>(LINEAGE, { ...pending.lineage, sessionId: current.getSessionId() });
      pending.initialized = current.getSessionId();
    }
    if (ctx.sessionManager.getSessionFile()) await showAncestors(ctx);
  });

  pi.on("session_shutdown", () => { live = false; controller?.abort(); });
  pi.on("session_before_switch", () => {
    if (shared.busy && !shared.busy.transferring) return { cancel: true };
  });
  pi.on("session_before_fork", () => {
    if (shared.busy?.kind === "distill") return { cancel: true };
  });

  pi.registerCommand("dive", {
    description: "Clone the current state into a named child: /dive <name>",
    handler: async (args, ctx) => {
      let token: string | undefined;
      let replaced = false;
      try {
        requireIdle(ctx);
        if (ctx.mode !== "tui") throw new Error("/dive requires interactive TUI mode.");
        const name = cleanName(args.replace(/^("[\s\S]*"|'[\s\S]*')$/, value => value.slice(1, -1)));
        if (!name || name.length > 100) throw new Error("Usage: /dive <name>, up to 100 characters.");
        token = acquire("dive");
        const source = currentSnapshot(ctx);
        const leafId = ctx.sessionManager.getLeafId();
        if (!leafId) throw new Error("Nothing to clone yet.");
        const ancestors = await ancestorRefs(source);
        requireIdle(ctx);
        if (ctx.sessionManager.getLeafId() !== leafId) throw new Error("Session changed; run /dive again.");
        const parent: Ref = { id: source.id, file: source.file, name: source.name };
        shared.pending = {
          token, source: parent, leafId, name,
          lineage: { version: 1, parent, ancestors: [...ancestors, parent], forkEntryId: leafId },
        };
        const result = await ctx.fork(leafId, { position: "at", withSession: async fresh => {
          replaced = true;
          fresh.ui.setEditorText("");
          if (shared.pending?.initialized !== fresh.sessionManager.getSessionId()) {
            fresh.ui.notify("Clone created, but lineage initialization failed. Do not distill until this is repaired.", "error");
          }
        } });
        if (result.cancelled && live) ctx.ui.notify("Dive cancelled.", "info");
      } catch (error) {
        if (!replaced && live) ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
      } finally { release(token); }
    },
  });

  pi.registerCommand("distill", {
    description: "Review a child report in $EDITOR and return it to its parent: /distill [instructions]",
    handler: async (args, ctx) => {
      let token: string | undefined;
      let replaced = false;
      let draft: Flow | undefined;
      try {
        requireIdle(ctx);
        if (ctx.mode !== "tui") throw new Error("/distill requires interactive TUI mode.");
        const editor = process.env.EDITOR?.trim();
        if (!editor) throw new Error("Set $EDITOR first (for example, vim). Exit 0 accepts; :cq cancels.");
        if (!ctx.model) throw new Error("No current model.");
        if (/^--to(?:\s|=|$)/.test(args)) throw new Error("This version returns only to the direct parent; --to is not supported yet.");
        token = acquire("distill");
        const source = currentSnapshot(ctx);
        const lineage = getLineage(ctx.sessionManager.getBranch(), source.id);
        if (!source.parentFile) throw new Error("This session has no parent. Use /dive <name> first.");
        const parent = await readSnapshot(source.parentFile);
        if (lineage && parent.id !== lineage.parent.id) throw new Error("Parent session identity changed; refusing to transfer context.");
        const target: Ref = { id: parent.id, file: parent.file, name: parent.name };
        const sourceRef: Ref = { id: source.id, file: source.file, name: source.name };
        const branch = ctx.sessionManager.getBranch();
        const forkIndex = lineage ? branch.findIndex(entry => entry.id === lineage.forkEntryId) : -1;
        const firstChild = forkIndex < 0 ? undefined : branch.slice(forkIndex + 1)
          .find(entry => entry.type === "message" && entry.message.role === "user");
        const firstText = firstChild?.type === "message" ? firstChild.message.content : undefined;
        const boundary = typeof firstText === "string" ? firstText : Array.isArray(firstText)
          ? firstText.filter(block => block.type === "text").map(block => block.text).join("\n") : "";
        const instructions = [DEFAULT_INSTRUCTION,
          `Child session: ${label(sourceRef)}. Parent session: ${label(target)}.`,
          ...(boundary ? [`The first user message after the fork started with:\n${boundary.slice(0, 2000)}`] : []),
          ...(args.trim() ? [`Additional instructions from the user:\n${args.trim()}`] : []),
        ].join("\n\n");
        requireIdle(ctx);
        const messages = convertToLlm(ctx.sessionManager.buildSessionProjection().messages);
        if (messages[0]?.role !== "system") throw new Error("No recorded system prompt. Send a normal prompt before using /distill.");
        const model = ctx.model;
        const reasoning = pi.getThinkingLevel();
        controller = new AbortController();
        let failure: unknown;
        const response = await ctx.ui.custom<any>((tui, theme, _keys, done) => {
          const loader = new BorderedLoader(tui, theme, `Distilling ${label(sourceRef)} → ${label(target)}…`);
          loader.onAbort = () => controller?.abort();
          const signal = AbortSignal.any([controller!.signal, loader.signal]);
          Promise.resolve().then(() => ctx.modelRegistry.streamSimple(model, {
            messages: [...messages, { role: "user", content: instructions, timestamp: Date.now() }],
          }, { sessionId: source.id, cacheRetention: "short", reasoning, maxTokens: Math.min(8192, model.maxTokens), signal }).result())
            .then(done, error => { failure = error; done(undefined); });
          return loader;
        });
        if (!live) return;
        const text = response?.content?.filter((block: any) => block.type === "text").map((block: any) => block.text).join("\n").trim() ?? "";
        draft = { kind: "draft", requestId: randomUUID(), sessionId: source.id, source: sourceRef, target,
          instructions, userInstructions: args.trim(), text, provider: model.provider, model: model.id, reasoning,
          responseModel: response?.responseModel, providerThinkingLevel: response?.providerThinkingLevel,
          usage: response?.usage, stopReason: response?.stopReason,
          error: failure ? String(failure) : response?.errorMessage };
        pi.appendEntry<Flow>(FLOW, draft);
        const aborted = controller.signal.aborted;
        controller.abort(); // Also release an unexpected parked tool call in provider bridges.
        controller = undefined;
        if (aborted || failure || response?.stopReason !== "stop" || !text
          || response.content.some((block: any) => block.type === "toolCall")) {
          throw new Error(aborted ? "Distill cancelled; staying in child. Any returned draft/usage was saved."
            : draft.error ?? `Distill did not produce a complete text report (${response?.stopReason ?? "error"}). Draft saved.`);
        }
        let edited: Awaited<ReturnType<typeof editExternally>>;
        try { edited = await editExternally(ctx, editor, text); }
        catch (error) { edited = { code: null, error: error instanceof Error ? error.message : String(error) }; }
        const review: Flow = { kind: "review", requestId: draft.requestId, sessionId: source.id,
          source: sourceRef, target, editedText: edited.text, editorExitCode: edited.code,
          status: edited.error ? "editor error" : edited.code === 0 ? "approved" : "cancelled", error: edited.error };
        pi.appendEntry<Flow>(FLOW, review);
        if (edited.error) throw new Error(`${edited.error} Staying in child; generated draft saved.`);
        if (edited.code !== 0) { ctx.ui.notify("Distill cancelled; staying in child. Draft and edits saved outside model context.", "info"); return; }
        if (!edited.text?.trim()) throw new Error("Edited report is empty; staying in child.");
        requireIdle(ctx);
        if ((await readSnapshot(target.file)).id !== target.id) throw new Error("Parent session identity changed; staying in child.");
        shared.busy!.transferring = true;
        let rollbackContext: ExtensionCommandContext | undefined;
        let transferError: string | undefined;
        const result = await ctx.switchSession(target.file, { withSession: async fresh => {
          replaced = true;
          try {
            if (fresh.sessionManager.getSessionId() !== target.id) throw new Error("Unexpected parent session.");
            const alreadySent = fresh.sessionManager.getEntries().some(entry => entry.type === "custom_message"
              && entry.customType === RESULT && (entry.details as any)?.requestId === draft!.requestId);
            if (!alreadySent) await fresh.sendMessage({ customType: RESULT, content: edited.text!, display: true,
              details: { source: sourceRef, requestId: draft!.requestId } }, { triggerTurn: false });
          } catch (error) {
            rollbackContext = fresh;
            transferError = error instanceof Error ? error.message : String(error);
          }
        } });
        // Wait for replacement to finish before starting another replacement.
        // Only the fresh parent context is valid here, never the old ctx/pi.
        if (rollbackContext) {
          const fresh = rollbackContext;
          const rollback = await fresh.switchSession(source.file, { withSession: async child => {
            child.ui.notify(`Transfer failed: ${transferError}. Returned to child; draft saved.`, "error");
          } });
          if (rollback.cancelled) fresh.ui.notify(`Transfer failed: ${transferError}. Draft remains in ${source.file}`, "error");
        }
        if (result.cancelled && live) ctx.ui.notify("Parent switch cancelled; staying in child. Approved report saved.", "warning");
      } catch (error) {
        if (!replaced && live) ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
      } finally {
        controller?.abort(); controller = undefined;
        release(token);
      }
    },
  });

  pi.registerCommand("surface", {
    description: "Switch to the direct parent session without transferring context",
    handler: async (_args, ctx) => {
      try {
        if (shared.busy) throw new Error(`/${shared.busy.kind} is already in progress.`);
        requireIdle(ctx);
        const source = currentSnapshot(ctx);
        if (!source.parentFile) throw new Error("This session has no parent. Use /dive <name> first.");
        const lineage = getLineage(ctx.sessionManager.getBranch(), source.id);
        const parent = await readSnapshot(source.parentFile);
        if (lineage && parent.id !== lineage.parent.id) throw new Error("Parent session identity changed; staying in child.");
        const result = await ctx.switchSession(parent.file);
        if (result.cancelled && live) ctx.ui.notify("Parent switch cancelled; staying in child.", "warning");
      } catch (error) {
        if (live) ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
      }
    },
  });

  pi.registerCommand("sap", {
    description: "Show API cost of this session and descendants, each counted after its own lineage marker",
    handler: async (_args, ctx) => {
      try {
        const subscriptions = await loadSubscriptions();
        const current = currentSnapshot(ctx);
        const { sessions, incomplete } = await loadSessions(ctx.sessionManager.getSessionDir(), current);
        if (live) ctx.ui.notify(sapReport(current, sessions, incomplete, subscriptions), "info");
      } catch (error) {
        if (live) ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
      }
    },
  });
}
