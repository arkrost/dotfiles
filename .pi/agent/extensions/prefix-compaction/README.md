# Prefix compaction

The `prefix-compaction` extension handles `/compact` and automatic compaction with one summary call through the current Pi provider, including `openai-codex` and `claude-bridge`.

The request preserves the active session projection: original system prompt, tool declarations, native conversation messages and earlier checkpoints. It appends a checkpoint instruction, passes the original Pi `sessionId`, and uses the configured reasoning level. It does not serialize the history into a new user message or use Pi's separate summarizer prompt.

For Codex, Pi derives `prompt_cache_key` and session-affinity headers from `sessionId`. For Claude bridge, the ID selects the existing Claude Code session; this extension does not pass `cacheRetention: "none"`, which would select the bridge's isolated summarizer instead.

The extension does not change the active model or session thinking level. The checkpoint instruction and reply are not appended as ordinary Pi conversation messages. Pi commits the reply as a compaction entry, and the bridge's existing `session_compact` handler rebuilds its mirror for subsequent turns.

## Configuration

Settings: `~/.pi/agent/prefix-compaction.json`, or `$PI_CODING_AGENT_DIR/prefix-compaction.json`. Read before each compaction; no reload is needed for config edits.

```json
{
  "enabled": true,
  "overrides": {
    "claude-bridge": {
      "reasoning": "high"
    },
    "openai-codex": {
      "reasoning": "inherit",
      "gpt-6.1-sol": {
        "enabled": false
      }
    }
  }
}
```

- Root `enabled: false` is the master switch: no provider or model override can enable the extension while it is off.
- Each entry in `overrides` is keyed by the exact provider ID. Its `enabled` and `reasoning` fields apply to that provider; other entries are model settings keyed by exact model ID, including any slashes. There are no wildcard keys.
- Otherwise, `enabled` resolves as model override → provider override → `true`. A model can explicitly enable an exception within a disabled provider. An override containing only `reasoning` does not change the inherited enabled state.
- `reasoning` resolves independently: model override → provider override → current session level. It is not supported at the root. Supported fixed levels: `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`; actual provider/model support still applies.
- `reasoning: "inherit"` explicitly selects the current session reasoning. At model level it bypasses the provider's fixed reasoning setting. Omitting reasoning at model level uses the provider setting; omitting it at provider level uses the current session level.
- Disabling this extension leaves Pi's standard compaction active, for both manual and automatic compaction. It does not disable compaction itself and makes no summary request from this extension.

A missing file or `{}` enables prefix compaction with the session's current reasoning. The session model is always used; there is no `model` setting. Unknown fields, invalid booleans and invalid reasoning levels cancel compaction with an error. The old settings filename is not read.

Recent-message retention and automatic thresholds remain controlled by Pi's normal `compaction` settings. The summary sees the full active projection, so it can overlap with the retained tail. Custom `/compact <instructions>`, file lists and provider usage are preserved. Output is requested to stay within 1,000 words, with an 8,192-token cap where the provider supports it.

## Completion notice

After Pi saves a successful prefix checkpoint, the `session_compact` handler appends a custom session entry and renders it in the TUI:

```text
prefix-compaction: reasoning high (sent); 18,560/18,893 input tokens cached
```

The reasoning is the concrete Pi level passed to the summary request after resolving `inherit`, not the session/config value at notification time. `(sent)` distinguishes the requested level from provider-internal effort, which can be mapped or clamped by a provider. If the response supplies `providerThinkingLevel`, the notice also shows `provider effort <value>` and saves it in checkpoint details; otherwise no provider effort is inferred.

The custom entry is excluded from LLM context. Unlike `ctx.ui.notify()`, it survives the TUI rebuild at `compaction_end` and remains visible after `/reload` or resume. RPC clients also receive the existing notification; TUI does not show a duplicate transient notification.

There is no success notice before the checkpoint is committed, on cancellation/failure, for built-in or other extensions' compaction, or for the standard overflow fallback. The overflow warning remains unchanged.

## Cache behavior and limits

