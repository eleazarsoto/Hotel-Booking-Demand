"""
Hotel Booking Demand — Análisis en Python (pandas)
====================================================
Réplica del análisis SQL, cargando el CSV original directamente
(sin pasar por SQLite), para validación cruzada entre herramientas.

Ejecutar como script o pegar celda por celda en un notebook.
"""

import pandas as pd

# ------------------------------------------------------------
# 1. Carga y reconocimiento general
# ------------------------------------------------------------
df = pd.read_csv("hotel_bookings.csv")
print(f"Filas: {df.shape[0]}, Columnas: {df.shape[1]}")
print(df.dtypes)

# ------------------------------------------------------------
# 2. Diagnóstico de calidad de datos
# ------------------------------------------------------------
print("\n--- Nulos por columna ---")
print(df.isnull().sum().sort_values(ascending=False))

print("\n--- Duplicados ---")
print(f"Duplicados (sin contar primera aparición): {df.duplicated().sum()}")
print(f"Filas en grupos duplicados (comparable a SQL): {df.duplicated(keep=False).sum()}")

# Investigación: ¿los duplicados son reservas grupales legítimas?
grupo_grande = df[
    (df.hotel == "City Hotel") & (df.is_canceled == 1) & (df.lead_time == 277) &
    (df.arrival_date_year == 2016) & (df.arrival_date_month == "November") &
    (df.arrival_date_day_of_month == 7)
]
print(grupo_grande["market_segment"].value_counts())

print("\n--- Outliers ---")
sin_huespedes = df[(df.adults == 0) & (df.children == 0) & (df.babies == 0)]
print(f"Reservas sin huéspedes: {len(sin_huespedes)}")
print(df["adr"].describe())
print(df[df.adr < 0][["hotel", "adr", "stays_in_week_nights"]])
print(df[df.adr == 5400][["hotel", "adr", "reserved_room_type", "stays_in_week_nights"]])

# ------------------------------------------------------------
# 3. Limpieza
# 119,390 filas originales -> 119,208 filas limpias
# ------------------------------------------------------------
df_clean = df.copy()
df_clean["agent"] = df_clean["agent"].fillna("Sin agencia")
df_clean["company"] = df_clean["company"].fillna("Sin empresa")
df_clean["children"] = df_clean["children"].fillna(0)  # 4 nulos, caso marginal

df_clean = df_clean[~((df_clean.adults == 0) & (df_clean.children == 0) & (df_clean.babies == 0))]
df_clean = df_clean[(df_clean.adr >= 0) & (df_clean.adr < 5000)]

# Nota: los duplicados exactos NO se eliminan a propósito -- son
# reservas grupales/mayoristas legítimas (market_segment = 'Groups').

df_clean["noches_totales"] = df_clean["stays_in_weekend_nights"] + df_clean["stays_in_week_nights"]
df_clean["ingreso_reserva"] = df_clean["adr"] * df_clean["noches_totales"]

orden_meses = ["January","February","March","April","May","June",
               "July","August","September","October","November","December"]
df_clean["arrival_date_month"] = pd.Categorical(
    df_clean["arrival_date_month"], categories=orden_meses, ordered=True
)

print(f"\nFilas limpias: {len(df_clean)}")

# ------------------------------------------------------------
# Pregunta 1 — Canales más rentables
# ------------------------------------------------------------
canales = (
    df_clean[df_clean.is_canceled == 0]
    .groupby("distribution_channel")
    .agg(total_reservas=("adr", "count"), adr_promedio=("adr", "mean"),
         ingreso_estimado_total=("ingreso_reserva", "sum"))
    .round(2).sort_values("adr_promedio", ascending=False)
)
print("\n--- Pregunta 1: Canales más rentables ---")
print(canales)

