# Mangroove

> The ultimate water-rooted tree.

Dive into a task, distill its result, and track the sap that feeds the work.

Personal Pi extension for named child sessions, reviewed return reports, and on-demand subtree cost estimates. Requires Pi 1.4.0.

## Commands

```text
/dive scout
/distill Keep verified findings, exact file paths, and unresolved questions.
/surface
/sap
```

### `/dive <name>`

Clones the current active branch **through the current leaf**, including a just-added context message or compaction. Assigns the child name and records its parent, fork point, and ancestor path. This child-owned lineage entry also marks the start of its own costs. The parent name/history is unchanged. No model request is made.

Uses Pi's fork API with `position: "at"` (the same semantics as native `/clone`), not slash-command dispatch. The new runtime names and initializes the clone; no stale `pi` or command context is used after replacement.

Above the input, a widget shows **ancestors only**:

```text
master → scout
```

The current session name belongs in the existing footer. Root sessions have no ancestor widget. Ancestors without names use short IDs. Names are resolved on session startup/reload; saved names are a fallback if an ancestor file is unavailable. There is no background cost scan or timer.

### `/distill [additional instructions]`

1. Calls the **current session model**, using current session reasoning, native projected history/system/tools, the same session ID, short cache retention, and an appended report instruction. It does not serialize history into a new system prompt or compact the child.
2. Saves a `distill-flow` custom entry with the instruction, user additions, generated text, model/reasoning, usage, and outcome. This entry **does not enter model context**. Expand it with Pi's usual expansion key to inspect/copy it later.
3. Opens a private temporary Markdown file in **`$EDITOR`**. Editor arguments are supported, e.g. `EDITOR='nvim -f'`. The editor must wait until editing is complete.
4. Exit **0** accepts the file; a nonzero exit or signal cancels. With Vim, use **`:x` to accept, `:cq` to cancel**. `:q!` also exits 0 and therefore accepts the original text. There is no additional confirmation dialog.
5. Saves the review, including edited text even on cancellation. On acceptance, switches to the **direct parent** and adds a `distill-result` context message, rendered with the source child's name. This does **not** start a parent model turn. The parent continues at its current active leaf, not the fork point.

The child is kept, not deleted. Cancellation, an incomplete/empty response, tool calls, an editor error, or an empty edited file does not transfer context. Provider failures do not trigger a second cold summary request. A failed context insertion attempts to return to the child using a fresh session context. Parent identity is checked before transfer.

The default report focuses on child-specific findings, decisions, changed files, verification, and unresolved work rather than repeating the inherited task. User additions extend that instruction. The first post-fork user message, when available, helps identify the child task. Review the report: model summaries can still omit facts.

A repeated `/distill` creates a new model request. Old drafts/reviews remain in the child JSONL for inspection and manual reuse; there is no automatic reuse command. Only the approved result participates in the parent's model context. No support for `--to`/skipping ancestors yet.

Claude bridge can still miss its server-side cache despite a preserved Pi-level prefix. See [Claude bridge cache follow-up](CLAUDE-BRIDGE-NOTES.md) for measured usage, limits and a deferred native-fork approach. No bridge rewrite is implemented.

### `/surface`

Switch to the direct parent session. No model call, no summary, and no context transfer; the child remains saved. Use `/distill` to return a reviewed report. Requires an idle persistent session with a parent.

### `/sap`

Prints a transient session-style report, without adding model context or starting a turn:

- Provider subtotals with model/reasoning `total`/`actual` breakdowns, plus a `TOTAL` row, across the current session and its discovered descendants. With one reasoning level, show `model:high`; with several, show a model subtotal with separate level rows. Reasoning levels sum to their model; models sum to their provider.
- A tree breakdown by session, showing **own** `total` and `actual` costs after each session’s lineage marker. Descendant costs are separate rows, not folded into their parent’s row.
- `total`: all saved `usage.cost.total` amounts, including subscription providers.
- `actual`: the same amounts, but **zero for configured subscription providers**.
- All stored branches, compactions, branch summaries, tool/nested usage, cache-warming usage, and distillation drafts (including cancelled attempts).

