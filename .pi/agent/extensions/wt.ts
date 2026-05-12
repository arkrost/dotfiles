import { execFileSync } from "node:child_process";
import { hostname } from "node:os";
import { basename, join, resolve } from "node:path";
import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { randomUUID } from "node:crypto";
import { CURRENT_SESSION_VERSION, type ExtensionFactory } from "@earendil-works/pi-coding-agent";

interface Worktree {
  name: string;
  path: string;
  branch: string;
}

function git(args: string[], cwd: string): string {
  return execFileSync("git", args, {
    cwd,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  }).trim();
}

function listWorktrees(cwd: string): Worktree[] {
  const output = git(["worktree", "list", "--porcelain"], cwd);
  const worktrees: Worktree[] = [];

  let path = "";
  let branch = "";

  const flush = () => {
    if (!path) return;
    worktrees.push({
      name: basename(path),
      path,
      branch: branch || "HEAD",
    });
    path = "";
    branch = "";
  };

  for (const line of output.split("\n")) {
    if (line.startsWith("worktree ")) {
      flush();
      path = line.slice("worktree ".length);
    } else if (line.startsWith("branch ")) {
      branch = line.slice("branch ".length).replace(/^refs\/heads\//, "");
    } else if (line === "detached") {
      branch = "HEAD";
    } else if (line === "") {
      flush();
    }
  }

  flush();
  return worktrees;
}

function findWorktree(worktrees: Worktree[], query: string): Worktree | undefined {
  const resolved = resolve(query);
  return worktrees.find(
    (wt) => wt.name === query || wt.branch === query || wt.path === query || wt.path === resolved,
  );
}

function emitOsc7(cwd: string): void {
  const encodedPath = cwd
    .split("/")
    .map((part) => encodeURIComponent(part))
    .join("/");
  process.stdout.write(`\x1b]7;file://${hostname()}${encodedPath}\x07`);
}

const extension: ExtensionFactory = async (pi) => {
  let cwdForCompletions = process.cwd();

  pi.on("session_start", (event) => {
    cwdForCompletions = event.cwd;
  });

  pi.registerCommand("wt", {
    description: "Start an empty session in a git worktree",

    getArgumentCompletions(prefix) {
      try {
        const items = listWorktrees(cwdForCompletions)
          .filter((wt) => wt.name.startsWith(prefix) || wt.branch.startsWith(prefix))
          .map((wt) => ({
            value: wt.name,
            label: `${wt.name}  ${wt.branch}`,
          }));

        return items.length > 0 ? items : null;
      } catch {
        return null;
      }
    },

    handler: async (args, ctx) => {
      cwdForCompletions = ctx.cwd;

      const query = args.trim();
      if (!query) {
        ctx.ui.notify("Usage: /wt <worktree-name|branch|path>", "error");
        return;
      }

      let target: Worktree | undefined;
      try {
        target = findWorktree(listWorktrees(ctx.cwd), query);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        ctx.ui.notify(`Unable to list git worktrees: ${message}`, "error");
        return;
      }

      if (!target) {
        ctx.ui.notify(`Worktree not found: ${query}`, "error");
        return;
      }

      if (!existsSync(target.path)) {
        ctx.ui.notify(`Worktree path does not exist: ${target.path}`, "error");
        return;
      }

      await ctx.waitForIdle();

      process.chdir(target.path);
      emitOsc7(target.path);
      cwdForCompletions = target.path;

      const sessionDir = join(target.path, ".pi", "sessions");
      mkdirSync(sessionDir, { recursive: true });

      const id = randomUUID();
      const timestamp = new Date().toISOString();
      const fileTimestamp = timestamp.replace(/[:.]/g, "-");
      const sessionFile = join(sessionDir, `${fileTimestamp}_${id}.jsonl`);

      writeFileSync(
        sessionFile,
        `${JSON.stringify({
          type: "session",
          version: CURRENT_SESSION_VERSION,
          id,
          timestamp,
          cwd: target.path,
        })}\n`,
      );

      await ctx.switchSession(sessionFile, {
        withSession: async (nextCtx) => {
          nextCtx.ui.notify(`New empty session in ${target.path}`, "info");
        },
      });
    },
  });
};

export default extension;
