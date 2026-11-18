import { createAssistantMessageEventStream } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  const cost = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 };
  pi.registerProvider("agents-fixture", {
    baseUrl: "http://localhost", apiKey: "fixture", api: "agents-fixture-api",
    models: ["fixture", "other"].map(id => ({ id, name: id, reasoning: true, input: ["text"], cost, contextWindow: 100000, maxTokens: 1000 })),
    streamSimple(model, context, options) {
      const stream = createAssistantMessageEventStream();
      const output: any = { role: "assistant", content: [], api: model.api, provider: model.provider, model: model.id, usage: { ...cost, totalTokens: 0, cost: { ...cost, total: 0 } }, timestamp: Date.now() };
      queueMicrotask(() => {
        stream.push({ type: "start", partial: output });
        const last: any = context.messages.at(-1);
        const text = typeof last.content === "string" ? last.content : last.content.filter((p: any) => p.type === "text").map((p: any) => p.text).join(" ");
        if (last.role === "user" && (text.startsWith("call ") || text === "launch fixture" || text === "remember cobalt")) {
          const [name, args] = text === "launch fixture" ? ["agent", { task: "child fixture" }] : text === "remember cobalt" ? ["bash", { command: "printf SHELL_OK" }] : JSON.parse(text.slice(5));
          const call = { type: "toolCall", id: `call-${Date.now()}`, name, arguments: args };
          output.content.push(call);
          stream.push({ type: "toolcall_start", contentIndex: 0, partial: output });
          stream.push({ type: "toolcall_end", contentIndex: 0, toolCall: call, partial: output });
          output.stopReason = "toolUse";
        } else {
          const answer = last.role === "toolResult" ? (last.toolName === "bash" ? text : "parent fixture response") : text === "child fixture" ? "child fixture result" : JSON.stringify({ history: context.messages.filter(m => m.role === "user").map(m => m.content), tools: context.tools?.map(t => t.name), thinking: options?.reasoning });
          output.content.push({ type: "text", text: answer });
          stream.push({ type: "text_start", contentIndex: 0, partial: output });
          stream.push({ type: "text_delta", contentIndex: 0, delta: answer, partial: output });
          stream.push({ type: "text_end", contentIndex: 0, content: answer, partial: output });
          output.stopReason = "stop";
        }
        stream.push({ type: "done", reason: output.stopReason, message: output });
        stream.end();
      });
      return stream;
    },
  });
}