- Cache reuse is best effort, not a session-ID-only lookup. The model, effective prompt, tools, history prefix and server routing must still match. A notice reports the provider's actual `cacheRead` count, including zero.
- See [Claude bridge cache follow-up](../mangroove/CLAUDE-BRIDGE-NOTES.md) for observed distillation/reload cache misses, a successful compact cache hit, and a deferred bridge-native fork approach. Preserving the Pi projection alone does not guarantee the same prefix after CC conversion.
- **Measured on Codex `gpt-6.1-sol`: `low → low` and `high → high` reused the prefix; `high → low` reported zero cached input despite identical history/tools/cache key.** Choose reasoning with this in mind; the extension never changes your selection to force a cache hit.
- **Measured on bridge `claude-opus-5-5`: `high → low` reused the conversation cache.** Bridge logs confirmed the same Claude Code `resume` session and `effort=low`.
- An already overflowing context cannot safely be replayed with an extra instruction. For `reason: "overflow"` only, the extension reports a warning and uses Pi's standard, smaller summary request with the selected reasoning. This path does not promise prefix reuse.
- Ordinary provider errors, empty/truncated replies and unexpected tool calls cancel compaction. No automatic second cold request is sent. Cancellation propagates to the provider, and partial replies are never saved.
- The source is the active persisted projection, not raw session history. Abandoned branches and omitted attempts are not reintroduced. Other extensions' request-only `context`/`context_with_system` or payload transforms are not rerun for the nested summary call; if they change the prefix, cache reuse can be reduced.
- No background jobs, post-compaction warm-up, raw-request persistence or alternate HTTP/SSE implementation are added.

Run `/reload` once after changing the extension code.

## Tests

Offline unit tests (no model calls):

```sh
node ~/.pi/agent/extensions/prefix-compaction/test.mjs
```

Live smoke tests use your existing credentials and synthetic data in fresh temporary sessions. They do not touch the current session. Provider calls consume quota. Temporary logs/session files are kept at the path printed by the script; credentials are referenced by symlink, not copied into logs.

```sh
# Codex: matching reasoning is intentional for the cache assertion.
SMOKE_THINKING=low node ~/.pi/agent/extensions/prefix-compaction/smoke.mjs openai-codex/gpt-6.1-sol

# Bridge: high conversation reasoning, low summary reasoning.
node ~/.pi/agent/extensions/prefix-compaction/smoke.mjs claude-bridge/claude-opus-5-5

# Real threshold compaction, then abort a streaming manual summary and continue.
SMOKE_AUTO=1 SMOKE_CANCEL=1 SMOKE_THINKING=low node ~/.pi/agent/extensions/prefix-compaction/smoke.mjs openai-codex/gpt-6.1-sol
SMOKE_AUTO=1 SMOKE_CANCEL=1 node ~/.pi/agent/extensions/prefix-compaction/smoke.mjs claude-bridge/claude-opus-5-5
```

`SMOKE_REASONING` selects the provider's summary reasoning (default `low`, or `inherit` to keep session reasoning). `SMOKE_THINKING` selects conversation reasoning (default `high`). For example, `SMOKE_REASONING=inherit node smoke.mjs openai-codex/gpt-6.1-sol` tests high → high. The smoke test requires a positive cache hit, so a known cache-breaking combination deliberately fails that assertion.

The live test checks one summary call, original session ID, configured reasoning, a post-commit `prefix-compaction` notice with resolved reasoning, positive provider-reported cache usage, preservation of two planted facts, unchanged session model/thinking and successful continuation. The cancellation test also checks that no success notice is shown for the cancelled request. On Codex it also checks the actual summary payload against the previous real request: prefix, instructions, tools and cache key must match.

Verified with Pi 1.4.0:

| Model | Conversation → summary reasoning | Cached summary input |
| --- | --- | --- |
| `openai-codex/gpt-6-astra` | low → low | 18,560 / 18,890 tokens |
| `openai-codex/gpt-6-luna` | low → low | 18,560 / 18,893 tokens |
| `openai-codex/gpt-6.1-sol` | low → low | 18,560 / 18,893 tokens |
| `openai-codex/gpt-6.1-sol` | high → high | 18,560 / 18,893 tokens |
| `openai-codex/gpt-6.1-sol` | high → low | 0 / 18,890 tokens |
| `openai-codex/gpt-6.1-terra` | low → low | 18,560 / 18,896 tokens |
| `claude-bridge/claude-opus-5-5` | high → low | 22,640 / 22,993 tokens |

Real automatic threshold compaction and cancellation after summary text started streaming also passed on Sol (low → low) and bridge (high → low). Both providers continued correctly after the cancelled summary without committing a partial checkpoint.
