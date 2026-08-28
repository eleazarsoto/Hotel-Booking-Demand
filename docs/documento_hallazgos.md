# Hotel Booking Demand — Documento de Hallazgos
## Semana 1 · Oráculo Analytics

**Dataset:** 119,208 reservas limpias (de 119,390 originales) · City Hotel y Resort Hotel, 2015-2017
**Metodología:** SQL (SQLite) + Python (pandas), validados cruzadamente · Dashboard en Power BI

---

## Los 5 hallazgos

### 1. El canal más rentable no es el que más vende
GDS genera la tarifa promedio más alta (119.93) pero representa apenas 156 de 119,208 reservas. TA/TO (agencias de viaje) domina el ingreso total (20.8M) por pura escala, no por margen. Corporate es el canal menos rentable por reserva (67.49, 37% debajo del promedio general) — probablemente por tarifas negociadas a largo plazo.

**Implicación de negocio:** si el objetivo es maximizar margen por reserva, priorizar Direct y GDS. Si el objetivo es volumen para llenar inventario, TA/TO es indispensable pero a menor rentabilidad.

### 2. Las cancelaciones tienen estacionalidad, y sube junto con el precio
La tasa de cancelación oscila entre 20.8% (noviembre 2015, el mínimo) y 45.4% (temporada alta). El patrón más consistente: **primavera-verano (abril-julio)** sostiene tasas de cancelación más altas (37-44%) año tras año.

**Hallazgo contraintuitivo:** cuando el ADR sube, la cancelación tiende a subir también — no bajar. Hipótesis: en temporada alta, los huéspedes reservan con más anticipación y comparan más opciones antes de confirmar.

### 3. Un solo canal domina el ingreso trimestre tras trimestre
En 8 de 9 trimestres analizados (2015 Q3 - 2017 Q1), el top 3 de ingreso por segmento es idéntico: Online TA (1°) → Offline TA/TO (2°) → Direct (3°). La única grieta aparece en 2017 Q3, donde Direct desplaza a Offline TA/TO — posible señal temprana de cambio de comportamiento.

### 4. El precio sube 15% de un año a otro, en el mismo mes
Comparando agosto 2016 (143.07) contra agosto 2017 (164.32): +15% interanual, además de la estacionalidad normal. El negocio no solo tiene temporadas, está subiendo precios estructuralmente.

### 5. Solo 3.15% de las reservas son de huéspedes repetidos
Este es el hallazgo con más peso estratégico. Un cálculo mal construido (aproximando "cliente" por país+tipo+agencia) sugería 97.2% de repetición — un error de 30x que hubiera llevado a una conclusión de negocio completamente opuesta a la realidad.

**Implicación de negocio:** el hotel depende casi por completo de adquisición de clientes nuevos. Hay una oportunidad clara y medible en programas de fidelización/retención — un área donde probablemente se está dejando ingreso sobre la mesa.

---

## Resumen ejecutivo

Este hotel depende casi por completo de clientes nuevos y de agencias de viaje online como motor de ingresos. Los precios y las cancelaciones suben juntos en temporada alta — quienes reservan cuando el precio está más caro también cancelan más, probablemente porque comparan más opciones antes de confirmar. El canal corporativo, aunque aporta volumen, es el menos rentable por reserva. Las tres recomendaciones con mayor impacto potencial: (1) invertir en retención de huéspedes, dado que solo 3 de cada 100 reservas son de clientes que regresan; (2) revisar la política de tarifas corporativas frente a su rentabilidad real; (3) monitorear el cambio reciente en el canal Direct, que ganó terreno sobre Offline TA/TO en el trimestre más reciente analizado.

---
> *"Analicé 119 mil reservas de hotel para responder una pregunta simple: ¿de dónde viene realmente el dinero, y qué tan sólido es ese negocio?*
>
> *Encontré que el canal que más vende — agencias de viaje online — no es el más rentable por reserva; ese título se lo lleva un canal casi marginal en volumen. También encontré que cuando sube el precio en temporada alta, sube la cancelación con él, lo cual es contraintuitivo pero tiene sentido: la gente compara más cuando paga más.*
>
> *Pero el hallazgo más importante fue este: intenté calcular qué porcentaje de huéspedes eran repetidos usando una aproximación razonable, y me dio 97%. Sonaba genial — hasta que lo validé contra el dato real del sistema, y era 3%. Un error de 30 veces. Si hubiera entregado ese primer número sin validarlo, el cliente habría tomado una decisión de negocio completamente equivocada — probablemente reducir su inversión en atraer clientes nuevos, cuando en realidad esa es la única fuente de crecimiento que tienen ahora mismo.*
>
> *Esa es la diferencia entre correr una consulta y hacer un análisis: la validación es la que separa un número de una decisión confiable."*

---

> #DataAnalytics #SQL #Python #PowerBI #OráculoAnalytics
