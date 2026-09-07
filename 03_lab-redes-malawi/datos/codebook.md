# Codebook — los cuatro subsets del Lab 3

Subconjuntos de enseñanza derivados del paquete de réplica de **Beaman, BenYishay,
Magruder y Mobarak (2021)**, *Can Network Theory-Based Targeting Increase Technology
Adoption?*. Ver [`SOURCE.md`](SOURCE.md) para la procedencia y la licencia.

> **Ojo con la palabra «derivado».** El paquete original **no trae** un archivo a nivel de
> aldea: trae el microdato de agricultores y unos do-files que construyen los resultados.
> Las dos variables de resultado de la Tabla 2 se calculan en
> [`../R/00-construir-datos.R`](../R/00-construir-datos.R), replicando paso por paso lo que
> hace `code/2_table2.do`.

---

## `beaman_redes_aldeas` — 200 filas × 19 columnas

Unidad de observación: **aldea**. Tres distritos semiáridos de Malawi. Es exactamente la
muestra de la **Tabla 2** del paper.

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `aldea` | entero | Identificador de aldea. **Nivel al que se agrupan los errores estándar** (y también el nivel de la fila: ver las notas de uso). | `s_v_code` |
| `distrito` | entero | Código de distrito: **1, 2 o 3**. Es el **estrato** del sorteo: la aleatorización se corrió por separado dentro de cada distrito. Ver la nota sobre los códigos más abajo. | `district` |
| `brazo` | factor | Los cuatro brazos, en orden: `Benchmark` · `Geo` · `Simple` · `Complejo`. **Benchmark es la categoría base** de la regresión. 50 aldeas en cada uno. | derivada |
| `complex` | 0/1 | 1 = los dos capacitados los eligió el algoritmo de **contagio complejo** (umbral λ≈2: hacen falta dos vecinos adoptando). | `t_complex` |
| `simple` | 0/1 | 1 = los eligió el algoritmo de **contagio simple** (λ≈1: basta un vecino). | `t_simple` |
| `geo` | 0/1 | 1 = los eligió un algoritmo que solo usa **proximidad geográfica**, sin datos de red. | `t_geo` |
| `adopcion_alguna_a2` | 0/1 | **El resultado principal.** 1 si al menos un agricultor **no-semilla** de la aldea adoptó la siembra en hoyos en el año 2. | construida desde `pp_adopted_2yr` y `seed` |
| `adopcion_alguna_a3` | 0/1 | Lo mismo en el año 3. `NA` en el distrito 3, que no se midió ese año. | `pp_adopted_3yr`, `seed` |
| `tasa_adopcion_a2` | numérico | Proporción de agricultores muestreados que adoptaron, año 2, **excluyendo semillas y sombras**. | `pp_adopted_2yr`, `seed`, `s_shadow_farmer` |
| `tasa_adopcion_a3` | numérico | Lo mismo en el año 3. `NA` en el distrito 3. | ídem con `pp_adopted_3yr` |
| `compost_base` | numérico | % de la aldea que usaba **compost** en línea base. Control de la rutina de re-aleatorización. | `compost_vbase` |
| `fertilizante_base` | numérico | % que usaba **fertilizante** en línea base. Ídem. | `fert_vbase` |
| `hoyos_base` | numérico | % que **ya sembraba en hoyos** en línea base. Ídem. | `pp_vbase` |
| `tam_aldea` | entero | Número de hogares de la aldea (de 5 a 303). Entra a la regresión junto con su cuadrado. | `villagesize` |
| `en_a3` | 0/1 | 1 = la aldea está en la muestra del año 3. Marca la **atrición**: es 0 en todo el distrito 3. | derivada |
| `sim_simple_a2`, `sim_simple_a3` | numérico | **Simulación**: fracción de veces que la difusión arrancaría en esta aldea bajo **aprendizaje simple** (basta un vecino informado), simulada sobre su red real. `NA` donde no hay año 3. | `ap_vout.dta`, columnas `*_SL` |
| `sim_complejo_a2`, `sim_complejo_a3` | numérico | Lo mismo bajo **aprendizaje complejo** (hacen falta dos vecinos). Es la base de la Figura 2. | `ap_vout.dta`, columnas `*_CL` |

### Cómo se eligió la columna de simulación

`ap_vout.dta` trae, para cada aldea y año, una columna por **algoritmo de selección** y por
**modelo de aprendizaje**. A cada aldea le corresponde la del brazo que efectivamente
recibió: una aldea Complejo usa `any_adopters_complexseed_*`, una Benchmark usa
`any_adopters_controlseed_*`. Y el año 3 se restringe a las aldeas donde de verdad se
midió: sin ese filtro las medias se calculan sobre 200 aldeas en vez de 141 y dejan de
coincidir con la figura publicada.

### Sobre los códigos de distrito

