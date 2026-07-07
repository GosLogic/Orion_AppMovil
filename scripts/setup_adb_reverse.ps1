# Configura adb reverse para Orion (celular fisico + USB).
# Uso: .\scripts\setup_adb_reverse.ps1

$adbCandidates = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe"
)

$adb = $adbCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $adb) {
    Write-Error "No se encontro adb.exe. Instala Android SDK Platform-Tools o agrega adb al PATH."
}

Write-Host "adb: $adb" -ForegroundColor Cyan
& $adb devices

$devices = (& $adb devices | Select-String "device$" | Where-Object { $_ -notmatch "List of devices" })
if ($devices.Count -eq 0) {
    Write-Error "No hay celular conectado. Activa Depuracion USB y acepta la autorizacion en el telefono."
}

& $adb reverse tcp:8080 tcp:8080
& $adb reverse tcp:8086 tcp:8086
Write-Host ""
Write-Host "Tuneles activos:" -ForegroundColor Green
& $adb reverse --list
Write-Host ""
Write-Host "Listo. Ejecuta: flutter run" -ForegroundColor Green
