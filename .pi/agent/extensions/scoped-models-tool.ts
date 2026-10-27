import { Type } from "@earendil-works/pi-ai";
import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const scopedModelsTool = defineTool({
  name: "scoped_models",
  label: "Scoped models",
  description:
    "List this session's scoped models as 'provider/id', the same set as the model selector's 'scoped' view " +
    "(from --models or enabledModels). An optional thinking level from the scope pattern is shown in parentheses.",
  parameters: Type.Object({}),

  async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
    // Pi resolves --models / enabledModels (globs, fuzzy, project settings) into this list.
    const models = ctx.scopedModels.map((s) => ({
      model: `${s.model.provider}/${s.model.id}`,
      thinking: s.thinkingLevel ?? null,
    }));
    const text = models.length
      ? models.map((s) => `- ${s.model}${s.thinking ? ` (${s.thinking})` : ""}`).join("\n")
      : "No scoped models are configured.";
    return { content: [{ type: "text", text }], details: { models } };
  },
});

export default function (pi: ExtensionAPI) {
  pi.registerTool(scopedModelsTool);
}
