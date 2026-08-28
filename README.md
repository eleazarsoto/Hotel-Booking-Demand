
Welcome to my README.

Para ver este README en español, ve directo a la sección [Español](#español) más abajo.

---

## English

# Hotel Booking Demand — SQL & Python Analysis

Full-cycle data analysis of 119,390 hotel bookings (City Hotel + Resort Hotel, 2015-2017), from raw data to a business-ready dashboard — every step done twice, in SQL and in Python, and cross-validated against each other.

**Live artifacts:**
- SQL scripts: [`/sql`](./sql)
- Python analysis: [`/python`](./python)
- Data quality log: [`/docs/log_calidad_datos.md`](./docs/log_calidad_datos.md)
- Findings & business recommendation: [`/docs/documento_hallazgos.md`](./docs/documento_hallazgos.md)

### Process

Business question → SQL → Python → dashboard → decision document, with every calibration mistake and every bug documented, not hidden.

1. **Sourced** the [Hotel Booking Demand dataset](https://www.kaggle.com/datasets/jessemostipak/hotel-booking-demand) (Kaggle / TidyTuesday) and defined 5 business questions before touching the data.
2. **Cleaned** the data in parallel, in SQLite and pandas — documented every quality issue found (nulls stored as literal text, false "duplicates" that turned out to be legitimate group bookings, ADR outliers, missing-guest records) with the decision and business justification for each.
3. **Queried** with window functions (`LAG`, `RANK`, `ROW_NUMBER` in SQL; `shift`, `rank`, `cumcount` in pandas), cross-validating every result between both tools.
4. **Built a dashboard** in Power BI (DAX measures, `RANKX` for quarterly segment ranking).
5. **Documented findings** in plain language, separate from the technical work.
6. **Translated to a business recommendation.**

### Key finding

An early calculation suggested 97% of guests were repeat customers. Validated against the real flag in the data, the true number was 3% — a 30x error caused by approximating "customer identity" with country + customer type + agent instead of a real identifier. Reported without validation, this would have led to the opposite of the correct business recommendation. Full write-up in the [findings document](./docs/documento_hallazgos.md).

### Stack
`SQL` `SQLite` `Python (pandas)` `Power BI` `DAX` `Git/GitHub`

---

## Español

# Análisis de Hotel Booking Demand — SQL y Python

Análisis de datos de ciclo completo sobre 119,390 reservas de hotel (City Hotel + Resort Hotel, 2015-2017), desde el dato crudo hasta un dashboard listo para negocio — cada paso hecho dos veces, en SQL y en Python, validado de forma cruzada entre ambos.

**Contenido del repositorio:**
- Scripts SQL: [`/sql`](./sql)
- Análisis en Python: [`/python`](./python)
- Log de calidad de datos: [`/docs/log_calidad_datos.md`](./docs/log_calidad_datos.md)
- Hallazgos y recomendación de negocio: [`/docs/documento_hallazgos.md`](./docs/documento_hallazgos.md)

### Proceso

Pregunta de negocio → SQL → Python → dashboard → documento de decisión, con cada error de calibración y cada bug documentado, no escondido.

1. **Obtención de datos:** dataset [Hotel Booking Demand](https://www.kaggle.com/datasets/jessemostipak/hotel-booking-demand) (Kaggle / TidyTuesday), con 5 preguntas de negocio definidas antes de tocar los datos.
2. **Limpieza en paralelo**, en SQLite y pandas — cada problema de calidad de datos encontrado (nulos guardados como texto literal, "duplicados" que resultaron ser reservas grupales legítimas, outliers de tarifa, registros sin huéspedes) documentado con su decisión y justificación de negocio.
3. **Consultas con funciones de ventana** (`LAG`, `RANK`, `ROW_NUMBER` en SQL; `shift`, `rank`, `cumcount` en pandas), validando cada resultado de forma cruzada entre ambas herramientas.
4. **Dashboard en Power BI** (medidas DAX, `RANKX` para ranking trimestral de segmentos).
5. **Documentación de hallazgos** en lenguaje simple, separado del trabajo técnico.
6. **Traducción a recomendación de negocio.**

### Hallazgo clave

Un cálculo inicial sugería que 97% de los huéspedes eran clientes repetidos. Al validarlo contra el dato real del sistema, el número verdadero era 3% — un error de 30 veces, causado por aproximar la "identidad del cliente" con país + tipo de cliente + agencia, en vez de un identificador real. Reportado sin validación, esto hubiera llevado a la recomendación de negocio opuesta a la correcta. Desarrollo completo en el [documento de hallazgos](./docs/documento_hallazgos.md).

### Stack técnico
`SQL` `SQLite` `Python (pandas)` `Power BI` `DAX` `Git/GitHub`

---

📫 **Eleazar Soto** — Data Analyst | Oráculo Analytics
eleazarsoto.data@gmail.com · [LinkedIn](https://www.linkedin.com/in/eleazar-soto-data/) · [GitHub](https://github.com/eleazarsoto)
