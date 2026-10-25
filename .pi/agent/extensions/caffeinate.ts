import { spawn, type ChildProcess } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** Prevent macOS idle sleep while the agent is working, including tool calls. */
export default function (pi: ExtensionAPI) {
  if (process.platform !== "darwin") return;

  let child: ChildProcess | undefined;

  const stop = () => {
    const current = child;
    child = undefined;
    current?.kill();
  };

  pi.on("agent_start", (_event, ctx) => {
    if (child) return;

    // -w also releases the assertion if Pi exits without running cleanup.
    const current = spawn("/usr/bin/caffeinate", ["-i", "-w", String(process.pid)], {
      stdio: "ignore",
    });
    child = current;
    current.unref();

    current.once("error", (error) => {
      if (child === current) child = undefined;
      const message = `Cannot prevent idle sleep: ${error.message}`;
      if (ctx.hasUI) ctx.ui.notify(message, "warning");
      else console.error(message);
    });
    current.once("exit", () => {
      if (child === current) child = undefined;
    });
  });

  // agent_end can be followed by retries or queued work. Wait for final idle.
  pi.on("agent_settled", stop);
  pi.on("session_shutdown", stop);
}
