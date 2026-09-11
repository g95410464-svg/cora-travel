import express from 'express';
import helmet from 'helmet';
import { rateLimit } from 'express-rate-limit';
import type { Config } from './config/env.js';
import { errorHandler } from './middleware/errors.js';
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
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
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
    endpoints: ['/api/chat', '/api/currency/convert'],
  }));
  app.get('/health', (_req, res) => res.json({ status: 'ok' }));
  app.use('/api', rateLimit({
    windowMs: 60000, limit: config.RATE_LIMIT_MAX,
    standardHeaders: 'draft-8', legacyHeaders: false,
    message: { error: { code: 'RATE_LIMITED', message: 'Espera un minuto antes de continuar.' } },
  }));
  app.use(express.json({ limit: '16kb' }));
  app.use('/api', chatRoutes(ai));
  app.use('/api', currencyRoutes());
  app.use((_req, res) => res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Ruta no encontrada.' } }));
  app.use(errorHandler);
  return app;
}