El paquete de réplica **no documenta a qué distrito corresponde cada código**: los `.dta`
vienen sin etiquetas de valor, y ni los do-files ni el `ReadMe.pdf` nombran los distritos.
Lo que sí está establecido:

- El **distrito 3 es Nkhotakota**. Entró al estudio un año después que los otros dos —el
  paper dice que allí se recogió en 2012 y 2013 «en vez de 2011»— y por eso `2_table2.do`
  le corre el calendario un año y no tiene año 3. Coincide con la nota de la Tabla 2: «la
  muestra del año 3 excluye el distrito de Nkhotakota».
- Los **distritos 1 y 2 son Machinga y Mwanza**, pero el paquete no dice cuál es cuál.

Por eso el subset conserva el código numérico en vez de inventar un nombre. Reparto:
30 aldeas en el distrito 1, 111 en el 2 y 59 en el 3.

---

## `beaman_redes_socios` — 1.248 filas × 10 columnas

Unidad de observación: **agricultor candidato**. Un «socio» es quien un algoritmo elegiría
como punto de entrada de la información. Si su aldea recibió ese brazo, lo capacitaron
—es una **semilla**—; si no, quedó como contrafactual observable, una **sombra**.

Sirve para una cosa, pero importante: verificar que los cuatro algoritmos de verdad
eligieron gente distinta. Es la réplica de la **Tabla 1** del paper.

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `aldea` | entero | Identificador de aldea; enlaza con `beaman_redes_aldeas`. | `s_v_code` |
| `distrito` | entero | Distrito de la aldea. | vía `aldea` |
| `brazo` | factor | Brazo que **recibió la aldea**. | vía `aldea` |
| `tipo` | factor | **El algoritmo que elegiría a este agricultor.** No es lo mismo que `brazo`: cada fila trae exactamente un tipo, y los cuatro algoritmos se pueden correr sobre todas las aldeas. Es la columna con la que se arma la Tabla 1. | `complex_type`, `simple_type`, `geo_type`, `control_type` |
| `es_semilla` | 0/1 | 1 = lo capacitaron de verdad (409 filas). | `seed` |
| `es_sombra` | 0/1 | 1 = socio «sombra», no capacitado (766 filas). | `s_shadow_farmer` |
| `centralidad_ev` | numérico | **Centralidad de vector propio**: qué tan conectada es la gente con la que uno habla. | `eig` |
| `grado` | numérico | **Grado**: con cuánta gente habla. | `deg` |
| `rango_ev` | entero | Puesto dentro de aldea × tipo según `centralidad_ev`, de mayor a menor. | derivada |
| `rango_grado` | entero | Puesto según `grado`. **No coincide con `rango_ev`**: el socio más central no siempre es el que más contactos tiene. | derivada |

Reparto por tipo: 395 filas de tipo Complejo, 382 Simple, 375 Geo y solo 96 Benchmark
—de las aldeas Benchmark no se observan sombras, porque no hay un algoritmo que las
defina—.

### Los empates deciden la Tabla 1

Los dos rangos se calculan con `rank(-x, ties.method = "min")`, que es el equivalente en R
de `egen rank(), track` de Stata: a los **empatados les da a todos el rango menor y salta
el siguiente** (1, 1, 3). Por eso hay 2 filas con `rango_ev == 3`.

Si uno usa `ties.method = "first"` —el reflejo natural, porque parece dar igual— el grado
promedio del primer socio del brazo complejo pasa de **17,49** a **18,08** y la tabla deja
de ser la del paper. No falla nada y no hay advertencia. Es la clase de decisión no
escrita que hace o deshace una réplica.

---

## `beaman_redes_conversaciones` — 43.525 filas × 12 columnas

Unidad de observación: **respondente × socio × año**. La encuesta le preguntó a cada
agricultor por unos socios concretos —unos capacitados y otros sombra— y si habían hablado
de siembra en hoyos. Es la base de la **Tabla 3**.

Están excluidos semillas y sombras: interesa qué oyeron **los vecinos**.

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `aldea`, `distrito` | entero | Aldea del respondente y su distrito. | `s_v_code`, `district` |
| `anio` | entero | Año del experimento (1, 2 o 3). | `year` |
| `capacitado` | 0/1 | **El regresor de interés.** 1 = el socio por el que se pregunta fue capacitado; 0 = era sombra. | `trained` |
| `hablaron` | 0/1 | **El resultado.** 1 = reportan haber hablado de siembra en hoyos con ese socio. | `pitorprep` |
| `socio_simple`, `socio_complejo`, `socio_geo` | 0/1 | De qué algoritmo era socio ese contacto, capacitado o no. Entran como controles. | `s_target`, `c_target`, `g_target` |
| `compost_base`, `fertilizante_base`, `hoyos_base`, `tam_aldea` | numérico | Los mismos controles de aldea. | ídem que en `aldeas` |

### El experimento escondido adentro del experimento

