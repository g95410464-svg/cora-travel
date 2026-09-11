import 'dotenv/config';
import { z } from 'zod';

const schema = z.object({
  AI_PROVIDER: z.enum(['openrouter', 'nvidia']).default('openrouter'),
  AI_MODEL: z.string().trim().default(''),
  OPENROUTER_API_KEY: z.string().trim().default(''),
  NVIDIA_NIM_API_KEY: z.string().trim().default(''),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  AI_TIMEOUT_MS: z.coerce.number().int().min(100).max(60000).default(20000),
  RATE_LIMIT_MAX: z.coerce.number().int().positive().default(30),
});

export type Config = z.infer<typeof schema>;
export function readConfig(): Config {
  const result = schema.safeParse(process.env);
  if (!result.success) throw new Error('Configuración de entorno inválida. Revisa .env.example.');
  return result.data;
}
