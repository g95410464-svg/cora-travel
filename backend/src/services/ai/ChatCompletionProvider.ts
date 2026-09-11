import { z } from 'zod';
import { AppError } from '../../middleware/errors.js';
import type { AIMessage, AIProvider } from './AIProvider.js';

const responseSchema = z.object({
  choices: z.array(z.object({ message: z.object({ content: z.string().trim().min(1) }) })).min(1),
});

export class ChatCompletionProvider implements AIProvider {
  constructor(
    private endpoint: string,
    private apiKey: string,
    private model: string,
    private timeoutMs: number,
    private transport: typeof fetch = fetch,
  ) {}

  async complete(messages: AIMessage[]): Promise<string> {
    if (!this.apiKey || !this.model) {
      throw new AppError(503, 'AI_NOT_CONFIGURED', 'CORA necesita configurar su proveedor de IA.');
    }
    const signal = AbortSignal.timeout(this.timeoutMs);
    try {
      const response = await this.transport(this.endpoint, {
        method: 'POST',
        headers: { Authorization: `Bearer ${this.apiKey}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ model: this.model, messages, stream: false, max_tokens: 800 }),
        signal,
      });
      if (!response.ok) throw new Error('Provider failed');
      const result = responseSchema.safeParse(await response.json());
      if (!result.success) throw new Error('Invalid provider response');
      return result.data.choices[0].message.content;
    } catch {
      throw new AppError(signal.aborted ? 504 : 502,
        signal.aborted ? 'AI_TIMEOUT' : 'AI_UNAVAILABLE',
        signal.aborted ? 'La respuesta tardó demasiado. Intenta de nuevo.' : 'La IA no está disponible. Intenta de nuevo.');
    }
  }
}
