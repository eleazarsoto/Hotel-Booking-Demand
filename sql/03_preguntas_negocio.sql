-- ============================================================
-- Hotel Booking Demand — 5 preguntas de negocio
-- Técnica de la semana: funciones de ventana (LAG, RANK, ROW_NUMBER)
-- ============================================================

-- ------------------------------------------------------------
-- Pregunta 1: ¿Qué canales generan las reservas más rentables
-- (mayor ADR) vs. cuáles generan más volumen pero menor valor?
-- ------------------------------------------------------------
SELECT
    distribution_channel,
    COUNT(*) AS total_reservas,
    ROUND(AVG(adr), 2) AS adr_promedio,
    ROUND(SUM(adr * (stays_in_weekend_nights + stays_in_week_nights)), 2) AS ingreso_estimado_total
FROM hotel_bookings_clean
WHERE is_canceled = 0
GROUP BY distribution_channel
ORDER BY adr_promedio DESC;

-- ------------------------------------------------------------
-- Pregunta 2: ¿Qué mes tiene la tasa de cancelación más alta,
-- y existe un patrón estacional? (LAG)
-- ------------------------------------------------------------
WITH mensual AS (
    SELECT
        arrival_date_year,
        arrival_date_month,
        COUNT(*) AS total_reservas,
        SUM(is_canceled) AS canceladas,
        ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2) AS tasa_cancelacion_pct
    FROM hotel_bookings_clean
    GROUP BY arrival_date_year, arrival_date_month
)
SELECT
    arrival_date_year,
    arrival_date_month,
    total_reservas,
    canceladas,
    tasa_cancelacion_pct,
    LAG(tasa_cancelacion_pct) OVER (
        ORDER BY arrival_date_year,
            CASE arrival_date_month
                WHEN 'January' THEN 1 WHEN 'February' THEN 2 WHEN 'March' THEN 3
                WHEN 'April' THEN 4 WHEN 'May' THEN 5 WHEN 'June' THEN 6
                WHEN 'July' THEN 7 WHEN 'August' THEN 8 WHEN 'September' THEN 9
                WHEN 'October' THEN 10 WHEN 'November' THEN 11 WHEN 'December' THEN 12
            END
    ) AS tasa_mes_anterior
FROM mensual
ORDER BY arrival_date_year,
    CASE arrival_date_month
        WHEN 'January' THEN 1 WHEN 'February' THEN 2 WHEN 'March' THEN 3
        WHEN 'April' THEN 4 WHEN 'May' THEN 5 WHEN 'June' THEN 6
        WHEN 'July' THEN 7 WHEN 'August' THEN 8 WHEN 'September' THEN 9
        WHEN 'October' THEN 10 WHEN 'November' THEN 11 WHEN 'December' THEN 12
    END;

-- ------------------------------------------------------------
-- Pregunta 3: ¿Qué segmentos de cliente están en el top 3
-- de ingresos cada trimestre? (RANK)
-- Nota: SQLite no soporta QUALIFY, se filtra con un CTE adicional.
-- ------------------------------------------------------------
WITH ingresos_trimestre AS (
    SELECT
        arrival_date_year,
        CASE
            WHEN arrival_date_month IN ('January','February','March') THEN 'Q1'
            WHEN arrival_date_month IN ('April','May','June') THEN 'Q2'
            WHEN arrival_date_month IN ('July','August','September') THEN 'Q3'
            ELSE 'Q4'
        END AS trimestre,
        market_segment,
        ROUND(SUM(adr * (stays_in_weekend_nights + stays_in_week_nights)), 2) AS ingreso_total
    FROM hotel_bookings_clean
    WHERE is_canceled = 0
    GROUP BY arrival_date_year, trimestre, market_segment
),
rankeado AS (
    SELECT
        arrival_date_year,
        trimestre,
        market_segment,
        ingreso_total,
        RANK() OVER (
            PARTITION BY arrival_date_year, trimestre
            ORDER BY ingreso_total DESC
        ) AS puesto
    FROM ingresos_trimestre
)
SELECT * FROM rankeado
WHERE puesto <= 3
ORDER BY arrival_date_year, trimestre, puesto;

-- ------------------------------------------------------------
-- Pregunta 4: ¿Cómo varía el ADR mes a mes? (LAG)
-- ------------------------------------------------------------
WITH metricas_mensuales AS (
    SELECT
        arrival_date_year,
        arrival_date_month,
        ROUND(AVG(adr), 2) AS adr_promedio,
        ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2) AS tasa_cancelacion_pct
    FROM hotel_bookings_clean
    GROUP BY arrival_date_year, arrival_date_month
)
SELECT
    arrival_date_year,
    arrival_date_month,
    adr_promedio,
    LAG(adr_promedio) OVER (
        ORDER BY arrival_date_year,
            CASE arrival_date_month
                WHEN 'January' THEN 1 WHEN 'February' THEN 2 WHEN 'March' THEN 3
                WHEN 'April' THEN 4 WHEN 'May' THEN 5 WHEN 'June' THEN 6
                WHEN 'July' THEN 7 WHEN 'August' THEN 8 WHEN 'September' THEN 9
                WHEN 'October' THEN 10 WHEN 'November' THEN 11 WHEN 'December' THEN 12
            END
    ) AS adr_mes_anterior,
    tasa_cancelacion_pct
FROM metricas_mensuales
ORDER BY arrival_date_year,
    CASE arrival_date_month
        WHEN 'January' THEN 1 WHEN 'February' THEN 2 WHEN 'March' THEN 3
        WHEN 'April' THEN 4 WHEN 'May' THEN 5 WHEN 'June' THEN 6
        WHEN 'July' THEN 7 WHEN 'August' THEN 8 WHEN 'September' THEN 9
        WHEN 'October' THEN 10 WHEN 'November' THEN 11 WHEN 'December' THEN 12
    END;

-- ------------------------------------------------------------
-- Pregunta 5: ¿Qué % de reservas son de clientes repetidos? (ROW_NUMBER)
-- ADVERTENCIA METODOLÓGICA: el dataset no tiene un ID de cliente real.
-- El proxy (country+customer_type+agent) SOBREESTIMA masivamente los
-- repetidos -- se compara a propósito contra la columna real
-- is_repeated_guest para ilustrar el riesgo de esta aproximación.
-- ------------------------------------------------------------
WITH reservas_numeradas AS (
    SELECT
        country,
        customer_type,
        agent,
        reservation_status_date,
        ROW_NUMBER() OVER (
            PARTITION BY country, customer_type, agent
            ORDER BY reservation_status_date
        ) AS num_reserva_del_cliente
    FROM hotel_bookings_clean
    WHERE country IS NOT NULL
)
SELECT
    CASE WHEN num_reserva_del_cliente = 1 THEN 'Primera reserva' ELSE 'Reserva repetida' END AS tipo_reserva,
    COUNT(*) AS total,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM reservas_numeradas), 2) AS porcentaje
FROM reservas_numeradas
GROUP BY tipo_reserva;

-- Comparación contra la columna real del dataset:
SELECT
    is_repeated_guest,
    COUNT(*) AS total,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM hotel_bookings_clean), 2) AS porcentaje
FROM hotel_bookings_clean
GROUP BY is_repeated_guest;
