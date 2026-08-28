-- ============================================================
-- Hotel Booking Demand — Diagnóstico de calidad de datos
-- ============================================================
-- Propósito: detectar (sin corregir todavía) nulos, duplicados
-- y outliers antes de tomar cualquier decisión de limpieza.
-- ============================================================

-- 1. Reconocimiento general
SELECT COUNT(*) AS total_filas FROM hotel_bookings;
SELECT * FROM hotel_bookings LIMIT 10;
SELECT group_concat(name, ', ') FROM pragma_table_info('hotel_bookings');

-- 2. Nulos por columna
-- Nota: en esta importación a SQLite, los nulos quedaron guardados
-- como el texto literal 'NULL', no como NULL real de SQL.
SELECT COUNT(*) AS agent_nulo_texto   FROM hotel_bookings WHERE agent   = 'NULL';
SELECT COUNT(*) AS company_nulo_texto FROM hotel_bookings WHERE company = 'NULL';
SELECT COUNT(*) AS country_nulo_texto FROM hotel_bookings WHERE country = 'NULL';

-- 3. Duplicados
-- 3a. Comparación "ingenua" con pocas columnas (produce falsos positivos)
SELECT hotel, arrival_date_year, arrival_date_month, arrival_date_day_of_month,
       adults, children, babies, COUNT(*) AS repeticiones
FROM hotel_bookings
GROUP BY hotel, arrival_date_year, arrival_date_month, arrival_date_day_of_month,
         adults, children, babies
HAVING COUNT(*) > 1
ORDER BY repeticiones DESC
LIMIT 15;

-- 3b. Duplicados exactos (las 32 columnas) — comparación real
SELECT COUNT(*) AS total_filas_en_grupos_duplicados
FROM (
  SELECT COUNT(*) AS repeticiones
  FROM hotel_bookings
  GROUP BY hotel, is_canceled, lead_time, arrival_date_year, arrival_date_month,
           arrival_date_week_number, arrival_date_day_of_month, stays_in_weekend_nights,
           stays_in_week_nights, adults, children, babies, meal, country, market_segment,
           distribution_channel, is_repeated_guest, previous_cancellations,
           previous_bookings_not_canceled, reserved_room_type, assigned_room_type,
           booking_changes, deposit_type, agent, company, days_in_waiting_list,
           customer_type, adr, required_car_parking_spaces, total_of_special_requests,
           reservation_status, reservation_status_date
  HAVING COUNT(*) > 1
);

-- 3c. Investigación: ¿los duplicados son reservas grupales legítimas?
SELECT market_segment, COUNT(*) AS total
FROM hotel_bookings
WHERE market_segment = 'Groups'
GROUP BY market_segment;

-- 4. Outliers y valores imposibles
SELECT COUNT(*) AS sin_huespedes
FROM hotel_bookings
WHERE adults = 0 AND children = 0 AND babies = 0;

SELECT MIN(adr) AS adr_min, MAX(adr) AS adr_max, AVG(adr) AS adr_promedio
FROM hotel_bookings;

SELECT * FROM hotel_bookings WHERE adr < 0;
SELECT * FROM hotel_bookings WHERE adr = 5400;

-- 5. Consistencia de formato
SELECT DISTINCT arrival_date_month FROM hotel_bookings ORDER BY 1;
SELECT DISTINCT country FROM hotel_bookings ORDER BY 1;
