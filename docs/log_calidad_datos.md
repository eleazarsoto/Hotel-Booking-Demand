# Hotel Booking Demand — Análisis de Datos
## Semana 1 · Ruta Técnica Semanal — Eleazar Soto

**Dataset:** Hotel Booking Demand (Kaggle / TidyTuesday) — 119,390 reservas de un City Hotel y un Resort Hotel
**Herramientas:** SQL (SQLite) y Python (pandas) — mismo análisis, dos rutas, validación cruzada
**Técnica SQL de la semana:** Funciones de ventana (LAG, RANK, ROW_NUMBER)

---

## 1. Preguntas de negocio

1. ¿Qué canales de venta generan las reservas más rentables (mayor ADR) vs. cuáles generan más volumen pero menor valor?
2. ¿Qué mes de cada año tiene la tasa de cancelación más alta, y existe un patrón estacional?
3. ¿Qué segmentos de cliente están en el top 3 de ingresos cada trimestre?
4. ¿Cómo varía el ADR mes a mes, y se relaciona con la tasa de cancelación?
5. ¿Qué porcentaje de reservas son de clientes repetidos?

---

## 2. Log de calidad de datos

| # | Problema | Cantidad | Decisión | Justificación |
|---|---|---|---|---|
| 1 | Nulos guardados como texto literal `'NULL'` (solo en la versión SQL, no en pandas) | agent: 16,340 · company: 112,593 · country: 488 | `agent`→"Sin agencia", `company`→"Sin empresa", `country`→NULL real | No son errores: significan "reserva directa" / "huésped individual" |
| 2 | Nulos reales en `children` (detectados solo en pandas) | 4 filas | Imputar como 0 | Muestra insignificante (0.003%); probable error de captura en un lote específico (todas de agosto 2015) |
| 3 | "Duplicados exactos" (32 columnas idénticas) | 8,171 filas (SQL) | **No eliminar** | Investigación confirmó: son reservas grupales/mayoristas legítimas (`market_segment = 'Groups'`), no errores |
| 4 | Reservas sin huéspedes (0 adultos, 0 niños, 0 bebés) | 180 filas | Excluir del análisis | Sin patrón de negocio que las explique (a diferencia de "Groups") — consistente con error de captura |
| 5 | ADR negativo | 1 fila (-6.38) | Excluir | Caso único y aislado, sin interpretación de negocio válida |
| 6 | ADR outlier extremo | 1 fila (5,400 vs. promedio ~102) | Excluir | Cuarto estándar, 1 noche — no hay justificación de negocio para el precio; caso aislado |

**Resultado:** 119,390 filas originales → **119,208 filas limpias**

### Hallazgo metodológico: discrepancia SQL vs. Python en duplicados

Al comparar duplicados exactos entre ambas herramientas, SQL reportó 8,171 filas y pandas reportó 40,165 (o 31,994 con el método por defecto). Se investigaron y descartaron dos hipótesis (inconsistencia de formato en `agent`/`company`, e inconsistencia en `reservation_status_date`) — ambas columnas coincidieron exactamente entre herramientas. La causa exacta no se aisló al 100%, pero se determinó que el número de pandas (31,994) coincide con el valor públicamente documentado para este dataset, por lo que se adoptó como fuente de verdad. **Lección:** cuando dos herramientas difieren sobre "los mismos" datos, la ruta con menos pasos de transformación intermedios (pandas leyendo el CSV directo, vs. una importación manual a SQLite) suele ser más confiable.

---

## 3. Limpieza de datos

**SQL:**
```sql
DROP TABLE IF EXISTS hotel_bookings_clean;

CREATE TABLE hotel_bookings_clean AS
SELECT
    hotel, is_canceled, lead_time, arrival_date_year, arrival_date_month,
    arrival_date_week_number, arrival_date_day_of_month, stays_in_weekend_nights,
    stays_in_week_nights, adults, children, babies, meal,
    CASE WHEN country = 'NULL' THEN NULL ELSE country END AS country,
    market_segment, distribution_channel, is_repeated_guest, previous_cancellations,
    previous_bookings_not_canceled, reserved_room_type, assigned_room_type,
    booking_changes, deposit_type,
    CASE WHEN agent = 'NULL' THEN 'Sin agencia' ELSE agent END AS agent,
    CASE WHEN company = 'NULL' THEN 'Sin empresa' ELSE company END AS company,
    days_in_waiting_list, customer_type, adr, required_car_parking_spaces,
    total_of_special_requests, reservation_status, reservation_status_date
FROM hotel_bookings
WHERE NOT (adults = 0 AND children = 0 AND babies = 0)
  AND adr >= 0 AND adr < 5000;
```

**Python:**
```python
df_clean = df.copy()
df_clean["agent"] = df_clean["agent"].fillna("Sin agencia")
df_clean["company"] = df_clean["company"].fillna("Sin empresa")
df_clean["children"] = df_clean["children"].fillna(0)
df_clean = df_clean[~((df_clean.adults == 0) & (df_clean.children == 0) & (df_clean.babies == 0))]
df_clean = df_clean[(df_clean.adr >= 0) & (df_clean.adr < 5000)]

df_clean["noches_totales"] = df_clean["stays_in_weekend_nights"] + df_clean["stays_in_week_nights"]
df_clean["ingreso_reserva"] = df_clean["adr"] * df_clean["noches_totales"]
```

---

## 4. Análisis: 5 preguntas de negocio (SQL y Python, validados cruzadamente)

### Pregunta 1 — Canales más rentables

