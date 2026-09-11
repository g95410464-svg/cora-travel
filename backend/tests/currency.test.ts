import { test } from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import request from 'supertest';
import { CurrencyService } from '../src/services/CurrencyService.js';
import { currencyRoutes } from '../src/routes/currencyRoutes.js';
import { errorHandler } from '../src/middleware/errors.js';

function service(counter = { calls: 0 }) {
  return new CurrencyService(async () => {
    counter.calls++;
    return Response.json({ result: 'success', base_code: 'USD', time_last_update_unix: Date.now()/1000,
      time_next_update_unix: Date.now()/1000 + 86400, rates: { USD: 1, GTQ: 7.5, EUR: .9 } });
  });
}
test('cross conversion, zero and same currency use one cached upstream request', async () => {
  const count = { calls: 0 }; const rates = service(count);
  const results = await Promise.all([rates.convert(75, 'GTQ', 'USD'), rates.convert(10, 'USD', 'EUR')]);
  assert.equal(results[0].result, 10); assert.equal(results[1].result, 9);
  assert.equal((await rates.convert(0, 'USD', 'GTQ')).result, 0);
  assert.equal((await rates.convert(12.34, 'USD', 'USD')).result, 12.34);
  assert.equal(count.calls, 1);
});
test('conversion API rejects negative amounts and unsupported currencies', async () => {
  const app = express(); app.use(express.json()); app.use(currencyRoutes(service())); app.use(errorHandler);
  await request(app).post('/currency/convert').send({ amount: -1, from:'USD', to:'GTQ' }).expect(400);
  await request(app).post('/currency/convert').send({ amount: 1, from:'BTC', to:'GTQ' }).expect(400);
  await request(app).post('/currency/convert').send({ amount: 100, from:'USD', to:'GTQ' }).expect(200).expect(r => assert.equal(r.body.result, 750));
});
test('upstream failure and stale rates produce safe errors', async () => {
  const failing = new CurrencyService(async () => { throw new Error('private error'); });
  await assert.rejects(failing.convert(1, 'USD', 'GTQ'), { code:'RATES_UNAVAILABLE', status:503 });
  const stale = new CurrencyService(async () => Response.json({ result:'success', base_code:'USD',
    time_last_update_unix:1, time_next_update_unix:2, rates:{USD:1, GTQ:7.5} }));
  await assert.rejects(stale.convert(1, 'USD', 'GTQ'), { code:'RATES_UNAVAILABLE' });
});
