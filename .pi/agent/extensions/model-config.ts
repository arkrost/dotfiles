import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function modelConfigExtension(pi: ExtensionAPI) {
	pi.registerCommand("model-config", {
		description: "Show current (or specified) model config as JSON",
		handler: async (args, ctx) => {
			let model = ctx.model;

			const trimmed = args?.trim();
			if (trimmed) {
				const parts = trimmed.split(/\s+/);
				if (parts.length >= 2) {
					const [provider, ...modelIdParts] = parts;
					const modelId = modelIdParts.join(" ");
					model = ctx.modelRegistry.find(provider, modelId);
				} else {
					ctx.ui.notify("Usage: /model-config [provider modelId]", "warning");
					return;
				}
			}

			if (!model) {
				ctx.ui.notify("No model found", "error");
				return;
			}

			// Serialize everything except undefined values
			const configJson = JSON.stringify(model, (_key, value) =>
				value === undefined ? undefined : value
			, 2);

			ctx.ui.notify(configJson, "info");
		},
	});
}
