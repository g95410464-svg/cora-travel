# CORA · Reporte de fase 1

Actualización posterior: se configuró NVIDIA NIM con el modelo `deepseek-ai/deepseek-v4-pro-0813` solicitado por el usuario. La prueba real a través de `POST /api/chat` devolvió HTTP 200 y una respuesta de CORA. Se amplió el timeout local a 60 segundos. Solo se modificaron `backend/.env` y la documentación; la clave no está incluida en este reporte. Las observaciones de credenciales pendientes que siguen describen el cierre inicial de fase 1 y quedan resueltas con esta prueba.

Workspace inicial vacío. No había proyecto ni archivos preexistentes que modificar. Node 24.15.0 y npm 11.12.1 disponibles. Se descargó Flutter 3.47.3 / Dart 3.13.3 en `.tools/flutter` (herramientas locales, excluidas de Git).

## Arquitectura

Flutter Material 3 → ChatApi → POST /api/chat → controlador validado con Zod → AIService → AIProvider → OpenRouterProvider / NvidiaNimProvider. Transporte HTTP compartido con timeout y validación de respuesta. El modelo y las claves solo se leen en el backend.

Se añadió Android y una vista web de la misma app para visualizarla localmente sin emulador. CORS permite exclusivamente el origen de vista previa `http://localhost:8080`. No hay persistencia, autenticación ni historial del lado servidor; `userId` es temporal. Las siguientes fases no están implementadas.

## Verificación

- `npm.cmd install --fetch-timeout=20000 --fetch-retries=0`: 112 paquetes; auditoría: 0 vulnerabilidades.
- `npm.cmd run build`: correcto, TypeScript estricto.
- `npm.cmd test`: 8/8 pruebas aprobadas (contrato, validación, CORS, rate limiting, credenciales ausentes, errores, adaptadores y timeout).
- `npm.cmd run test:smoke`: servidor compilado arranca; GET /health 200; POST /api/chat sin configuración 503.
- Flutter `analyze`: sin problemas.
- Flutter `test`: 1/1 prueba de interfaz aprobada.
- Flutter `build web --dart-define=API_BASE_URL=http://localhost:3000`: correcto. Advertencia sobre fuente opcional CupertinoIcons; la app usa Material Icons.
- No se probó una llamada real a OpenRouter/NVIDIA: falta configurar clave/modelo.
- No se compiló APK ni se ejecutó en un dispositivo Android; falta verificar/provisionar Android SDK, Java y emulador.

## Comandos de preparación ejecutados

Desde la raíz salvo indicación contraria:

```powershell
Get-Location
Get-ChildItem -Force
rg --files -g AGENTS.md -g pubspec.yaml -g package.json -g '*.sln' -g hosting.json -g README.md
Get-Command node,npm,flutter,dart -ErrorAction SilentlyContinue
node --version
npm.cmd --version
where.exe flutter
where.exe dart
git --version
git clone --depth 1 --branch stable https://github.com/flutter/flutter.git .tools/flutter
.\.tools\flutter\bin\flutter.bat --version
```

En backend se ejecutaron `npm.cmd install`, `npm.cmd ping --fetch-timeout=10000 --fetch-retries=0`, instalación con los límites indicados arriba, build, test, test:smoke y start. La instalación inicial fue cancelada tras diagnosticar EACCES al registro npm. Se reintentó con permisos concedidos. Las pruebas también necesitaron ejecución fuera del sandbox por `uv_os_get_passwd ENOMEM` de tsx. El servidor persistente requirió ejecución fuera del sandbox.

El inicializador de Flutter quedó esperando `git fetch --tags`. Se inspeccionaron procesos y scripts internos, se cancelaron los intentos detenidos y se ejecutó la herramienta oficial directamente con Dart y `--no-version-check`. Se intentó preparar la caché snapshot y su stamp; el inicializador volvió a reconstruirla, por lo que se dejó `scripts/flutter.ps1` como entrada local. No se modificó el código fuente del SDK.