# ------------------------------------------------------------
# Pregunta 2 — Estacionalidad de cancelaciones (shift = LAG)
# ------------------------------------------------------------
mensual = (
    df_clean
    .groupby(["arrival_date_year", "arrival_date_month"], observed=True)
    .agg(total_reservas=("is_canceled", "count"), canceladas=("is_canceled", "sum"))
    .reset_index()
)
mensual["tasa_cancelacion_pct"] = (100 * mensual["canceladas"] / mensual["total_reservas"]).round(2)
mensual = mensual.sort_values(["arrival_date_year", "arrival_date_month"])
mensual["tasa_mes_anterior"] = mensual["tasa_cancelacion_pct"].shift(1)
mensual["variacion_puntos_pct"] = (mensual["tasa_cancelacion_pct"] - mensual["tasa_mes_anterior"]).round(2)
print("\n--- Pregunta 2: Estacionalidad de cancelaciones ---")
print(mensual)

# ------------------------------------------------------------
# Pregunta 3 — Top 3 segmentos por trimestre (rank = RANK)
# ------------------------------------------------------------
def mes_a_trimestre(mes):
    if mes in ["January", "February", "March"]:
        return "Q1"
    elif mes in ["April", "May", "June"]:
        return "Q2"
    elif mes in ["July", "August", "September"]:
        return "Q3"
    return "Q4"

df_clean["trimestre"] = df_clean["arrival_date_month"].apply(mes_a_trimestre)

ingresos_trimestre = (
    df_clean[df_clean.is_canceled == 0]
    .groupby(["arrival_date_year", "trimestre", "market_segment"])
    .agg(ingreso_total=("ingreso_reserva", "sum"))
    .round(2).reset_index()
)
ingresos_trimestre["puesto"] = (
    ingresos_trimestre.groupby(["arrival_date_year", "trimestre"])["ingreso_total"]
    .rank(method="min", ascending=False)
)
top3 = ingresos_trimestre[ingresos_trimestre["puesto"] <= 3].sort_values(
    ["arrival_date_year", "trimestre", "puesto"]
)
print("\n--- Pregunta 3: Top 3 segmentos por trimestre ---")
print(top3)

# ------------------------------------------------------------
# Pregunta 4 — Variación de ADR mes a mes (shift = LAG)
# ------------------------------------------------------------
mensual_adr = (
    df_clean
    .groupby(["arrival_date_year", "arrival_date_month"], observed=True)
    .agg(adr_promedio=("adr", "mean"),
         tasa_cancelacion_pct=("is_canceled", lambda x: round(100 * x.sum() / len(x), 2)))
    .round(2).reset_index()
    .sort_values(["arrival_date_year", "arrival_date_month"])
)
mensual_adr["adr_mes_anterior"] = mensual_adr["adr_promedio"].shift(1)
print("\n--- Pregunta 4: Variación de ADR mes a mes ---")
print(mensual_adr)

# ------------------------------------------------------------
# Pregunta 5 — % de clientes repetidos (cumcount = ROW_NUMBER)
# ADVERTENCIA: el proxy sobreestima. Se compara contra is_repeated_guest.
# ------------------------------------------------------------
df_valid = df_clean[df_clean["country"].notnull()].copy()
df_valid["num_reserva_del_cliente"] = (
    df_valid.sort_values("reservation_status_date")
    .groupby(["country", "customer_type", "agent"])
    .cumcount() + 1
)
df_valid["tipo_reserva"] = df_valid["num_reserva_del_cliente"].apply(
    lambda n: "Primera reserva" if n == 1 else "Reserva repetida"
)

print("\n--- Pregunta 5: % de clientes repetidos ---")
print("Proxy (sobreestima repetidos):")
print(df_valid["tipo_reserva"].value_counts(normalize=True).mul(100).round(2))
print("\nColumna real is_repeated_guest:")
print(df_clean["is_repeated_guest"].value_counts(normalize=True).mul(100).round(2))

# ------------------------------------------------------------
# Exportar tabla limpia para Power BI
# ------------------------------------------------------------
df_clean.to_csv("hotel_bookings_clean.csv", index=False)
print("\nArchivo hotel_bookings_clean.csv exportado correctamente.")
