/// Configuración de red para desarrollo local.
class DevApiConfig {
  DevApiConfig._();

  /// IP LAN de tu PC en Wi‑Fi (ipconfig → IPv4). Usada en celular físico.
  /// Override: `--dart-define=ORION_DEV_HOST=192.168.1.11`
  static const String pcLanHost = String.fromEnvironment(
    'ORION_DEV_HOST',
    defaultValue: '192.168.1.11',
  );

  /// Emulador Android: `--dart-define=ORION_USE_EMULATOR=true`
  static const bool useEmulator = bool.fromEnvironment(
    'ORION_USE_EMULATOR',
    defaultValue: false,
  );

  /// Celular físico por USB: `adb reverse tcp:8080 tcp:8080` y
  /// `--dart-define=ORION_USE_ADB_REVERSE=true`
  static const bool useAdbReverse = bool.fromEnvironment(
    'ORION_USE_ADB_REVERSE',
    defaultValue: true,
  );
}
