"""Offline integration test: real Pi TUI, PTY, vim, and a stubbed provider.
Requires Python pyte, pi, and vim on PATH. No provider requests are made.
"""
import codecs
import fcntl
import json
import os
from pathlib import Path
import pty
import re
import select
import shutil
import signal
import struct
import tempfile
import termios
import time
import uuid
import pyte

root = Path(tempfile.mkdtemp(prefix="mangroove-tui-"))
agent = root / "agent"
agent.mkdir()
(agent / "settings.json").write_text(json.dumps({"packages": [], "enableInstallTelemetry": False,
    "cacheWarming": "off", "compaction": {"enabled": False}, "defaultTools": []}))
(agent / "mangroove.json").write_text(json.dumps({"billing": {"subscription": ["openai-codex"]}}))
usage = {"input": 10, "output": 20, "cacheRead": 90, "cacheWrite": 0, "totalTokens": 120,
    "cost": {"input": 0.01, "output": 0.01, "cacheRead": 0, "cacheWrite": 0, "total": 0.02}}
now = "2026-10-29T00:00:00.000Z"
entries = [{"type": "session", "version": 3, "id": str(uuid.uuid4()), "timestamp": now, "cwd": str(root)}]
parent = None

def add(kind, **data):
    global parent
    item = {"type": kind, "id": uuid.uuid4().hex[:8], "parentId": parent, "timestamp": now, **data}
    parent = item["id"]
    entries.append(item)

add("model_change", provider="openai-codex", modelId="gpt-6.1-sol")
add("thinking_level_change", thinkingLevel="high")
add("session_info", name="master")
add("message", message={"role": "system", "content": "Synthetic offline test.", "timestamp": 1, "toolsAdded": []})
add("message", message={"role": "user", "content": "Parent task", "timestamp": 2})
add("message", message={"role": "assistant", "content": [{"type": "text", "text": "Parent answer"}],
    "provider": "openai-codex", "api": "openai-codex-responses", "model": "gpt-6.1-sol",
    "stopReason": "stop", "usage": usage, "timestamp": 3})
add("custom_message", customType="saved-context", content="CURRENT_LEAF_CONTEXT", display=True)
session = root / "master.jsonl"
session.write_text("\n".join(json.dumps(item) for item in entries) + "\n")
summary_usage = {**usage, "cost": {**usage["cost"], "input": 0.25, "output": 0.25, "total": 0.5}}
observer = root / "offline.ts"
observer.write_text('''import { appendFileSync, writeFileSync } from 'node:fs';
export default function(pi) {
  pi.on('session_start', (_, ctx) => {
    const registry = ctx.modelRegistry, original = registry.streamSimple;
    registry.streamSimple = (model, context, options) => {
      appendFileSync(TRACE, JSON.stringify({ context, reasoning: options.reasoning }) + '\\n');
      return { result: async () => ({ content: [{ type: 'text', text: 'ORIGINAL_DRAFT_ONLY_NOT_MODEL' }],
        stopReason: 'stop', usage: USAGE }) };
    };
    pi.on('session_shutdown', () => { registry.streamSimple = original; });
    writeFileSync(READY, 'ready');
  });
  pi.registerCommand('fixture-low', { description: 'test only', handler: async () => { pi.setThinkingLevel('low'); } });
  pi.registerCommand('fixture-context', { description: 'test only', handler: async (_, ctx) => {
    pi.sendMessage({ customType: 'saved-context', content: 'CHILD_CONTEXT', display: true }, { triggerTurn: false });
  } });
  pi.registerCommand('probe-flow', { description: 'test only', handler: async (_, ctx) => {
    writeFileSync(PROBE, JSON.stringify({ file: ctx.sessionManager.getSessionFile(),
      id: ctx.sessionManager.getSessionId(), name: ctx.sessionManager.getSessionName(),
      entries: ctx.sessionManager.getEntries(), projection: ctx.sessionManager.buildSessionProjection() }));
  } });
}
'''.replace("TRACE", json.dumps(str(root / "requests.log")))
    .replace("USAGE", json.dumps(summary_usage)).replace("READY", json.dumps(str(root / "ready")))
    .replace("PROBE", json.dumps(str(root / "probe.json")) ))
pi = os.environ.get("PI_BIN") or shutil.which("pi")
assert pi and shutil.which("vim"), "pi and vim must be on PATH"
args = [pi, "--offline", "--no-extensions", "--no-context-files", "--no-skills", "--no-prompt-templates",
    "--no-themes", "--no-mcp", "--session", str(session), "--model", "openai-codex/gpt-6.1-sol",
    "--thinking", "high", "-e", str(Path(__file__).resolve().parent / "index.ts"), "-e", str(observer)]
pid, fd = pty.fork()
if pid == 0:
    os.chdir(root)
    env = {**os.environ, "PI_CODING_AGENT_DIR": str(agent), "TERM": "xterm-256color", "EDITOR": "vim -Nu NONE -n -i NONE"}
    env.pop("PI_SESSION_FILE", None)
    env.pop("PI_SESSION_ID", None)
    os.execvpe(pi, args, env)
fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 60, 160, 0, 0))
class Screen(pyte.Screen):
    # vim can emit private SGR sequences that pyte does not accept as kwargs.
    def select_graphic_rendition(self, *attrs, **_kwargs):
        super().select_graphic_rendition(*attrs)

screen = Screen(160, 60)
stream = pyte.Stream(screen)
decoder = codecs.getincrementaldecoder("utf-8")("replace")
raw = bytearray()

