-- ============================================================
-- Hotel Booking Demand — Limpieza de datos
-- ============================================================
-- Aplica las decisiones documentadas en /docs/log_calidad_datos.md
-- 119,390 filas originales -> 119,208 filas limpias
-- ============================================================

DROP TABLE IF EXISTS hotel_bookings_clean;

CREATE TABLE hotel_bookings_clean AS
SELECT
    hotel,
    is_canceled,
    lead_time,
    arrival_date_year,
    arrival_date_month,
    arrival_date_week_number,
    arrival_date_day_of_month,
    stays_in_weekend_nights,
    stays_in_week_nights,
    adults,
    children,
    babies,
    meal,
    -- country nulo -> NULL real (sin interpretación de negocio clara)
    CASE WHEN country = 'NULL' THEN NULL ELSE country END AS country,
    market_segment,
    distribution_channel,
    is_repeated_guest,
    previous_cancellations,
    previous_bookings_not_canceled,
    reserved_room_type,
    assigned_room_type,
    booking_changes,
    deposit_type,
    -- agent nulo -> "Sin agencia" (reserva directa, es un valor válido)
    CASE WHEN agent = 'NULL' THEN 'Sin agencia' ELSE agent END AS agent,
    -- company nulo -> "Sin empresa" (huésped individual, es un valor válido)
    CASE WHEN company = 'NULL' THEN 'Sin empresa' ELSE company END AS company,
    days_in_waiting_list,
    customer_type,
    adr,
    required_car_parking_spaces,
    total_of_special_requests,
    reservation_status,
    reservation_status_date
FROM hotel_bookings
-- Excluir reservas sin ningún huésped (180 filas, sin patrón de negocio que las explique)
WHERE NOT (adults = 0 AND children = 0 AND babies = 0)
-- Excluir outliers de ADR: 1 caso negativo (-6.38) y 1 caso extremo (5,400)
  AND adr >= 0
  AND adr < 5000;

-- Nota: los 8,171 "duplicados exactos" NO se filtran aquí a propósito.
-- Se investigaron y son reservas grupales/mayoristas legítimas (market_segment = 'Groups'),
-- no errores de captura. Ver log_calidad_datos.md, problema #3.

-- Verificación post-limpieza
SELECT COUNT(*) AS filas_originales FROM hotel_bookings;
SELECT COUNT(*) AS filas_limpias FROM hotel_bookings_clean;
SELECT COUNT(*) FROM hotel_bookings_clean WHERE agent = 'NULL';
SELECT COUNT(*) FROM hotel_bookings_clean WHERE company = 'NULL';
SELECT MIN(adr), MAX(adr) FROM hotel_bookings_clean;
