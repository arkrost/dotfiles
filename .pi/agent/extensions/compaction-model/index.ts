import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { compact, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

type Reasoning = ReturnType<ExtensionAPI["getThinkingLevel"]>;
type Selection = { model?: string; reasoning?: Reasoning };
type Settings = Selection & { modelOverrides?: Record<string, Selection> };

const levels = new Set(["off", "minimal", "low", "medium", "high", "xhigh", "max"]);

function validateSelection(value: unknown): asserts value is Selection {
	if (!value || typeof value !== "object" || Array.isArray(value)) {
		throw new Error("Compaction selection must be an object");
	}
	const selection = value as Selection;
	if (selection.model !== undefined &&
		(typeof selection.model !== "string" || !/^[^/]+\/.+$/.test(selection.model))) {
		throw new Error("Compaction model must be provider/modelId");
	}
	if (selection.reasoning !== undefined && !levels.has(selection.reasoning)) {
		throw new Error("Invalid compaction reasoning level");
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_before_compact", async (event, ctx) => {
		try {
			const path = join(process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent"), "compaction-model.json");
			let settings: Settings;
			try {
				settings = JSON.parse(await readFile(path, "utf8"));
			} catch (error) {
				if ((error as NodeJS.ErrnoException).code === "ENOENT") return;
				throw error;
			}
			validateSelection(settings);
			if (settings.modelOverrides !== undefined) {
				if (!settings.modelOverrides || typeof settings.modelOverrides !== "object" || Array.isArray(settings.modelOverrides)) {
					throw new Error("modelOverrides must be an object");
				}
				for (const value of Object.values(settings.modelOverrides)) validateSelection(value);
			}
			const current = ctx.model;
			if (!current) throw new Error("No current model");
			const key = `${current.provider}/${current.id}`;
			const override = settings.modelOverrides?.[key];
			const modelId = override?.model ?? settings.model ?? key;
			const reasoning = override?.reasoning ?? settings.reasoning ?? pi.getThinkingLevel();
			if (modelId === key && reasoning === pi.getThinkingLevel()) return;
			const slash = modelId.indexOf("/");
			const model = modelId === key ? current : ctx.modelRegistry.find(modelId.slice(0, slash), modelId.slice(slash + 1));
			if (!model) throw new Error(`Unknown compaction model: ${modelId}`);
			// Keep Pi's standard prompts, split-turn handling, file lists and kept boundary.
			// The session model and thinking level are never changed.
			const result = await compact(
				event.preparation, model, undefined, undefined,
				event.customInstructions, event.signal, reasoning,
				(selected, context, options) => ctx.modelRegistry.streamSimple(selected, context, options),
			);
			return { compaction: result };
		} catch (error) {
			if (!event.signal.aborted) {
				ctx.ui.notify(`Compaction model: ${error instanceof Error ? error.message : String(error)}`, "error");
			}
			// Do not silently send the history to a different model after an error.
			return { cancel: true };
		}
	});
}
