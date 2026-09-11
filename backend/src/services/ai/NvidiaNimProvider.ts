import type { Config } from '../../config/env.js';
import { ChatCompletionProvider } from './ChatCompletionProvider.js';

export class NvidiaNimProvider extends ChatCompletionProvider {
  constructor(config: Config, transport: typeof fetch = fetch) {
    super('https://integrate.api.nvidia.com/v1/chat/completions', config.NVIDIA_NIM_API_KEY,
      config.AI_MODEL, config.AI_TIMEOUT_MS, transport);
  }
}
