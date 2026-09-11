import express from 'express';
import helmet from 'helmet';
import { rateLimit } from 'express-rate-limit';
import type { Config } from './config/env.js';
import { readGoogleAuthConfig } from './config/googleAuth.js';
import { errorHandler } from './middleware/errors.js';
import { authRoutes } from './routes/authRoutes.js';
import { chatRoutes } from './routes/chatRoutes.js';
import { currencyRoutes } from './routes/currencyRoutes.js';
import { createAIService, type AIService } from './services/ai/AIService.js';

export function createApp(config: Config, ai: AIService = createAIService(config)) {
  const app = express();
  app.disable('x-powered-by');
  app.use(helmet());
  // Local Flutter web preview; native mobile does not require CORS.
  app.use((req, res, next) => {
    if (req.headers.origin === 'http://localhost:8080') {
      res.setHeader('Access-Control-Allow-Origin', 'http://localhost:8080');
      res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    }
    res.vary('Origin');
    if (req.method === 'OPTIONS') { res.sendStatus(204); return; }
    next();
  });
  app.get('/', (_req, res) => res.json({
    name: 'CORA API',
    status: 'online',
    message: 'Backend de CORA activo.',
    health: '/health',
    endpoints: ['/auth/google/redirect', '/auth/mobile/exchange', '/api/chat', '/api/currency/convert'],
  }));
  app.get('/health', (_req, res) => res.json({ status: 'ok' }));
  app.use(express.json({ limit: '16kb' }));

  app.use('/auth', rateLimit({
    windowMs: 60000, limit: 20,
    standardHeaders: 'draft-8', legacyHeaders: false,
    message: { error: { code: 'RATE_LIMITED', message: 'Espera un momento antes de intentar iniciar sesión de nuevo.' } },
  }), authRoutes(readGoogleAuthConfig()));

  app.use('/api', rateLimit({
    windowMs: 60000, limit: config.RATE_LIMIT_MAX,
    standardHeaders: 'draft-8', legacyHeaders: false,
    message: { error: { code: 'RATE_LIMITED', message: 'Espera un minuto antes de continuar.' } },
  }));
  app.use('/api', chatRoutes(ai));
  app.use('/api', currencyRoutes());
  app.use((_req, res) => res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Ruta no encontrada.' } }));
  app.use(errorHandler);
  return app;
}
