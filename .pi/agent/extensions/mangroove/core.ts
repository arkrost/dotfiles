import { readdir, readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";

export const LINEAGE = "dive-lineage";
export const FLOW = "distill-flow";
export const RESULT = "distill-result";
export const MAX_BYTES = 2 * 1024 * 1024;

export type Ref = { id: string; file: string; name?: string };
export type Lineage = {
  version: 1;
  sessionId: string;
  parent: Ref;
  ancestors: Ref[];
  forkEntryId: string;
};
// JSONL is an open format: other extensions can add entry types.
export type Entry = { type: string; id: string; timestamp?: string; [key: string]: any };
export type Snapshot = { file: string; id: string; name?: string; parentFile?: string; entries: Entry[]; incomplete?: boolean };
export type Cost = { total: number; unknown: boolean };
export type Flow = {
  kind: "draft" | "review";
  requestId: string;
  sessionId: string;
  source: Ref;
  target: Ref;
  instructions?: string;
  userInstructions?: string;
  text?: string;
  editedText?: string;
  provider?: string;
  model?: string;
  responseModel?: string;
  reasoning?: string;
  providerThinkingLevel?: string;
  usage?: any;
  stopReason?: string;
  error?: string;
  status?: string;
  editorExitCode?: number | null;
};

export const DEFAULT_INSTRUCTION = `Stop working on the task. Do not call tools or change files.
Distill the useful result of this child session for its parent session.
Focus on work done in the child, not a repetition of the inherited conversation.
Preserve concrete findings, decisions and their reasons, constraints, exact paths and identifiers,
file changes, verification results, unresolved questions, and any next action the parent needs.
Do not claim that unperformed checks passed. Distinguish facts from assumptions.
Use only sections that are useful. Be concise, self-contained, and aim for at most 1,000 words.
Output only the report in English, without a preamble or instructions to continue this child session.`;

export function cleanName(name: string): string {
  return name.replace(/[\x00-\x1f\x7f-\x9f]/g, " ").trim();
}

export function label(ref: Ref): string { return cleanName(ref.name ?? "") || ref.id.slice(0, 8); }

export function getLineage(entries: Entry[], sessionId: string): Lineage | undefined {
  return [...entries].reverse().find(entry => entry.type === "custom" && entry.customType === LINEAGE
    && entry.data?.version === 1 && entry.data?.sessionId === sessionId)?.data;
}

export function entryUsage(entry: Entry): any | undefined {
  if (entry.type === "message") return entry.message?.usage;
  if (["compaction", "branch_summary", "usage"].includes(entry.type)) return entry.usage;
  if (entry.type === "custom" && entry.customType === FLOW && entry.data?.kind === "draft") {
    // An attempted report with no usage returned has an unknown cost, not zero.
    return entry.data.usage ?? {};
  }
}

export function usageCost(usage: any): Cost {
  const total = usage?.cost?.total;
  const tokens = usage?.totalTokens ?? ((usage?.input ?? 0) + (usage?.output ?? 0)
    + (usage?.cacheRead ?? 0) + (usage?.cacheWrite ?? 0));
  // Conservatively mark unpriced, nonzero usage as unknown, not free.
  return typeof total === "number" && Number.isFinite(total) && total >= 0 && (total > 0 || tokens === 0)
    ? { total, unknown: false } : { total: 0, unknown: true };
}

export function costLabel(cost: Cost): string {
  if (cost.unknown && cost.total === 0) return "$?";
  return `~\$${cost.total.toFixed(4)}${cost.unknown ? " + ?" : ""}`;
}

export async function loadSubscriptions(): Promise<Set<string>> {
  const file = join(process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent"), "mangroove.json");
  let settings: any;
  try { settings = JSON.parse(await readFile(file, "utf8")); }
  catch (error) { if ((error as NodeJS.ErrnoException).code === "ENOENT") return new Set(); throw error; }
  if (!settings || typeof settings !== "object" || Array.isArray(settings)
    || Object.keys(settings).some(key => key !== "billing")) {
    throw new Error("mangroove.json must contain only billing settings.");
  }
  const billing = settings.billing === undefined ? {} : settings.billing;
  if (!billing || typeof billing !== "object" || Array.isArray(billing)
    || Object.keys(billing).some(key => key !== "subscription")) {
    throw new Error("billing must be an object containing only subscription.");
  }
  const providers = billing.subscription === undefined ? [] : billing.subscription;
  if (!Array.isArray(providers) || providers.some(value => typeof value !== "string" || !value.trim() || value !== value.trim())) {
    throw new Error("billing.subscription must be an array of nonempty provider IDs without surrounding whitespace.");
  }
  return new Set(providers);
}

export function snapshot(file: string, header: any, entries: Entry[]): Snapshot {
  return {
    file: resolve(file), id: header.id,
    parentFile: header.parentSession ? resolve(dirname(file), header.parentSession) : undefined,
    name: [...entries].reverse().find(entry => entry.type === "session_info")?.name,
    entries,
  };
}

export async function readSnapshot(file: string): Promise<Snapshot> {
  const entries: Entry[] = [];
  let incomplete = false;
  for (const line of (await readFile(file, "utf8")).split("\n")) {
    if (!line.trim()) continue;
    try { entries.push(JSON.parse(line)); } catch { incomplete = true; }
  }
  const header = entries.shift();
  if (header?.type !== "session" || typeof header.id !== "string") throw new Error(`Invalid session: ${file}`);
  return { ...snapshot(file, header, entries), incomplete };
}

/** Load only the ancestor chain for the widget. No descendant scans or timers. */
export async function ancestorRefs(current: Snapshot): Promise<Ref[]> {
  const saved = getLineage(current.entries, current.id)?.ancestors ?? [];
  const result: Ref[] = [];
  const visited = new Set([current.file]);
  let file = current.parentFile;
  while (file && !visited.has(file)) {
    visited.add(file);
    try {
      const node = await readSnapshot(file);
      result.unshift({ id: node.id, file: node.file, name: node.name });
      file = node.parentFile;
    } catch {
      const index = saved.findIndex(ref => resolve(ref.file) === file);
      if (index >= 0) result.unshift(...saved.slice(0, index + 1));
      else result.unshift({ id: "unavailable", file });
      break;
    }
  }
  return result;
}

export async function loadSessions(directory: string, current: Snapshot): Promise<{ sessions: Map<string, Snapshot>; incomplete: boolean }> {
  const files = new Set<string>([current.file]);
  let incomplete = false;
  try {
    for (const item of await readdir(directory, { withFileTypes: true })) {
      if (item.isFile() && item.name.endsWith(".jsonl")) files.add(resolve(directory, item.name));
    }
  } catch { incomplete = true; }
  const sessions = new Map<string, Snapshot>();
  for (const file of files) {
    try { sessions.set(file, file === current.file ? current : await readSnapshot(file)); }
    catch { incomplete = true; }
  }
  return { sessions, incomplete };
}

export function sapReport(current: Snapshot, sessions: Map<string, Snapshot>, incomplete = false,
  subscriptions: ReadonlySet<string> = new Set()): string {
  const included = new Set([current.file]);
  let changed = true;
  while (changed) {
    changed = false;
    for (const node of sessions.values()) {
      if (!included.has(node.file) && node.parentFile && included.has(node.parentFile)) {
        included.add(node.file); changed = true;
      }
    }
  }
  const total: Cost = { total: 0, unknown: incomplete };
  const actual: Cost = { total: 0, unknown: incomplete };
  type Amounts = { total: Cost; actual: Cost };
  type ModelAmounts = Amounts & { levels: Map<string | undefined, Amounts> };
  const providers = new Map<string | undefined, Amounts & { models: Map<string | undefined, ModelAmounts> }>();
  const ownCosts = new Map<string, { total: Cost; actual: Cost }>();
  for (const file of included) {
    const node = sessions.get(file);
    const unknown = !node || !!node.incomplete;
    const own = { total: { total: 0, unknown }, actual: { total: 0, unknown } };
    ownCosts.set(file, own);
    if (unknown) { total.unknown = true; actual.unknown = true; }
    if (!node) continue;
    const boundary = node.entries.findIndex(entry => entry.type === "custom" && entry.customType === LINEAGE
      && entry.data?.version === 1 && entry.data?.sessionId === node.id);
    // Resolve model selection along tree ancestry, not the last raw entry:
    // /tree can return to a branch that used a different provider/model.
    const selectedModels = new Map<string, { provider?: string; model?: string; reasoning?: string } | undefined>();
    for (let index = 0; index < node.entries.length; index++) {
      const entry = node.entries[index];
      const previous = selectedModels.get(entry.parentId);
      const selected = entry.type === "model_change" ? { ...previous, provider: entry.provider, model: entry.modelId }
        : entry.type === "thinking_level_change" ? { ...previous, reasoning: entry.thinkingLevel } : previous;
      selectedModels.set(entry.id, selected);
      if (index <= boundary) continue;
      const usage = entryUsage(entry);
      if (!usage) continue;
      let provider: unknown, model: unknown, reasoning: unknown;
      if (entry.type === "message") {
        provider = entry.message?.provider;
        model = entry.message?.responseModel ?? entry.message?.model;
        reasoning = entry.message?.thinkingLevel;
        // Legacy assistant messages can use their saved branch setting, but
        // nested tool usage and routed models must not inherit an unrelated level.
        if (reasoning === undefined && entry.message?.role === "assistant" && typeof provider === "string"
          && typeof entry.message?.model === "string" && provider === selected?.provider
          && entry.message.model === selected?.model) reasoning = selected?.reasoning;
      } else if (entry.type === "custom" && entry.customType === FLOW) {
        provider = entry.data?.provider;
        model = entry.data?.responseModel ?? entry.data?.model;
        reasoning = entry.data?.reasoning;
      } else if (entry.type === "usage") {
        provider = entry.provider; model = entry.model;
        reasoning = entry.thinkingLevel ?? entry.reasoning;
      } else if (entry.type === "compaction" || entry.type === "branch_summary") {
        const hint = entry.details?.model;
        provider = entry.details?.provider ?? (typeof hint === "string" && hint.includes("/") ? hint.split("/")[0] : selected?.provider);
        model = typeof hint === "string" ? (typeof provider === "string" && hint.startsWith(`${provider}/`)
          ? hint.slice(provider.length + 1) : hint) : provider === selected?.provider ? selected?.model : undefined;
        reasoning = entry.details?.reasoning ?? entry.details?.thinkingLevel ?? entry.thinkingLevel;
        if (reasoning === undefined && !entry.fromHook && typeof provider === "string" && typeof model === "string"
          && provider === selected?.provider && model === selected?.model) reasoning = selected?.reasoning;
      }
      const key = typeof provider === "string" && provider.trim() ? provider : undefined;
      const modelKey = typeof model === "string" && model.trim() ? model : undefined;
      const level = typeof reasoning === "string" && reasoning.trim() ? reasoning : undefined;
      let row = providers.get(key);
      if (!row) {
        row = { total: { total: 0, unknown: false }, actual: { total: 0, unknown: false }, models: new Map() };
        providers.set(key, row);
      }
      let modelRow = row.models.get(modelKey);
      if (!modelRow) {
        modelRow = { total: { total: 0, unknown: false }, actual: { total: 0, unknown: false }, levels: new Map() };
        row.models.set(modelKey, modelRow);
      }
      let levelRow = modelRow.levels.get(level);
      if (!levelRow) {
        levelRow = { total: { total: 0, unknown: false }, actual: { total: 0, unknown: false } };
        modelRow.levels.set(level, levelRow);
      }
      const cost = usageCost(usage);
      const paid = key === undefined ? { total: 0, unknown: cost.unknown || cost.total > 0 }
        : subscriptions.has(key) ? { total: 0, unknown: false } : cost;
      for (const amount of [total, row.total, modelRow.total, levelRow.total, own.total]) { amount.total += cost.total; amount.unknown ||= cost.unknown; }
      for (const amount of [actual, row.actual, modelRow.actual, levelRow.actual, own.actual]) { amount.total += paid.total; amount.unknown ||= paid.unknown; }
    }
  }
  type Row = [name: string, total: Cost, actual: Cost];
  const providerRows: Row[] = [];
  const levelOrder = ["off", "minimal", "low", "medium", "high", "xhigh", "max"];
  const rank = (level: string | undefined) => level === undefined ? levelOrder.length + 1
    : levelOrder.includes(level) ? levelOrder.indexOf(level) : levelOrder.length;
  for (const [provider, cost] of [...providers.entries()].sort(([a], [b]) => (a ?? "").localeCompare(b ?? ""))) {
    providerRows.push([cleanName(provider ?? "(unknown)"), cost.total, cost.actual]);
    const models = [...cost.models.entries()].sort(([a], [b]) => (a ?? "").localeCompare(b ?? ""));
    models.forEach(([model, amount], index) => {
      const last = index === models.length - 1;
      const edge = last ? "└─ " : "├─ ";
      const name = cleanName(model ?? "(unknown model)");
      const levels = [...amount.levels.entries()].sort(([a], [b]) => rank(a) - rank(b) || (a ?? "").localeCompare(b ?? ""));
      if (levels.length === 1) {
        providerRows.push([`${edge}${name}:${cleanName(levels[0][0] ?? "unknown")}`, amount.total, amount.actual]);
      } else {
        providerRows.push([`${edge}${name}`, amount.total, amount.actual]);
        levels.forEach(([level, cost], levelIndex) => {
          const branch = levelIndex === levels.length - 1 ? "└─ " : "├─ ";
          providerRows.push([`${last ? "   " : "│  "}${branch}${cleanName(level ?? "unknown")}`, cost.total, cost.actual]);
        });
      }
    });
  }
  providerRows.push(["TOTAL", total, actual]);
  const children = new Map<string, Snapshot[]>();
  for (const file of included) {
    const node = sessions.get(file);
    if (node?.parentFile) {
      const siblings = children.get(node.parentFile) ?? [];
      siblings.push(node); children.set(node.parentFile, siblings);
    }
  }
  for (const siblings of children.values()) siblings.sort((a, b) => label(a).localeCompare(label(b)) || a.id.localeCompare(b.id));
  const sessionRows: Row[] = [];
  const visited = new Set<string>();
  const stack = [{ file: current.file, prefix: "", edge: "" }];
  while (stack.length) {
    const { file, prefix, edge } = stack.pop()!;
    if (visited.has(file)) continue;
    visited.add(file);
    const node = sessions.get(file) ?? current;
    const cost = ownCosts.get(file)!;
    sessionRows.push([`${prefix}${edge}${label(node)}${file === current.file ? " (current)" : ""}`, cost.total, cost.actual]);
    const siblings = children.get(file) ?? [];
    const nextPrefix = prefix + (edge ? edge === "└─ " ? "   " : "│  " : "");
    for (let index = siblings.length - 1; index >= 0; index--) {
      stack.push({ file: siblings[index].file, prefix: nextPrefix, edge: index === siblings.length - 1 ? "└─ " : "├─ " });
    }
  }
  const table = (heading: string, rows: Row[]) => {
    const width = Math.max(heading.length, ...rows.map(([name]) => name.length));
    return [
      `${heading.padEnd(width)}  ${"total".padStart(15)}  ${"actual".padStart(15)}`,
      ...rows.map(([name, total, actual]) => `${name.padEnd(width)}  ${costLabel(total).padStart(15)}  ${costLabel(actual).padStart(15)}`),
    ];
  };
  return [
    "Sap — current session and descendants", "", ...table("provider / model / reasoning", providerRows), "",
    "By session (own cost)", ...table("session", sessionRows), "", `Sessions: ${included.size}`,
    ...(total.unknown || actual.unknown ? ["? = unpriced/incomplete usage or unknown provider attribution."] : []),
  ].join("\n");
}
