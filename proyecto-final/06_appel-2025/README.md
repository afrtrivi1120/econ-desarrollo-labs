# 06 — ¿Quién usa la IA en el mundo? Adopción de Claude e ingreso por país

**Appel, R., McCrory, P., Tamkin, A., McCain, M., Neylon, T. y Stern, M. (2025).** "Anthropic Economic Index report: Uneven geographic and enterprise AI adoption." Informe de Anthropic, publicado el 15 de septiembre de 2025; *preprint* arXiv:2511.15080. DOI: [10.48550/arXiv.2511.15080](https://doi.org/10.48550/arXiv.2511.15080)

| Tema | Método | Dónde | Código original | Paquete de réplica |
|---|---|---|---|---|
| Difusión tecnológica / desigualdad entre países | Medición + regresión descriptiva de corte transversal | 150+ países y estados de EE. UU. | Python (scripts y Jupyter) | Hugging Face `Anthropic/EconomicIndex`, carpeta `release_2025_09_15`, ~58 MB |

> **Advertencia de fuente.** Este es un **informe de una empresa** (Anthropic), escrito por su personal sobre el uso de su propio producto. **No ha pasado por revisión de pares.** Léalo como un documento de datos con posible conflicto de intereses, no como un artículo académico.

---

## La pregunta

¿Dónde se usa la IA generativa y para qué? El informe mide cuánto se usa Claude.ai en cada país en relación con su población en edad de trabajar y pregunta si esa adopción sigue el patrón de tecnologías anteriores: concentrada al inicio en países ricos.

## Por qué nos importa en Economía del Desarrollo

La difusión desigual de tecnologías es una explicación clásica de la divergencia de ingresos entre países. El propio informe plantea que, si las ganancias de productividad son mayores donde la adopción es alta, la IA podría ampliar la desigualdad global y revertir la convergencia de las últimas décadas (p. 4). Para Colombia la pregunta es concreta: ¿adopta lo que "le corresponde" por su ingreso, o menos?

## Datos y diseño

- **Uso:** una muestra aleatoria de 1 millón de conversaciones de Claude.ai (planes Free y Pro) entre el 4 y el 11 de agosto de 2025, geolocalizadas por dirección IP; se excluyen VPN y servicios de alojamiento (nota 2, p. 28).
- **Índice:** el *Anthropic AI Usage Index* (AUI) divide la participación de un país en el uso de Claude por su participación en la población mundial de 15 a 64 años. AUI > 1 indica más uso del esperado por población (p. 14).
- **Variables de país:** población de 15 a 64 años del Banco Mundial (`SP.POP.1564.TO`) y PIB total en dólares corrientes de 2024 del FMI (serie `NGDPD`), que el código divide por la población en edad de trabajar (`data_documentation.md`). Note que **no** es PIB en paridad de poder adquisitivo.
- **Unidad de análisis:** país, con al menos 200 conversaciones en la muestra (p. 14).

## Estrategia de identificación

No hay identificación causal: es una **correlación de corte transversal**. Se estima por mínimos cuadrados ordinarios (MCO)

ln(AUI_c) = a + b · ln(PIB por persona en edad de trabajar_c) + e_c

y b se lee como una elasticidad. Nada en el diseño separa el efecto del ingreso del de la infraestructura digital, el idioma, la estructura productiva o la presencia comercial de Anthropic; el propio informe enumera varios de estos factores (pp. 17–18).

> ⚠️ **El supuesto del que depende todo:** que el uso de **Claude** es una buena medida del uso de **IA** en un país. Si la participación de mercado de Anthropic frente a otros proveedores varía entre países, y esa variación está correlacionada con el ingreso, la pendiente mezcla adopción de IA con preferencia por una marca.

## Resultado principal

El uso de Claude por persona en edad de trabajar crece con el ingreso: según el informe, un aumento de 1 % en el PIB per cápita se asocia con un aumento de 0,7 % en el uso per cápita (p. 16); la Figura 2.4 reporta una pendiente de 0,690 (p < 0,001) y un R² de 0,709 (p. 17). Colombia aparece en el grupo "medio bajo" de adopción, cuyo rango de AUI va de 0,37 a 0,85 (Tabla 2.1, p. 15).

## Qué replicar

- **Resultado objetivo:** la **Figura 2.4** (p. 17): dispersión log-log del AUI contra el PIB por persona en edad de trabajar, con la recta de MCO, su pendiente y su R².
- **Dónde está en el paquete:** datos en `data/output/aei_enriched_claude_ai_2025-08-04_to_2025-08-11.csv` (formato largo; filas con `facet == "country"` y variables `usage_count`, `usage_per_capita_index` y `gdp_per_working_age_capita`). La figura la produce la función `plot_gdp_scatter()` de `code/aei_analysis_functions_claude_ai.py`, llamada desde `code/aei_report_v3_analysis_claude_ai.ipynb`; el filtro de 200 observaciones está en `get_filtered_geographies()`. El índice se calcula en `code/aei_report_v3_preprocessing_claude_ai.ipynb`.
- **Dificultad:** **baja**. Los datos vienen procesados. Si recalcula desde el archivo crudo (`data/intermediate/aei_raw_claude_ai_...csv`, con códigos ISO de dos letras), Namibia aparece como `"NA"` y R lo convierte en dato faltante si no se lo impide (`na = ""` en `readr::read_csv`).
- **Trabajo en R:** `tidyverse` para filtrar y pasar a formato ancho, `fixest::feols` o `lm` para la regresión, `ggplot2` para la figura. Reporte cuántos países entran y compare su pendiente y su R² con los del informe. Luego recalcule usted el AUI a partir de `usage_count` y de la población.

## Ideas para el análisis adicional

1. **¿Ingreso o infraestructura?** — agregue al modelo usuarios de internet, suscripciones de banda ancha y matrícula terciaria. ¿Sobrevive la elasticidad respecto al ingreso? ¿Cambia si usa PIB en paridad de poder adquisitivo (PPA)? *Datos:* WDI vía el paquete [`WDI`](https://cran.r-project.org/package=WDI): `IT.NET.USER.ZS`, `IT.NET.BBND.P2` (ambos de la UIT), `SE.TER.ENRR`, `NY.GDP.PCAP.PP.KD`.
2. **Colombia frente a América Latina** — ¿Colombia está por encima o por debajo de la recta? Compare su residuo con los de sus pares de la región y discuta qué explica las diferencias. *Datos:* el mismo CSV + [indicadores WDI](https://datacatalog.worldbank.org/search/dataset/0037712/world-development-indicators).
3. **¿Para qué se usa en Colombia?** — compare la distribución por grupo ocupacional (`soc_pct`) de Colombia con la global: ¿pesa más la programación, como el informe encuentra en países de menor adopción (p. 12)? *Datos:* el mismo CSV ([Hugging Face](https://huggingface.co/datasets/Anthropic/EconomicIndex)).

## Para el Escéptico

- **Un solo proveedor, usuarios autoseleccionados.** Los datos vienen solo de quienes usan Claude.ai. Si en América Latina predominan otros asistentes, el AUI subestima la adopción de IA y la pendiente con el ingreso podría ser en parte un efecto de mercado de Anthropic. Además, el informe lo escribe la empresa que vende el producto: examine qué incentivos tiene para presentar los resultados de cierta forma.
- **Una semana y filtros.** La muestra cubre una sola semana de agosto de 2025, excluye VPN y suprime celdas con menos de 15 conversaciones o 5 usuarios (nota 1, p. 28). Los países pequeños quedan con mucho ruido, y por eso el umbral de 200.
- **Correlación, no causalidad.** El ingreso puede causar adopción, la adopción puede (con el tiempo) causar ingreso, y ambos pueden depender del capital humano o del idioma. Con un corte transversal no se distinguen estas historias.

## Descargas

- **Paper:** `paper/appel2025_arxiv2511.15080.pdf` (CC BY 4.0).
- **Paquete de réplica:** <https://huggingface.co/datasets/Anthropic/EconomicIndex> (carpeta `release_2025_09_15`).
- **Script de descarga:** `R/descargar-datos.R` (baja el paquete a `datos/_crudos/`).

## Licencias

Informe en arXiv: CC BY 4.0. Repositorio en Hugging Face: etiqueta MIT; la tarjeta del conjunto indica datos bajo CC BY y código bajo MIT. Las fuentes externas mantienen sus términos: población del Banco Mundial (CC BY 4.0) y PIB del FMI (términos de uso de datos del FMI), según `data_documentation.md`.
