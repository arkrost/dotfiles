import { readFile, stat } from "node:fs/promises";
import { homedir } from "node:os";
import { isAbsolute, resolve } from "node:path";
import type { ExtensionAPI, SessionManager } from "@earendil-works/pi-coding-agent";

const MAX_BYTES = 2 * 1024 * 1024;

/** Snapshot context now, without starting a turn or depending on the source later. */
export default function (pi: ExtensionAPI) {
  pi.registerCommand("ctx", {
    description: "Save context without running the model: /ctx <file | text> (or --file / --text)",
    handler: async (args, ctx) => {
      try {
        if (!ctx.isIdle()) throw new Error("Agent is busy. Add context when it is idle.");
        let input = args.trim();
        if (!input) throw new Error("Usage: /ctx <file | text>, /ctx --file <path>, /ctx --text <text>");
        const forceText = /^--text(?:\s|$)/.test(input);
        const fileOption = /^--file(?:\s|$)/.test(input);
        const forceFile = fileOption || input.startsWith("@");
        if (forceText || fileOption) input = input.slice(6).trim();
        else if (input.startsWith("@")) input = input.slice(1).trim();
        if (!input) throw new Error("Context argument is empty.");
        const unquoted = /^("[\s\S]*"|'[\s\S]*')$/.test(input) ? input.slice(1, -1) : input;
        const expanded = unquoted === "~" ? homedir() : unquoted.startsWith("~/") ? resolve(homedir(), unquoted.slice(2)) : unquoted;
        const path = isAbsolute(expanded) ? expanded : resolve(ctx.cwd, expanded);
        let source = "text";
        let content = input;
        if (!forceText) {
          let info;
          try {
            info = await stat(path);
          } catch (error) {
            if ((error as NodeJS.ErrnoException).code !== "ENOENT" && (error as NodeJS.ErrnoException).code !== "ENAMETOOLONG") throw error;
          }
          const looksLikePath = /^(?:~\/|\/|\.{1,2}\/)/.test(unquoted) || /\.(?:md|txt|jsonl?|ya?ml)$/i.test(unquoted);
          if (info) {
            if (!info.isFile()) throw new Error(`Not a file: ${path}`);
            if (info.size > MAX_BYTES) throw new Error("Context file exceeds 2 MiB. Select a smaller document.");
            const data = await readFile(path);
            if (data.length > MAX_BYTES) throw new Error("Context file exceeds 2 MiB.");
            if (data.includes(0)) throw new Error("Context must be a UTF-8 text file, not binary data.");
            content = new TextDecoder("utf-8", { fatal: true }).decode(data);
            source = path;
          } else if (forceFile || looksLikePath) {
            throw new Error(`File not found: ${path}. Use --text for literal text.`);
          }
        }
        if (!content.trim()) throw new Error("Context is empty.");
        if (Buffer.byteLength(content, "utf8") > MAX_BYTES) throw new Error("Context exceeds 2 MiB.");
        // A run can start while file I/O is pending. Do not steer or queue a turn.
        if (!ctx.isIdle()) throw new Error("Agent became busy. Context was not added; try again when idle.");
        if (!ctx.sessionManager.getSessionFile()) throw new Error("This is an in-memory session. Start a persistent session before using /ctx.");
        pi.sendMessage({
          customType: "saved-context",
          content: content,
          display: true,
          details: { source, bytes: Buffer.byteLength(content, "utf8") },
        }, { triggerTurn: false });
      } catch (error) {
        ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
      }
    },
  });
}
