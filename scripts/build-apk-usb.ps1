# Debug APK for a phone connected using adb reverse tcp:3000 tcp:3000.
$ErrorActionPreference = 'Stop'
$coraRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$coraJavaTemp = Join-Path $coraRoot '.tools/java-tmp'
New-Item -ItemType Directory -Force -Path $coraJavaTemp | Out-Null
$coraPreviousJavaOptions = $env:JAVA_TOOL_OPTIONS
# Java 25 needs a usable local directory for its Windows loopback sockets.
$env:JAVA_TOOL_OPTIONS = ($coraPreviousJavaOptions + ' -Djdk.net.unixdomain.tmpdir="' + $coraJavaTemp + '"').Trim()
Push-Location (Join-Path $coraRoot 'mobile')
try {
    & (Join-Path $PSScriptRoot 'flutter.ps1') pub get
    if ($LASTEXITCODE -ne 0) { throw 'No se pudieron preparar las dependencias de la app.' }
    & (Join-Path $PSScriptRoot 'flutter.ps1') build apk --debug '--dart-define=API_BASE_URL=http://127.0.0.1:3000'
    if ($LASTEXITCODE -ne 0) { throw 'La compilacion del APK fallo. Revisa el error anterior.' }
    $coraApk = Join-Path (Get-Location) 'build/app/outputs/flutter-apk/app-debug.apk'
    if (!(Test-Path -LiteralPath $coraApk)) { throw 'Flutter no genero el APK en la ubicacion esperada.' }
    Write-Host "APK generado: $coraApk"
} finally {
    Pop-Location
    $env:JAVA_TOOL_OPTIONS = $coraPreviousJavaOptions
}
