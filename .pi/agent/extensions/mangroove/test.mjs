import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { randomUUID } from 'node:crypto';
import { stripTypeScriptTypes } from 'node:module';

const root = await mkdtemp(join(tmpdir(), 'mangroove-test-'));
const previousEditor = process.env.EDITOR;
const previousAgentDir = process.env.PI_CODING_AGENT_DIR;
const globalKey = Symbol.for('personal.mangroove.runtime.v1');
const dataUrl = text => 'data:text/javascript;base64,' + Buffer.from(text).toString('base64');
const coreUrl = dataUrl(stripTypeScriptTypes(await readFile(new URL('./core.ts', import.meta.url), 'utf8')));
const core = await import(coreUrl);
const { FLOW, LINEAGE, RESULT } = core;
assert.deepEqual([LINEAGE, FLOW, RESULT], ['dive-lineage', 'distill-flow', 'distill-result'],
  'persisted session types must survive extension renames');
const usage = (cost = 0.5) => ({ input: 10, cacheRead: 90, cacheWrite: 0, output: 20, totalTokens: 120,
  cost: { input: cost / 2, output: cost / 2, cacheRead: 0, cacheWrite: 0, total: cost } });
const entry = (type, fields = {}) => ({ type, id: randomUUID().slice(0, 8), timestamp: new Date().toISOString(), ...fields });
let editorCode = 0, editorText = 'Reviewed result', editorCalls = 0, calls = [], notices = [], active, response, streamError;
let switchCancelled = false, failSend = false, editorHook;
const states = new Map();
class Text { constructor(text) { this.text = text; } render() { return [this.text]; } }
class Container { children = []; addChild(child) { this.children.push(child); } render(width) { return this.children.flatMap(child => child.render(width)); } }
class Loader { signal = new AbortController().signal; render() { return []; } }
globalThis.__diveHost = {
  Text, Container, Markdown: Text, BorderedLoader: Loader,
  getMarkdownTheme: () => ({}), convertToLlm: messages => structuredClone(messages),
  truncateToWidth: (text, width) => text.slice(0, width),
  spawnSync: (_shell, args) => {
    editorCalls++;
    assert.match(args[1], /exec test-editor --wait "\$1"/);
    assert.equal(args[2], 'distill-editor');
    if (editorText !== undefined) writeFileSync(args[3], editorText);
    editorHook?.();
    return { status: editorCode };
  },
};
let source = await readFile(new URL('./index.ts', import.meta.url), 'utf8');
source = source.replace('import { spawnSync } from "node:child_process";', 'const { spawnSync } = globalThis.__diveHost;')
  .replace(/^import .* from "@earendil-works\/pi-coding-agent";$/m, 'const { BorderedLoader, convertToLlm, getMarkdownTheme } = globalThis.__diveHost;')
  .replace(/^import .* from "@earendil-works\/pi-tui";$/m, 'const { Container, Markdown, Text, truncateToWidth } = globalThis.__diveHost;')
  .replace('"./core.ts"', JSON.stringify(coreUrl))
  .replace('process.stdout.write("\\x1b[2J\\x1b[H");', 'void 0;');