```powershell
# Herramienta oficial directa usada para generar Android:
.\.tools\flutter\bin\cache\dart-sdk\bin\dart.exe --packages=.tools/flutter/packages/flutter_tools/.dart_tool/package_config.json .tools/flutter/packages/flutter_tools/bin/flutter_tools.dart --no-version-check create --platforms=android --project-name=cora --org=sv.cora mobile
.\.tools\flutter\bin\cache\dart-sdk\bin\dart.exe format mobile/lib mobile/test
# Desde mobile, usando el wrapper equivalente:
..\scripts\flutter.ps1 pub get
..\scripts\flutter.ps1 analyze
..\scripts\flutter.ps1 create --platforms=web --project-name=cora .
..\scripts\flutter.ps1 test
..\scripts\flutter.ps1 build web --dart-define=API_BASE_URL=http://localhost:3000
..\scripts\flutter.ps1 run -d web-server --web-hostname=localhost --web-port=8080 --dart-define=API_BASE_URL=http://localhost:3000
```

## Ejecución y configuración

Ver [README.md](README.md) para comandos de backend, web y Android. Rellenar `OPENROUTER_API_KEY` y `AI_MODEL` en `backend/.env`; conservar `AI_PROVIDER=openrouter`. Para NVIDIA: `AI_PROVIDER=nvidia`, `NVIDIA_NIM_API_KEY` y un `AI_MODEL` compatible. El servidor no necesita credenciales para iniciar y comprobar `/health`.

## Archivos

Todos los archivos de aplicación listados abajo fueron creados en esta fase. No se modificaron archivos preexistentes. `backend/.env` apareció durante la sesión y no fue escrito ni sobrescrito por el agente. Se excluyen de este inventario SDK, dependencias, builds, cachés y metadatos locales del IDE; permanecen ignorados por Git.

```text
.gitignore
backend\.env.example
backend\package-lock.json
backend\package.json
backend\src\app.ts
backend\src\config\env.ts
backend\src\controllers\chatController.ts
backend\src\middleware\errors.ts
backend\src\routes\chatRoutes.ts
backend\src\server.ts
backend\src\services\ai\AIProvider.ts
backend\src\services\ai\AIService.ts
backend\src\services\ai\ChatCompletionProvider.ts
backend\src\services\ai\NvidiaNimProvider.ts
backend\src\services\ai\OpenRouterProvider.ts
backend\tests\chat.test.ts
backend\tests\smoke.mjs
backend\tsconfig.json
mobile\.gitignore
mobile\.metadata
mobile\analysis_options.yaml
mobile\android\.gitignore
mobile\android\app\build.gradle.kts
mobile\android\app\src\debug\AndroidManifest.xml
mobile\android\app\src\main\AndroidManifest.xml
mobile\android\app\src\main\kotlin\sv\cora\cora\MainActivity.kt
mobile\android\app\src\main\res\drawable-v21\launch_background.xml
mobile\android\app\src\main\res\drawable\launch_background.xml
mobile\android\app\src\main\res\mipmap-hdpi\ic_launcher.png
mobile\android\app\src\main\res\mipmap-mdpi\ic_launcher.png
mobile\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png
mobile\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png
mobile\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png
mobile\android\app\src\main\res\values-night\styles.xml
mobile\android\app\src\main\res\values\styles.xml
mobile\android\app\src\profile\AndroidManifest.xml
mobile\android\build.gradle.kts
mobile\android\gradle.properties
mobile\android\gradle\wrapper\gradle-wrapper.jar
mobile\android\gradle\wrapper\gradle-wrapper.properties
mobile\android\gradlew
mobile\android\gradlew.bat
mobile\android\settings.gradle.kts
mobile\lib\core\config.dart
mobile\lib\main.dart
mobile\lib\services\chat_api.dart
mobile\pubspec.lock
mobile\pubspec.yaml
mobile\README.md
mobile\test\widget_test.dart
mobile\web\favicon.png
mobile\web\icons\Icon-192.png
mobile\web\icons\Icon-512.png
mobile\web\icons\Icon-maskable-192.png
mobile\web\icons\Icon-maskable-512.png
mobile\web\index.html
mobile\web\manifest.json
README.md
REPORTE_FASE1.md
scripts\flutter.ps1
```
