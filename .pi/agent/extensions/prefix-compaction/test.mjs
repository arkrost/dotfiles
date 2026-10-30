import { readFile, mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { stripTypeScriptTypes } from 'node:module';
import assert from 'node:assert/strict';

const dir = await mkdtemp(join(tmpdir(), 'prefix-compaction-unit-'));
const previous = process.env.PI_CODING_AGENT_DIR;
process.env.PI_CODING_AGENT_DIR = dir;
try {
  let coldCalls = [], calls = [], notices = [], entries = [], renderer, failure, afterResponse;
  const usage = { input: 100, output: 20, cacheRead: 900, cacheWrite: 0, totalTokens: 1020, cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 } };
  let response;
  globalThis.__host = {
    Text: class { constructor(text) { this.text = text; } render() { return [this.text]; } },
    convertToLlm: messages => structuredClone(messages),
    compact: async (...args) => {
      coldCalls.push(args);
      return { summary: 'cold summary', firstKeptEntryId: 'kept', tokensBefore: 123 };
    },
  };
  let source = await readFile(new URL('./index.ts', import.meta.url), 'utf8');
  source = source.replace('import { compact, convertToLlm, type ExtensionAPI } from "@earendil-works/pi-coding-agent";', 'const { compact, convertToLlm } = globalThis.__host;')
    .replace('import { Text } from "@earendil-works/pi-tui";', 'const { Text } = globalThis.__host;');
  const { default: extension } = await import('data:text/javascript;base64,' + Buffer.from(stripTypeScriptTypes(source)).toString('base64'));
  let handler, compacted;
  const current = { provider: 'main', id: 'model/with/slashes', maxTokens: 16000 };
  let sessionReasoning = 'high';
  const pi = { on: (name, fn) => {
    if (name === 'session_before_compact') handler = fn;
    else if (name === 'session_compact') compacted = fn;
    else assert.fail(`Unexpected event: ${name}`);
  }, getThinkingLevel: () => sessionReasoning,
    registerEntryRenderer: (type, fn) => { assert.equal(type, 'prefix-compaction'); renderer = fn; },
    appendEntry: (customType, data) => entries.push({ type: 'custom', customType, data }),
  };
  extension(pi);
  const messages = [
    { role: 'system', content: 'Original prompt', toolsAdded: [{ name: 'read', description: 'Read a file', parameters: { type: 'object' } }], timestamp: 1 },
    { role: 'user', content: 'SECRET_FACT_73', timestamp: 2 },
    { role: 'assistant', content: [{ type: 'text', text: 'Acknowledged' }], timestamp: 3 },
  ];
  const ctx = { mode: 'rpc', model: current, sessionManager: { getSessionId: () => 'original-session', buildSessionProjection: () => ({ messages }) },
    modelRegistry: { streamSimple: (model, context, options) => {
      calls.push({ model, context, options });
      return { result: async () => { if (failure) throw failure; afterResponse?.(); return structuredClone(response); } };
    } }, ui: { notify: (...args) => notices.push(args) } };
  let event;
  const complete = (compaction, change = {}) => compacted({ type: 'session_compact', compactionEntry: compaction, fromExtension: true, reason: event.reason, willRetry: false, ...change }, ctx);
  async function run(settings = {}, change = {}) {
    calls = []; coldCalls = []; notices = []; entries = [];
    response = { content: [{ type: 'text', text: '  checkpoint  ' }], stopReason: 'stop', usage };
    event = { preparation: { firstKeptEntryId: 'kept', tokensBefore: 123, fileOps: { read: new Set(['a.ts', 'b.ts']), edited: new Set(['b.ts']), written: new Set(['c.ts']) } },
      branchEntries: [], reason: 'manual', signal: new AbortController().signal, ...change };
    await writeFile(join(dir, 'prefix-compaction.json'), typeof settings === 'string' ? settings : JSON.stringify(settings));
    const snapshot = JSON.stringify(messages);
    const originalModel = ctx.model;
    const originalReasoning = pi.getThinkingLevel();
    const result = await handler(event, ctx);
    assert.equal(JSON.stringify(messages), snapshot, 'must not mutate session history');
    assert.equal(ctx.model, originalModel);
    assert.equal(pi.getThinkingLevel(), originalReasoning);
    return result;
  }
  let result = await run({ overrides: { main: { reasoning: 'low' } } }, { customInstructions: 'Preserve SECRET_FACT_73' });
  assert.equal(calls.length, 1); assert.equal(coldCalls.length, 0);
  assert.equal(calls[0].model, current);
  assert.deepEqual(calls[0].context.messages.slice(0, -1), messages, 'exact prompt/tools/history prefix');
  assert.match(calls[0].context.messages.at(-1).content, /Preserve SECRET_FACT_73/);
  assert.equal(calls[0].options.sessionId, 'original-session');
  assert.equal(calls[0].options.cacheRetention, 'short');
  assert.equal(calls[0].options.reasoning, 'low');
  assert.equal(calls[0].options.signal.aborted, false);
  assert.equal(calls[0].options.maxTokens, 8192);
  assert.equal(result.compaction.firstKeptEntryId, 'kept');
  assert.equal(result.compaction.tokensBefore, 123);
  assert.deepEqual(result.compaction.usage, usage);
  assert.deepEqual(result.compaction.details.readFiles, ['a.ts']);
  assert.deepEqual(result.compaction.details.modifiedFiles, ['b.ts', 'c.ts']);
  assert.match(result.compaction.summary, /<read-files>\na.ts\n<\/read-files>/);
  assert.deepEqual(notices, [], 'no success notice before checkpoint commit');
  assert.deepEqual(entries, [], 'no status entry before checkpoint commit');
  await complete(result.compaction);
  assert.deepEqual(notices, [['prefix-compaction: reasoning low (sent); 900/1,000 input tokens cached', 'info']]);
  assert.deepEqual(entries, [{ type: 'custom', customType: 'prefix-compaction', data: notices[0][0] }]);
  for (const change of [
    { fromExtension: false },
    { compactionEntry: { details: undefined } },
    { compactionEntry: { details: { strategy: 'other-extension', reasoning: 'low' } } },
    { compactionEntry: { details: { strategy: 'prefix-compaction' } } },
  ]) {
    notices = []; entries = [];
    await complete(result.compaction, change);
    assert.deepEqual(notices, [], 'do not label standard, other or incomplete compactions as prefix-compaction');
    assert.deepEqual(entries, []);
  }
  await complete({ ...result.compaction, usage: undefined });
  assert.deepEqual(notices, [['prefix-compaction: reasoning low (sent)', 'info']]);
  afterResponse = () => { response.providerThinkingLevel = 'max'; };
  result = await run({ overrides: { main: { reasoning: 'xhigh' } } });
  afterResponse = undefined;
  assert.equal(result.compaction.details.providerThinkingLevel, 'max');
  await complete(result.compaction);
  assert.deepEqual(notices, [['prefix-compaction: reasoning xhigh (sent); provider effort max; 900/1,000 input tokens cached', 'info']]);
  await run({}); assert.equal(calls[0].options.reasoning, 'high');
  await rm(join(dir, 'prefix-compaction.json'));
  assert.ok((await handler(event, ctx)).compaction, 'missing config still uses prefix compaction');
  await run({ overrides: { main: { 'model/with/slashes': { reasoning: 'off' } } } });
  assert.equal(calls[0].options.reasoning, 'off');
  await run({ overrides: { main: { reasoning: 'low' } } });
  assert.equal(calls[0].options.reasoning, 'low');
  await run({ overrides: { main: { reasoning: 'low', 'model/with/slashes': { reasoning: 'medium' } } } });
  assert.equal(calls[0].options.reasoning, 'medium');
  await run({ overrides: { other: { enabled: false, reasoning: 'off' }, main: { other: { enabled: false } } } });
  assert.equal(calls.length, 1); assert.equal(calls[0].options.reasoning, 'high');
  for (const reasoning of ['off', 'low', 'xhigh']) {
    sessionReasoning = reasoning;
    for (const settings of [
      {},
      { overrides: { main: { reasoning: 'inherit' } } },
      { overrides: { main: { reasoning: 'low', 'model/with/slashes': { reasoning: 'inherit' } } } },
    ]) {
      result = await run(settings);
      assert.equal(calls[0].options.reasoning, reasoning, 'inherit must select current session reasoning, not a parent setting');
      assert.deepEqual(notices, []);
      await complete(result.compaction);
      assert.equal(notices[0][0], `prefix-compaction: reasoning ${reasoning} (sent); 900/1,000 input tokens cached`);
    }
  }
  sessionReasoning = 'high';
  await run({ overrides: { main: { reasoning: 'low', 'model/with/slashes': {} } } });
  assert.equal(calls[0].options.reasoning, 'low');
  await run({ overrides: { main: { reasoning: 'inherit', 'model/with/slashes': { reasoning: 'minimal' } } } });
  assert.equal(calls[0].options.reasoning, 'minimal');
  for (const reason of ['manual', 'threshold', 'overflow']) {
    for (const disabled of [
      { enabled: false },
      { enabled: false, overrides: { main: { enabled: true, 'model/with/slashes': { enabled: true } } } },
      { overrides: { main: { enabled: false } } },
      { overrides: { main: { 'model/with/slashes': { enabled: false } } } },
      { overrides: { main: { enabled: false, 'model/with/slashes': { reasoning: 'low' } } } },
      { overrides: { main: { enabled: true, 'model/with/slashes': { enabled: false } } } },
    ]) {
      assert.equal(await run(disabled, { reason }), undefined, 'disabled extension must yield to Pi');
      assert.equal(calls.length, 0); assert.equal(coldCalls.length, 0); assert.equal(notices.length, 0);
    }
  }
  await run({ overrides: { main: { enabled: false, reasoning: 'low', 'model/with/slashes': { enabled: true } } } });
  assert.equal(calls.length, 1); assert.equal(calls[0].options.reasoning, 'low');
  ctx.model = undefined; assert.equal(await run({ enabled: false }), undefined); ctx.model = current;
  for (const invalid of [
    { model: 'other/model' }, { model: 'main/model/with/slashes' },
    { reasoning: 'low' }, { reasoning: 'inherit' }, { reasoning: 'invalid' }, { enabled: 'false' },
    { overrides: [] }, { overrides: null }, { overrides: { main: false } }, { overrides: { main: [] } },
    { overrides: { main: { enabled: 'true' } } }, { overrides: { main: { reasoning: 'invalid' } } },
    { overrides: { main: { 'model/with/slashes': null } } }, { overrides: { main: { 'model/with/slashes': false } } },
    { overrides: { main: { 'model/with/slashes': { enabled: 0 } } } },
    { overrides: { main: { 'model/with/slashes': { reasoning: null } } } },
    { overrides: { main: { 'model/with/slashes': { reasoning: 'invalid' } } } },
    { overrides: { main: { 'model/with/slashes': { model: 'main/model' } } } },
    { overrides: { main: { 'model/with/slashes': { overrides: {} } } } },
    { typo: true }, [], null, '{invalid',
  ]) {
    assert.deepEqual(await run(invalid), { cancel: true }); assert.equal(calls.length, 0);
  }
  result = await run({}, { branchEntries: [{ type: 'compaction', details: { strategy: 'prefix-compaction', readFiles: ['old.ts', 'b.ts'], modifiedFiles: ['modified.ts'] } }] });
  assert.equal(result.compaction.details.strategy, 'prefix-compaction');
  assert.deepEqual(result.compaction.details.readFiles, ['a.ts', 'old.ts']);
  assert.deepEqual(result.compaction.details.modifiedFiles, ['b.ts', 'c.ts', 'modified.ts']);
  const stream = ctx.modelRegistry.streamSimple;
  for (const bad of [
    { stopReason: 'error', errorMessage: 'provider failed' }, { stopReason: 'aborted' },
    { stopReason: 'length' }, { stopReason: 'toolUse' }, { content: [{ type: 'toolCall', name: 'write' }] },
    { content: [{ type: 'text', text: '  ' }] },
  ]) {
    ctx.modelRegistry.streamSimple = (...args) => { const s = stream(...args); return { result: async () => ({ ...await s.result(), ...bad }) }; };
    assert.deepEqual(await run(), { cancel: true }); assert.equal(coldCalls.length, 0);
    assert.equal(calls[0].options.signal.aborted, true, 'release failed provider request');
  }
  ctx.modelRegistry.streamSimple = stream;
  failure = new Error('network failure');
  assert.deepEqual(await run(), { cancel: true }); assert.equal(calls.length, 1); failure = undefined;
  assert.deepEqual(await run({}, { signal: AbortSignal.abort() }), { cancel: true });
  assert.equal(calls.length, 0); assert.equal(notices.length, 0);
  const controller = new AbortController(); afterResponse = () => controller.abort();
  assert.deepEqual(await run({}, { signal: controller.signal }), { cancel: true });
  assert.equal(notices.length, 0); afterResponse = undefined;
  result = await run({ overrides: { main: { reasoning: 'low' } } }, { reason: 'overflow', customInstructions: 'keep facts' });
  assert.equal(result.compaction.summary, 'cold summary'); assert.equal(calls.length, 0); assert.equal(coldCalls.length, 1);
  assert.equal(coldCalls[0][1], current); assert.equal(coldCalls[0][4], 'keep facts'); assert.equal(coldCalls[0][6], 'low');
  assert.match(notices[0][0], /without prefix reuse/);
  await complete(result.compaction);
  assert.equal(notices.length, 1, 'overflow fallback must not report prefix-compaction success');
  await run({ overrides: { main: { reasoning: 'inherit' } } }, { reason: 'overflow' });
  assert.equal(coldCalls[0][6], 'high');
  for (const reason of ['manual', 'threshold']) {
    result = await run({}, { reason });
    assert.equal(calls.length, 1); assert.deepEqual(notices, []);
    sessionReasoning = 'low';
    await writeFile(join(dir, 'prefix-compaction.json'), JSON.stringify({ enabled: false }));
    await complete(result.compaction);
    assert.match(notices[0][0], /^prefix-compaction: reasoning high \(sent\)/, 'report saved reasoning despite later session/config changes');
    sessionReasoning = 'high';
  }
  ctx.mode = 'tui';
  for (const reason of ['manual', 'threshold']) {
    result = await run({}, { reason });
    assert.deepEqual(entries, []);
    await complete(result.compaction);
    assert.deepEqual(notices, [], 'TUI must use a durable entry, not an erased transient notification');
    assert.equal(entries.length, 1);
    const theme = { fg: (_color, text) => text };
    const renderHistory = () => entries.flatMap(entry => renderer(entry, {}, theme).render(120));
    assert.deepEqual(renderHistory(), ['prefix-compaction: reasoning high (sent); 900/1,000 input tokens cached'], 'entry survives a chat rebuild');
    extension(pi);
    assert.deepEqual(renderHistory(), [entries[0].data], 'renderer is registered again after reload');
  }
  ctx.mode = 'rpc';
  ctx.model = undefined; assert.deepEqual(await run(), { cancel: true }); ctx.model = current;
  ctx.sessionManager.buildSessionProjection = () => ({ messages: [] });
  assert.deepEqual(await run(), { cancel: true }); assert.equal(calls.length, 0);
  console.log('PASS: native prefix, global/provider/model switches, nested overrides, precedence, inherit reasoning, instructions, checkpoint file lists, usage, post-commit notices, durable TUI entry/reload, provider effort, manual/auto/overflow, invalid config, errors, cancellation, unchanged session');
} finally {
  if (previous === undefined) delete process.env.PI_CODING_AGENT_DIR; else process.env.PI_CODING_AGENT_DIR = previous;
  delete globalThis.__host;
  await rm(dir, { recursive: true, force: true });
}
