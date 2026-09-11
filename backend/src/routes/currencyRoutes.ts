import { Router } from 'express';
import { z } from 'zod';
import { CurrencyService, currencyCodes } from '../services/CurrencyService.js';
import { AppError } from '../middleware/errors.js';

export function currencyRoutes(service = new CurrencyService()) {
  const router = Router();
  const input = z.object({ amount: z.number().finite().min(0).max(100000000),
    from: z.enum(currencyCodes), to: z.enum(currencyCodes) }).strict();
  router.post('/currency/convert', async (req, res) => {
    const parsed = input.safeParse(req.body);
    if (!parsed.success) throw new AppError(400, 'INVALID_CONVERSION', 'Revisa el monto y las monedas.');
    const {amount, from, to} = parsed.data;
    res.json(await service.convert(amount, from, to));
  });
  return router;
}