Configure `~/.pi/agent/mangroove.json` (or `$PI_CODING_AGENT_DIR/mangroove.json`):

```json
{
  "billing": {
    "subscription": ["openai-codex"]
  }
}
```

The configuration is read on every `/sap`; changing it does not require reload and also changes how older usage is displayed. A missing file means no subscription exclusions. Invalid configuration fails explicitly rather than silently calculating incorrect `actual` amounts. Both columns remain API cost estimates; `actual` is not a measured invoice and does not allocate fixed subscription fees.

For each session, cost starts **after its first own `dive-lineage` entry**, identified by that session's ID. Copied ancestor markers are ignored; subsequent metadata does not reset the boundary. This excludes the history inherited through `/dive`, including earlier distillation drafts. If there is no own marker, the entire session is counted. Ordinary native clones without a `/dive` marker do not automatically get an accounting boundary.

Consequently a child's own cost can be lower than native `/session`, which also includes inherited history. `/sap` additionally includes distillation usage stored in custom flow entries; native `/session` does not account for these custom entries. Review entries carry no usage and are not charged again. Older lineage records with inherited-usage lists still work; those lists are no longer needed or consulted.

Providers/models are attributed per usage record, not from the currently selected session model. Assistant messages and new distillation drafts prefer `responseModel` when available, otherwise their saved requested model. Native compactions/branch summaries can use model selection on their tree ancestry; extension summary metadata can identify `provider/model`, preserving slashes inside model IDs. Unattributed nested/tool usage appears under `(unknown)`; its `total` can be known while its `actual` is unknown. Missing model attribution appears as `(unknown model)` within its provider, without discarding its known cost or changing billing classification.

Reasoning means the saved Pi request level, not the backend’s `providerThinkingLevel`. Prefer assistant `thinkingLevel`, distillation `reasoning`, and explicit summary/usage metadata. Legacy assistant messages and native summaries may use their historical branch setting when provider/requested model match. This includes state before the lineage boundary and follows tree ancestry rather than the latest raw setting. Custom summaries, routed/nested calls, and cache warming without a saved level use `unknown` rather than borrowing the current session level. A missing level does not discard or invalidate otherwise known cost.

Prices come from saved `usage.cost` supplied/calculated by Pi and its adapters, not a tariff hardcoded in this extension. Missing prices, nonzero usage reported at zero price, unreadable/incomplete files, and unknown provider attribution are marked `?`, not silently treated as free. A known subscription provider still has `actual = 0` if its API equivalent is unknown.

Descendants are discovered in the current session directory when `/sap` is invoked. Cost attribution does not require reading ancestor files. Deleted or relocated descendant files cannot be fully recovered/accounted for. No background registry or polling is used.

## Storage

Persisted custom entry/message types keep their command-based names. Existing sessions, lineage boundaries, and flow records remain compatible after the extension rename.

- `dive-lineage`: child-owned durable ancestry metadata and accounting boundary, excluded from model context. Inherited lineage records belonging to other session IDs are ignored.
- `distill-flow`: generated draft and subsequent editor review, excluded from model context. The draft owns usage, so review entries do not charge it again. A temporary process-global plain-data handoff exists only during cloning; durable data lives in JSONL.
- `distill-result`: approved parent context with source session ID/name/file and request ID in renderer metadata.

Commands requiring clone/editor interactions are TUI-only and require persistent, idle sessions. Configure `$EDITOR` before `/distill`. A recorded system prompt is required for prefix-preserving reports; legacy/empty sessions need a normal model turn first.

## Tests

Offline unit/flow tests:

```sh
node test.mjs
```

Real TUI integration with a stubbed provider, a PTY screen emulator, and actual Vim `:cq`/`:x`:

```sh
# Requires pi and vim on PATH, plus pyte in the Python environment.
python3 tui-test.py
```

Both tests make **zero paid provider requests**. The TUI test saves terminal traces/screens in a printed temporary directory. It tests leaf cloning, naming, nested ancestry/reload, real editor exit status, flow exclusion from model context, named return messages, absence of automatic parent turns, and provider `total`/`actual` costs counted from each session’s own lineage marker.
