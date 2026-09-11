import { spawn } from 'node:child_process';
import assert from 'node:assert/strict';
import { once } from 'node:events';

const port = 31387;
const server = spawn(process.execPath, ['dist/server.js'], {
  env: { ...process.env, PORT: String(port), OPENROUTER_API_KEY: '', AI_PROVIDER: 'openrouter', AI_MODEL: '' },
  stdio: ['ignore', 'pipe', 'pipe'],
});
const exited = once(server, 'exit');
try {
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Server did not start')), 5000);
    server.once('error', error => { clearTimeout(timer); reject(error); });
    server.stdout.on('data', data => {
      if (String(data).includes('CORA API disponible')) { clearTimeout(timer); resolve(); }
    });
    server.once('exit', code => { clearTimeout(timer); reject(new Error(`Server exited: ${code}`)); });
  });
  const response = await fetch(`http://127.0.0.1:${port}/health`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: 'ok' });
  const chat = await fetch(`http://127.0.0.1:${port}/api/chat`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: 'Hola', userId: 'smoke', context: {} }),
  });
  assert.equal(chat.status, 503);
  assert.equal((await chat.json()).error.code, 'AI_NOT_CONFIGURED');
  console.log('PASS: compiled server starts; /health 200; unconfigured chat 503.');
} finally {
  server.kill();
  await exited;
}
