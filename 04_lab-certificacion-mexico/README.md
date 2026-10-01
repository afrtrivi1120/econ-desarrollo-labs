# Lab 4 — Certificar la tierra y migrar: PROCEDE en los ejidos de México

**Economía del Desarrollo (06230) · Universidad ICESI · Departamento de Economía**

Hasta 1992, la parcela de un ejidatario mexicano se conservaba de una sola forma:
**trabajándola**. La Constitución ordenaba quitársela a quien no la cultivara dos años
seguidos, y estaba prohibido venderla o arrendarla. El derecho dependía de estar.

Entre 1993 y 2006 el programa **PROCEDE** entregó certificados a los ejidatarios de casi
todo el país y rompió ese vínculo: con el certificado, uno se podía ir sin perder la
tierra. El programa llegó a los ejidos **en años distintos**, y esa diferencia de
calendario es la que usa el paper.

Este laboratorio replica en R el estudio de **de Janvry, Emerick, Gonzalez-Navarro y
Sadoulet (2015)** para responder: **si la tierra ya no exige que uno se quede, ¿la gente
se va?**

Es el primer lab del semestre con **diferencias en diferencias**, y además en su versión
difícil: **adopción escalonada**, donde cada ejido se trata en un año distinto.

> ⚠️ **Acá no hay sorteo: hay calendario.** La comparación es entre ejidos certificados
> antes y ejidos certificados después, y descansa en un supuesto que no se puede probar:
> sin PROCEDE, la migración habría evolucionado **igual** en unos y otros (**tendencias
> paralelas**). Si el programa llegó primero adonde la migración ya venía subiendo, el
> método confunde esa tendencia con un efecto. Las secciones 5 y 6 atacan el supuesto,
> y la 7 busca la misma respuesta en otras dos bases de datos.

---

## ¿Qué vamos a ver en clase?

| Sección | Qué hacemos | Réplica de | Gráfica |
|---|---|---|---|
| 1 | Los datos: un panel de hogares, un resultado **acumulado** y un tratamiento que es solo un calendario | — | — |
| 2 | **El calendario de PROCEDE** y las cuatro cohortes del panel | Figura 1 (en barras) | `figuras/1-calendario-procede.png`, `figuras/2-tendencias-por-cohorte.png` |
| 3 | **El resultado titular**: un DiD 2×2 a mano y después la regresión de efectos fijos | Tabla 1, col. 1 | — |
| 4 | ¿Aguanta? Controles, efectos fijos de hogar y tendencias específicas | Tabla 1, cols. 2–6 | — |
| 5 | ¿**Tendencias paralelas**? Pre-tendencias, *Ashenfelter dip* y estudio de evento | Tabla A4 | `figuras/3-estudio-de-evento.png` |
| 6 | **El problema del TWFE** con adopción escalonada: Callaway y Sant'Anna | extensión | `figuras/4-twfe-vs-callaway-santanna.png` |
| 7 | **Otras dos bases, el mismo signo**: censos de población (con placebo 1980–1990) y censo ejidal | Tablas 2 y 3 | — |
| 8 | **¿Y la tierra?** Menos productores, la misma área: consolidación | Figura 2 y Tabla 4 | `figuras/5-consolidacion-procampo.png` |
| 9–10 | Guardar gráficas y números, y **síntesis** para discutir | — | — |

> ⏱ **Si el tiempo aprieta**, se pueden dejar de tarea la **Tabla 3** (7b), que es la
> evidencia más débil del paper, y las **imágenes satelitales** (8b). Lo que no debería
> saltarse es la sección 6: es donde el lab pasa de «replicar» a «preguntarse si el
> estimador del paper sigue siendo el correcto».

**Los números del paper que el código replica:**

- Con el certificado, la probabilidad de que un hogar tenga un migrante permanente sube
  **1,49 puntos** (EE 0,0061), sobre una media de **5,3 %**: un aumento de **28 %**.
  Son **27.189** observaciones de **7.577 hogares** en **127 ejidos**.
- El coeficiente se mantiene entre **0,013 y 0,017** con controles de hogar, efectos fijos
  de hogar, año × estado y características del ejido × año.
- **Antes** del programa, el año de certificación no predice los cambios en la migración
  (p = 0,190 y 0,493, Tabla A4 del apéndice).
