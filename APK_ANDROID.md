# APK Android de prueba

El APK debug se compiló correctamente y ADB confirmó su instalación (`Success`) en el teléfono conectado durante esta sesión.

- Archivo: `mobile/build/app/outputs/flutter-apk/app-debug.apk`.
- Aplicación: `sv.cora.cora`.
- Backend incluido en la configuración pública del APK: `http://127.0.0.1:3000`, accesible desde el teléfono mediante `adb reverse tcp:3000 tcp:3000`.
- Las claves de IA permanecen exclusivamente en el backend.
- Esta entrega verifica compilación e instalación; la interacción completa en el teléfono queda por probar al abrir CORA.

## Repetir la compilación

Desde la raíz del proyecto:

```powershell
.\scripts\build-apk-usb.ps1
```

El script resuelve dependencias con la caché local, fija la URL correcta y aplica solo durante el comando una carpeta temporal para los sockets de Java 25. Restaura `JAVA_TOOL_OPTIONS` al terminar.

## Reparaciones aplicadas

- Instalado el NDK 28.2.13676358 mediante Android CLI directamente (`sdk install ndk/28.2.13676358`); el lanzador de compatibilidad sdkmanager separaba el nombre del paquete y fallaba. El instalador terminó con código 1 sin explicación después de extraerlo, pero se verificaron versión, compilador y metadatos; la compilación posterior lo utilizó correctamente.
- Reparadas las rutas de los plugins con `pub get` en la caché local de CORA.
- Corregido `.tools/flutter/bin/internal/shared.bat` local: invocación de Git y ruta con espacios; desactivada la comprobación de actualizaciones durante la generación del snapshot. Gradle necesita ese inicializador aunque se use el wrapper PowerShell. Esta corrección vive en el SDK local ignorado por Git y puede perderse al reemplazar/actualizar dicho SDK.
- Resuelto `Unable to establish loopback connection` con una carpeta temporal local para `jdk.net.unixdomain.tmpdir`.

Persisten advertencias de herramientas Java/Gradle y del formato XML del SDK; no impidieron generar el APK. No se trata todavía de una publicación firmada para Play Store ni de una app conectada a un backend público: para probar chat y divisas hay que mantener el equipo encendido y el USB conectado.
