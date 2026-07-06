-- Segunda hoja de ruta demo para conductor@empresa.com (driver-demo)
-- Ejecutar: docker exec -i orion-postgres psql -U postgres -d orion-dispatch < scripts/seed_route_demo_002.sql

BEGIN;

-- 1) Reasignar y resetear route-demo-001 para pruebas frescas
UPDATE route_sheets
SET driver_external_id = 'driver-demo',
    tenant_external_id = 'tenant-demo',
    vehicle_external_id = 'vehicle-001',
    vehicle_plate = 'ABC-1234',
    vehicle_model = 'Mercedes Sprinter 2024',
    status = 'ASSIGNED',
    date = CURRENT_DATE,
    started_at = NULL,
    completed_at = NULL,
    updated_at = NOW()
WHERE external_id = 'route-demo-001';

UPDATE trip_stops
SET status = 'PENDING',
    arrival_time = NULL,
    departure_time = NULL
WHERE route_sheet_id = (SELECT id FROM route_sheets WHERE external_id = 'route-demo-001');

-- 2) Nueva hoja route-demo-002 (solo si no existe)
INSERT INTO route_sheets (
    created_at, date, driver_external_id, external_id, status,
    tenant_external_id, vehicle_external_id, vehicle_model, vehicle_plate, updated_at
)
SELECT NOW(), CURRENT_DATE, 'driver-demo', 'route-demo-002', 'ASSIGNED',
       'tenant-demo', 'vehicle-001', 'Mercedes Sprinter 2024', 'XYZ-5678', NOW()
WHERE NOT EXISTS (SELECT 1 FROM route_sheets WHERE external_id = 'route-demo-002');

-- 3) Paradas para route-demo-002
INSERT INTO trip_stops (
    external_id, route_sheet_id, stop_order, status,
    address, location_name, estimated_arrival, latitude, longitude
)
SELECT v.external_id, rs.id, v.stop_order, 'PENDING',
       v.address, v.location_name, v.estimated_arrival, v.latitude, v.longitude
FROM route_sheets rs
CROSS JOIN (VALUES
    ('stop-201', 1, 'Av. Javier Prado 1000, San Isidro', 'Cliente Norte', NOW() + INTERVAL '1 hour', -12.0983, -77.0323),
    ('stop-202', 2, 'Av. Arequipa 2500, Lince', 'Cliente Centro', NOW() + INTERVAL '2 hours', -12.0847, -77.0335),
    ('stop-203', 3, 'Av. La Marina 500, Pueblo Libre', 'Cliente Sur', NOW() + INTERVAL '3 hours', -12.0755, -77.0850)
) AS v(external_id, stop_order, address, location_name, estimated_arrival, latitude, longitude)
WHERE rs.external_id = 'route-demo-002'
  AND NOT EXISTS (SELECT 1 FROM trip_stops ts WHERE ts.external_id = v.external_id);

COMMIT;

-- Verificación
SELECT external_id, driver_external_id, status, date FROM route_sheets WHERE driver_external_id = 'driver-demo';
SELECT ts.external_id, rs.external_id AS route_sheet, ts.stop_order, ts.status
FROM trip_stops ts
JOIN route_sheets rs ON rs.id = ts.route_sheet_id
WHERE rs.driver_external_id = 'driver-demo'
ORDER BY rs.external_id, ts.stop_order;
