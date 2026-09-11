# Bienvenida, market y divisas

- CORA pregunta nombre, país, idioma de conversación, presupuesto diario en USD e intereses, un paso a la vez.
- El perfil se guarda en el dispositivo y puede editarse o borrarse. Al volver, se abre «Mi viaje». El chat recibe ese perfil como contexto a través del backend; las claves siguen exclusivamente en `.env`.
- Inicio móvil con acceso a chat, market y convertidor. El chat conserva el botón para regresar al inicio.
- Market: seis experiencias demo, búsqueda, categorías, detalles y borrador de consulta para CORA. No hay pagos, reservas ni negocios reales contratados.
- Divisas: USD, GTQ, EUR, MXN, HNL, CRC, CAD y GBP; fecha de tasa visible y errores controlados. Datos diarios de ExchangeRate-API, caché de una hora en backend, sin usar IA para calcular.

## Verificación

- Backend: `npm.cmd run build` correcto; `npm.cmd test`: 11 pruebas aprobadas.
- Flutter: análisis sin problemas; 2 pruebas aprobadas de bienvenida, persistencia, filtros y validación de montos.
- `flutter build web --dart-define=API_BASE_URL=http://localhost:3000`: correcto. Continúa la advertencia no bloqueante de la fuente opcional CupertinoIcons; la app utiliza Material Icons.
- Revisión visual a 390 × 844: bienvenida, inicio, market, detalles y conversión real desde la interfaz correctos.
- Android no se compiló ni se probó en un dispositivo. La vista web es solo una forma de revisar el mismo proyecto Flutter localmente.

## Archivos principales

Nuevos: `mobile/lib/models/traveler_profile.dart`, `mobile/lib/repositories/profile_repository.dart`, `mobile/lib/features/onboarding/onboarding_screen.dart`, `mobile/lib/features/assistant/assistant_screen.dart`, `mobile/lib/features/market/market_screen.dart`, `mobile/lib/features/currency/currency_screen.dart`, `backend/src/services/CurrencyService.ts`, `backend/src/routes/currencyRoutes.ts`, `backend/tests/currency.test.ts` y este reporte.

Actualizados: `mobile/lib/main.dart`, `mobile/lib/services/chat_api.dart`, `mobile/pubspec.yaml`, `mobile/pubspec.lock`, `mobile/test/widget_test.dart`, `backend/src/app.ts` y `README.md`. Se regeneraron los metadatos locales de plugins Flutter al resolver dependencias.

La interfaz permanece en español. El idioma elegido indica a CORA cómo responder; todavía no hay traducción completa de los menús.

Ejecución: seguir los comandos del README. Vista previa: http://localhost:8080; backend: http://localhost:3000.
