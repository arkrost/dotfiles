import { readFile, mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { stripTypeScriptTypes } from 'node:module';
import assert from 'node:assert/strict';

const dir = await mkdtemp(join(tmpdir(), 'compaction-model-'));
const previous = process.env.PI_CODING_AGENT_DIR;
process.env.PI_CODING_AGENT_DIR = dir;
try {
  let source = await readFile(new URL('./index.ts', import.meta.url), 'utf8');
  source = source.replace(/import \{ compact, type ExtensionAPI \} from "@earendil-works\/pi-coding-agent";/, 'const compact = globalThis.__compact;');
  let calls = [], failure = false;
  globalThis.__compact = async (...args) => {
    calls.push(args);
    if (failure) throw new Error('provider failed');
    return { summary: 'summary', firstKeptEntryId: 'kept', tokensBefore: 123 };
  };
  const { default: extension } = await import('data:text/javascript;base64,' + Buffer.from(stripTypeScriptTypes(source)).toString('base64'));
  let handler;
  const current = { provider: 'main', id: 'model' };
  const alternate = { provider: 'other', id: 'model/with/slashes' };
  const pi = { on: (name, fn) => { assert.equal(name, 'session_before_compact'); handler = fn; }, getThinkingLevel: () => 'high' };
  extension(pi);
  let notices = [];
  const ctx = { model: current, modelRegistry: { find: (p, id) => p === alternate.provider && id === alternate.id ? alternate : undefined, streamSimple() {} }, ui: { notify: (...args) => notices.push(args) } };
  const event = { preparation: { firstKeptEntryId: 'kept' }, customInstructions: 'preserve goals', signal: new AbortController().signal };
  async function run(settings) {
    calls = []; notices = [];
    await writeFile(join(dir, 'compaction-model.json'), JSON.stringify(settings));
    const result = await handler(event, ctx);
    assert.equal(ctx.model, current);
    assert.equal(pi.getThinkingLevel(), 'high');
    return result;
  }
  assert.equal(await handler(event, ctx), undefined);
  assert.equal(await run({}), undefined);
  await run({ model: 'other/model/with/slashes' });
  assert.equal(calls[0][1], alternate); assert.equal(calls[0][6], 'high');
  await run({ reasoning: 'off' });
  assert.equal(calls[0][1], current); assert.equal(calls[0][6], 'off');
  await run({ model: 'other/model/with/slashes', reasoning: 'low', modelOverrides: { 'main/model': { reasoning: 'medium' } } });
  assert.equal(calls[0][1], alternate); assert.equal(calls[0][6], 'medium');
  const result = await run({ reasoning: 'low', modelOverrides: { 'main/model': { model: 'other/model/with/slashes' } } });
  assert.equal(calls[0][6], 'low'); assert.equal(calls[0][0], event.preparation);
  assert.equal(calls[0][4], event.customInstructions); assert.equal(calls[0][5], event.signal);
  assert.equal(result.compaction.firstKeptEntryId, 'kept');
  assert.deepEqual(await run({ model: 'unknown/model' }), { cancel: true });
  assert.deepEqual(await run({ reasoning: 'invalid' }), { cancel: true });
  failure = true;
  assert.deepEqual(await run({ reasoning: 'low' }), { cancel: true });
  assert.equal(notices.length, 1);
  event.signal = AbortSignal.abort();
  assert.deepEqual(await run({ reasoning: 'low' }), { cancel: true });
  assert.equal(notices.length, 0);
  console.log('PASS: fallback, overrides, model IDs, forwarding, errors, cancellation, unchanged session');
} finally {
  if (previous === undefined) delete process.env.PI_CODING_AGENT_DIR;
  else process.env.PI_CODING_AGENT_DIR = previous;
  delete globalThis.__compact;
  await rm(dir, { recursive: true, force: true });
}
