import 'dotenv/config';
import { z } from 'zod';

const schema = z.object({
  GOOGLE_CLIENT_ID: z.string().trim().default(''),
  GOOGLE_CLIENT_SECRET: z.string().trim().default(''),
  GOOGLE_REDIRECT_URI: z.string().trim().default(''),
  MOBILE_AUTH_REDIRECT_URI: z.string().trim().default('cora://auth/callback'),
  AUTH_SESSION_SECRET: z.string().trim().default(''),
});

export type GoogleAuthConfig = z.infer<typeof schema>;

export function readGoogleAuthConfig(): GoogleAuthConfig {
  const result = schema.safeParse(process.env);
  if (!result.success) {
    throw new Error('Configuración de Google OAuth inválida.');
  }
  return result.data;
}
