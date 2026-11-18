#!/usr/bin/env python3
import fcntl
import os
from pathlib import Path
import pty
import select
import shutil
import signal
import struct
import subprocess
import tempfile
import termios
import time

HERE = Path(__file__).resolve().parent
with tempfile.TemporaryDirectory(prefix='pi-agents-tui-') as temp:
    root = Path(temp)
    config = root / 'agent'
    extensions = config / 'extensions'
    extensions.mkdir(parents=True)
    (extensions / 'agents.ts').symlink_to(HERE.parent / 'agent/extensions/agents.ts')
    (extensions / 'provider.ts').symlink_to(HERE / 'fake-provider.ts')
    (config / 'settings.json').write_text('{"enabledModels":["agents-fixture/fixture:low"]}')
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', 40, 120, 0, 0))
    env = dict(os.environ, PI_CODING_AGENT_DIR=str(config), PI_OFFLINE='1', TERM='xterm-256color')
    process = subprocess.Popen([shutil.which('pi'), '--tui-mode', 'regular', '--session', str(root / 'parent.jsonl'), '--model', 'agents-fixture/fixture'], cwd=root, env=env, stdin=slave, stdout=slave, stderr=slave, start_new_session=True)
    os.close(slave)
    output = bytearray()
    cursor = 0
    def wait_for(value, timeout=15):
        global cursor
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            match = output.find(value, cursor)
            if match >= 0:
                cursor = match + len(value)
                return
            ready, _, _ = select.select([master], [], [], 0.2)
            if ready:
                try:
                    output.extend(os.read(master, 65536))
                except OSError:
                    break
            if process.poll() is not None:
                break
        raise AssertionError(f'not found: {value!r}; output tail={bytes(output[-6000:])!r}')
    try:
        wait_for(b'agents.ts, provider.ts')
        os.write(master, b'launch fixture\r')
        wait_for(b'child fixture result')
        wait_for(b'parent fixture response')
        os.write(master, b'/agents\r')
        wait_for(b'Agent sessions')
        wait_for(b'child fixture')
        os.write(master, b'\r')
        wait_for(b'Resumed session')
        os.write(master, b'/agents\r')
        wait_for(b'Parent session')
        os.write(master, b'\r')
        wait_for(b'launch fixture')
        os.killpg(process.pid, signal.SIGKILL)
        process.wait(timeout=5)
        os.close(master)
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', 40, 120, 0, 0))
        process = subprocess.Popen([shutil.which('pi'), '--tui-mode', 'regular', '--session', str(root / 'parent.jsonl'), '--model', 'agents-fixture/fixture'], cwd=root, env=env, stdin=slave, stdout=slave, stderr=slave, start_new_session=True)
        os.close(slave)
        output = bytearray()
        cursor = 0
        wait_for(b'parent fixture response')
        os.write(master, b'/agents\r')
        wait_for(b'Agent sessions')
        wait_for(b'completed')
        wait_for(b'child fixture')
        print('PASS Pi TUI: switch to child and back; restore list after restart')
    finally:
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
        os.close(master)