def pump(seconds=1):
    end = time.monotonic() + seconds
    while time.monotonic() < end:
        if select.select([fd], [], [], min(0.1, max(0, end - time.monotonic())))[0]:
            try: data = os.read(fd, 65536)
            except OSError: break
            if not data: break
            raw.extend(data)
            stream.feed(decoder.decode(data))
            if b"\x1b[6n" in data: os.write(fd, b"\x1b[1;1R")

def frame(): return "\n".join(screen.display)

def command(text, delay=1):
    os.write(fd, text.encode()); pump(0.15); os.write(fd, b"\r"); pump(delay)

def probe():
    command("/probe-flow")
    return json.loads((root / "probe.json").read_text())

def accept(text):
    os.write(fd, b"\x1bggdGi" + text.encode() + b"\x1b:x\r"); pump(2)

try:
    pump(4)
    assert (root / "ready").exists(), "Pi must start"
    command("/dive scout", 2)
    scout = probe()
    assert scout["name"] == "scout", frame()
    assert any(item["id"] == parent for item in scout["entries"]), "clone includes exact current leaf"
    assert any(line.strip() == "master" for line in screen.display), "only ancestor appears above editor"
    command("/fixture-context")
    command("/dive prompt", 2)
    prompt = probe()
    assert prompt["name"] == "prompt", frame()
    assert any(line.strip() == "master → scout" for line in screen.display), frame()
    command("/distill Keep exact paths", 1.5)
    assert "ORIGINAL_DRAFT_ONLY_NOT_MODEL" in frame(), "real vim must receive generated report"
    os.write(fd, b"\x1b:cq\r"); pump(2)
    cancelled = probe()
    assert cancelled["id"] == prompt["id"], "vim :cq stays in child"
    drafts = [item for item in cancelled["entries"] if item.get("customType") == "distill-flow" and item["data"]["kind"] == "draft"]
    assert len(drafts) == 1 and "Keep exact paths" in drafts[0]["data"]["instructions"]
    assert "ORIGINAL_DRAFT_ONLY_NOT_MODEL" not in json.dumps(cancelled["projection"]["messages"])
    command("/sap")
    assert re.search(r"└─ gpt-6\.1-sol:high\s+~\$0\.5000\s+~\$0\.0000", frame()), frame()
    command("/reload", 2)
    assert any(line.strip() == "master → scout" for line in screen.display), "lineage survives reload"
    assert "distill " in frame(), "saved flow has a renderer after reload"
    command("/fixture-low")
    command("/distill Return verified findings", 1.5)
    accept("Reviewed report from prompt.")
    returned = probe()
    assert returned["id"] == scout["id"], frame()
    assert "Result from prompt" in frame(), "named custom result renderer survives session replacement"
    result = [item for item in returned["entries"] if item.get("customType") == "distill-result"]
    assert len(result) == 1 and result[0]["content"].strip() == "Reviewed report from prompt."
    assert result[0]["details"]["source"]["id"] == prompt["id"]
    command("/distill", 1.5)
    accept("Reviewed report from scout.")
    master = probe()
    assert master["file"] == str(session), frame()
    count = len(master["entries"])
    command("/sap", 2)
    (root / "sap-screen.txt").write_text(frame())
    assert re.search(r"TOTAL\s+~\$1\.5200\s+~\$0\.0000", frame()), frame()
    assert re.search(r"openai-codex\s+~\$1\.5200\s+~\$0\.0000", frame()), frame()
    assert re.search(r"└─ gpt-6\.1-sol\s+~\$1\.5200\s+~\$0\.0000", frame()), frame()
    assert re.search(r"├─ low\s+~\$0\.5000\s+~\$0\.0000", frame()), frame()
    assert re.search(r"└─ high\s+~\$1\.0200\s+~\$0\.0000", frame()), frame()
    assert "Sessions: 3" in frame(), frame()
    assert re.search(r"master \(current\)\s+~\$0\.0200\s+~\$0\.0000", frame()), frame()
    assert re.search(r"└─ scout\s+~\$0\.5000\s+~\$0\.0000", frame()), frame()
    assert re.search(r"   └─ prompt\s+~\$1\.0000\s+~\$0\.0000", frame()), frame()
    assert "not invoices" not in frame()
    assert len(probe()["entries"]) == count, "/sap does not append context or metadata"
    command("/surface", 1)
    assert "no parent" in frame() and probe()["file"] == str(session), "/surface is registered and root has no parent"
    requests = [json.loads(line) for line in (root / "requests.log").read_text().splitlines()]
    assert len(requests) == 3, "only three direct report requests; no parent model turns"
    assert [request["reasoning"] for request in requests] == ["high", "low", "high"]
    print(json.dumps({"ok": True, "mode": "real Pi TUI + PTY + vim :cq/:x", "providerCalls": 0,
        "checks": ["current-leaf clone", "ancestor-only widget", "reload", "editor cancel/accept", "UI-only flow",
            "named result in parent", "no automatic parent turn", "/surface registered", "provider/model/reasoning/session totals and single-level folding"], "artifacts": str(root)}), flush=True)
finally:
    (root / "terminal.raw").write_bytes(raw)
    (root / "last-screen.txt").write_text(frame())
    os.kill(pid, signal.SIGKILL)
    os.waitpid(pid, 0)
    os.close(fd)
    print("Artifacts:", root, flush=True)
