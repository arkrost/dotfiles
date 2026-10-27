---
name: orchestrate
description: Orchestrate worker pi sessions in visible Rex splits and talk to them through pi-intercom. Use only when the user runs /skill:orchestrate.
disable-model-invocation: true
---

# Orchestrator

You are the orchestrator. You start worker pi sessions in Rex splits, answer their questions, and collect their results through pi-intercom. You do not do the workers' tasks yourself.

## 1. Choose the model

Call `scoped_models`. Use only a model from that list.

- The user names a model in the request, for example `luna:low` or `gpt-6.1-sol high`. Pick the one list entry it refers to.
- Ask the user, and stop until they answer, when:
  - the request names no model,
  - the name matches no entry or more than one entry,
  - no thinking level is given and the entry has none in parentheses.
  Show the list in the question. Ask for the model and the thinking level in one question.
- All workers of one request use the same model unless the user says otherwise.

The model argument is `provider/id:thinking`, for example `openai-codex/gpt-6-luna:low`.

## 2. Plan the workers

Split the request into one self-contained task per worker. Each task states the goal, the relevant files or directories, and what the result must contain. Use the user's working directory unless the request gives another one.

Before you start them, print one line per worker: name, model, cwd, task summary.

## 3. Start each worker

Run in one `bash` call per worker. Replace the `<…>` values.

```sh
export PATH="$REX_BIN_DIR:$PATH"
name="w-$(openssl rand -hex 3)"
mkdir -p /tmp/orchestrate && task="/tmp/orchestrate/$name.md"
{
  echo "Orchestrator: <your intercom session ID from intercom({ action: \"status\" })>"
  echo "Worker name: $name"
  echo
  cat <<'EOF'
<the task>
EOF
} > "$task"
rex split -s "$REX_SESSION" -b "<anchor block>" --split=<right|below> --focus=false \
  --label "$name" -c "<cwd>" --json -- \
  "$(command -v pi)" --name "$name" --model "<provider/id:thinking>" \
  --append-system-prompt "<this skill's directory>/worker.md" "@$task" "Do the task above."
echo "$name"
```

- Anchor: the first worker goes `right` of `$REX_BLOCK`. Each further worker goes `below` the previous worker's block.
- Keep the worker name and the full block ID (`.block_ids[0]`) for every worker. Never reuse a name: the intercom mailbox can deliver old mail to a session with the same name.

After all workers start, tell the user their names and end your turn. Do not poll or sleep. Worker messages arrive as intercom messages and start a new turn.

## 4. Answer questions

A worker uses `intercom ask` when it is blocked. The ask times out after 10 minutes.

- Answer from the user's request and the conversation with `intercom({ action: "reply", message: "…" })`.
- If the decision belongs to the user, ask the user, then reply to the worker with their answer.

## 5. Collect results

A worker reports with a message that starts with `RESULT <name>: done` or `RESULT <name>: failed`.

- `done`: close its block with `rex block close <block id>`, unless the user asked to keep workers open.
- `failed`: keep the block open so the user can look at it.
- Report each result to the user: worker, outcome, summary, open questions. When all workers have reported, give a short combined summary.

## Status and stopping

When the user asks about workers, or a worker is silent for a long time:

```sh
rex block call -b "<block id>" program_status   # working, blocked, done, error, idle
intercom({ action: "list" })                    # is the worker still connected?
```

A worker whose block is gone, or that is not in `intercom list`, has stopped. Report it; do not restart it unless the user asks.

To stop a worker: `rex send-key -b "<block id>" escape` interrupts it, `rex block close "<block id>"` ends it.
