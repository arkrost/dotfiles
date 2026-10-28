---
name: batch
description: Prepares temporary programs for batches of similar tasks in native Pi and Rex. Use when auditing files, classifying items, or repeating one task across a list. Copies the program path without starting it.
---

# Prepare a batch

Prepare only: do not start work, open panes, or make model requests. The user runs it later.

Agree on scope, output, permitted writes, exact provider/model, thinking, and parallel limit. Reuse prior decisions; ask only for missing details.

## Program and assignments

```sh
umask 077
dir=$(mktemp -d /tmp/batch.XXXXXX)
script="$dir/run.py"
```

Write a small program for this batch; choose the implementation yourself. Keep preparation files beside it, outside the repository. Use one shared context for the goal, criteria, permissions, and result format, plus short assignments from one template:

```text
Read: <absolute shared context path>
Scope: <object or small group>
Write result: <absolute item result path>
```

## Pi and layout

Read the installed `rex` skill/guide. Create fixed worker panes once: controller in the top half, equal-width columns in the bottom half, up to the parallel limit. Keep this layout until the batch ends. Preserve unrelated panes.

Launch a fresh native Pi session per task, with separate session/result paths. Reuse panels, not conversations:

```sh
pi --provider "$provider" --model "$model" --thinking "$thinking" \
  --session-dir "$task_dir/sessions" -- "@$prompt"
```

Pi inherits terminal I/O and the foreground process group; no print/JSON/RPC mode or custom renderer. Confirm results and wait for Pi to exit before reusing a slot. Retain blocked/failed Pi for inspection.

## Progress and handover

Print a simple append-only log with completed/total counts, current items, and errors. Respect the parallel limit and serialize shared-file writes. On an error, question, or ambiguous launch, stop new dispatch while active work can finish. Do not retry automatically or silently rerun started tasks.

Check the program and item coverage without executing the batch. Copy only the absolute program path, then show it and the manual run command; do not run it:

```sh
printf '%s' "$script" | pbcopy
```
