import { z } from 'zod';
import { AppError } from '../middleware/errors.js';

const schema = z.object({ result: z.literal('success'), base_code: z.literal('USD'),
  time_last_update_unix: z.number().positive(), time_next_update_unix: z.number().positive(),
  rates: z.record(z.string(), z.number().positive().finite()),
});
type Rates = z.infer<typeof schema>;
export const currencyCodes = ['USD', 'GTQ', 'EUR', 'MXN', 'HNL', 'CRC', 'CAD', 'GBP'] as const;

export class CurrencyService {
  private cached?: { data: Rates; expires: number };
  private pending?: Promise<Rates>;
  constructor(private transport: typeof fetch = fetch) {}

  private async rates(): Promise<Rates> {
    if (this.cached && this.cached.expires > Date.now()) return this.cached.data;
    if (this.pending) return this.pending;
    this.pending = (async () => {
      try {
        const res = await this.transport('https://open.er-api.com/v6/latest/USD', { signal: AbortSignal.timeout(10000) });
        if (!res.ok) throw new Error('Currency provider failed');
        const data = schema.parse(await res.json());
        if (Date.now() - data.time_last_update_unix * 1000 > 72 * 3600000 ||
            data.time_last_update_unix * 1000 > Date.now() + 3600000) throw new Error('Invalid rate timestamp');
        this.cached = { data, expires: Date.now() + 3600000 };
        return data;
      } catch { throw new AppError(503, 'RATES_UNAVAILABLE', 'No pudimos consultar las tasas. Intenta más tarde.'); }
    })();
    try { return await this.pending; } finally { this.pending = undefined; }
  }

  async convert(amount: number, from: string, to: string) {
    const data = await this.rates();
    if (!data.rates[from] || !data.rates[to]) throw new AppError(503, 'RATE_MISSING', 'No hay tasa disponible para esta moneda.');
    const rate = data.rates[to] / data.rates[from];
    return { amount, from, to, result: Math.round(amount * rate * 100) / 100, rate,
      updatedAt: new Date(data.time_last_update_unix * 1000).toISOString(),
      source: 'ExchangeRate-API', sourceUrl: 'https://www.exchangerate-api.com' };
  }
}
