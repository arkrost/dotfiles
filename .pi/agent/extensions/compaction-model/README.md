# Compaction model

Uses Pi's standard compaction with a separate model and reasoning level. Applies to automatic compaction and `/compact`. The active session model and reasoning are never changed, including on failure or cancellation.

Configuration: `~/.pi/agent/compaction-model.json` (or `$PI_CODING_AGENT_DIR/compaction-model.json`). Read again before each compaction. No reload is needed for configuration changes.

```json
{
  "model": "provider/summary-model",
  "reasoning": "low",
  "modelOverrides": {
    "provider/conversation-model": {
      "model": "provider/another-summary-model",
      "reasoning": "high"
    }
  }
}
```

Replace example model IDs with registered model IDs. Each field resolves independently: matching override → root setting → current session value. Override keys match the original conversation model, not the summary model. IDs are exact `provider/modelId`; model IDs may contain slashes.

Reasoning: `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`. Actual support depends on the selected model/provider. Non-reasoning models ignore reasoning.

Missing configuration or `{}` keeps standard behavior. Invalid configuration, unknown models or provider errors cancel compaction and report an error rather than silently use another model. The selected model must accept the history being summarized; a small context window can cause failure.

Standard recent-message retention, split-turn summaries, custom instructions, file tracking and usage accounting are preserved. Token thresholds remain controlled by Pi's ordinary compaction settings.

Run tests:

```sh
node ~/.pi/agent/extensions/compaction-model/test.mjs
```
