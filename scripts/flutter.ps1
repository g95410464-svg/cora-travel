# Keep Flutter tool dependencies in the project, independent of the shell's Pub cache.
$ErrorActionPreference = 'Stop'
$coraSdk = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../.tools/flutter'))
$coraDart = Join-Path $coraSdk 'bin/cache/dart-sdk/bin/dart.exe'
$coraPackages = Join-Path $coraSdk 'packages/flutter_tools/.dart_tool/package_config.json'
$coraTool = Join-Path $coraSdk 'packages/flutter_tools/bin/flutter_tools.dart'
$coraCache = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../.tools/pub-cache'))
$coraArguments = @($args | Where-Object { $_ -ne '--repair-tool' })
if (!(Test-Path -LiteralPath $coraDart)) {
    throw 'SDK local no disponible. Instala Flutter y usa flutter desde el PATH.'
}
$coraNeedsRepair = ($args -contains '--repair-tool') -or !(Test-Path -LiteralPath $coraPackages)
if (!$coraNeedsRepair) {
    try {
        $coraConfig = Get-Content -Raw -LiteralPath $coraPackages | ConvertFrom-Json
        $coraConfigUri = [Uri]::new($coraPackages)
        foreach ($coraPackage in $coraConfig.packages) {
            $coraPackageUri = [Uri]::new($coraConfigUri, [string]$coraPackage.rootUri)
            if ($coraPackageUri.IsFile) {
                $coraRoot = $coraPackageUri.LocalPath
                if (!(Test-Path -LiteralPath $coraRoot) -or
                    ($coraPackage.rootUri -match '/hosted/' -and !$coraRoot.StartsWith($coraCache, [StringComparison]::OrdinalIgnoreCase))) {
                    $coraNeedsRepair = $true
                    break
                }
            }
        }
    } catch { $coraNeedsRepair = $true }
}
$coraPreviousCache = $env:PUB_CACHE
try {
    $env:PUB_CACHE = $coraCache
    if ($coraNeedsRepair) {
        Write-Host 'Preparando dependencias de las herramientas Flutter...'
        Push-Location (Join-Path $coraSdk 'packages/flutter_tools')
        try {
            & $coraDart pub get
            if ($LASTEXITCODE -ne 0) { throw 'No se pudieron descargar las dependencias de Flutter. Revisa la conexion e intenta de nuevo.' }
        } finally { Pop-Location }
    }
    & $coraDart "--packages=$coraPackages" $coraTool --no-version-check @coraArguments
    $coraExitCode = $LASTEXITCODE
} finally { $env:PUB_CACHE = $coraPreviousCache }
exit $coraExitCode
