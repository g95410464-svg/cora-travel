# CORA · Fase 1

Flutter (Material 3) → Express/TypeScript → AIService → AIProvider → OpenRouter o NVIDIA NIM.

CORA es una app móvil. La ejecución web es una vista previa de desarrollo del mismo código Flutter. La configuración local actual usa NVIDIA NIM con `AI_PROVIDER=nvidia` y `AI_MODEL=deepseek-ai/deepseek-v4-pro-0813`; la clave permanece exclusivamente en `backend/.env`. `.env.example` conserva valores vacíos para no distribuir credenciales.

La app inicia con una bienvenida de cinco preguntas: nombre, país, idioma de conversación, presupuesto diario en USD e intereses. El perfil se guarda localmente, puede editarse o borrarse y se envía como contexto al chat. Al regresar se muestra «Mi viaje», con acceso a CORA, Market y Divisas. La interfaz sigue en español; el idioma elegido se usa en las respuestas de IA.

Market contiene seis experiencias de demostración con búsqueda, categorías, detalles y acceso a CORA para planear algo similar. Los precios son ilustrativos; no procesa pagos, contactos ni reservas reales.

Divisas convierte USD, GTQ, EUR, MXN, HNL, CRC, CAD y GBP mediante `POST /api/currency/convert` (`amount`, `from`, `to`). El backend consulta ExchangeRate-API, mantiene una caché de una hora, muestra la fecha de la tasa y devuelve un error seguro si no obtiene datos válidos. Las tasas se actualizan diariamente y no incluyen comisiones. [Fuente y documentación](https://www.exchangerate-api.com/docs/free).

Sin base de datos de servidor, autenticación, historial de conversación persistente, itinerarios ni traductor todavía. `userId` es un identificador local, no una credencial. No se registran mensajes.

## Backend

Requiere Node.js 22 o posterior. Desde la raíz, en PowerShell:

```powershell
cd backend
npm.cmd ci
Copy-Item .env.example .env
# Editar .env y completar clave y modelo antes de usar el chat.
npm.cmd run dev
```

Variables:

| Variable | Valor |
|---|---|
| `AI_PROVIDER` | `openrouter` (inicial) o `nvidia` |
| `AI_MODEL` | Identificador de un modelo disponible en el proveedor seleccionado |
| `OPENROUTER_API_KEY` | Tu clave de OpenRouter |
| `NVIDIA_NIM_API_KEY` | Solo necesaria al seleccionar NVIDIA |
| `PORT` | `3000` |
| `AI_TIMEOUT_MS` | `20000` (máximo `60000`) |
| `RATE_LIMIT_MAX` | `30` solicitudes por IP por minuto |

No hay modelo predeterminado. Sin clave o modelo, el servidor arranca pero el chat responde `503 AI_NOT_CONFIGURED`. `.env` se excluye de Git. No copies credenciales al cliente Flutter.

```powershell
npm.cmd run build
npm.cmd test
npm.cmd run test:smoke
npm.cmd start
```

`GET /health` devuelve `{"status":"ok"}`; comprueba el proceso, no la disponibilidad del proveedor.

```powershell
Invoke-RestMethod http://localhost:3000/api/chat -Method Post -ContentType 'application/json' -Body '{"message":"Hola CORA","userId":"demo","context":{}}'
```

Respuesta: `{"reply":"..."}`. `message`: 1–4000 caracteres. `userId`: 1–128 caracteres alfanuméricos, guion o guion bajo. `context`: hasta 20 valores planos string/number/boolean; no enviar datos sensibles. Errores: `{ "error": { "code": "...", "message": "..." } }` con estado 400/413/429/502/503/504/500. Límite JSON: 16 KB.

El límite usa memoria local y no presupone un proxy confiable. Esta fase es para desarrollo: antes de exponerla públicamente se necesitará autenticación y configurar el despliegue/proxy y límites compartidos según corresponda.

## Flutter

### APK de prueba por USB

Con Android SDK 36, Build-Tools 36.0.0 y NDK 28.2.13676358 instalados, ejecuta desde la raíz:

```powershell
.\scripts\build-apk-usb.ps1
```

Este comando genera `mobile/build/app/outputs/flutter-apk/app-debug.apk` con la URL local correcta. En un teléfono con depuración USB autorizada, mantén el backend encendido y ejecuta:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:3000 tcp:3000
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r ".\mobile\build\app\outputs\flutter-apk\app-debug.apk"
```

El USB conecta la app con el backend del equipo; para usarla fuera de esa conexión hace falta un backend HTTPS alojado. Si sdkmanager 23 falla al instalar el NDK, Android CLI permite instalarlo directamente con `android sdk install ndk/28.2.13676358`, indicando la ruta del SDK con `--sdk`. También puede instalarse esa versión desde SDK Manager → SDK Tools → Show Package Details → NDK (Side by side).

Para ver CORA en el navegador, inicia el backend y abre otra terminal:

```powershell
cd "C:\Users\Administrator\Desktop\cora ia\mobile"
..\scripts\flutter.ps1 run -d web-server --web-hostname=localhost --web-port=8080 --dart-define=API_BASE_URL=http://localhost:3000
```

Abre http://localhost:8080. El backend admite ese origen local. El script usa la herramienta oficial directamente y omite la comprobación de actualizaciones que demoraba el inicializador Windows. Con otro SDK puedes sustituir el script por `flutter`.

El SDK local se guarda en `.tools/flutter` y no forma parte del código de la app. También puedes usar un SDK propio en el PATH. Android requiere Android SDK, Java y un emulador o dispositivo, según `flutter doctor`.

El script prepara las dependencias de las herramientas en `.tools/pub-cache` para evitar depender de la caché de otra terminal. Si aparecen errores de dependencias dentro de `flutter_tools`, ejecuta desde la raíz `./scripts/flutter.ps1 --repair-tool doctor -v`. Esto restaura las dependencias de la herramienta; no borra el proyecto ni el perfil del viajero.

Desde la raíz:

```powershell
.\scripts\flutter.ps1 doctor
cd mobile
..\scripts\flutter.ps1 pub get
..\scripts\flutter.ps1 analyze
..\scripts\flutter.ps1 test
..\scripts\flutter.ps1 run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

`10.0.2.2` conecta el emulador Android con el host. En un teléfono físico usa la IP LAN del equipo, con ambos dispositivos en la misma red. HTTP se habilita solo para desarrollo Android; para release usa un backend HTTPS. El cliente solo conoce la URL del backend.

Referencias de integración: [OpenRouter](https://openrouter.ai/docs/quickstart), [NVIDIA NIM](https://docs.api.nvidia.com/nim/re/reference/llm-apis), [configuración Android/Flutter](https://docs.flutter.dev/platform-integration/android/setup).
