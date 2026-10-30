import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { compact, convertToLlm, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

type Reasoning = ReturnType<ExtensionAPI["getThinkingLevel"]>;
type Selection = { enabled?: boolean; reasoning?: Reasoning | "inherit" };
type ProviderOverride = Selection & Record<string, unknown>;
type Settings = { enabled?: boolean; overrides?: Record<string, ProviderOverride> };

const levels = new Set(["off", "minimal", "low", "medium", "high", "xhigh", "max"]);
const marker = "prefix-compaction";

const summaryInstruction = `Stop working on the task. Do not call tools or make changes.
Create a context checkpoint of the conversation above for another assistant to continue the work.
If an earlier checkpoint is present, merge it and preserve everything still relevant.
Include these sections: Goal; Constraints & Preferences; Progress (Done, In Progress, Blocked);
Key Decisions; Next Steps; Critical Context.
Preserve exact file paths, identifiers, user requirements, unresolved questions and important facts.
The most recent messages will also be kept verbatim. Do not treat this checkpoint request as a user task to preserve.
Be concise: aim for at most 1,000 words. Output only the checkpoint in English, without a preamble.`;

function validateSelection(value: unknown, scope: "root" | "provider" | "model" = "model"): asserts value is Selection {
	if (!value || typeof value !== "object" || Array.isArray(value)) {
		throw new Error("Prefix compaction selection must be an object");
	}
	const allowed = scope === "root" ? ["enabled", "overrides"] : ["enabled", "reasoning"];
	for (const [key, entry] of Object.entries(value)) {
		if (allowed.includes(key)) continue;
		if (scope === "provider") validateSelection(entry);
		else throw new Error(`Unknown prefix compaction setting: ${key}`);
	}
	const selection = value as Selection;
	if (selection.enabled !== undefined && typeof selection.enabled !== "boolean") {
		throw new Error("Prefix compaction enabled must be a boolean");
	}
	if (selection.reasoning !== undefined && selection.reasoning !== "inherit" && !levels.has(selection.reasoning)) {
		throw new Error("Invalid compaction reasoning level");
	}
}

async function loadSettings(): Promise<Settings> {
	const path = join(process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent"), "prefix-compaction.json");
	let settings: Settings;
	try {
		settings = JSON.parse(await readFile(path, "utf8"));
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code === "ENOENT") return {};
		throw error;
	}
	validateSelection(settings, "root");
	if (settings.overrides !== undefined) {
		if (!settings.overrides || typeof settings.overrides !== "object" || Array.isArray(settings.overrides)) {
			throw new Error("overrides must be an object");
		}
		for (const value of Object.values(settings.overrides)) validateSelection(value, "provider");
	}
	return settings;
}

export default function prefixCompaction(pi: ExtensionAPI) {
	pi.registerEntryRenderer<string>(marker, (entry, _options, theme) =>
		new Text(theme.fg("dim", entry.data ?? ""), 0, 0));

	pi.on("session_compact", (event, ctx) => {
		const { usage } = event.compactionEntry;
		const details = event.compactionEntry.details as {
			strategy?: string; reasoning?: string; providerThinkingLevel?: string;
		} | undefined;
		if (!event.fromExtension || details?.strategy !== marker || !details.reasoning) return;
		const effort = details.providerThinkingLevel ? `; provider effort ${details.providerThinkingLevel}` : "";
		const cache = usage
			? `; ${usage.cacheRead.toLocaleString()}/${(usage.input + usage.cacheRead + usage.cacheWrite).toLocaleString()} input tokens cached`
			: "";
		// Report the saved request, not current settings or a possibly changed session level.
		const message = `${marker}: reasoning ${details.reasoning} (sent)${effort}${cache}`;
		// TUI clears transient notifications at compaction_end. A custom entry survives
		// that rebuild and reload, but does not participate in the model context.
		pi.appendEntry(marker, message);
		if (ctx.mode !== "tui") ctx.ui.notify(message, "info");
	});

	pi.on("session_before_compact", async (event, ctx) => {
		let requestAbort: AbortController | undefined;
		try {
			event.signal.throwIfAborted();
			const settings = await loadSettings();
			// Disabling this extension leaves Pi's standard manual/automatic compaction enabled.
			if (settings.enabled === false) return;
			const model = ctx.model;
			if (!model) throw new Error("No current model");
			const key = `${model.provider}/${model.id}`;
			const provider = Object.hasOwn(settings.overrides ?? {}, model.provider)
				? settings.overrides?.[model.provider] : undefined;
			const override = provider && Object.hasOwn(provider, model.id)
				? provider[model.id] as Selection : undefined;
			if ((override?.enabled ?? provider?.enabled ?? true) === false) return;
			const selectedReasoning = override?.reasoning ?? provider?.reasoning ?? "inherit";
			const reasoning = selectedReasoning === "inherit" ? pi.getThinkingLevel() : selectedReasoning;
			const { preparation, signal } = event;

			// A context that already overflowed cannot safely be replayed with more input.
			// Use Pi's smaller serialized summary request, explicitly reporting the cold path.
			if (event.reason === "overflow") {
				ctx.ui.notify("Prefix compaction: context overflow; using standard compaction without prefix reuse", "warning");
				const result = await compact(
					preparation, model, undefined, undefined, event.customInstructions, signal, reasoning,
					(selected, context, options) => ctx.modelRegistry.streamSimple(selected, context, options),
				);
				return { compaction: result };
			}

			// The active projection includes earlier checkpoints and context edits, but not
			// abandoned branches. Keep system/tool declarations and native message structure.
			const messages = convertToLlm(ctx.sessionManager.buildSessionProjection().messages);
			if (messages[0]?.role !== "system") throw new Error("Session context has no leading system message");
			const instruction = event.customInstructions
				? `${summaryInstruction}\n\nAdditional checkpoint instructions from the user:\n${event.customInstructions}`
				: summaryInstruction;
			requestAbort = new AbortController();
			const requestSignal = AbortSignal.any([signal, requestAbort.signal]);
			const response = await ctx.modelRegistry.streamSimple(model, {
				messages: [...messages, { role: "user", content: instruction, timestamp: Date.now() }],
			}, {
				sessionId: ctx.sessionManager.getSessionId(),
				cacheRetention: "short",
				reasoning,
				maxTokens: Math.min(8192, model.maxTokens),
				signal: requestSignal,
			}).result();
			signal.throwIfAborted();
			if (response.stopReason !== "stop" || response.content.some((block) => block.type === "toolCall")) {
				throw new Error(response.errorMessage ?? `Summary did not complete (${response.stopReason})`);
			}
			const text = response.content.filter((block) => block.type === "text").map((block) => block.text).join("\n").trim();
			if (!text) throw new Error("Summary was empty");

			// Pi does not carry file lists from extension-generated checkpoints by itself.
			const previous = [...event.branchEntries].reverse().find((entry) => entry.type === "compaction");
			const details = previous?.type === "compaction" ? previous.details as {
				strategy?: string; readFiles?: string[]; modifiedFiles?: string[];
			} | undefined : undefined;
			const ownCheckpoint = details?.strategy === marker;
			const modified = new Set([...preparation.fileOps.edited, ...preparation.fileOps.written,
				...(ownCheckpoint ? details?.modifiedFiles ?? [] : [])]);
			const read = new Set([...preparation.fileOps.read,
				...(ownCheckpoint ? details?.readFiles ?? [] : [])]);
			const readFiles = [...read].filter((path) => !modified.has(path)).sort();
			const modifiedFiles = [...modified].sort();
			const fileLists = [
				...(readFiles.length ? [`<read-files>\n${readFiles.join("\n")}\n</read-files>`] : []),
				...(modifiedFiles.length ? [`<modified-files>\n${modifiedFiles.join("\n")}\n</modified-files>`] : []),
			];
			const { usage, providerThinkingLevel } = response;
			return {
				compaction: {
					summary: [text, ...fileLists].join("\n\n"),
					firstKeptEntryId: preparation.firstKeptEntryId,
					tokensBefore: preparation.tokensBefore,
					usage,
					details: { strategy: marker, model: key, reasoning, providerThinkingLevel, readFiles, modifiedFiles },
				},
			};
		} catch (error) {
			// Also release a bridge query parked on an unexpected tool call.
			requestAbort?.abort();
			if (!event.signal.aborted) {
				ctx.ui.notify(`Prefix compaction: ${error instanceof Error ? error.message : String(error)}`, "error");
			}
			// Never save a partial summary or silently send a second, cold request.
			return { cancel: true };
		}
	});
}