- Las localidades de ejidos certificados en 1993–1999 perdieron **4 %** más de población
  entre 1990 y 2000 (−0,0404, EE 0,0128, **17.328 localidades**). En la década anterior,
  sin PROCEDE, la diferencia es cero: **−0,0082** (EE 0,0148).
- Cada año más con certificado sube **0,35 puntos** la probabilidad de que la mayoría de
  los jóvenes del ejido migre (censo ejidal 2007).
- Certificar **no** cambió el área cultivada (0,0013, EE 0,0093, imágenes Landsat). En los
  ejidos certificados primero hay menos productores y la misma área: el área por productor
  subió alrededor de **10 %**.

**Y lo que el paper no dice, porque el estimador no existía:** con Callaway y Sant'Anna
(2021), que no usa como control a ejidos ya tratados, el efecto en hogares baja a
**0,0108** (EE 0,0068) y su intervalo incluye el cero. El signo sobrevive; la precisión
de la Tabla 1, no del todo. Por eso importa que el paper se apoye en tres bases y no en
una.

Todos los números de la réplica están en [`results.json`](results.json), escrito por el
propio código.

---

## Cómo correrlo

Necesita **R** (≥ 4.1). Lo único que hay que instalar a mano es `pacman`:

```r
install.packages("pacman")
```

El script arranca con `pacman::p_load(tidyverse, scales, fixest, broom, did)`, que instala
lo que falte y carga lo que ya esté.

Hay dos formas equivalentes de trabajar el lab:

**a) Script de R** (para ejecutar por bloques en clase):

```r
source("R/lab4-did-certificacion.R")
```

> En **Positron / RStudio**: abra la carpeta `04_lab-certificacion-mexico` como
> directorio de trabajo y ejecute `R/lab4-did-certificacion.R` por secciones (los bloques
> `# ===` separan cada parte) para ir mirando los datos en clase.

**b) Cuaderno Quarto** (mismo contenido, con explicaciones y salida en HTML):

```bash
quarto render lab4-did-certificacion.qmd
```

Abra `lab4-did-certificacion.html` (ya incluido en el repo) para leer el lab con prosa,
tablas y gráficas, sin necesidad de correr nada.

El lab completo corre en unos 5 segundos. La parte más lenta es el bootstrap de
Callaway y Sant'Anna en la sección 6.

---

## Los datos

Seis archivos, uno por cada base del paper:

| Archivo | Unidad | Filas | Alimenta |
|---|---|---|---|
| `janvry_hogares` | hogar × año, 1997–2000 | 27.189 | Tabla 1, Tabla A4, estudio de evento, Callaway–Sant'Anna |
| `janvry_localidades` | localidad × año, 1990 y 2000 | 54.916 | Tabla 2, cols. 1–5 |
| `janvry_localidades_80_90` | localidad × año, 1980 y 1990 | 32.356 | Tabla 2, col. 6 (placebo) |
| `janvry_censo_ejidal` | ejido, 2007 | 19.713 | Tabla 3 |
| `janvry_procampo` | ejido (1995 y 2012 lado a lado) | 18.437 | Figura 2 |
| `janvry_satelite` | ejido × imagen (1993, 2002, 2007) | 79.443 | Tabla 4 y Figura 1 |

Cada uno viene en `.rds` y en `.csv.gz` (mismo contenido). Ver el
[**codebook**](datos/codebook.md) para la descripción de cada columna y la
[**procedencia**](datos/SOURCE.md) de cada archivo.

Para reconstruir los subsets desde el paquete original, ver
[`R/00-construir-datos.R`](R/00-construir-datos.R) (no hace falta para la clase). El
script verifica contra el paper antes de guardar: si un número no da, no escribe nada.

