#!/usr/bin/env python3
"""Run real Pi with an offline provider and a fresh process for every turn."""
import json, os, re, subprocess, tempfile
from pathlib import Path

here = Path(__file__).resolve().parent
model = 'agents-fixture/fixture'
with tempfile.TemporaryDirectory() as temp:
    root = Path(temp)
    ext = root / 'agent/extensions'
    ext.mkdir(parents=True)
    (ext / 'provider.ts').symlink_to(here / 'fake-provider.ts')
    (ext / 'agents.ts').symlink_to(here.parent / 'agent/extensions/agents.ts')
    env = dict(os.environ, PI_CODING_AGENT_DIR=str(ext.parent), PI_OFFLINE='1')
    parent = root / 'parent.jsonl'
    def run(message, path=parent, scope=model+':low'):
        args = ['pi', '-p', '--mode', 'json', '--session', str(path), '--model', model]
        if scope: args += ['--models', scope]
        proc = subprocess.run(args + ['--', message], cwd=root, env=env, timeout=30, capture_output=True, text=True, check=True)
        return [json.loads(l) for l in proc.stdout.splitlines() if l.startswith('{')]
    def call(tool, args, error=False, scope=model+':low'):
        events = run('call '+json.dumps([tool, args]), scope=scope)
        end = next(e for e in events if e['type']=='tool_execution_end' and e['toolName']==tool)
        text = end['result']['content'][0]['text']
        assert bool(end.get('isError')) == error, text
        return text
    def children():
        return [e['data'] for line in parent.read_text().splitlines() if (e:=json.loads(line)).get('customType')=='agents:child']
    assert call('list_subagent_models', {}) == model+' (low)'
    for invalid in ['fixture','other','agents-fixture/other']:
        assert 'not scoped' in call('agent', {'model':invalid, 'task':'no'}, error=True)
    assert '/scoped-models' in call('agent', {'task':'no'}, error=True, scope=None)
    assert 'Unsupported effort max' in call('agent', {'model':model, 'task':'no', 'effort':'max'}, error=True)
    assert not children()
    answer = call('agent', {'model':model,'task':'remember cobalt','effort':'high'})
    [link] = children()
    child = Path(link['path'])
    assert link['id'] in answer and 'SHELL_OK' in answer, answer
    assert json.loads(child.read_text().splitlines()[0])['parentSession'] == str(parent)
    def levels():
        return [e['thinkingLevel'] for line in child.read_text().splitlines() if (e:=json.loads(line)).get('type')=='thinking_level_change']
    assert levels()[-1] == 'high', levels()
    run('manual note: amber', child)
    args = {'session_id':link['id'],'task':'/agents'}
    before = child.read_bytes()
    assert 'Unsupported effort max' in call('agent', dict(args, effort='max'), error=True)
    assert child.read_bytes() == before
    answer = call('agent', dict(args, effort='medium'))
    assert json.loads(answer.split('\n\n', 1)[1])['thinking'] == 'medium'
    assert levels()[-1] == 'medium'
    assert json.loads(call('agent', args, scope=model).split('\n\n', 1)[1])['thinking'] == 'medium'
    assert all(s in answer for s in ['remember cobalt', 'manual note: amber','/agents',link['id']]), answer
    assert 'not scoped' in call('agent', args, error=True, scope='agents-fixture/other')
    assert 'Unknown child' in call('agent', dict(args,session_id='unrelated'),error=True)
    child.unlink()
    assert 'missing' in call('agent', args, error=True) and not child.exists()
    assert children() == [link]
    print('PASS: exact/pinned scope, strict rejection, sync result, shell available, manual + delegated follow-up after restart, no replacement')
