# Orion Driver — Dispatch + Telemetría

## Pantallas Dispatch (4)

| # | Pantalla | Archivo |
|---|----------|---------|
| 1 | Lista hojas de ruta | `route_sheets_list_page.dart` |
| 2 | Detalle hoja + paradas | `route_home_page.dart` |
| 3 | Detalle parada | `stop_detail_page.dart` |
| 4 | Registrar entrega | `proof_of_delivery_page.dart` |

## Flujo

```
Login → Mis Hojas de Ruta
           ↓ tap
        Hoja de Ruta (vehículo, jornada, paradas, chip GPS)
           ↓ INICIAR JORNADA → GPS + sync batch
           ↓ tap parada
        Detalle parada → Registrar entrega
           ↓ FINALIZAR JORNADA → stop GPS + flush
```

## Telemetría GPS

- **Iniciar jornada** → captura GPS cada 15 s → SQLite (`synced=0`)
- **Con red** → `POST /v1/telemetry/vehicle-positions/batch` cada ~1 min
- **Sin red** → posiciones pendientes; sync al recuperar conectividad
- **Finalizar jornada** → detiene GPS y envía pendientes finales
- Headers: `Authorization`, `X-Tenant-Id`, `X-Driver-Id` (vía `ApiClient`)

### Permisos

| Plataforma | Permiso |
|------------|---------|
| Android | `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` |
| iOS | `NSLocationWhenInUseUsageDescription` en `Info.plist` |

## Demo

`conductor@empresa.com` / `123456`

```powershell
flutter run --dart-define=ORION_API_BASE_URL=http://10.0.2.2:8080/v1
```

### Si falla el GPS (emulador o dispositivo)

1. **Permiso:** al iniciar jornada, acepta "ubicación".
2. **Emulador Android:** panel lateral `⋯` → **Location** → elige Lima u otra ciudad (no dejes "No location").
3. **Reinicia jornada:** finaliza y vuelve a iniciar, o recarga la hoja.
4. **Consola Flutter:** busca líneas `[GPS] Guardado local: -12.x, -77.x`.
5. **Icono AppBar:** verde = OK · rojo = error (toca el icono para ayuda).

```powershell
# Ver logs solo GPS
flutter run --dart-define=ORION_API_BASE_URL=http://10.0.2.2:8080/v1 2>&1 | findstr GPS
```

## Mantenimiento (orion-maintenance-service)

### Pantallas

| Pantalla | Archivo |
|----------|---------|
| Reportar mantenimiento | `report_maintenance_page.dart` (desde hoja de ruta con jornada activa) |
| Historial local | `maintenance_history_page.dart` |

### Flujo

```
Hoja de ruta (jornada activa) → Reportar mantenimiento
  → genera id maint-<uuid> y guarda en SQLite (synced=0)
  → POST /v1/maintenance/requests
  → si OK: synced=1 y status del servidor (PENDING, etc.)
  → si sin red: queda pendiente; MaintenanceSyncService reintenta con el mismo id
```

### Contrato HTTP

- **Base URL:** puerto `8084` (directo o vía gateway según `--dart-define`)
- **Headers:** `Content-Type`, `X-Tenant-Id`, `X-Driver-Id` (sin JWT obligatorio en servicio directo)
- **Body:** snake_case — `id`, `vehicle_id`, `description`, `severity` (LOW|MEDIUM|HIGH|CRITICAL)
- **Idempotencia:** reintentos usan el mismo `id` generado en el móvil
- **Foto:** solo se envía `photo_evidence_path` (nombre local); el backend no recibe multipart

```powershell
# Maintenance directo (sin gateway)
flutter run --dart-define=ORION_MAINTENANCE_BASE_URL=http://10.0.2.2:8084/v1

# O vía API Gateway (8080)
flutter run --dart-define=ORION_API_BASE_URL=http://10.0.2.2:8080/v1
```

Demo headers: `tenant-demo`, `driver-demo`, `vehicle_id: vehicle-001`.

## Notificaciones (orion-notification-service)

### Pantallas

| Pantalla | Archivo |
|----------|---------|
| Listado | `notifications_list_page.dart` |
| Detalle | `notification_detail_page.dart` |

Acceso: icono campana en **Mis Hojas de Ruta** o tile en Home.

### Flujo

```
Login (driver-demo / tenant-demo)
  → GET /v1/notification con X-Tenant-Id
  → filtro en cliente: user_id === driverId de sesión
  → tap item → GET /v1/notification/{id}
```

### Contrato HTTP

- **Base URL:** puerto `8086` — `ORION_NOTIFICATION_BASE_URL`
- **Header obligatorio:** `X-Tenant-Id` (desde sesión IAM)
- **Sin filtro por usuario en backend:** la app filtra por `user_id` localmente
- **Sin PATCH is_read:** badge "leída" solo local al abrir detalle

```powershell
# Notification directo (recomendado para pruebas)
flutter run --dart-define=ORION_NOTIFICATION_BASE_URL=http://10.0.2.2:8086/v1

# Validar backend con curl
curl -X GET "http://localhost:8086/v1/notification" -H "X-Tenant-Id: tenant-demo"
```

### URLs base según entorno

| Entorno | URL base |
|---------|----------|
| Emulador Android | `http://10.0.2.2:8086/v1` |
| Simulador iOS / Windows desktop | `http://localhost:8086/v1` |
| Dispositivo físico | `http://<IP-LAN-DE-TU-PC>:8086/v1` (ej. `192.168.1.50`) |

Si no pasas `--dart-define`, la app usa por defecto `10.0.2.2:8086` en Android y `localhost:8086` en el resto.
