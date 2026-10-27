# 05 — ¿Ya desplaza la IA generativa a los trabajadores de la tercerización de servicios en Filipinas?

**Ravanilla, N. (2026).** "Generative AI and Labor Displacement in the Global South: Evidence from Philippine Business Process Outsourcing." *SSRN Working Paper* (documento de trabajo). DOI: [10.2139/ssrn.7313383](https://doi.org/10.2139/ssrn.7313383)

| Tema | Método | Dónde | Código original | Paquete de réplica |
|---|---|---|---|---|
| Inteligencia artificial (IA) generativa y mercado laboral; los servicios exportados como ruta de desarrollo | Diferencias en diferencias (DiD) con exposición continua tipo *shift-share*, estudio de evento y diseño de dosis-respuesta con la adopción de IA en EE. UU. | Filipinas: 87 provincias (áreas de lugar de trabajo), industrias dentro de provincia y municipios | Stata 18 (`reghdfe`, `boottest`) + Python (figuras y tablas del apéndice) | Harvard Dataverse, un solo `.zip` de ~13,5 MB (13.475.491 bytes) |

> ⚠️ **Lea esta fuente con cautela.** Es un **documento de trabajo** de **un solo autor** (Universidad de California en San Diego), publicado en SSRN en 2026 y **sin revisión de pares**: sus resultados pueden cambiar antes de una eventual publicación. Además, la medida de exposición a la IA se construye con el **Anthropic Economic Index (AEI)**, es decir, con datos de uso de Claude, un producto de la empresa Anthropic. Ese uso no necesariamente representa el uso de otras herramientas de IA (por ejemplo, ChatGPT) por parte de los clientes de la tercerización. ⚠ Páginas por confirmar con el PDF: el PDF no se pudo descargar de forma automática, así que las cifras de abajo se citan del resumen (*abstract*) o de los archivos de `Output/` del paquete, que según su README reproducen "every number, table, and figure in the paper".

---

## La pregunta

¿Ya empezó la IA generativa a quitarle empleo a la tercerización de procesos de negocio (BPO, *business process outsourcing*: centros de contacto, soporte de back-office, servicios de información y programación) en Filipinas? El autor compara provincias cuyo empleo, antes de ChatGPT, estaba concentrado en ocupaciones muy expuestas a la IA con provincias menos expuestas, y sigue qué les pasa al empleo, los salarios, las horas, el desempleo y la migración al exterior a medida que las empresas clientes de EE. UU. adoptan IA.

## Por qué nos importa en Economía del Desarrollo

El resumen lo plantea así: "Exported services have become for labor-abundant countries what manufacturing once was: a development path that absorbs large numbers of workers into internationally traded production." Si la IA hace las mismas tareas que estos países exportan, esa ruta de desarrollo se puede cerrar antes de madurar. Filipinas es el caso más extremo ("the economy most dependent on this development path", según el resumen). El paper conecta tres temas del curso: mercados laborales y cambio estructural, migración (el autor pregunta si la salida tradicional, emigrar como trabajador en el exterior, compensa la pérdida) y la geografía del desarrollo (efectos por provincia y municipio). La pregunta importa para cualquier economía de ingreso medio que apueste por exportar servicios.

## Datos y diseño

- **Empleo:** microdatos de uso público de la Encuesta de Fuerza Laboral (LFS, *Labor Force Survey*) de la Autoridad de Estadística de Filipinas (PSA), agregados por **provincia de lugar de trabajo** y trimestre. El panel principal tiene 17 rondas trimestrales (2021T2 a 2025T2) y 87 áreas (provincias; los distritos de la Región Capital Nacional, NCR o Metro Manila, aparecen por separado): 1.479 observaciones provincia-trimestre (`Output/tab2_did.tex`, filas "Observations" y "Provinces").
- **Sector BPO:** divisiones 62, 63 y 82 de la clasificación industrial filipina PSIC 2009 (`Codebook.txt`).
- **Exposición de cada provincia (fija en el tiempo):** la suma, sobre ocupaciones, de la participación de cada ocupación en el empleo provincial **antes de ChatGPT** (rondas 2021-04 a 2022-10 agrupadas) multiplicada por la exposición observada de esa ocupación según el AEI (`Codebook.txt`, `province_exposure.csv`). En las regresiones se estandariza (media 0, desviación estándar 1, ponderando por el empleo período previo): variable `expz` (`Code/2_analysis/07_analysis_shiftshare.do`).
- **"Dosis" de adopción:** porcentaje de empresas de EE. UU. que usan IA, de la Encuesta de Tendencias y Perspectivas Empresariales (BTOS, *Business Trends and Outlook Survey*) del US Census Bureau. Antes de 2023T3 la serie se reconstruye hacia atrás con el Ramp AI Index, Google Trends y Similarweb, y desde 2025T4 se empalma con la pregunta revisada de la BTOS (columna `construction` de `Data/raw/dose_Dt_quarterly.csv`). En la tabla principal entra con un rezago de un trimestre.
- **Otros diseños y resultados:** industria dentro de provincia (67.290 observaciones), municipios con zonas de tecnología (1.170), salarios y horas en BPO (594) (`Output/tab1_main.tex`); desempleo, participación laboral y trabajadores filipinos en el exterior (OFW, *Overseas Filipino Workers*) en 17 regiones (la geografía de residencia en los microdatos públicos es solo regional, según `23_adjustment_margins.do`); y despliegues de migrantes del Departamento de Trabajadores Migrantes (DMW), cuyos paneles provinciales son restringidos (ver Licencias).

## Estrategia de identificación

Es un DiD con tratamiento continuo tipo *shift-share*: la "participación" es la mezcla de ocupaciones de la provincia antes de ChatGPT y el "choque" es la exposición de cada ocupación a la IA. El diseño avanza en tres pasos:

1. **DiD simple y estudio de evento.** Se regresa el resultado (por ejemplo, la participación del BPO en el empleo provincial, en puntos porcentuales) sobre `expz × Post` (después de noviembre de 2022), con efectos fijos de provincia y de ronda, ponderando por el empleo período previo y agrupando errores por provincia (`07_analysis_shiftshare.do`). El estudio de evento interactúa `expz` con cada ronda (base 2022T4). Ese estudio muestra que las provincias más expuestas **ya venían ganando participación BPO antes de ChatGPT**: el coeficiente de 2021T2 es −0,751 (error estándar 0,114) frente a la base (`Output/eventstudy_coefs.csv`, fila 2). El propio do-file advierte que, por eso, el DiD en niveles "overstates any post effect".
2. **Quiebre de tendencia.** Se controla por `expz × tendencia lineal` y se pregunta si la pendiente cambió en la fecha de lanzamiento (`expz × tendencia × Post`).
3. **Dosis-respuesta (especificación principal).** En lugar de una fecha, el tratamiento es la curva de adopción de EE. UU.:

   *y*<sub>pt</sub> = α<sub>p</sub> + δ<sub>t</sub> + β (E<sub>p</sub> × t) + γ (E<sub>p</sub> × D<sub>t−1</sub>) + ε<sub>pt</sub>,

   donde E<sub>p</sub> es la exposición estandarizada y D<sub>t−1</sub> el porcentaje de empresas de EE. UU. que usan IA en el trimestre anterior (`18_main_table.do`). Como ya se controla por una tendencia lineal diferencial, γ se identifica con la **curvatura** de la adopción de EE. UU., no con cualquier divergencia gradual entre provincias. El autor complementa con un diseño **dentro de provincia, entre industrias** (efectos fijos provincia × ronda, que absorben todo choque provincial) y con inferencia robusta a la exposición a nivel del choque ocupacional (Borusyak–Hull–Jaravel; `14_akm_bhj.do`).

> ⚠️ **El supuesto del que depende todo:** condicionando en la tendencia lineal diferencial por exposición y en los efectos fijos, ningún otro choque sigue la **forma** de la curva de adopción de IA en EE. UU. de manera distinta entre provincias más y menos expuestas (así lo formula `25_validity_tests.do`). Si, por ejemplo, la recuperación pospandemia o el regreso a la oficina en las provincias con más BPO se aplanara justo cuando la adopción se acelera, el coeficiente γ confundiría esa desaceleración con la IA. Un riesgo adicional: tendencia y dosis son series suaves y muy parecidas; el paquete documenta, para el panel de despliegues de migrantes, una correlación parcial de 0,82 entre ambas después de los efectos fijos (`Output/dmw_prov_collinearity.csv`, fila "29 window").

El autor pone a prueba el supuesto con dos implicaciones en el período previo (no linealidad de la tendencia y una "dosis placebo" asignada a las rondas pre-ChatGPT): `25_validity_tests.do` → `Output/validity_tests.csv` y `Output/tabS_validity.tex`.

## Resultado principal

Según el resumen: "Employment growth slows in the most exposed provinces, industries, and municipalities, amounting to roughly a quarter million foregone jobs by mid-2025. The adjustment occurs through reduced hiring rather than layoffs: wages and hours do not change. Displaced workers enter unemployment, and the traditional adjustment through overseas migration does not offset these losses."

En la Tabla 1 (`Output/tab1_main.tex`), que el README del paquete identifica como "Table 1 (main estimates)":

- Columna (1): por cada desviación estándar adicional de exposición y cada punto porcentual adicional de empresas de EE. UU. que usan IA (rezago 1), la participación del BPO en el empleo provincial cae **−0,1495 puntos porcentuales** (error estándar 0,0275; 1.479 observaciones).
- Columna (2): el logaritmo del empleo BPO provincial cae −0,0366 (0,0119; 1.312 observaciones).
- Columnas (6) y (7): salario diario básico y horas semanales en BPO, 0,0015 (0,0040) y 0,0021 (0,0019): ni salarios ni horas responden, en línea con "reduced hiring rather than layoffs".

⚠ La cifra de "a quarter million foregone jobs" viene del resumen. Los ingredientes del cálculo están en `19_magnitude.do` (su encabezado dice "translation to jobs"), que los imprime en pantalla sin exportarlos a `Output/`; el paquete no trae el número final. Para citar su página hay que tener el PDF.

## Qué replicar

- **Resultado objetivo:** Tabla 1, columnas (1) y (2) (`Output/tab1_main.tex`): el efecto de exposición × adopción de IA (rezago 1) sobre la participación y el logaritmo del empleo BPO provincial. Como complemento, el DiD simple y el estudio de evento que motivan el diseño (`Output/tab2_did.tex`, columna 1, y `Output/eventstudy_coefs.csv`; ⚠ la numeración de esa tabla y de esa figura en el paper está por confirmar con el PDF, porque el README del paquete solo mapea la Tabla 1 y las Figuras 1 a 4).
- **Dónde está en el paquete:** `Code/2_analysis/18_main_table.do` (Tabla 1) y `Code/2_analysis/07_analysis_shiftshare.do` (DiD y estudio de evento). Datos: `Data/analysis/lfs_province_quarter.dta` (ya trae `bposhare`, `lbpo`, `expz`, `w0`, `rid`, `pid`), `Data/analysis/dose_quarterly.dta` (dosis `d_t_pct_firms_using_ai`) y, para las columnas (6) y (7), `Data/analysis/lfs_industry_quarter.dta`.
- **Dificultad:** media-baja. El panel ya viene limpio (1.479 filas, 87 provincias); el trabajo es construir el rezago de la dosis, la tendencia centrada en 2022T4 y las interacciones. Una prueba rápida en R reprodujo exactamente los coeficientes de las columnas (1) y (2), la columna (1) de `tab2_did.tex` y el estudio de evento.
- **Trabajo en R:** `haven::read_dta()` + `dplyr` para unir la dosis por ronda; `fixest::feols(bposhare ~ x_trend + x_dose1 | pid + rid, weights = ~w0, cluster = ~pid)` en lugar de `areg ... absorb(pid) cluster(pid)`. Dos detalles para que los errores estándar coincidan: (i) `areg` cuenta los efectos fijos absorbidos en la corrección de grados de libertad, así que use `vcov = vcov_cluster("pid", ssc = ssc(fixef.K = "full"))`; (ii) para las columnas (6) y (7), `fixest` elimina por defecto 5 observaciones aisladas (*singleton*) (queda N = 589 en vez de 594); use `fixef.rm = "none"`. `reghdfe` (columnas 3 a 5) también se traduce a `feols` con efectos fijos múltiples. El *wild cluster bootstrap* (`boottest`) **no** se usa en la Tabla 1 (solo en los do-files de migración y despliegues); en R es opcional: `fwildclusterboot` fue retirado de CRAN el 2024-05-29 y hoy se instala desde r-universe (`s3alfisc.r-universe.dev`). Tablas con `modelsummary` o `etable`.

## Descargas

- **Paper:** [https://doi.org/10.2139/ssrn.7313383](https://doi.org/10.2139/ssrn.7313383) (SSRN, de descarga gratuita desde el navegador; no se redistribuye en este repositorio).
- **Paquete de réplica:** [https://doi.org/10.7910/DVN/L5M1NK](https://doi.org/10.7910/DVN/L5M1NK) (Harvard Dataverse).
- **Script de descarga:** `R/descargar-datos.R` (descarga el paquete y descomprime el `.zip` anidado en `datos/_crudos/`).

## Licencias

- **Paquete de réplica:** CC0 1.0 (dominio público), según los metadatos del conjunto de datos en Harvard Dataverse.
- **Qué incluye y qué no:** el README del paquete dice que "All files in `Data/raw/` are redistributable and deposited here" y que `Data/derived/` contiene "Intermediates built from restricted-use source files (included where redistribution is permitted; the DMW provincial deployment panels are not — see below)". Los microdatos de la LFS, la FIES y la Survey on Overseas Filipinos de la PSA no vienen en el paquete ("Available to registered researchers from the PSA Microdata Portal"), pero sí sus agregados, que bastan para la Tabla 1. El libro provincial de despliegues del DMW se obtuvo por solicitud y no se incluye; sus resultados vienen ya estimados en `Output/` (`dmw_prov_*.csv`, `tabS_dmw*.tex`). Del AEI, el README dice: "Public under CC-BY from Anthropic's data repository".
- **Paper:** sin licencia declarada en los metadatos consultados (⚠ verificar en la página de SSRN).
