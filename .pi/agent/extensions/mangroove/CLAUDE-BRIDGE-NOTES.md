# Claude bridge cache follow-up

Recorded: 2026-10-30. Inspected versions: Pi 1.4.0, pi-claude-bridge 0.9.3.

**Status: bridge cache/native-fork rewrite deferred, not implemented.** The user does not currently want to rewrite bridge.

Later on the same day, the user approved a local `~/.pi/agent/models.json` cost override for `claude-bridge/claude-sonnet-5-5`: input `2`, output `10`, cache read `0.1`, cache write `4` USD per million tokens. The write rate matches the observed **one-hour** cache, not the catalog's five-minute write rate. Native Pi loaded the override in an offline check; calculated distill/compact costs matched the two CC estimates below without provider calls. This affects new saved usage only; old zero-priced records were not repriced. Bridge code and subscription classification remain unchanged. A change in cache TTL or API rates would require reviewing this static override.

An additional approved override covers `claude-bridge/claude-opus-5-5`: input `4`, output `20`, cache read `0.2`, cache write `8` USD per million tokens, again for one-hour writes. Its existing `contextWindow: 500000` is preserved. An offline native-Pi check reproduced CC's saved `$8.9733764` estimate from 2,026 input, 101,746 output, 22,962,842 cache-read and 292,223 one-hour cache-write tokens; the Sonnet check still passed.

## Observed behavior

Both Mangroove `/distill` and prefix compaction send the current Pi projection plus an appended instruction, using the original Pi session ID and `cacheRetention: "short"`. This preserves the Pi-level prefix; it does not guarantee an identical request after Claude Code converts/reconstructs its history.

Actual `claude-sonnet-5-5` usage from the same Pi child session:

| Operation / response time (UTC) | Cache read | Cache write | CC session |
| --- | ---: | ---: | --- |
| `/distill`, 00:45:44 | 4,077 | 53,707 | `168ee260-e224-4328-adfb-636926efe790` |
| Next ordinary prompt, 00:46:38 | 4,077 | 53,439 | `a8eb561c-7beb-4bf8-bde6-1ee31b590b03` |
| `/compact`, 00:51:24 | 61,853 | 419 | `a8eb561c-7beb-4bf8-bde6-1ee31b590b03` |

The ordinary prompt at 00:46 was asking which distillation prompt had been used. The later compact reused that CC session; it did not create it. CC's resume list uses the last prompt as a label, not the reason the session was created.

- The compact itself was a cache hit: 61,853 of 62,274 input tokens were cached. It generated 3,312 output tokens. Pi's `66k tokens billed` sums input, output, cache reads and writes; it does not mean 66k uncached input tokens.
- CC's displayed `$0.3527` was the cumulative session estimate. Its saved total increased from `$0.3117521` to `$0.3527374` for compact: about `$0.0410`, not the whole session amount.
- Distillation did have a large cache miss. Its single-query CC estimate was `$0.2165697`.
- Recorded cache writes used `cache_creation.ephemeral_1h_input_tokens`. Pi's `short` option did not select a five-minute TTL on this bridge path.
- Reconstructed API request history differed across the CC sessions. The exact cache-breaking difference was not isolated. A new UUID alone is not proof of a cache miss.

Evidence remains in:

- Pi: `~/.pi/agent/sessions/--Users-arost@tempo.io-.pi-agent--/2026-10-30T00-42-23-618Z_01a18a42-0002-7247-9e31-6c80368d80ec.jsonl` (draft at 00:45:44, compaction `6fb742e1`).
- CC: `~/.claude/projects/-Users-arost-tempo-io--pi-agent/`, using the UUIDs above. Earlier working session: `4ad44599-020f-44b1-9fcd-b1384ddbb8e1`.
- CC `cost-state` records are cumulative snapshots: do not sum repeated snapshots. Multiple assistant records can also share a response ID; do not count each content block as a separate API response.

## Bridge behavior to revisit

In `pi-claude-bridge/src/index.ts`:

- `streamClaudeAgentSdk` uses the regular session-sync path for these `short` requests. `cacheRetention: "none"` instead selects an isolated summarizer; switching to `none` is not a cache-preservation fix.
- `syncSharedSession` can resume an existing mirror or reconstruct history with `createSession` / `convertAndImportMessages`.
- `clearSession` clears the in-memory Pi-to-CC mappings on new/resume/fork and runtime shutdown, including `/reload`.
- Abort handling can require a new UUID to avoid racing an old CC writer. Do not remove that safety guard merely to retain an ID.

## Possible future approach

Investigate a bridge-owned summary request that forks the existing **native CC history**, instead of importing Pi messages into a new CC transcript:

1. Keep/recover the Pi-to-CC session mapping across reload/resume, and verify that the mirror still matches the active Pi branch/projection.
2. For `/distill` and summary generation, investigate SDK `resume` + `forkSession: true`. Keep the effective model, system prompt, tools and existing history prefix stable; append only the report/checkpoint instruction.
3. Keep the report request/response out of the original working CC history and Pi model context. Do not advance the working mirror's cursor to include the report. Approved distillation results alone enter the parent context, as today.
4. Never resume stale history to obtain a cache hit: compaction, context edits and branch changes must remain authoritative. Retain cancellation and concurrent-writer safety.

The installed Agent SDK documents native resume/fork support and cache reuse for its own forked progress summaries. This is a supported mechanism to investigate, **not a tested bridge implementation or a guaranteed cache hit**. Disk persistence, CC session IDs and server-side prompt caching are distinct concerns.

### Limits and acceptance criteria

- Preserve the old prefix for the request that generates a compact summary. After Pi replaces history with that summary, subsequent requests legitimately have a different prefix. Cache writes for changed content are expected; zero cache writes is not the goal.
- For distillation, verify high cache reads and small tail-only cache writes when a valid, warm matching mirror exists. Check that the original working history is unchanged and the next ordinary turn does not require a full cold reconstruction because of distillation.
- Verify reload/resume, parent/child isolation, cancellation and recovery. Compare actual outgoing CC requests and provider usage, not just Pi projections or UUIDs.
- Existing unit and real-TUI tests use stub providers. They verify Pi request construction and workflow, **not actual Claude Code conversion or server cache reuse**.
- Do not run paid provider tests without explicit approval.

## Separate billing follow-up (also deferred)

The SDK exposes `total_cost_usd` and per-model `modelUsage[].costUSD`, but the inspected bridge calculates Pi costs from zero-priced registered models instead. Mangroove therefore shows `$?` for nonzero unpriced usage. Forwarding SDK costs would avoid manual tariff duplication, but cumulative totals need proper baselines/deltas across turns, resume/fork and resets; they must not be summed repeatedly. SDK costs remain estimates, not invoices. SDK-cost forwarding is not implemented; the local pricing workaround is recorded above.
