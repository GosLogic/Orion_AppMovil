@echo off
REM Orion Driver - arranque con tunel USB (evita error "Sin conexion al servidor")
REM Uso: scripts\run_dev.cmd

set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
if not exist "%ADB%" (
  echo ERROR: No se encontro adb en %ADB%
  echo Instala Android SDK Platform-Tools.
  exit /b 1
)

echo === Verificando celular USB ===
"%ADB%" devices
echo.

echo === Configurando tunel (adb reverse) ===
"%ADB%" reverse tcp:8080 tcp:8080
"%ADB%" reverse tcp:8086 tcp:8086
"%ADB%" reverse --list
echo.

echo === Verificando Docker Gateway ===
curl -s -o NUL -w "Gateway HTTP %%{http_code}\n" --connect-timeout 3 http://127.0.0.1:8080/v1/auth/driver/login
echo Si no ves 401/405/200, inicia Docker: docker compose up -d
echo.

echo === Iniciando Flutter ===
cd /d "%~dp0.."
flutter run %*