Vale la pena detenerse en por qué esta regresión identifica algo. Como la encuesta **solo**
pregunta por socios —gente que algún algoritmo habría elegido— y unos resultaron
capacitados y otros no según el brazo que le tocó a la aldea, **cuál de ellos fue
capacitado es aleatorio**. No hay que suponer nada sobre quién es más sociable: la
comparación es entre personas igual de centrales, unas entrenadas y otras no.

---

## `beaman_redes_censo` — 14.909 filas × 21 columnas

Unidad de observación: **agricultor** del censo de línea base, excluyendo semillas y
sombras. Es la base de la **Tabla A5**, el balance fino.

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `aldea`, `distrito` | entero | Aldea y distrito. | `numvill`, `district` |
| `brazo`, `complex`, `simple`, `geo` | factor / 0/1 | El brazo de la aldea. | `t_*` |
| `vivienda_pc`, `activos_pc`, `ganado_pc` | numérico | Índices de componentes principales de vivienda, activos y ganado. | `housing_pc1`, `assets_pc1`, `livestock_pc1` |
| `fert_basal`, `fert_cobertura` | numérico | Cantidades de fertilizante basal y de cobertura, ajustadas. | `basal_qty_adj`, `topfert_qty_adj` |
| `adultos`, `ninos` | entero | Composición del hogar. | `adults`, `num_children` |
| `tam_finca`, `tierra_propia` | numérico | Tamaño de finca ajustado y tierra en propiedad. | `farmsize_adj`, `land_own` |
| `rendimiento` | numérico | Rendimiento de maíz. | `yield` |
| `presta_ganyu`, `usa_ganyu` | 0/1 | Si provee o usa *ganyu*, el trabajo agrícola por jornal en Malawi. | `provganyu_intro`, `useganyu_intro` |
| `compost_base`, `fertilizante_base`, `hoyos_base` | numérico | Controles de aldea. | ídem |

> ⚠ **Los do-files usan nombres abreviados.** Stata completa solo los nombres de variable
> cuando no hay ambigüedad, así que `A5_tableA5.do` escribe `provganyu` y `useganyu`
> aunque en el `.dta` se llamen `provganyu_intro` y `useganyu_intro`. Lo mismo pasa en
> otros do-files con `pp_adopted_1y` (por `pp_adopted_1yr`) y `s_shadow` (por
> `s_shadow_farmer`). En R hay que escribir el nombre completo.

---

### Por qué el resultado es «alguna adopción» y no la tasa

Con una adopción tan baja, la pregunta de política no es a qué velocidad se difunde la
tecnología sino **si el proceso arranca**. En el brazo Benchmark, dos años después de la
capacitación, en el 58 % de las aldeas no había adoptado nadie fuera de los dos
capacitados. Los autores argumentan que una aldea con cero adoptantes a los tres años
probablemente no adopte nunca: el proceso se estanca, no va lento.

Por eso el indicador binario es el resultado titular y la tasa es el complemento. Las dos
están en el lab y cuentan historias distintas: el targeting logra que la difusión
**empiece** en muchas más aldeas, pero donde empieza sigue siendo un fenómeno pequeño.

---

### Notas de uso

- **Una fila por aldea.** El dato ya viene colapsado al nivel del tratamiento, así que
  `cluster = ~aldea` en `fixest` no agrupa nada: da lo mismo que pedir errores robustos a
  heterocedasticidad. Se escribe así por fidelidad a lo que declara el paper, pero
  conviene saberlo.
- **Interpretar el coeficiente.** El resultado es 0/1, así que un coeficiente `b` se lee
  directo en **puntos porcentuales**: 0,252 son 25,2 puntos sobre una base de 42 %.
- **Benchmark es la base.** Los tres coeficientes se leen contra el grupo donde el
  extensionista eligió a los capacitados a dedo, no contra «no hacer nada»: todas las
  aldeas recibieron el programa.
- **Los grados de libertad importan.** Al probar la igualdad de dos coeficientes hay que
  usar la **t** con el número de clústeres menos 1 (199), no la normal. Con la normal el
  p de `simple = complejo` da 0,298 en vez del 0,300 publicado.
- **Los controles no deberían mover el punto.** En un experimento están incorrelacionados
  con el tratamiento por construcción: solo bajan la varianza. Si al agregarlos el
  coeficiente salta, hay que preocuparse por el sorteo, no celebrar el ajuste.
- **El año 3 no es una submuestra al azar.** Es 200 aldeas menos un distrito completo. Los
  coeficientes de los años 2 y 3 no son comparables sin volver a correr el año 2 sobre la
  muestra del año 3 — y al hacerlo el efecto sube a 0,366, más que el propio año 3.

**Fuente:** Beaman, L., BenYishay, A., Magruder, J. y Mobarak, A. M. (2021). Can Network
Theory-Based Targeting Increase Technology Adoption? *American Economic Review*, 111(6),
1918–1943. Datos vía openICPSR-130605 (CC BY 4.0).
