# CORA · Asistente turístico inteligente para El Salvador

<p align="center">
  <strong>Tu viaje empieza con una conversación.</strong><br>
  Recomendaciones locales, planificación y herramientas de viaje en una sola app móvil.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white">
  <img alt="Node.js" src="https://img.shields.io/badge/Node.js-22%2B-339933?logo=node.js&logoColor=white">
  <img alt="TypeScript" src="https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript&logoColor=white">
  <img alt="AI providers" src="https://img.shields.io/badge/AI-OpenRouter%20%7C%20NVIDIA%20NIM-76B900">
</p>

## Qué es CORA

CORA es una aplicación móvil de turismo con inteligencia artificial creada para ayudar a descubrir y disfrutar El Salvador. La persona responde unas preguntas al entrar, obtiene un perfil inicial y luego puede conversar con CORA para encontrar actividades, playas, surf, gastronomía, cultura y naturaleza que encajen con su presupuesto y estilo.

La experiencia está pensada para viajeros reales: incluye un asistente con tono cercano, un Market de experiencias turísticas y un conversor de divisas. El backend mantiene aisladas las credenciales de IA y permite cambiar de proveedor sin modificar la aplicación móvil.

El proyecto y la marca CORA son propiedad de **g95410464-svg**. Todos los derechos sobre el código, diseño y contenidos originales quedan reservados, salvo las dependencias de terceros indicadas por sus respectivas licencias.

## Funciones actuales

- Onboarding con nombre, país, idioma, presupuesto e intereses.
- Perfil de viajero guardado localmente y editable.
- Asistente CORA conectado al backend mediante `POST /api/chat`.
- Market con experiencias salvadoreñas, búsqueda y categorías.
- Conversor de divisas mediante `POST /api/currency/convert`.
- Proveedores de IA intercambiables: OpenRouter y NVIDIA NIM.
- Límites de solicitudes, validación de entrada, timeout y errores seguros.

El roadmap contempla itinerarios estructurados, traductor cultural de modismos salvadoreños, recomendaciones patrocinadas relevantes, autenticación e historial opcional.

## Arquitectura

```text
Flutter / Android / iOS
          │ HTTPS
          ▼
Express + TypeScript (API)
          ▼
AIService → AIProvider
             ├─ OpenRouterProvider
             └─ NvidiaNimProvider
```

La app nunca contiene claves de OpenRouter ni NVIDIA NIM. Solo conoce la URL pública del backend.

## Requisitos para instalar

- Node.js 22 o posterior y npm.
- Flutter estable, Android Studio y Android SDK para compilar Android.
- Una clave de OpenRouter o NVIDIA NIM.
- PostgreSQL cuando se habilite persistencia; el MVP actual funciona con repositorios locales/mock.

## Configuración del backend

```powershell
cd backend
npm.cmd ci
Copy-Item .env.example .env
```

Edita `backend/.env` (este archivo está excluido de Git):

```env
PORT=3000
AI_PROVIDER=nvidia
AI_MODEL=deepseek-ai/deepseek-v4-pro-0813
NVIDIA_NIM_API_KEY=tu_clave_nvidia
OPENROUTER_API_KEY=
AI_TIMEOUT_MS=20000
RATE_LIMIT_MAX=30
```

Para usar OpenRouter cambia `AI_PROVIDER=openrouter`, rellena `OPENROUTER_API_KEY` y usa el identificador del modelo elegido en `AI_MODEL`. Nunca pegues claves en Flutter, commits, capturas ni tickets.

Arranque de desarrollo y verificación:

```powershell
npm.cmd run dev
# En otra terminal:
npm.cmd run build
npm.cmd test
npm.cmd run test:smoke
```

La API queda en `http://localhost:3000`. Comprueba `http://localhost:3000/health` o prueba el chat:

```powershell
Invoke-RestMethod http://localhost:3000/api/chat -Method Post -ContentType 'application/json' -Body '{"message":"Quiero comer pupusas","userId":"demo","context":{}}'
```

## Configuración de la app móvil

```powershell
cd mobile
..\scripts\flutter.ps1 pub get
..\scripts\flutter.ps1 run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

`10.0.2.2` apunta al equipo host desde un emulador Android. En un teléfono físico usa la IP local del equipo y mantén ambos dispositivos en la misma red. Para compilar un APK:

```powershell
..\scripts\flutter.ps1 build apk --release --dart-define=API_BASE_URL=https://api.tudominio.com
```

El APK se genera en `mobile/build/app/outputs/flutter-apk/app-release.apk`.

## Despliegue real

### Backend

En un servidor Linux, VPS o plataforma como Render, Railway o Fly.io:

```bash
cd backend
npm ci
npm run build
npm start
```

Configura las variables de entorno del panel de la plataforma, expón el puerto asignado por `PORT` y apunta un dominio HTTPS mediante el proxy de la plataforma (o Nginx + Let's Encrypt). No subas `.env` al servidor mediante Git; usa los secretos administrados por la plataforma.

Antes de abrir la API a internet, configura autenticación, un rate limit compartido, logs sin mensajes personales y PostgreSQL para perfiles persistentes. El endpoint `/health` sirve para el health check del proveedor.

### Android

Para una versión firmada crea un keystore de producción, configura `key.properties` fuera de Git y añade la firma release en `mobile/android/app/build.gradle.kts`. Después:

```powershell
cd mobile
..\scripts\flutter.ps1 build appbundle --release --dart-define=API_BASE_URL=https://api.tudominio.com
```

El archivo `app-release.aab` se sube a Google Play Console. Para distribución directa puedes generar un APK firmado; el `debug.apk` es solo para desarrollo. iOS requiere macOS y certificados de Apple.

## Estructura del repositorio

```text
backend/    API Express, servicios de IA, validación y pruebas
mobile/     Aplicación Flutter Material 3
scripts/    Atajos reproducibles para Flutter y APK
```

## Variables de entorno

| Variable | Uso |
|---|---|
| `AI_PROVIDER` | `openrouter` o `nvidia` |
| `AI_MODEL` | Modelo elegido en el proveedor |
| `OPENROUTER_API_KEY` | Clave privada de OpenRouter |
| `NVIDIA_NIM_API_KEY` | Clave privada de NVIDIA NIM |
| `PORT` | Puerto HTTP del backend |
| `AI_TIMEOUT_MS` | Timeout de llamadas de IA |
| `RATE_LIMIT_MAX` | Solicitudes por IP y minuto |

## Propiedad y contacto

© 2026 **g95410464-svg · CORA**. Proyecto privado de hackathon y producto en desarrollo. Para colaboraciones o licencias, contacta al propietario del repositorio: [github.com/g95410464-svg](https://github.com/g95410464-svg).

Las marcas Flutter, Node.js, OpenRouter, NVIDIA y las demás referencias pertenecen a sus respectivos propietarios.

