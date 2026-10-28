import assert from "node:assert/strict";
import { mkdtemp, readFile, writeFile, rm, unlink } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { stripTypeScriptTypes } from "node:module";

const dir = await mkdtemp(join(tmpdir(), "ctx-test-"));
try {
  const source = await readFile(new URL("./index.ts", import.meta.url), "utf8");
  const { default: extension } = await import("data:text/javascript;base64," + Buffer.from(stripTypeScriptTypes(source)).toString("base64"));
  let handler;
  const saved = [], notices = [];
  extension({
    registerCommand: (name, command) => { assert.equal(name, "ctx"); handler = command.handler; },
    sendMessage: (message, options) => {
      assert.equal(options.triggerTurn, false);
      saved.push(structuredClone(message));
    },
  });
  const entries = [];
  const ctx = {
    cwd: dir, isIdle: () => true, ui: { notify: (...args) => notices.push(args) },
    sessionManager: {
      getSessionFile: () => join(dir, "session.jsonl"),
      getEntries: () => entries,
      appendMessage: message => entries.push({ type: "message", message }),
    },
  };
  await handler("literal context", ctx);
  assert.match(saved[0].content, /literal context/);
  const path = join(dir, "handoff with spaces.md");
  await writeFile(path, "HANDOFF SNAPSHOT");
  await handler(`"${path}"`, ctx);
  await unlink(path);
  assert.match(saved[1].content, /HANDOFF SNAPSHOT/);
  assert.equal(saved[1].details.source, path);
  await handler("--text /not/a/file.md", ctx);
  assert.match(saved[2].content, /\/not\/a\/file.md/);
  await handler("missing.md", ctx);
  await handler("--file absent", ctx);
  await handler(dir, ctx);
  await handler("", ctx);
  await handler("--text ", ctx);
  assert.equal(saved.length, 3);
  const binary = join(dir, "binary");
  await writeFile(binary, Buffer.from([0, 255, 0]));
  await handler(binary, ctx);
  const invalid = join(dir, "invalid");
  await writeFile(invalid, Buffer.from([255, 255]));
  await handler(invalid, ctx);
  const large = join(dir, "large");
  await writeFile(large, "x".repeat(2 * 1024 * 1024 + 1));
  await handler(large, ctx);
  await handler("do not start", { ...ctx, isIdle: () => false });
  let checks = 0;
  await handler("race", { ...ctx, isIdle: () => ++checks === 1 });
  assert.equal(saved.length, 3);
  assert.equal(notices.at(-1)[1], "error");
  assert.equal(saved.filter(m => m.customType === "saved-context").length, 3);
  assert.equal(entries.length, 1, "fresh-session persistence marker is appended only once");
  await handler("memory", { ...ctx, sessionManager: { getSessionFile: () => undefined } });
  assert.equal(saved.length, 3, "in-memory sessions must not claim durable storage");
  console.log("PASS: file/text snapshot, quoted paths, append, missing/binary/oversize input, idle guard, no triggerTurn");
} finally {
  await rm(dir, { recursive: true, force: true });
}
