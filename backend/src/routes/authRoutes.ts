import { createHmac, randomBytes } from 'node:crypto';
import { Router } from 'express';
import type { GoogleAuthConfig } from '../config/googleAuth.js';

type GoogleUser = {
  sub: string;
  email: string;
  name: string;
  picture?: string;
};

type PendingCode = {
  user: GoogleUser;
  expiresAt: number;
};

const STATE_TTL_MS = 10 * 60 * 1000;
const CODE_TTL_MS = 2 * 60 * 1000;
const SESSION_TTL_SECONDS = 30 * 24 * 60 * 60;

function b64(value: string | Buffer): string {
  return Buffer.from(value).toString('base64url');
}

function createSessionToken(user: GoogleUser, secret: string): string {
  const now = Math.floor(Date.now() / 1000);
  const header = b64(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const payload = b64(JSON.stringify({
    sub: user.sub,
    email: user.email,
    name: user.name,
    picture: user.picture,
    provider: 'google',
    iat: now,
    exp: now + SESSION_TTL_SECONDS,
  }));
  const signature = createHmac('sha256', secret)
    .update(`${header}.${payload}`)
    .digest('base64url');
  return `${header}.${payload}.${signature}`;
}

function isConfigured(config: GoogleAuthConfig): boolean {
  return Boolean(
    config.GOOGLE_CLIENT_ID &&
    config.GOOGLE_CLIENT_SECRET &&
    config.GOOGLE_REDIRECT_URI,
  );
}

export function authRoutes(
  config: GoogleAuthConfig,
  transport: typeof fetch = fetch,
) {
  const router = Router();
  const pendingStates = new Map<string, number>();
  const pendingCodes = new Map<string, PendingCode>();
  const sessionSecret = config.AUTH_SESSION_SECRET || randomBytes(32).toString('hex');

  const prune = () => {
    const now = Date.now();
    for (const [state, expiresAt] of pendingStates) {
      if (expiresAt <= now) pendingStates.delete(state);
    }
    for (const [code, pending] of pendingCodes) {
      if (pending.expiresAt <= now) pendingCodes.delete(code);
    }
  };

  const mobileRedirect = (res: Parameters<Parameters<typeof router.get>[1]>[1], params: Record<string, string>) => {
    const uri = new URL(config.MOBILE_AUTH_REDIRECT_URI);
    for (const [key, value] of Object.entries(params)) uri.searchParams.set(key, value);
    return res.redirect(uri.toString());
  };

  router.get('/google/redirect', (_req, res) => {
    if (!isConfigured(config)) {
      res.status(503).json({
        error: {
          code: 'GOOGLE_AUTH_NOT_CONFIGURED',
          message: 'Google OAuth todavía no está configurado en el servidor.',
        },
      });
      return;
    }

    prune();
    const state = randomBytes(24).toString('base64url');
    pendingStates.set(state, Date.now() + STATE_TTL_MS);

    const params = new URLSearchParams({
      client_id: config.GOOGLE_CLIENT_ID,
      redirect_uri: config.GOOGLE_REDIRECT_URI,
      response_type: 'code',
      scope: 'openid email profile',
      state,
      prompt: 'select_account',
      include_granted_scopes: 'true',
    });
    res.redirect(`https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`);
  });

  router.get('/google/callback', async (req, res) => {
    prune();

    if (typeof req.query.error === 'string') {
      mobileRedirect(res, { error: 'google_denied' });
      return;
    }

    const state = typeof req.query.state === 'string' ? req.query.state : '';
    const code = typeof req.query.code === 'string' ? req.query.code : '';
    const expiresAt = pendingStates.get(state);
    pendingStates.delete(state);

    if (!code || !state || !expiresAt || expiresAt <= Date.now()) {
      mobileRedirect(res, { error: 'invalid_oauth_state' });
      return;
    }

    try {
      const tokenResponse = await transport('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          code,
          client_id: config.GOOGLE_CLIENT_ID,
          client_secret: config.GOOGLE_CLIENT_SECRET,
          redirect_uri: config.GOOGLE_REDIRECT_URI,
          grant_type: 'authorization_code',
        }),
      });

      if (!tokenResponse.ok) {
        mobileRedirect(res, { error: 'google_token_exchange_failed' });
        return;
      }

      const tokenBody = await tokenResponse.json() as { access_token?: string };
      if (!tokenBody.access_token) {
        mobileRedirect(res, { error: 'google_token_missing' });
        return;
      }

      const userResponse = await transport('https://openidconnect.googleapis.com/v1/userinfo', {
        headers: { Authorization: `Bearer ${tokenBody.access_token}` },
      });
      if (!userResponse.ok) {
        mobileRedirect(res, { error: 'google_profile_failed' });
        return;
      }

      const profile = await userResponse.json() as Partial<GoogleUser>;
      if (!profile.sub || !profile.email) {
        mobileRedirect(res, { error: 'google_profile_invalid' });
        return;
      }

      const user: GoogleUser = {
        sub: profile.sub,
        email: profile.email,
        name: profile.name?.trim() || profile.email,
        picture: profile.picture,
      };
      const mobileCode = randomBytes(32).toString('base64url');
      pendingCodes.set(mobileCode, { user, expiresAt: Date.now() + CODE_TTL_MS });
      mobileRedirect(res, { code: mobileCode });
    } catch {
      mobileRedirect(res, { error: 'google_unavailable' });
    }
  });

  router.post('/mobile/exchange', (req, res) => {
    prune();
    const code = typeof req.body?.code === 'string' ? req.body.code : '';
    const pending = pendingCodes.get(code);
    pendingCodes.delete(code);

    if (!pending || pending.expiresAt <= Date.now()) {
      res.status(401).json({
        error: { code: 'AUTH_CODE_INVALID', message: 'El código de acceso venció o ya fue usado.' },
      });
      return;
    }

    res.json({
      token: createSessionToken(pending.user, sessionSecret),
      user: {
        id: pending.user.sub,
        email: pending.user.email,
        name: pending.user.name,
        picture: pending.user.picture,
        provider: 'google',
      },
    });
  });

  return router;
}