const { default: extension } = await import(dataUrl(stripTypeScriptTypes(source)));
const theme = { fg: (_color, text) => text };
function persist(state) {
  writeFileSync(state.file, [state.header, ...state.entries].map(item => JSON.stringify(item)).join('\n') + '\n');
}
function add(state, type, fields) {
  const result = entry(type, { parentId: state.entries.at(-1)?.id ?? null, ...fields });
  state.entries.push(result); persist(state); return result;
}
function makeState(name, parent, entries = []) {
  const id = randomUUID();
  const state = { file: join(root, `${id}.jsonl`), header: { type: 'session', version: 3, id, cwd: root, parentSession: parent?.file }, entries: structuredClone(entries) };
  states.set(state.file, state);
  if (name) add(state, 'session_info', { name }); else persist(state);
  return state;
}
const nameOf = state => [...state.entries].reverse().find(item => item.type === 'session_info')?.name;
function instantiate(state) {
  const handlers = {}, commands = {}, widgets = {}, renderers = {}, messageRenderers = {};
  let valid = true;
  const guard = () => assert.ok(valid, 'must not use stale pi/ctx after replacement');
  const pi = {
    on: (event, handler) => { (handlers[event] ??= []).push(handler); },
    registerCommand: (name, command) => { commands[name] = command.handler; },
    registerEntryRenderer: (name, renderer) => { renderers[name] = renderer; },
    registerMessageRenderer: (name, renderer) => { messageRenderers[name] = renderer; },
    setSessionName: name => { guard(); add(state, 'session_info', { name }); },
    appendEntry: (customType, data) => { guard(); add(state, 'custom', { customType, data: structuredClone(data) }); },
    getThinkingLevel: () => { guard(); return 'high'; },
  };
  const manager = {
    getSessionId: () => state.header.id, getSessionFile: () => state.file, getHeader: () => state.header,
    getSessionDir: () => root, getSessionName: () => nameOf(state), getEntries: () => state.entries,
    getBranch: () => state.entries, getLeafId: () => state.entries.at(-1)?.id,
    buildSessionProjection: () => ({ messages: state.entries.flatMap(item => item.type === 'message' ? [item.message]
      : item.type === 'custom_message' ? [{ role: 'custom', content: item.content }] : []) }),
  };
  const ctx = { mode: 'tui', hasUI: true, cwd: root, sessionManager: manager, isIdle: () => true, hasPendingMessages: () => false,
    model: { provider: 'offline', id: 'stub', maxTokens: 16000 },
    modelRegistry: { streamSimple: (model, context, options) => {
      calls.push({ model, context: structuredClone(context), options });
      return { result: async () => { if (streamError) throw streamError; return structuredClone(response); } };
    } },
    ui: {
      notify: (...args) => { guard(); notices.push(args); },
      confirm: () => assert.fail('no extra confirmation after editor'),
      setEditorText: text => { guard(); assert.equal(text, ''); },
      setWidget: (name, widget) => { guard(); widgets[name] = widget; },
      custom: factory => new Promise((resolve, reject) => {
        try { factory({ stop() {}, start() {}, requestRender() {} }, theme, {}, resolve); } catch (error) { reject(error); }
      }),
    },
    fork: async (id, options) => {
      guard(); assert.equal(id, manager.getLeafId()); assert.equal(options.position, 'at');
      for (const fn of handlers.session_before_fork ?? []) if (await fn({}, ctx)) return { cancelled: true };
      await emit('session_shutdown'); valid = false;
      const child = makeState(undefined, state, state.entries);
      active = instantiate(child); await active.emit('session_start', { reason: 'fork' });
      await options.withSession(active.ctx);
      return { cancelled: false };
    },
    switchSession: async (file, options) => {
      guard();
      for (const fn of handlers.session_before_switch ?? []) if (await fn({}, ctx)) return { cancelled: true };
      if (switchCancelled) return { cancelled: true };
      await emit('session_shutdown'); valid = false;
      active = instantiate(states.get(resolve(file))); await active.emit('session_start', { reason: 'resume' });
      await options?.withSession?.(active.ctx);
      return { cancelled: false };
    },
    sendMessage: async (message, options) => {
      guard(); assert.deepEqual(options, { triggerTurn: false });
      if (failSend) { failSend = false; throw new Error('synthetic insertion failure'); }
      add(state, 'custom_message', message);
    },
  };
  const emit = async (event, payload = {}) => { for (const handler of handlers[event] ?? []) await handler(payload, ctx); };
  extension(pi);
  return { state, ctx, commands, widgets, renderers, messageRenderers, emit };
}
async function command(name, args = '') { await active.commands[name](args, active.ctx); }
function reset() {
  response = { content: [{ type: 'text', text: 'Original report' }], stopReason: 'stop', usage: usage() };
  editorCode = 0; editorText = 'Reviewed result'; editorCalls = 0; calls = []; notices = [];
  switchCancelled = false; failSend = false; streamError = undefined; editorHook = undefined;
}
const widget = () => active.widgets['dive-ancestors']?.({}, theme).render(200).join('\n');
const drafts = state => state.entries.filter(item => item.type === 'custom' && item.customType === FLOW && item.data.kind === 'draft');
try {
  process.env.EDITOR = 'test-editor --wait';
  process.env.PI_CODING_AGENT_DIR = root;
  assert.deepEqual([...await core.loadSubscriptions()], [], 'missing config defaults to no subscription providers');
  const configFile = join(root, 'mangroove.json');
  for (const invalid of [null, [], { typo: [] }, { subscriptionProviders: [] },
    { billing: null }, { billing: [] }, { billing: 'subscription' }, { billing: { typo: [] } },
    ...[null, 'openai-codex', [''], [' codex']].map(subscription => ({ billing: { subscription } }))]) {
    writeFileSync(configFile, JSON.stringify(invalid));
    await assert.rejects(core.loadSubscriptions());
  }
  writeFileSync(configFile, '{ invalid json');
  await assert.rejects(core.loadSubscriptions());
  writeFileSync(configFile, JSON.stringify({ billing: { subscription: ['openai-codex', 'openai-codex'] } }));
  assert.deepEqual([...await core.loadSubscriptions()], ['openai-codex']);
  writeFileSync(configFile, JSON.stringify({ billing: {} }));
  assert.deepEqual([...await core.loadSubscriptions()], []);
  writeFileSync(configFile, '{}');
  reset();
  const master = makeState('master');
  add(master, 'message', { message: { role: 'system', content: 'Original system', toolsAdded: [{ name: 'read' }] } });
  add(master, 'message', { message: { role: 'user', content: 'Parent task' } });
  add(master, 'message', { message: { role: 'assistant', content: [{ type: 'text', text: 'Parent answer' }], usage: usage(1) } });
  const tail = add(master, 'custom_message', { customType: 'saved-context', content: 'CONTEXT_ADDED_JUST_BEFORE_DIVE', display: true });
  active = instantiate(master); await active.emit('session_start', { reason: 'startup' });
  assert.equal(widget(), undefined, 'root gets no ancestor widget');
  await command('dive', ''); assert.equal(active.state, master); assert.equal(calls.length, 0);
  await command('dive', 'scout');
  const scout = active.state;
  assert.notEqual(scout, master); assert.equal(nameOf(scout), 'scout');
  assert.equal(nameOf(master), 'master', 'parent name unchanged');
  assert.equal('inheritedUsageKeys' in core.getLineage(scout.entries, scout.header.id), false, 'no usage baseline is stored');
  assert.equal(scout.header.parentSession, master.file);
  assert.ok(scout.entries.some(item => item.id === tail.id), 'clone includes the exact current leaf');
  assert.equal(widget(), 'master', 'widget excludes current session and money');
  assert.equal(calls.length, 0, 'dive is free');
  add(scout, 'message', { message: { role: 'user', content: 'Scout task only' } });
  add(scout, 'message', { message: { role: 'assistant', content: [{ type: 'text', text: 'Scout result' }], usage: usage(2) } });
  await command('dive', 'prompt');
  const prompt = active.state;
  assert.equal(widget(), 'master → scout');
  add(prompt, 'message', { message: { role: 'user', content: 'Prompt subtask' } });
  add(prompt, 'message', { message: { role: 'assistant', content: [{ type: 'text', text: 'Prompt result' }], usage: usage(3) } });
  const sourceMessages = structuredClone(active.ctx.sessionManager.buildSessionProjection().messages);
  editorCode = 1; editorText = 'Cancelled but reusable edits';
  await command('distill', 'Keep exact paths');
  assert.equal(active.state, prompt); assert.equal(calls.length, 1); assert.equal(editorCalls, 1);
  assert.deepEqual(calls[0].context.messages.slice(0, -1), sourceMessages, 'unchanged native prefix');
  assert.match(calls[0].context.messages.at(-1).content, /Keep exact paths/);
  assert.match(calls[0].context.messages.at(-1).content, /Prompt subtask/);
  assert.equal(calls[0].options.sessionId, prompt.header.id);
  assert.equal(calls[0].options.reasoning, 'high'); assert.equal(calls[0].options.cacheRetention, 'short');
  assert.equal(drafts(prompt).length, 1);
  assert.match(drafts(prompt)[0].data.instructions, /Keep exact paths/);
  assert.equal(drafts(prompt)[0].data.text, 'Original report');
  assert.ok(prompt.entries.some(item => item.data?.editedText === editorText));
  assert.deepEqual(active.ctx.sessionManager.buildSessionProjection().messages, sourceMessages, 'draft/review excluded from model context');
  assert.equal(prompt.entries.filter(item => item.type === 'compaction').length, 0);
  await command('sap');
  assert.match(notices.at(-1)[0], /TOTAL\s+~\$3\.5000/); // no scout/master costs
  assert.match(notices.at(-1)[0], /Sessions: 1/);
  assert.match(notices.at(-1)[0], /^prompt \(current\)\s+~\$3\.5000/m);
  await active.emit('session_shutdown'); active = instantiate(prompt); await active.emit('session_start', { reason: 'reload' });
  assert.equal(widget(), 'master → scout');
  assert.ok(active.renderers[FLOW](drafts(prompt)[0], { expanded: true }, theme).render(100).join('\n').includes('Original report'));

  reset(); response.responseModel = 'physical-child-model'; await command('distill', 'Return only verified findings');
  assert.equal(drafts(prompt).at(-1).data.responseModel, 'physical-child-model');
  assert.equal(active.state, scout, 'success returns to direct parent, not root');
  const delivered = scout.entries.filter(item => item.type === 'custom_message' && item.customType === RESULT);
  assert.equal(delivered.length, 1); assert.equal(delivered[0].content, 'Reviewed result');
  assert.equal(delivered[0].details.source.name, 'prompt');
  assert.equal(delivered[0].details.source.id, prompt.header.id);
  assert.equal(widget(), 'master');
  assert.equal(calls.length, 1, 'transfer does not start a parent model turn');
  assert.match(active.messageRenderers[RESULT]({ ...delivered[0] }, {}, theme).render(100).join('\n'), /Result from prompt/);
  await command('sap');
  assert.match(notices.at(-1)[0], /TOTAL\s+~\$6\.0000/); // scout 2 + prompt 3 + two drafts .5 each
  assert.match(notices.at(-1)[0], /Sessions: 2/);
  assert.match(notices.at(-1)[0], /^scout \(current\)\s+~\$2\.0000/m);
  assert.match(notices.at(-1)[0], /^└─ prompt\s+~\$4\.0000/m);

  // Return scout to master; inherited drafts must not be charged again after clone.
  reset(); await command('distill'); assert.equal(active.state, master);
  await command('sap'); assert.match(notices.at(-1)[0], /TOTAL\s+~\$7\.5000/);
  assert.match(notices.at(-1)[0], /Sessions: 3/);
  assert.match(notices.at(-1)[0], /^master \(current\)\s+~\$1\.0000/m);
  assert.match(notices.at(-1)[0], /^└─ scout\s+~\$2\.5000/m);
  assert.match(notices.at(-1)[0], /^   └─ prompt\s+~\$4\.0000/m);
  assert.doesNotMatch(notices.at(-1)[0], /actual = total|not invoices/);

  // /surface only switches to the direct parent; nothing is sent or summarized.
  reset(); await command('surface'); assert.equal(active.state, master); assert.match(notices.at(-1)[0], /no parent/);
  await command('dive', 'surface-child'); const surfaceChild = active.state;
  const parentEntries = master.entries.length, childEntries = surfaceChild.entries.length;
  reset(); switchCancelled = true; await command('surface'); assert.equal(active.state, surfaceChild); assert.match(notices.at(-1)[0], /switch cancelled/);
  reset(); await command('surface'); assert.equal(active.state, master);
  assert.equal(calls.length, 0); assert.equal(master.entries.length, parentEntries); assert.equal(surfaceChild.entries.length, childEntries);

  // Errors/cancellation never inject parent context.
  await command('dive', 'failures'); const child = active.state;
  for (const stopReason of ['length', 'toolUse', 'error', 'aborted']) {
    reset(); response.stopReason = stopReason;
    await command('distill'); assert.equal(active.state, child); assert.equal(editorCalls, 0);
  }
  reset(); response.content = [{ type: 'toolCall', name: 'read' }]; await command('distill'); assert.equal(editorCalls, 0);
  reset(); response.content = [{ type: 'text', text: '   ' }]; await command('distill'); assert.equal(editorCalls, 0);
  reset(); editorText = ''; await command('distill'); assert.equal(active.state, child); assert.match(notices.at(-1)[0], /empty/);
  reset(); switchCancelled = true; await command('distill'); assert.equal(active.state, child); assert.match(notices.at(-1)[0], /switch cancelled/);
  reset(); failSend = true; await command('distill'); assert.equal(active.state, child, 'insertion failure rolls back using fresh context');
  assert.match(notices.at(-1)[0], /Transfer failed/);
  reset(); delete process.env.EDITOR; await command('distill'); assert.equal(calls.length, 0); process.env.EDITOR = 'test-editor --wait';
  reset(); await command('distill', '--to master'); assert.equal(calls.length, 0);
  reset(); streamError = new Error('Synthetic provider failure'); await command('distill');
  assert.equal(active.state, child); assert.equal(drafts(child).at(-1).data.error, 'Error: Synthetic provider failure');
  await command('sap'); assert.match(notices.at(-1)[0], /\+ \?/);

  // Own usage includes raw abandoned branches, compaction, tool/nested and cache warming.
  const single = makeState('accounting');
  add(single, 'compaction', { usage: usage(1) });
  add(single, 'branch_summary', { usage: usage(2) });
  add(single, 'usage', { usage: usage(3), kind: 'cache_warm' });
  add(single, 'message', { message: { role: 'toolResult', usage: usage(4) } });
  const snap = await core.readSnapshot(single.file);
  const report = core.sapReport(snap, new Map([[snap.file, snap]]));
  assert.match(report, /TOTAL\s+~\$10\.0000/);
  // Count from the first own marker, not an inherited or later marker.
  const bounded = makeState('boundary');
  bounded.header.parentSession = join(root, 'deleted-parent.jsonl');
  add(bounded, 'message', { message: { role: 'assistant', usage: usage(100) } });
  add(bounded, 'custom', { customType: LINEAGE, data: { version: 1, sessionId: 'ancestor' } });
  add(bounded, 'message', { message: { role: 'assistant', usage: usage(50) } });
  add(bounded, 'custom', { customType: LINEAGE, data: { version: 1, sessionId: bounded.header.id,
    inheritedUsageKeys: ['obsolete field must be ignored'] } });
  add(bounded, 'message', { message: { role: 'assistant', usage: usage(1) } });
  add(bounded, 'custom', { customType: LINEAGE, data: { version: 1, sessionId: bounded.header.id } });
  add(bounded, 'message', { message: { role: 'assistant', usage: usage(2) } });
  add(bounded, 'custom', { customType: FLOW, data: { kind: 'draft', requestId: 'bounded-draft', usage: usage(0.5) } });
  add(bounded, 'custom', { customType: FLOW, data: { kind: 'review', requestId: 'bounded-draft', editedText: 'cancelled' } });
  const boundedSnap = await core.readSnapshot(bounded.file);
  assert.match(core.sapReport(boundedSnap, new Map([[boundedSnap.file, boundedSnap]])), /TOTAL\s+~\$3\.5000/);
  assert.equal((await core.loadSessions(root, boundedSnap)).incomplete, false, 'deleted ancestor is not needed for accounting');
  const unmarked = makeState('unmarked');
  unmarked.header.parentSession = join(root, 'deleted-parent.jsonl');
  add(unmarked, 'custom', { customType: LINEAGE, data: { version: 1, sessionId: 'copied-ancestor' } });
  add(unmarked, 'message', { message: { role: 'assistant', usage: usage(7) } });
  const unmarkedSnap = await core.readSnapshot(unmarked.file);
  assert.match(core.sapReport(unmarkedSnap, new Map([[unmarkedSnap.file, unmarkedSnap]])), /TOTAL\s+~\$7\.0000/,
    'without an own marker, count the whole session even if it has a missing parent');
  // Provider grouping follows each usage record, not the session's current model.
  const mixed = makeState('mixed billing');
  add(mixed, 'model_change', { provider: 'openai-codex', modelId: 'codex' });
  const codexSelection = add(mixed, 'thinking_level_change', { thinkingLevel: 'high' });
  add(mixed, 'message', { message: { role: 'assistant', provider: 'openai-codex', model: 'codex', usage: usage(2) } });
  add(mixed, 'compaction', { usage: usage(1) }); // native compaction uses selected provider
  add(mixed, 'model_change', { provider: 'openai', modelId: 'api' });
  add(mixed, 'message', { message: { role: 'assistant', provider: 'openai', model: 'api', usage: usage(3) } });
  add(mixed, 'custom', { customType: FLOW, data: { kind: 'draft', provider: 'openai-codex', model: 'codex-mini', reasoning: 'low', requestId: 'mixed', usage: usage(0.5) } });
  add(mixed, 'custom', { customType: FLOW, data: { kind: 'review', requestId: 'mixed', editedText: 'review' } });
  add(mixed, 'usage', { provider: 'claude-bridge', model: 'warm-model', usage: usage(4), kind: 'cache_warm' });
  add(mixed, 'branch_summary', { parentId: codexSelection.id, usage: usage(0.25) }); // old branch, not latest raw selection
  add(mixed, 'compaction', { usage: usage(0.75), fromHook: true, details: { strategy: 'prefix-compaction', model: 'claude-bridge/model/with/slashes', reasoning: 'low' } });
  await active.emit('session_shutdown'); active = instantiate(mixed); await active.emit('session_start', { reason: 'startup' });
  const callsBeforeSap = calls.length, entriesBeforeSap = mixed.entries.length;
  writeFileSync(configFile, JSON.stringify({ billing: { subscription: ['openai-codex'] } }));
  await command('sap');
  const mixedReport = notices.at(-1)[0];
  assert.match(mixedReport, /^openai-codex\s+~\$3\.7500\s+~\$0\.0000$/m);
  assert.match(mixedReport, /^openai\s+~\$3\.0000\s+~\$3\.0000$/m);
  assert.match(mixedReport, /^claude-bridge\s+~\$4\.7500\s+~\$4\.7500$/m);
  assert.match(mixedReport, /^TOTAL\s+~\$11\.5000\s+~\$7\.7500$/m);
  assert.match(mixedReport, /^├─ codex:high\s+~\$3\.2500\s+~\$0\.0000$/m, 'native summary model follows the selected tree branch');
  assert.match(mixedReport, /^└─ codex-mini:low\s+~\$0\.5000\s+~\$0\.0000$/m);
  assert.match(mixedReport, /^├─ model\/with\/slashes:low\s+~\$0\.7500\s+~\$0\.7500$/m);
  assert.match(mixedReport, /^└─ warm-model:unknown\s+~\$4\.0000\s+~\$4\.0000$/m);
  writeFileSync(configFile, JSON.stringify({ billing: { subscription: ['openai-codex', 'claude-bridge'] } }));
  await command('sap');
  assert.match(notices.at(-1)[0], /^TOTAL\s+~\$11\.5000\s+~\$3\.0000$/m, 'config changes apply without reload');
  assert.equal(calls.length, callsBeforeSap); assert.equal(mixed.entries.length, entriesBeforeSap);
  add(mixed, 'message', { message: { role: 'toolResult', usage: usage(0.125) } }); // un-attributed nested usage
  const mixedSnap = await core.readSnapshot(mixed.file);
  const unknownReport = core.sapReport(mixedSnap, new Map([[mixedSnap.file, mixedSnap]]), false, new Set(['openai-codex']));
  assert.match(unknownReport, /^\(unknown\)\s+~\$0\.1250\s+\$\?$/m);
  assert.match(unknownReport, /^TOTAL\s+~\$11\.6250\s+~\$7\.7500 \+ \?$/m);
  const unpriced = makeState('unpriced subscription');
  add(unpriced, 'custom', { customType: FLOW, data: { kind: 'draft', provider: 'openai-codex', requestId: 'unpriced' } });
  const unpricedSnap = await core.readSnapshot(unpriced.file);
  assert.match(core.sapReport(unpricedSnap, new Map([[unpricedSnap.file, unpricedSnap]]), false, new Set(['openai-codex'])),
    /^openai-codex\s+\$\?\s+~\$0\.0000$/m, 'subscription actual is zero even if its API equivalent is unknown');
  // Multiple descendants are shown as a sorted tree of own costs, not subtree sums.
  const trunk = makeState('trunk');
  add(trunk, 'message', { message: { role: 'assistant', provider: 'openai', usage: usage(1) } });
  const alpha = makeState('alpha', trunk, trunk.entries);
  add(alpha, 'custom', { customType: LINEAGE, data: { version: 1, sessionId: alpha.header.id } });
  add(alpha, 'message', { message: { role: 'assistant', provider: 'openai-codex', usage: usage(2) } });
  const leaf = makeState('leaf', alpha, alpha.entries);
  add(leaf, 'custom', { customType: LINEAGE, data: { version: 1, sessionId: leaf.header.id } });
  add(leaf, 'message', { message: { role: 'assistant', provider: 'openai', usage: usage(3) } });
  const zeta = makeState('zeta', trunk, trunk.entries);
  add(zeta, 'custom', { customType: LINEAGE, data: { version: 1, sessionId: zeta.header.id } });
  add(zeta, 'usage', { provider: 'openai', usage: usage(4), kind: 'cache_warm' });
  const tree = await Promise.all([zeta, leaf, trunk, alpha].map(node => core.readSnapshot(node.file)));
  const treeReport = core.sapReport(tree[2], new Map(tree.map(node => [node.file, node])), false, new Set(['openai-codex']));
  assert.match(treeReport, /^TOTAL\s+~\$10\.0000\s+~\$8\.0000$/m);
  assert.match(treeReport, /^trunk \(current\)\s+~\$1\.0000\s+~\$1\.0000$/m);
  assert.match(treeReport, /^├─ alpha\s+~\$2\.0000\s+~\$0\.0000$/m);
  assert.match(treeReport, /^│  └─ leaf\s+~\$3\.0000\s+~\$3\.0000$/m);
  assert.match(treeReport, /^└─ zeta\s+~\$4\.0000\s+~\$4\.0000$/m);
  assert.ok(treeReport.indexOf('├─ alpha') < treeReport.indexOf('│  └─ leaf'));
  assert.ok(treeReport.indexOf('│  └─ leaf') < treeReport.indexOf('└─ zeta'));
  // Physical response models win over aliases; equal model names stay scoped to their provider.
  const models = makeState('model breakdown');
  add(models, 'message', { message: { role: 'assistant', provider: 'openai', model: 'requested-alias', responseModel: 'vendor/resolved-v1', thinkingLevel: 'high', usage: usage(1) } });
  add(models, 'message', { message: { role: 'assistant', provider: 'openai', model: 'known', thinkingLevel: 'high', usage: usage(2) } });
  add(models, 'message', { message: { role: 'assistant', provider: 'openai', thinkingLevel: 'high', usage: usage(3) } });
  add(models, 'usage', { provider: 'openai', model: 'warm/v2', reasoning: 'off', usage: usage(4), kind: 'cache_warm' });
  add(models, 'custom', { customType: FLOW, data: { kind: 'draft', provider: 'openai', model: 'summary-alias', responseModel: 'summary/v3', reasoning: 'high', requestId: 'physical-model', usage: usage(5) } });
  add(models, 'message', { message: { role: 'assistant', provider: 'openai', model: 'shared-name', thinkingLevel: 'high', usage: usage(6) } });
  add(models, 'message', { message: { role: 'assistant', provider: 'openai-codex', model: 'shared-name', thinkingLevel: 'high', usage: usage(7) } });
  const modelsSnap = await core.readSnapshot(models.file);
  const modelReport = core.sapReport(modelsSnap, new Map([[modelsSnap.file, modelsSnap]]), false, new Set(['openai-codex']));
  assert.match(modelReport, /^openai\s+~\$21\.0000\s+~\$21\.0000$/m);
  assert.match(modelReport, /^openai-codex\s+~\$7\.0000\s+~\$0\.0000\n└─ shared-name:high\s+~\$7\.0000\s+~\$0\.0000$/m);
  assert.match(modelReport, /^├─ shared-name:high\s+~\$6\.0000\s+~\$6\.0000$/m);
  assert.match(modelReport, /^├─ \(unknown model\):high\s+~\$3\.0000\s+~\$3\.0000$/m);
  assert.match(modelReport, /^├─ vendor\/resolved-v1:high\s+~\$1\.0000\s+~\$1\.0000$/m);
  assert.match(modelReport, /^├─ summary\/v3:high\s+~\$5\.0000\s+~\$5\.0000$/m);
  assert.doesNotMatch(modelReport, /requested-alias|summary-alias|\? =/);
  const modelRows = modelReport.split('By session')[0].split('\n').filter(line => /^[├└]─ /.test(line));
  const modelSum = modelRows.reduce((sum, line) => {
    const amounts = [...line.matchAll(/~\$(\d+\.\d+)/g)].map(match => Number(match[1]));
    return [sum[0] + amounts[0], sum[1] + amounts[1]];
  }, [0, 0]);
  assert.deepEqual(modelSum, [28, 21], 'model rows reconcile with provider and overall totals');
  assert.match(modelReport, /^TOTAL\s+~\$28\.0000\s+~\$21\.0000$/m);
  // Reasoning is a separate cost dimension, with historic branch fallback only where safe.
  const efforts = makeState('reasoning breakdown');
  add(efforts, 'model_change', { provider: 'openai-codex', modelId: 'gpt-6.1-sol' });
  const historicalHigh = add(efforts, 'thinking_level_change', { thinkingLevel: 'high' });
  add(efforts, 'message', { message: { role: 'assistant', provider: 'openai-codex', model: 'gpt-6.1-sol', usage: usage(1) } });
  add(efforts, 'thinking_level_change', { thinkingLevel: 'low' });
  add(efforts, 'message', { message: { role: 'assistant', provider: 'openai-codex', model: 'gpt-6.1-sol', thinkingLevel: 'high', providerThinkingLevel: 'max', usage: usage(2) } });
  add(efforts, 'message', { message: { role: 'assistant', provider: 'openai-codex', model: 'gpt-6.1-sol', usage: usage(3) } });
  add(efforts, 'message', { message: { role: 'assistant', provider: 'openai-codex', model: 'gpt-6.1-sol', thinkingLevel: 'off', usage: usage(4) } });
  add(efforts, 'compaction', { usage: usage(5), fromHook: true, details: { model: 'openai-codex/gpt-6.1-sol', reasoning: 'low' } });
  add(efforts, 'branch_summary', { parentId: historicalHigh.id, usage: usage(6) });
  add(efforts, 'compaction', { usage: usage(7), fromHook: true, details: { model: 'openai-codex/gpt-6.1-sol' } });
  add(efforts, 'usage', { provider: 'openai-codex', model: 'gpt-6.1-sol', kind: 'cache_warm', usage: usage(8) });
  add(efforts, 'custom', { customType: FLOW, data: { kind: 'draft', provider: 'openai-codex', model: 'gpt-6.1-sol', reasoning: 'low', requestId: 'effort-low', usage: usage(9) } });
  add(efforts, 'usage', { provider: 'openai', model: 'single', reasoning: 'high', usage: usage(10) });
  add(efforts, 'message', { message: { role: 'assistant', provider: 'openai-codex', model: 'routed-physical', usage: usage(11) } });
  const effortSnap = await core.readSnapshot(efforts.file);
  const savedEfforts = JSON.stringify(efforts.entries);
  const effortReport = core.sapReport(effortSnap, new Map([[effortSnap.file, effortSnap]]), false, new Set(['openai-codex']));
  assert.match(effortReport, /^openai-codex\s+~\$56\.0000\s+~\$0\.0000$/m);
  assert.match(effortReport, /^├─ gpt-6\.1-sol\s+~\$45\.0000\s+~\$0\.0000$/m);
  assert.match(effortReport, /^│  ├─ off\s+~\$4\.0000\s+~\$0\.0000$/m);
  assert.match(effortReport, /^│  ├─ low\s+~\$17\.0000\s+~\$0\.0000$/m);
  assert.match(effortReport, /^│  ├─ high\s+~\$9\.0000\s+~\$0\.0000$/m);
  assert.match(effortReport, /^│  └─ unknown\s+~\$15\.0000\s+~\$0\.0000$/m);
  assert.match(effortReport, /^└─ routed-physical:unknown\s+~\$11\.0000\s+~\$0\.0000$/m);
  assert.match(effortReport, /^└─ single:high\s+~\$10\.0000\s+~\$10\.0000$/m);
  assert.match(effortReport, /^TOTAL\s+~\$66\.0000\s+~\$10\.0000$/m);
  assert.doesNotMatch(effortReport, /\? =|├─ max|└─ max/);
  const levelSum = effortReport.split('By session')[0].split('\n').filter(line => /^│  [├└]─ /.test(line))
    .reduce((sum, line) => sum + Number(line.match(/~\$(\d+\.\d+)/)[1]), 0);
  assert.equal(levelSum, 45, 'reasoning leaves reconcile with their model subtotal');
  assert.equal(JSON.stringify(efforts.entries), savedEfforts, 'accounting must not rewrite history');
  const inheritedEffort = makeState('reasoning child', efforts, efforts.entries);
  add(inheritedEffort, 'custom', { customType: LINEAGE, data: { version: 1, sessionId: inheritedEffort.header.id } });
  add(inheritedEffort, 'message', { message: { role: 'assistant', provider: 'openai-codex', model: 'gpt-6.1-sol', usage: usage(1) } });
  const childEffortSnap = await core.readSnapshot(inheritedEffort.file);
  assert.match(core.sapReport(childEffortSnap, new Map([[childEffortSnap.file, childEffortSnap]]), false, new Set(['openai-codex'])),
    /^└─ gpt-6\.1-sol:high\s+~\$1\.0000\s+~\$0\.0000$/m, 'saved reasoning before the own lineage boundary is retained');
  assert.equal(core.usageCost(usage(0)).unknown, true);
  assert.equal(core.usageCost({ totalTokens: 0, cost: { total: 0 } }).unknown, false);
  assert.deepEqual(core.getLineage(scout.entries, scout.header.id).parent.id, master.header.id);
  assert.equal(core.getLineage(scout.entries, 'not-this-session'), undefined);
  assert.equal(core.cleanName('scout\u001b\n'), 'scout');
  console.log('PASS: current-leaf clone, naming, ancestor-only widget/reload, cached prefix, editor exit status, flow persistence/context exclusion, parent delivery/rollback, /surface, marker-based subtree costs, provider/model/session total/actual, model/reasoning reconciliation, saved branch reasoning, sorted descendant tree, nested billing config and error paths.');
} finally {
  if (previousEditor === undefined) delete process.env.EDITOR; else process.env.EDITOR = previousEditor;
  if (previousAgentDir === undefined) delete process.env.PI_CODING_AGENT_DIR; else process.env.PI_CODING_AGENT_DIR = previousAgentDir;
  delete globalThis.__diveHost; delete globalThis[globalKey];
  await rm(root, { recursive: true, force: true });
}
