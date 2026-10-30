// Live test. Uses your provider credentials, but only temporary sessions and synthetic data.
// node smoke.mjs [openai-codex/gpt-6.1-sol | claude-bridge/claude-opus-5-5]
import { mkdtemp, mkdir, writeFile, readFile, symlink, access } from 'node:fs/promises';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';

const model = process.argv[2] ?? 'openai-codex/gpt-6.1-sol';
const isBridge = model.startsWith('claude-bridge/');
const sessionReasoning = process.env.SMOKE_THINKING ?? 'high';
const summaryReasoning = process.env.SMOKE_REASONING ?? 'low';
const expectedSummaryReasoning = summaryReasoning === 'inherit' ? sessionReasoning : summaryReasoning;
const auto = process.env.SMOKE_AUTO === '1';
const cancel = process.env.SMOKE_CANCEL === '1';
const extensionDir = dirname(fileURLToPath(import.meta.url));
const agentDir = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), '.pi', 'agent');
const temp = await mkdtemp(join(tmpdir(), 'prefix-compaction-live-'));
const config = join(temp, 'agent');
await mkdir(config);
for (const name of ['auth.json', 'models.json', 'models-store.json', 'claude-bridge.json']) {
  try { await access(join(agentDir, name)); await symlink(join(agentDir, name), join(config, name)); } catch {}
}
await writeFile(join(config, 'settings.json'), JSON.stringify({
  packages: [], enableInstallTelemetry: false, cacheWarming: 'off',
  compaction: { enabled: auto, keepRecentTokens: 1000 }, defaultTools: ['read'],
}));
await writeFile(join(config, 'prefix-compaction.json'), JSON.stringify({ overrides: { [model.slice(0, model.indexOf('/'))]: { reasoning: summaryReasoning } } }));
const fixture = join(temp, 'fixture.txt');
const rows = Array.from({ length: 420 }, (_, i) => `record ${i}: ${createHash('sha256').update(`fixture-${i}`).digest('hex')}`);
rows.splice(3, 0, 'IMPORTANT: LAUNCH_PIN=violet-canyon-731; RELEASE_TARGET=reef-42. Preserve these exact values.');
await writeFile(fixture, rows.join('\n'));
const trace = join(temp, 'requests.jsonl');
const observer = join(temp, 'observe.ts');
await writeFile(observer, `
import { appendFileSync } from 'node:fs';
export default function(pi) {
  let lastPayload, summaryCount = 0;
  const log = value => appendFileSync(${JSON.stringify(trace)}, JSON.stringify(value) + '\\n');
  pi.on('before_provider_request', event => { lastPayload = structuredClone(event.payload); });
  pi.on('session_start', (_, ctx) => {
    if (${auto}) ctx.model.contextWindow = 30000; // Only the local auto-compaction threshold.
    const registry = ctx.modelRegistry;
    const original = registry.streamSimple;
    registry.streamSimple = function(model, context, options) {
      const last = context.messages.at(-1);
      if (last?.role !== 'user' || !String(last.content).includes('Create a context checkpoint of the conversation above')) {
        return original.call(this, model, context, options);
      }
      summaryCount++;
      log({ type: 'summary', sessionId: options.sessionId, expectedSessionId: ctx.sessionManager.getSessionId(), reasoning: options.reasoning, cacheRetention: options.cacheRetention });
      const oldPayload = options.onPayload;
      const wrapped = { ...options, onPayload: async (payload, model) => {
        const previous = lastPayload;
        const input = payload.input ?? payload.messages;
        const oldInput = previous?.input ?? previous?.messages;
        log({ type: 'payload', reasoning: payload.reasoning ?? payload.reasoning_effort,
          cacheKey: payload.prompt_cache_key,
          prefixMatches: !!oldInput && JSON.stringify(input.slice(0, oldInput.length)) === JSON.stringify(oldInput),
          instructionsMatch: previous?.instructions === payload.instructions,
          toolsMatch: JSON.stringify(previous?.tools) === JSON.stringify(payload.tools),
          cacheKeyMatches: previous?.prompt_cache_key === payload.prompt_cache_key });
        return oldPayload ? await oldPayload(payload, model) : payload;
      } };
      const stream = original.call(this, model, context, wrapped);
      if (${cancel} && summaryCount === 2) {
        return { result: async () => {
          let notified = false;
          for await (const event of stream) {
            if (!notified && event.type === 'text_delta') {
              notified = true; ctx.ui.notify('SMOKE_CANCEL_NOW', 'info');
            }
          }
          return stream.result();
        } };
      }
      return stream;
    };
    pi.on('session_shutdown', () => { registry.streamSimple = original; });
  });
}
`);
const args = ['--mode', 'rpc', '--offline', '--no-extensions', '--no-context-files', '--no-skills', '--no-prompt-templates', '--no-themes', '--no-mcp', '--session-dir', join(temp, 'sessions'), '--model', model, '--thinking', sessionReasoning, '--tools', 'read', '-e', join(extensionDir, 'index.ts')];
if (isBridge) args.push('-e', join(agentDir, 'npm/node_modules/pi-claude-bridge/src/index.ts'));
args.push('-e', observer);
const child = spawn(process.env.PI_BIN ?? 'pi', args, { cwd: temp, env: { ...process.env, PI_CODING_AGENT_DIR: config,
  ...(isBridge ? { CLAUDE_BRIDGE_DEBUG: '1', CLAUDE_BRIDGE_DEBUG_PATH: join(temp, 'bridge.log') } : {}),
}, stdio: ['pipe', 'pipe', 'pipe'] });
const events = [], pending = new Map(), waiters = new Set();
let buffer = '', stderr = '', seq = 0;
const started = Date.now();
child.stderr.on('data', data => { stderr += data; });
child.stdout.on('data', data => {
  buffer += data.toString();
  let newline;
  while ((newline = buffer.indexOf('\n')) !== -1) {
    const line = buffer.slice(0, newline); buffer = buffer.slice(newline + 1);
    if (!line.trim()) continue;
    let event;
    try { event = JSON.parse(line); } catch { stderr += `\nNON-JSON: ${line}`; continue; }
    events.push(event);
    if (event.type === 'response' && pending.has(event.id)) {
      const { resolve, reject, timer } = pending.get(event.id); pending.delete(event.id); clearTimeout(timer);
      event.success ? resolve(event.data) : reject(new Error(event.error));
    }
    for (const waiter of [...waiters]) if (waiter.test(event)) { clearTimeout(waiter.timer); waiters.delete(waiter); waiter.resolve(event); }
  }
});
function command(type, fields = {}) {
  return new Promise((resolve, reject) => {
    const id = `test-${++seq}`;
    const timer = setTimeout(() => { pending.delete(id); reject(new Error(`Timeout: ${type}`)); }, 180000);
    pending.set(id, { resolve, reject, timer });
    child.stdin.write(JSON.stringify({ id, type, ...fields }) + '\n');
  });
}
function waitFor(test) {
  return new Promise((resolve, reject) => {
    const waiter = { test, resolve, timer: setTimeout(() => { waiters.delete(waiter); reject(new Error('Timeout waiting for session event')); }, 180000) };
    waiters.add(waiter);
  });
}
async function prompt(message) {
  const settled = waitFor(event => event.type === 'agent_settled');
  await command('prompt', { message }); await settled;
  const result = await command('get_last_assistant_text');
  return result?.text ?? result;
}
const report = { model, sessionReasoning, summaryReasoning, auto, cancel, temp };
try {
  const initial = await command('get_state');
  assert.equal(initial.thinkingLevel, sessionReasoning);
  console.log(JSON.stringify({ stage: 'started', model, temp }));
  await prompt(`Read ${fixture} with the read tool. Remember LAUNCH_PIN and RELEASE_TARGET for this session. Do not repeat the records. Reply only READY after reading.`);
  console.log(JSON.stringify({ stage: 'fixture-read' }));
  let compact, before;
  if (auto) {
    before = initial;
    const completed = events.find(event => event.type === 'compaction_end' && event.reason === 'threshold' && event.result);
    assert.ok(completed, 'Pi must trigger real threshold compaction');
    compact = completed.result;
  } else {
    await prompt('Keep both important values. Reply only ACK, without tools.');
    before = await command('get_state');
    compact = await command('compact', { customInstructions: 'Preserve the exact values of LAUNCH_PIN and RELEASE_TARGET. Keep the checkpoint short.' });
  }
  assert.match(compact.summary, /violet-canyon-731/);
  assert.match(compact.summary, /reef-42/);
  assert.ok(compact.usage?.cacheRead > 0, 'provider must report cached summary input');
  assert.equal(compact.details.strategy, 'prefix-compaction');
  assert.equal(compact.details.reasoning, expectedSummaryReasoning);
  const successNotices = () => events.filter(event => event.type === 'extension_ui_request' && event.method === 'notify' && event.message?.startsWith('prefix-compaction: reasoning '));
  assert.equal(successNotices().length, 1, 'one post-commit prefix-compaction notice');
  assert.ok(successNotices()[0].message.startsWith(`prefix-compaction: reasoning ${expectedSummaryReasoning} (sent)`));
  if (compact.details.providerThinkingLevel) assert.ok(successNotices()[0].message.includes(`provider effort ${compact.details.providerThinkingLevel}`));
  report.notice = successNotices()[0].message;
  const after = await command('get_state');
  assert.equal(after.sessionId, before.sessionId);
  assert.equal(after.thinkingLevel, sessionReasoning);
  assert.equal(after.model.id, before.model.id);
  const traceRecords = (await readFile(trace, 'utf8')).trim().split('\n').map(JSON.parse);
  const summaries = traceRecords.filter(record => record.type === 'summary');
  assert.equal(summaries.length, 1, 'one summary call');
  assert.equal(summaries[0].sessionId, before.sessionId);
  assert.equal(summaries[0].reasoning, expectedSummaryReasoning);
  assert.equal(summaries[0].cacheRetention, 'short');
  if (!isBridge) {
    const payload = traceRecords.find(record => record.type === 'payload');
    assert.ok(payload, 'observe actual summary payload');
    assert.equal(payload.reasoning.effort, expectedSummaryReasoning);
    for (const key of ['prefixMatches', 'instructionsMatch', 'toolsMatch', 'cacheKeyMatches']) assert.equal(payload[key], true, key);
  }
  const answer = await prompt('Without tools: what are the exact LAUNCH_PIN and RELEASE_TARGET? Reply with the two key=value pairs.');
  assert.match(String(answer), /violet-canyon-731/); assert.match(String(answer), /reef-42/);
  let entries = await command('get_entries');
  if (cancel) {
    await command('set_auto_compaction', { enabled: false });
    await prompt(`Read ${fixture} again for the cancellation test. Reply only READY, without repeating the file.`);
    const completedBefore = events.filter(event => event.type === 'compaction_end' && event.result).length;
    const noticesBefore = successNotices().length;
    const readyToCancel = waitFor(event => event.type === 'extension_ui_request' && event.message === 'SMOKE_CANCEL_NOW');
    const cancelled = command('compact', { customInstructions: 'Preserve both values and give a detailed checkpoint.' }).then(value => ({ value }), error => ({ error: String(error) }));
    await Promise.race([readyToCancel, cancelled.then(result => { throw new Error(`Compaction ended before cancellation: ${JSON.stringify(result)}`); })]);
    await command('abort');
    const result = await cancelled;
    assert.ok(result.error, 'cancelled compaction must fail');
    assert.equal(events.filter(event => event.type === 'compaction_end' && event.result).length, completedBefore, 'no partial checkpoint committed');
    assert.equal(successNotices().length, noticesBefore, 'cancelled compaction must not announce success');
    const recovered = await prompt('Without tools, give LAUNCH_PIN and RELEASE_TARGET again.');
    assert.match(String(recovered), /violet-canyon-731/); assert.match(String(recovered), /reef-42/);
    report.cancelRecovered = true;
    entries = await command('get_entries');
  }
  const completionEntries = entries.entries.filter(entry => entry.type === 'custom' && entry.customType === 'prefix-compaction');
  assert.equal(completionEntries.length, 1, 'only successful compaction gets a durable UI entry');
  assert.equal(completionEntries[0].data, report.notice);
  await writeFile(join(temp, 'entries.json'), JSON.stringify(entries, null, 2));
  report.ok = true; report.usage = compact.usage; report.answer = answer; report.seconds = Math.round((Date.now() - started) / 1000);
  console.log(JSON.stringify(report));
} catch (error) {
  report.ok = false; report.error = String(error); console.error(JSON.stringify(report)); process.exitCode = 1;
} finally {
  await writeFile(join(temp, 'events.json'), JSON.stringify(events, null, 2));
  await writeFile(join(temp, 'stderr.log'), stderr);
  for (const entry of pending.values()) clearTimeout(entry.timer);
  for (const waiter of waiters) clearTimeout(waiter.timer);
  child.stdin.end();
  const kill = setTimeout(() => child.kill('SIGTERM'), 3000); kill.unref();
}
