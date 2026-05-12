/**
 * Custom Footer Extension - compact 1-2 line footer.
 *
 * Line 1 left:  ~/cwd + session-name + context used percent
 * Line 1 right: provider + model + thinking level
 * Line 2:       extension statuses (if any)
 *
 * Enabled by default. Toggle with /custom-footer
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const SESSION_SEPARATOR = " \u2022 "; // •

const THINKING_SYMBOLS: Record<string, string> = {
  off: "\u2205", // ∅
  minimal: "\u2581", // ▁
  low: "\u2582", // ▂
  medium: "\u2584", // ▄
  high: "\u25cf", // ●
  xhigh: "\u25ce", // ◎
};

const FOOTER_THEME: Record<string, string> = {
  pwd: "mdHeading",
  session: "mdLink",
  percentDim: "dim",
  percentWarn: "warning",
  model: "dim",
};

export default function (pi: ExtensionAPI) {
  let enabled = true;
  let colors_enabled = true;
  let extensions_enabled = true;

  const createFooter = (ctx: any) => {
    return (_tui: any, theme: any, footerData: any) => {
      const footerTheme = colors_enabled ? FOOTER_THEME : {};
      const footerFg = (name: string, text: string) => theme.fg(footerTheme[name] || "dim", text);

      return {
        dispose: () => {},
        invalidate: () => {},
        render: (width: number): string[] => {
          // --- Context usage ---
          const contextUsage = ctx.getContextUsage();
          const contextPercent = contextUsage?.percent;
          const contextPercentValue = contextPercent ?? 0;
          const contextPercentStr =
            contextPercent === null || contextPercent === undefined || Number.isNaN(contextPercent)
              ? "?%"
              : `${contextPercent.toFixed(1)}%`;

          // --- PWD ---
          let pwd = ctx.sessionManager.getCwd();
          const home = process.env.HOME || process.env.USERPROFILE;
          if (home && pwd.startsWith(home)) {
            pwd = `~${pwd.slice(home.length)}`;
          }

          // --- Session name ---
          const sessionName = ctx.sessionManager.getSessionName();

          // --- Model info ---
          const modelName = ctx.model?.id || "no-model";
          let modelStr = modelName;

          // --- Thinking level ---
          let thinkingLevel = "off";
          for (const e of ctx.sessionManager.getBranch()) {
            if (e.type === "thinking_level_change") {
              thinkingLevel = (e as { thinkingLevel: string }).thinkingLevel;
            }
          }
          modelStr += ` ${THINKING_SYMBOLS[thinkingLevel] ?? THINKING_SYMBOLS.off}`;

          if (footerData.getAvailableProviderCount() > 1 && ctx.model) {
            modelStr = `(${ctx.model.provider}) ${modelStr}`;
          } else if (ctx.model?.provider) {
            modelStr = `${ctx.model.provider} ${modelStr}`;
          }

          // LINE 1
          let line1Left = footerFg("pwd", pwd);
          if (sessionName) {
            line1Left += theme.fg("dim", SESSION_SEPARATOR) + footerFg("session", sessionName);
          }
          const percentColor = contextPercentValue < 60 ? "percentDim" : "percentWarn";
          line1Left += theme.fg("dim", SESSION_SEPARATOR) + footerFg(percentColor, contextPercentStr);

          const line1Right = footerFg("model", modelStr);
          const lines = [joinLR(line1Left, line1Right, width)];

          // LINE 2
          const extensionStatuses = footerData.getExtensionStatuses();
          if (extensionStatuses.size > 0 && extensions_enabled) {
            const statusLine = Array.from(extensionStatuses.entries())
              .sort(([a], [b]) => a.localeCompare(b))
              .map(([, text]) =>
                String(text)
                  .replace(/[\r\n\t]/g, " ")
                  .replace(/ +/g, " ")
                  .trim(),
              )
              .join(" ");

            lines.push(truncateToWidth(statusLine, width, theme.fg("dim", "...")));
          }

          return lines;
        },
      };
    };
  };

  pi.on("session_start", (_event, ctx) => {
    if (enabled) {
      ctx.ui.setFooter(createFooter(ctx));
    }
  });

  pi.registerCommand("custom-footer:color", {
    description: "Toggle custom-footer color",
    handler: () => {
      colors_enabled = !colors_enabled;
    },
  });

  pi.registerCommand("custom-footer:extensions", {
    description: "Toggle custom-footer extensions",
    handler: () => {
      extensions_enabled = !extensions_enabled;
    },
  });

  pi.registerCommand("custom-footer", {
    description: "Toggle custom footer",
    handler: async (_args, ctx) => {
      enabled = !enabled;
      if (enabled) {
        ctx.ui.setFooter(createFooter(ctx));
        ctx.ui.notify("Custom footer enabled", "info");
      } else {
        ctx.ui.setFooter(undefined);
        ctx.ui.notify("Default footer restored", "info");
      }
    },
  });
}

/** Join left and right strings with padding, truncated to width. */
const joinLR = (left: string, right: string, width: number): string => {
  const leftW = visibleWidth(left);
  const rightW = visibleWidth(right);

  if (leftW + rightW >= width) {
    return truncateToWidth(left + " " + right, width, "");
  }

  const padding = " ".repeat(width - leftW - rightW);
  return left + padding + right;
};
