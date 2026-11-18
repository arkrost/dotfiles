import { expect, mock, test } from "bun:test";

// Pause SDK initialization so we can cancel deterministically before dispatch.
let begin!: () => void, release!: () => void;
const started = new Promise<void>(r => begin = r), gate = new Promise<void>(r => release = r);
const model = { id: "tiny", provider: "fake" };
let prompts = 0, disposed = false;
mock.module("@earendil-works/pi-coding-agent", () => ({
  SettingsManager: { create() {} },
  SessionManager: { create: () => ({ getSessionId: () => "child", getSessionFile: () => "child.jsonl" }) },
  createAgentSession: async () => {
    begin(); await gate;
    return { session: { model, messages: [], bindExtensions() {}, prompt() { prompts++; }, extensionRunner: { emit() {} }, dispose() { disposed = true; } } };
  },
}));
mock.module("@earendil-works/pi-ai", () => ({ StringEnum: Object, getSupportedThinkingLevels: () => ["off"] }));
mock.module("typebox", () => ({ Type: { Object: Object, String: () => ({}), Optional: Object } }));
const { default: extension } = await import("../agent/extensions/agents.ts");

test("a pending call blocks navigation, cancellation disposes it without prompting", async () => {
  const tools: any = {}, commands: any = {}, handlers: any = {}, entries: any[] = [], notices: any[] = [];
  const pi: any = { on: (n, h) => handlers[n] = h, registerTool: t => tools[t.name] = t, registerCommand: (n, c) => commands[n] = c,
    getActiveTools: () => ["bash"], appendEntry: (customType, data) => entries.push({ type: "custom", customType, data }) };
  extension(pi);
  const ctx: any = { model, cwd: "/tmp", scopedModels: [{ model }], mode: "tui", isProjectTrusted: () => false,
    sessionManager: { getEntries: () => entries, getSessionDir: () => "/tmp", getSessionFile: () => "/tmp/parent" }, ui: { notify: msg => notices.push(msg) } };
  const controller = new AbortController();
  const call = tools.agent.execute("x", { task: "test" }, controller.signal, undefined, ctx);
  await started;
  expect(handlers.session_before_switch()).toEqual({ cancel: true });
  await commands.agents.handler("", ctx);
  expect(notices.join("")).toMatch(/wait/i);
  await expect(tools.agent.execute("other", { session_id: "child", task: "again" }, undefined, undefined, ctx)).rejects.toThrow("busy");
  controller.abort(); release();
  await expect(call).rejects.toThrow("session_id: child");
  expect(prompts).toBe(0); expect(disposed).toBe(true);
  expect(handlers.session_before_switch()).toBeUndefined();
  expect(entries.at(-1).data.status).toBe("failed");
});
