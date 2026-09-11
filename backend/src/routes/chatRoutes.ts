import { Router } from 'express';
import { chatController } from '../controllers/chatController.js';
import type { AIService } from '../services/ai/AIService.js';

export function chatRoutes(ai: AIService) {
  const router = Router();
  router.post('/chat', chatController(ai));
  return router;
}
