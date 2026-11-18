import { statSync } from "node:fs";
import { getSupportedThinkingLevels, StringEnum } from "@earendil-works/pi-ai";
import { createAgentSession, SessionManager, SettingsManager, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const LINK = "agents:child", OUTCOME = "agents:outcome";
const emptyScope = "No scoped models. Configure /scoped-models before delegating.";
type Link = { id: string; path: string; name: string; task: string };
const key = (model: { provider: string; id: string }) => `${model.provider}/${model.id}`;
const result = (text: string) => ({ content: [{ type: "text" as const, text }], details: {} });
function entries<T>(ctx: ExtensionContext, kind: string): T[] {
  return ctx.sessionManager.getEntries().flatMap(e => e.type === "custom" && e.customType === kind ? [e.data as T] : []);
}
function checkFile(path: string) {
  if (!statSync(path, { throwIfNoEntry: false })?.size) throw new Error("Session file missing or empty; no replacement created.");
}

export default function (pi: ExtensionAPI) {
  const busy = new Set<string>();
  const guard = () => busy.size ? { cancel: true } : undefined;
  pi.on("session_before_switch", guard);
  pi.on("session_before_fork", guard);

  pi.registerCommand("agents", {
    description: "Open a saved child session or return to its parent",
    async handler(_, ctx) {
      if (ctx.mode !== "tui") return;
      if (busy.size) return ctx.ui.notify("Wait for the agents to finish.", "warning");
      const status = new Map(entries<{ id: string; status: string }>(ctx, OUTCOME).map(e => [e.id, e.status]));
      const choices = entries<Link>(ctx, LINK).map(c => ({ path: c.path, label: `${c.name} · ${status.get(c.id) ?? "interrupted or unknown"} · ${c.task}` }));
      const parent = ctx.sessionManager.getHeader()?.parentSession;
      if (parent) choices.unshift({ path: parent, label: "↑ Parent session" });
      if (!choices.length) return ctx.ui.notify("No agent sessions.", "info");
      const labels = choices.map((c, i) => `${i + 1}. ${c.label}`);
      const selected = await ctx.ui.select("Agent sessions", labels);
      if (!selected) return;
      const path = choices[labels.indexOf(selected)].path;
      try { checkFile(path); await ctx.switchSession(path); }
      catch (e) { ctx.ui.notify(String(e), "error"); }
    },
  });

  pi.registerTool({
    name: "list_subagent_models", label: "Subagent models", description: "List exact model IDs and any pinned thinking levels allowed for delegation.",
    parameters: Type.Object({}),
    async execute(_, _args, _signal, _update, ctx) {
      return result(ctx.scopedModels.map(({ model, thinkingLevel }) => key(model) + (thinkingLevel ? ` (${thinkingLevel})` : "")).join("\n") || emptyScope);
    },
  });

  pi.registerTool({
    name: "agent", label: "Agent", description: "Delegate only on explicit user request. Wait for the reply. Pass session_id to continue a direct child's actual conversation.",
    parameters: Type.Object({ task: Type.String(), name: Type.Optional(Type.String({ description: "Short label for a new child in /agents." })), model: Type.Optional(Type.String({ description: "Exact provider/model from list_subagent_models. Defaults to the parent model if scoped." })),
      effort: Type.Optional(StringEnum(["off", "minimal", "low", "medium", "high", "xhigh", "max"] as const, { description: "Reasoning effort for this child, on launch or resume. Must be supported by its model." })),
      session_id: Type.Optional(Type.String()) }),
    async execute(_, { task, model, session_id, name, effort }, signal, _update, ctx) {
      signal?.throwIfAborted();
      if (!task.trim()) throw new Error("Empty task.");
      if (!ctx.scopedModels.length) throw new Error(emptyScope);
      const parentSession = ctx.sessionManager.getSessionFile();
      if (!parentSession) throw new Error("Save the parent session before delegating.");
      let manager: SessionManager;
      if (session_id !== undefined) {
        const link = entries<Link>(ctx, LINK).find(c => c.id === session_id);
        if (!link) throw new Error("Unknown child session_id for this parent.");
        if (model !== undefined || name !== undefined) throw new Error("On resume omit model and name; the child's saved selection is used.");
        if (busy.has(link.id)) throw new Error("This child session is busy.");
        checkFile(link.path);
        manager = SessionManager.open(link.path);
        if (manager.getSessionId() !== link.id || manager.getHeader()?.parentSession !== parentSession) throw new Error("Child session identity mismatch.");
        const saved = manager.getBranch().findLast(e => e.type === "model_change");
        if (!saved) throw new Error("Child has no saved model selection.");
        model = `${saved.provider}/${saved.modelId}`;
      } else {
        model ??= ctx.model && key(ctx.model);
        manager = SessionManager.create(ctx.cwd, ctx.sessionManager.getSessionDir(), { parentSession });
      }
      const scoped = ctx.scopedModels.find(s => key(s.model) === model);
      if (!scoped) throw new Error(`Model ${model ?? "(none)"} is not scoped. Use list_subagent_models.`);
      const levels = getSupportedThinkingLevels(scoped.model);
      if (effort !== undefined && !levels.includes(effort)) throw new Error(`Unsupported effort ${effort} for ${model}. Supported: ${levels.join(", ")}.`);
      const id = manager.getSessionId();
      busy.add(id);
      let status = "failed";
      try {
        if (!session_id) pi.appendEntry(LINK, { id, path: manager.getSessionFile()!, name: name?.trim() || model!, task: task.replace(/\s+/g, " ").slice(0, 80) } satisfies Link);
        pi.appendEntry(OUTCOME, { id, status: "interrupted or unknown" });
        const { session } = await createAgentSession({ cwd: ctx.cwd, sessionManager: manager, model: scoped.model, scopedModels: [...ctx.scopedModels],
          thinkingLevel: scoped.thinkingLevel ?? (session_id ? undefined : ctx.thinkingLevel), tools: pi.getActiveTools(),
          settingsManager: SettingsManager.create(ctx.cwd, undefined, { projectTrusted: ctx.isProjectTrusted() }),
        });
        const abort = () => { void session.abort(); };
        try {
          await session.bindExtensions({});
          if (!session.model || key(session.model) !== model) throw new Error("Child model selection changed before dispatch.");
          if (effort !== undefined) {
            session.setThinkingLevel(effort);
            if (session.thinkingLevel !== effort) throw new Error(`Could not apply effort ${effort}.`);
          }
          const previous = session.messages.at(-1);
          signal?.addEventListener("abort", abort, { once: true });
          signal?.throwIfAborted();
          await session.prompt(task, { expandPromptTemplates: false });
          signal?.throwIfAborted();
          const last = session.messages.at(-1);
          if (last === previous || last?.role !== "assistant") throw new Error("No new assistant reply.");
          if (last.stopReason === "aborted" || last.stopReason === "error") throw new Error(last.errorMessage || last.stopReason);
          const reply = last.content.filter(p => p.type === "text").map(p => p.text).join("\n");
          status = "completed";
          return result(`session_id: ${id}\n\n${reply.length > 50000 ? reply.slice(0, 50000) + "\n[Truncated; open /agents for the full reply.]" : reply || "(No text output.)"}`);
        } finally {
          signal?.removeEventListener("abort", abort);
          try { await session.extensionRunner.emit({ type: "session_shutdown", reason: "quit" }); } finally { session.dispose(); }
        }
      } catch (e) { throw new Error(`session_id: ${id}\n${String(e)}`); }
      finally { busy.delete(id); pi.appendEntry(OUTCOME, { id, status }); }
    },
  });
}
