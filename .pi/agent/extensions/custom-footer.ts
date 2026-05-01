/**
 * Custom Footer Extension - compact 2-3 line footer with context bar.
 *
 * Line 1 left:  ~/cwd + session-name + label path
 * Line 1 right: git branch
 * Line 2 left:  cost
 * Line 2 right: model + provider
 * Line 2 mid:   context occupation bar (diamonds style)
 * Line 3:       extension statuses (if any)
 *
 * Enabled by default. Toggle with /custom-footer
 */

import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

const BAR_USED = '\u25c6'; // ◆
const BAR_FREE = '\u25c7'; // ◇
const BAR_RESERVED = '\u26cb'; // ⛋
const LABEL_SEPARATOR = ' \u203a '; // ›
const SESSION_SEPARATOR = ' \u2022 '; // •

const THINKING_SYMBOLS = {
  off: '\u2205', // ∅
  minimal: '\u2581', // ▁
  low: '\u2582', // ▂
  medium: '\u2584', // ▄
  high: '\u25cf', // ●
  xhigh: '\u25ce', // ◎
};

const FOOTER_THEME = {
  pwd: 'mdHeading',
  session: 'mdLink',
  git: 'mdCodeBlock',
  label: 'mdListBullet',
};

export default function (pi: ExtensionAPI) {
  let enabled = true;
  let colors_enabled = true;
  let extensions_enabled = true;

  const createFooter = (ctx: any) => {
    return (tui: any, theme: any, footerData: any) => {
      const unsub = footerData.onBranchChange(() => tui.requestRender());

      return {
        dispose: unsub,
        invalidate: () => {},
        render: (width: number): string[] => {
          // --- Token / cost stats ---
          let totalCost = 0;
          for (const e of ctx.sessionManager.getBranch()) {
            if (e.type === 'message' && e.message.role === 'assistant') {
              const m = e.message as AssistantMessage;
              totalCost += m.usage.cost.total;
            }
          }

          // --- Context usage ---
          const contextUsage = ctx.getContextUsage();
          const contextWindow =
            contextUsage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
          const contextPercent = contextUsage?.percent ?? 0;

          // --- PWD ---
          let pwd = ctx.sessionManager.getCwd();
          const home = process.env.HOME || process.env.USERPROFILE;
          if (home && pwd.startsWith(home)) {
            pwd = `~${pwd.slice(home.length)}`;
          }

          // --- Session name ---
          const sessionName = ctx.sessionManager.getSessionName();

          // --- Label path ---
          const labelPath = buildLabelPath(ctx.sessionManager);

          // --- Git branch ---
          const branch = footerData.getGitBranch();

          // --- Model info ---
          const modelName = ctx.model?.id || 'no-model';
          let modelStr = modelName;

          // --- Thinking level ---
          let thinkingLevel = 'off';
          for (const e of ctx.sessionManager.getBranch()) {
            if (e.type === 'thinking_level_change') {
              thinkingLevel = (
                e as { thinkingLevel: string }
              ).thinkingLevel;
            }
          }
          modelStr += ` ${THINKING_SYMBOLS[thinkingLevel] ?? THINKING_SYMBOLS.off}`;

          const footerTheme = colors_enabled ? FOOTER_THEME : {};
          const footerFg = (name, text) => theme.fg(footerTheme[name] || 'dim', text);

          if (footerData.getAvailableProviderCount() > 1 && ctx.model) {
            modelStr = `(${ctx.model.provider}) ${modelStr}`;
          }

          // LINE 1
          let line1Left = footerFg('pwd', pwd);
          if (sessionName) line1Left += theme.fg('dim', SESSION_SEPARATOR) + footerFg('session', sessionName);
          if (labelPath) line1Left += footerFg('label', `${LABEL_SEPARATOR}${labelPath}`);
          const line1Right = !branch ? '' : footerFg('git', `\uE0A0 ${branch}`);

          const line1 = joinLR(line1Left, line1Right, width);

          // LINE 2
          const costStr = `$${totalCost.toFixed(3)}`.padStart(7, ' ');

          const line2Left = theme.fg('dim', costStr);
          const line2Right = theme.fg('dim', modelStr);

          const leftW = visibleWidth(line2Left);
          const rightW = visibleWidth(line2Right);
          const barSpace = Math.max(0, width - leftW - rightW - 2);

          let line2: string;
          if (barSpace < 4) {
            line2 = joinLR(line2Left, line2Right, width);
          } else {
            const bar = buildBricks(
              barSpace,
              contextWindow,
              contextPercent,
              theme,
            );
            line2 = line2Left + ' ' + bar + ' ' + line2Right;
          }

          const lines = [line1, line2];

          // LINE 3
          const extensionStatuses = footerData.getExtensionStatuses();
          if (extensionStatuses.size > 0 && extensions_enabled) {
            const statusLine = Array.from(extensionStatuses.entries())
              .sort(([a], [b]) => a.localeCompare(b))
              .map(([, text]) =>
                text.replace(/[\r\n\t]/g, ' ')
                  .replace(/ +/g, ' ')
                  .trim(),
              )
              .join(' ');

            lines.push(
              truncateToWidth(
                statusLine,
                width,
                theme.fg('dim', '...'),
              ),
            );
          }

          return lines;
        },
      };
    };
  };

  pi.on('session_start', (_event, ctx) => {
    if (enabled) {
      ctx.ui.setFooter(createFooter(ctx));
    }
  });

  pi.registerCommand('custom-footer:color', {
    description: 'Toggle custom-footer color',
    handler: () => {
      colors_enabled = !colors_enabled;
    },
  });

  pi.registerCommand('custom-footer:extensions', {
    description: 'Toggle custom-footer extensions',
    handler: () => {
      extensions_enabled = !extensions_enabled;
    },
  });

  pi.registerCommand('custom-footer', {
    description: 'Toggle custom footer',
    handler: async (_args, ctx) => {
      enabled = !enabled;
      if (enabled) {
        ctx.ui.setFooter(createFooter(ctx));
        ctx.ui.notify('Custom footer enabled', 'info');
      } else {
        ctx.ui.setFooter(undefined);
        ctx.ui.notify('Default footer restored', 'info');
      }
    },
  });
}

