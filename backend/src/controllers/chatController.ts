import type { RequestHandler } from 'express';
import { z } from 'zod';
import { AppError } from '../middleware/errors.js';
import type { AIService } from '../services/ai/AIService.js';

const chatSchema = z.object({
  message: z.string().trim().min(1).max(4000),
  userId: z.string().trim().min(1).max(128).regex(/^[a-zA-Z0-9_-]+$/),
  context: z.record(z.string().max(64), z.union([
    z.string().max(1000), z.number().finite(), z.boolean(),
  ])).refine(value => Object.keys(value).length <= 20).default({}),
}).strict();

export function chatController(ai: AIService): RequestHandler {
  return async (req, res) => {
    const input = chatSchema.safeParse(req.body);
    if (!input.success) throw new AppError(400, 'INVALID_INPUT', 'Revisa message, userId y context.');
    const reply = await ai.chat(input.data.message, input.data.context);
    res.json({ reply });
  };
}
