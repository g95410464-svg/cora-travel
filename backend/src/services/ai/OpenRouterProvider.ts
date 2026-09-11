import type { Config } from '../../config/env.js';
import { ChatCompletionProvider } from './ChatCompletionProvider.js';

export class OpenRouterProvider extends ChatCompletionProvider {
  constructor(config: Config, transport: typeof fetch = fetch) {
    super('https://openrouter.ai/api/v1/chat/completions', config.OPENROUTER_API_KEY,
      config.AI_MODEL, config.AI_TIMEOUT_MS, transport);
  }
}
