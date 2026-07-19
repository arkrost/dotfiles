import {
  UserMessageComponent,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";

const originalRender = UserMessageComponent.prototype.render;
let theme: any;
let patchApplied = false;

function applyPatch(): void {
  if (patchApplied) return;

  UserMessageComponent.prototype.render = function (width: number): string[] {
    const lines = originalRender.call(this, width);
    if (lines.length === 0) return lines;

    const ruleText = "─".repeat(Math.max(0, width));
    const rule = theme ? theme.fg("border", ruleText) : ruleText;
    return [rule, ...lines, rule];
  };

  patchApplied = true;
}

function restoreOriginal(): void {
  if (!patchApplied) return;
  UserMessageComponent.prototype.render = originalRender;
  patchApplied = false;
}

export default function (pi: ExtensionAPI): void {
  applyPatch();

  pi.on("session_start", (_event, ctx) => {
    theme = ctx.ui.theme;
  });

  pi.on("session_shutdown", () => {
    restoreOriginal();
    theme = undefined;
  });
}
