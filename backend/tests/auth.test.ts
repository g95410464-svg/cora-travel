import { test } from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import request from 'supertest';
import { authRoutes } from '../src/routes/authRoutes.js';
import type { GoogleAuthConfig } from '../src/config/googleAuth.js';

const config: GoogleAuthConfig = {
  GOOGLE_CLIENT_ID: 'cora-client.apps.googleusercontent.com',
  GOOGLE_CLIENT_SECRET: 'test-secret',
  GOOGLE_REDIRECT_URI: 'https://api.example.com/auth/google/callback',
  MOBILE_AUTH_REDIRECT_URI: 'cora://auth/callback',
  AUTH_SESSION_SECRET: 'session-secret-for-tests',
};

function makeApp(transport: typeof fetch) {
  const app = express();
  app.use(express.json());
  app.use('/auth', authRoutes(config, transport));
  return app;
}

test('Google OAuth redirects, returns to the app and exchanges one-time code', async () => {
  const transport: typeof fetch = async (url, options) => {
    if (String(url).includes('oauth2.googleapis.com/token')) {
      assert.equal(options?.method, 'POST');
      const body = new URLSearchParams(String(options?.body));
      assert.equal(body.get('client_id'), config.GOOGLE_CLIENT_ID);
      assert.equal(body.get('client_secret'), config.GOOGLE_CLIENT_SECRET);
      assert.equal(body.get('redirect_uri'), config.GOOGLE_REDIRECT_URI);
      return Response.json({ access_token: 'google-access-token' });
    }
    if (String(url).includes('openidconnect.googleapis.com/v1/userinfo')) {
      assert.equal(new Headers(options?.headers).get('Authorization'), 'Bearer google-access-token');
      return Response.json({
        sub: 'google-user-1',
        email: 'viajero@example.com',
        name: 'Viajero CORA',
        picture: 'https://example.com/avatar.png',
      });
    }
    throw new Error(`Unexpected URL: ${String(url)}`);
  };

  const app = makeApp(transport);
  const start = await request(app).get('/auth/google/redirect').expect(302);
  const googleUrl = new URL(start.headers.location);
  assert.equal(googleUrl.origin, 'https://accounts.google.com');
  assert.equal(googleUrl.searchParams.get('client_id'), config.GOOGLE_CLIENT_ID);
  assert.equal(googleUrl.searchParams.get('redirect_uri'), config.GOOGLE_REDIRECT_URI);
  const state = googleUrl.searchParams.get('state');
  assert.ok(state);

  const callback = await request(app)
    .get('/auth/google/callback')
    .query({ code: 'google-code', state })
    .expect(302);
  const mobileUrl = new URL(callback.headers.location);
  assert.equal(mobileUrl.protocol, 'cora:');
  assert.equal(mobileUrl.host, 'auth');
  assert.equal(mobileUrl.pathname, '/callback');
  const mobileCode = mobileUrl.searchParams.get('code');
  assert.ok(mobileCode);

  const exchange = await request(app)
    .post('/auth/mobile/exchange')
    .send({ code: mobileCode })
    .expect(200);
  assert.equal(exchange.body.user.email, 'viajero@example.com');
  assert.equal(exchange.body.user.provider, 'google');
  assert.equal(typeof exchange.body.token, 'string');
  assert.equal(exchange.body.token.split('.').length, 3);

  await request(app)
    .post('/auth/mobile/exchange')
    .send({ code: mobileCode })
    .expect(401);
});

test('Google OAuth refuses stale or unknown state', async () => {
  const app = makeApp(async () => { throw new Error('transport should not run'); });
  const response = await request(app)
    .get('/auth/google/callback')
    .query({ code: 'code', state: 'unknown' })
    .expect(302);
  const mobileUrl = new URL(response.headers.location);
  assert.equal(mobileUrl.searchParams.get('error'), 'invalid_oauth_state');
});
