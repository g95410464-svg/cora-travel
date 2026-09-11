import { createApp } from './app.js';
import { readConfig } from './config/env.js';
import { createServer } from 'node:http';

const config = readConfig();
const server = createServer(createApp(config));
server.listen(config.PORT, '0.0.0.0', () => {
  console.log(`CORA API disponible en puerto ${config.PORT}`);
  const key = config.AI_PROVIDER === 'openrouter' ? config.OPENROUTER_API_KEY : config.NVIDIA_NIM_API_KEY;
  if (!key || !config.AI_MODEL) console.warn('IA sin configurar: completa la API key y AI_MODEL en .env.');
});
server.on('error', (error: NodeJS.ErrnoException) => {
  console.error(error.code === 'EADDRINUSE'
    ? `El puerto ${config.PORT} ya está ocupado. Si CORA está activa, usa esa instancia; de lo contrario configura otro PORT.`
    : 'No se pudo iniciar CORA API. Revisa el puerto y la configuración.');
  process.exitCode = 1;
});
for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(signal, () => server.close());
}