**SQL:**
```sql
SELECT distribution_channel, COUNT(*) AS total_reservas,
    ROUND(AVG(adr), 2) AS adr_promedio,
    ROUND(SUM(adr * (stays_in_weekend_nights + stays_in_week_nights)), 2) AS ingreso_estimado_total
FROM hotel_bookings_clean
WHERE is_canceled = 0
GROUP BY distribution_channel
ORDER BY adr_promedio DESC;
```

**Python:**
```python
canales = (
    df_clean[df_clean.is_canceled == 0]
    .groupby("distribution_channel")
    .agg(total_reservas=("adr", "count"), adr_promedio=("adr", "mean"),
         ingreso_estimado_total=("ingreso_reserva", "sum"))
    .round(2).sort_values("adr_promedio", ascending=False)
)
```

**Resultado (idéntico en ambas herramientas):**

| Canal | Reservas | ADR promedio | Ingreso total |
|---|---|---|---|
| GDS | 156 | 119.93 | 33,007.96 |
| Undefined | 1 | 112.70 | 563.50 |
| Direct | 12,055 | 106.30 | 4,323,529.31 |
| TA/TO | 57,614 | 101.78 | 20,802,010.34 |
| Corporate | 5,184 | 67.49 | 827,864.92 |

**Hallazgo:** GDS tiene el mayor ADR pero volumen marginal. TA/TO domina el ingreso total por escala, no por rentabilidad unitaria. Corporate es el canal menos rentable por reserva (probable efecto de tarifas negociadas por volumen).

---

### Pregunta 2 — Estacionalidad de cancelaciones (LAG / shift)

**SQL:** `LAG(tasa_cancelacion_pct) OVER (ORDER BY año, mes)`
**Python:** `mensual["tasa_cancelacion_pct"].shift(1)`

**Hallazgo:** la caída más pronunciada ocurre de octubre a noviembre 2015 (-14.18 puntos). El patrón más confiable y repetido: los meses de **primavera-verano boreal (abril-julio)** en 2016 y 2017 sostienen tasas de cancelación más altas (37-44%) que el resto del año.

---

### Pregunta 3 — Top 3 segmentos por trimestre (RANK)

**SQL:** CTE con `RANK() OVER (PARTITION BY año, trimestre ORDER BY ingreso_total DESC)`
**Python:** `groupby(["año","trimestre"])["ingreso_total"].rank(method="min", ascending=False)`

**Hallazgo:** patrón dominante y consistente en 8 de 9 trimestres: **1° Online TA → 2° Offline TA/TO → 3° Direct**. La primera excepción aparece en 2017 Q3, donde Direct desplaza a Offline TA/TO al segundo lugar — posible señal de cambio de comportamiento hacia el final del periodo observado.

---

### Pregunta 4 — Variación de ADR mes a mes (LAG / shift)

**Hallazgo doble:**
- **Estacionalidad:** mínimos en invierno (nov 2015: 60.66), máximos en verano (ago 2017: 164.32)
- **Crecimiento interanual:** ago 2016 (143.07) → ago 2017 (164.32) = +15% en un año
- **Relación con cancelaciones:** contrario a la intuición común — los meses de ADR más alto tienden a tener también cancelación más alta, no más baja. Posible explicación: en temporada alta, los huéspedes reservan con más anticipación y comparan más opciones antes de confirmar.

---

### Pregunta 5 — % de clientes repetidos (ROW_NUMBER / cumcount)

**SQL:** `ROW_NUMBER() OVER (PARTITION BY country, customer_type, agent ORDER BY reservation_status_date)`
**Python:** `groupby(["country","customer_type","agent"]).cumcount()`

| Método | Repetidos | Primera vez |
|---|---|---|
| Proxy (país+tipo cliente+agente) | 97.2% | 2.8% |
| Columna real (`is_repeated_guest`) | 3.15% | 96.85% |

**Hallazgo crítico:** el proxy sobreestima dramáticamente (30x) porque agrupa por categorías amplias, no por identidad real de cliente. **Lección de negocio:** nunca reportar un identificador de cliente inventado sin validarlo contra una fuente de verdad — la conclusión errónea ("97% son leales") hubiera llevado a una decisión de negocio equivocada (reducir inversión en adquisición de nuevos clientes). El dato real (solo 3.15% son repetidos) sugiere, al contrario, una oportunidad clara en programas de fidelización.

---

## 5. Resumen ejecutivo (para un lector no técnico)

Este hotel depende casi por completo de clientes nuevos (97% de las reservas) y de agencias de viaje online (motor principal de ingresos). Los precios y las cancelaciones suben juntos en temporada alta — quienes reservan cuando el precio está más caro también cancelan más, probablemente porque comparan más opciones. El canal Corporate, aunque aporta volumen, es el menos rentable por reserva. Recomendaciones: (1) invertir en retención de huéspedes, dado el bajísimo porcentaje de clientes repetidos; (2) revisar la política de tarifas corporativas; (3) investigar por qué Direct ganó terreno sobre Offline TA/TO en el trimestre más reciente — podría ser una tendencia a monitorear.

---

## 6. Próximos pasos (Etapas 4-6 de la Ruta Técnica Semanal)

- [ ] Etapa 4 — Dashboard en Power BI (semana 1 según la progresión sugerida)
- [ ] Etapa 5 — Documento de hallazgos de 1 página (ya esbozado en la sección 5)
- [ ] Etapa 6 — Explicación de negocio en <2 min + publicación en LinkedIn
