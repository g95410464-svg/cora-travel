import { test } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import { createApp } from '../src/app.js';
import type { Config } from '../src/config/env.js';
import { AIService } from '../src/services/ai/AIService.js';
import { OpenRouterProvider } from '../src/services/ai/OpenRouterProvider.js';
import { NvidiaNimProvider } from '../src/services/ai/NvidiaNimProvider.js';

const config: Config = { AI_PROVIDER: 'openrouter', AI_MODEL: 'test-model',
  OPENROUTER_API_KEY: 'test-key', NVIDIA_NIM_API_KEY: 'nim-test-key',
  AI_TIMEOUT_MS: 100, PORT: 3000, RATE_LIMIT_MAX: 30 };
const body = { message: 'Hola CORA', userId: 'demo', context: {} };

test('CORS permits only local web preview origin', async () => {
  const app = createApp(config);
  await request(app).options('/api/chat').set('Origin', 'http://localhost:8080')
    .expect('Access-Control-Allow-Origin', 'http://localhost:8080').expect(204);
  const response = await request(app).options('/api/chat').set('Origin', 'https://untrusted.example');
  assert.equal(response.headers['access-control-allow-origin'], undefined);
});

test('health and chat contract through injected AIProvider', async () => {
  const app = createApp(config, new AIService({ complete: async messages => {
    assert.equal(messages[0].role, 'system');
    assert.match(messages[1].content, /Hola CORA/);
    return 'Hola, ¿exploramos El Salvador?';
  } }));
  await request(app).get('/health').expect(200, { status: 'ok' });
  await request(app).post('/api/chat').send(body).expect(200, { reply: 'Hola, ¿exploramos El Salvador?' });
});

test('reject invalid inputs before calling AI', async () => {
  const app = createApp(config, new AIService({ complete: async () => { throw new Error('Must not run'); } }));
  for (const invalid of [{}, { ...body, message: ' ' }, { ...body, message: 'x'.repeat(4001) },
    { ...body, userId: 1 }, { ...body, context: { nested: {} } }]) {
    await request(app).post('/api/chat').send(invalid).expect(400);
  }
  await request(app).post('/api/chat').set('Content-Type', 'application/json').send('{bad').expect(400);
  await request(app).post('/api/chat').send({ ...body, message: 'x'.repeat(20000) }).expect(413);
});

test('rate limiting prevents excess AI requests', async () => {
  const app = createApp({ ...config, RATE_LIMIT_MAX: 1 }, new AIService({ complete: async () => 'Hola' }));
  await request(app).post('/api/chat').send(body).expect(200);
  await request(app).post('/api/chat').send(body).expect(429);
});

test('missing configuration is explicit and internal errors remain private', async () => {
  await request(createApp({ ...config, OPENROUTER_API_KEY: '' })).post('/api/chat').send(body).expect(503);
  const app = createApp(config, new AIService({ complete: async () => { throw new Error('SECRET'); } }));
  const response = await request(app).post('/api/chat').send(body).expect(500);
  assert.ok(!JSON.stringify(response.body).includes('SECRET'));
});

test('both providers send configured model and server-side authorization', async () => {
  for (const Provider of [OpenRouterProvider, NvidiaNimProvider]) {
    const transport: typeof fetch = async (url, options) => {
      assert.match(String(url), Provider === OpenRouterProvider ? /openrouter.ai/ : /integrate.api.nvidia.com/);
      assert.equal(JSON.parse(String(options?.body)).model, 'test-model');
      assert.equal(new Headers(options?.headers).get('Authorization'),
        Provider === OpenRouterProvider ? 'Bearer test-key' : 'Bearer nim-test-key');
      return Response.json({ choices: [{ message: { content: 'Chivo' } }] });
    };
    assert.equal(await new Provider(config, transport).complete([{ role: 'user', content: 'Hola' }]), 'Chivo');
  }
});

test('upstream failure and malformed content map to safe 502', async () => {
  for (const response of [new Response('secret upstream error', { status: 401 }), Response.json({ choices: [] })]) {
    const provider = new OpenRouterProvider(config, async () => response);
    await assert.rejects(provider.complete([]), { status: 502, code: 'AI_UNAVAILABLE' });
  }
});

test('timeout aborts provider request', async () => {
  const transport: typeof fetch = async (_url, options) => new Promise((_resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Timeout not triggered')), 1000);
    options?.signal?.addEventListener('abort', () => { clearTimeout(timer); reject(new Error('aborted')); });
  });
  await assert.rejects(new OpenRouterProvider(config, transport).complete([]), { status: 504, code: 'AI_TIMEOUT' });
});