/** Walk from current leaf to root, collect labels, return root->leaf order. */
const buildLabelPath = (
  sessionManager: {
    getBranch(fromId?: string): Array<{ id: string }>;
    getLabel(id: string): string | undefined;
  },
): string => {
  const entries = sessionManager.getBranch();
  const labels: string[] = [];

  for (const entry of entries) {
    const label = sessionManager.getLabel(entry.id);
    if (label) labels.push(label);
  }

  return labels.join(LABEL_SEPARATOR);
};

/** Join left and right strings with padding, truncated to width. */
const joinLR = (left: string, right: string, width: number): string => {
  const leftW = visibleWidth(left);
  const rightW = visibleWidth(right);

  if (leftW + rightW >= width) {
    return truncateToWidth(left + ' ' + right, width, '');
  }

  const padding = ' '.repeat(width - leftW - rightW);
  return left + padding + right;
};

/**
 * Build a context occupation bar.
 * ◆ used, ◇ free, ⛋ reserved (~10% compaction headroom).
 */
const buildBricks = (
  cells: number,
  totalTokens: number,
  contextPercent: number,
  theme: { fg: (color: string, text: string) => string },
): string => {
  const n = Math.max(0, Math.min(cells, 200));
  if (n === 0) return '';

  const total = Math.max(1, Math.floor(totalTokens));
  const usedTokens = Math.max(
    0,
    Math.min(total, Math.floor((contextPercent / 100) * total)),
  );

  const reserveFraction = 0.1;
  const reserveTokens = Math.floor(total * reserveFraction);
  const safeTokens = Math.max(0, Math.min(total, total - reserveTokens));

  let safeCells = Math.floor((safeTokens * n) / total);
  safeCells = Math.max(0, Math.min(n, safeCells));
  if (reserveTokens > 0 && n > 1 && safeCells >= n) {
    safeCells = n - 1;
  }

  let usedCells = Math.floor((usedTokens * n) / total);
  if (usedTokens > 0 && usedCells === 0) usedCells = 1;
  usedCells = Math.max(0, Math.min(n, usedCells));

  let usedColor: string;
  if (contextPercent > 90) {
    usedColor = 'error';
  } else if (contextPercent > 70) {
    usedColor = 'warning';
  } else {
    usedColor = 'dim';
  }

  let out = '';
  for (let i = 0; i < usedCells; i++) {
    out += theme.fg(usedColor, BAR_USED);
  }
  for (let i = usedCells; i < safeCells; i++) {
    out += theme.fg('dim', BAR_FREE);
  }
  for (let i = Math.max(usedCells, safeCells); i < n; i++) {
    out += theme.fg('dim', BAR_RESERVED);
  }

  return out;
};