**Fuentes:** depósito **openICPSR-112931** de la American Economic Association; los datos
están bajo licencia [CC BY 4.0](https://creativecommons.org/licenses/by/4.0). La descarga
**no se puede automatizar**: exige cuenta de ICPSR y aceptar los términos de uso desde un
navegador. Este repositorio no versiona el paquete crudo, solo el subconjunto derivado y
mínimo para el ejercicio docente. Detalles en [`datos/SOURCE.md`](datos/SOURCE.md).

---

## Lecturas de la sesión

- **de Janvry, A., Emerick, K., Gonzalez-Navarro, M. y Sadoulet, E. (2015).** "Delinking
  Land Rights from Land Use: Certification and Migration in Mexico." *American Economic
  Review*, 105(10), 3125–3149.
  [DOI: 10.1257/aer.20130853](https://doi.org/10.1257/aer.20130853). ← **el paper del lab**
- **Besley, T. y Ghatak, M. (2010).** "Property Rights and Economic Development." En D.
  Rodrik y M. Rosenzweig (eds.), *Handbook of Development Economics*, vol. 5, 4525–4595.
  [DOI: 10.1016/B978-0-444-52944-2.00006-9](https://doi.org/10.1016/B978-0-444-52944-2.00006-9).
- **Goldstein, M., Houngbedji, K., Kondylis, F., O'Sullivan, M. y Selod, H. (2018).**
  "Formalization without Certification? Experimental Evidence on Property Rights and
  Investment." *Journal of Development Economics*, 132, 57–74.
  [DOI: 10.1016/j.jdeveco.2017.12.008](https://doi.org/10.1016/j.jdeveco.2017.12.008).
- **Galán, J. S. (2024).** "Tied to the Land? Intergenerational Mobility and Agrarian
  Reform in Colombia." Documento CEDE 2024-43, Universidad de los Andes.

**Para el método** (sección 6):

- **Callaway, B. y Sant'Anna, P. H. C. (2021).** "Difference-in-Differences with Multiple
  Time Periods." *Journal of Econometrics*, 225(2), 200–230.
  [DOI: 10.1016/j.jeconom.2020.12.001](https://doi.org/10.1016/j.jeconom.2020.12.001).
- **Goodman-Bacon, A. (2021).** "Difference-in-Differences with Variation in Treatment
  Timing." *Journal of Econometrics*, 225(2), 254–277.
  [DOI: 10.1016/j.jeconom.2021.03.014](https://doi.org/10.1016/j.jeconom.2021.03.014).
- **Sun, L. y Abraham, S. (2021).** "Estimating Dynamic Treatment Effects in Event Studies
  with Heterogeneous Treatment Effects." *Journal of Econometrics*, 225(2), 175–199.
  [DOI: 10.1016/j.jeconom.2020.09.006](https://doi.org/10.1016/j.jeconom.2020.09.006).

### ¿Por qué este paper y no los otros dos de la sesión?

Es el único de las lecturas 2 a 4 que permite replicar sus resultados principales con datos
públicos:

- **Goldstein et al. (2018)** no tiene paquete de réplica. La encuesta de Benín está en la
  Microdata Library del Banco Mundial, pero en bruto: habría que reconstruir cada resultado
  desde los cuestionarios. Además es un experimento aleatorizado, el método del Lab 3.
- **Galán (2024)** usa archivos del INCORA y registros administrativos cruzados por número
  de cédula, que son confidenciales.
- **de Janvry et al. (2015)** tiene paquete en openICPSR con las seis bases y el do-file
  completo. Este lab replica las Tablas 1 a 4, la Figura 2 y la Tabla A4 del apéndice.

---

## Para discutir en clase

- ¿Por qué deberíamos creer que esto es causal si no hubo sorteo? Compare lo que hubo que
  defender acá con lo que compró el sorteo en el Lab 3 y la frontera en el Lab 2.
- **Para el Escéptico:** ¿qué determinó el orden en que PROCEDE llegó a los ejidos? Si llegó
  primero a los más organizados o mejor conectados, ¿no son esos también los que tienen
  redes de migración que maduran justo en esos años?
- Con Callaway y Sant'Anna el efecto en hogares se achica y su intervalo toca el cero. ¿Cambia
  eso la conclusión del paper? ¿Cuál de las tres bases le parece ahora la evidencia más
  fuerte?
- Galán (2024) encuentra que la tierra de la reforma agraria colombiana tampoco «ató» a las
  familias al campo. ¿Qué le diría a quien diseña hoy una política de formalización de
  tierras en Colombia?

---

*Material del curso Economía del Desarrollo (06230), Universidad ICESI.
Datos: de Janvry et al. (2015), openICPSR-112931 (datos CC BY 4.0; código BSD-3).*
