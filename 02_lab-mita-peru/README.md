# Lab 2 — La mita minera del Perú: una frontera que todavía se nota

**Economía del Desarrollo (06230) · Universidad ICESI · Departamento de Economía**

Entre **1573 y 1812**, la Corona española obligó a los pueblos que caían **dentro** de
un área definida por decreto a enviar **la séptima parte de sus hombres adultos** a las
minas de **Potosí** y **Huancavelica**. Los pueblos que quedaban **justo afuera** de esa
línea quedaron exentos. La *mita* se abolió hace más de dos siglos.

Este laboratorio replica en R el diseño de **Dell (2010)** para responder la pregunta
de fondo: **¿todavía se nota esa frontera en el bienestar de los hogares de hoy?**

Es el primer lab del semestre donde pasamos de **describir** a **identificar**: aquí sí
hacemos una afirmación causal, con la herramienta de la Unidad 2 —la **regresión
discontinua (RDD) geográfica**.

> ⚠️ **Todo descansa en un supuesto: la continuidad en la frontera.** Suponemos que
> todo lo que determina el consumo —geografía, cultura, historia previa— varía de forma
> **suave** al cruzar el límite, y que lo único que **salta** es haber estado sujeto a
> la mita. Ese supuesto no se puede probar; solo se puede atacar. Si la frontera
> coincide con otra discontinuidad —un límite étnico, un piso ecológico, la frontera de
> las haciendas— el diseño se cae. La sección 6 pone ese supuesto a prueba.

---

## ¿Qué vamos a ver en clase?

| Sección | Qué hacemos | Gráfica |
|---|---|---|
| 1 | Los datos: el tratamiento, el resultado y la **variable de asignación** | — |
| 2 | El **mapa** de la frontera de la mita en el sur del Perú | `figuras/1-frontera-mita.png` |
| 3 | La **gráfica del RDD**: el salto en el consumo al cruzar la línea | `figuras/2-salto-consumo.png` |
| 4 | La **estimación** (Tabla II, Panel A del paper) y su lectura en % | — |
| 5 | ¿Aguanta? Tres polinomios × tres ventanas, y `rdrobust` | `figuras/3-especificaciones.png` |
| 6 | ¿Es creíble la frontera? Balance de hoy y **censo de 1572** | `figuras/4-balance-frontera.png` |
| 7 | ¿Por qué persiste? El **mecanismo** que propone Dell | — |
| 8–9 | Guardar gráficas y **síntesis** para discutir | — |

**Resultados que reproduce el código:**

- Un hogar de un distrito de mita consume **24,7 % menos** que su vecino del otro lado
  de la frontera (coeficiente **−0,284**, EE 0,199, agrupado por distrito).
- La muestra es de **1.478 hogares** en **71 distritos** a menos de 100 km de la línea.
- El efecto **no depende de la especificación**: los nueve coeficientes de la rejilla
  (3 polinomios × 3 ventanas) caen entre **−0,34 y −0,22**, es decir, entre −29 % y −20 %.
- **Nada más salta** en la frontera: ni la elevación ni la pendiente de hoy, ni la
  composición demográfica del **censo de Toledo de 1572**, levantado un año antes de
  que empezara la mita.

Son las cifras del paper: Dell reporta un efecto de **cerca de −25 %** y advierte que
en el Panel A los coeficientes **no** son estadísticamente significativos.

---

## Cómo correrlo

Necesita **R** (≥ 4.1). Lo único que hay que instalar a mano es `pacman`:

```r
install.packages("pacman")
```

El script arranca con `pacman::p_load(tidyverse, scales, fixest, rdrobust, broom)`, que
instala lo que falte y carga lo que ya esté.

Hay dos formas equivalentes de trabajar el lab:

**a) Script de R** (para ejecutar por bloques en clase):

```r
source("R/lab2-rdd-mita.R")
```

> En **Positron / RStudio**: abra la carpeta `02_lab-mita-peru` como directorio de
> trabajo y ejecute `R/lab2-rdd-mita.R` por secciones (los bloques `# ===` separan cada
> parte) para ir mirando los datos en clase.

**b) Cuaderno Quarto** (mismo contenido, con explicaciones y salida en HTML):

```bash
quarto render lab2-rdd-mita.qmd
```

Abra `lab2-rdd-mita.html` (ya incluido en el repo) para leer el lab con prosa, tablas y
gráficas, sin necesidad de correr nada.

Ambos cargan `datos/dell_mita_hogares.rds` y corren en pocos segundos.

---

## Los datos

`datos/dell_mita_hogares.rds` son **1.478 hogares** de la ENAHO 2001 del Perú a menos de
100 km de la frontera —la muestra exacta de la Tabla II del paper—, y
`datos/dell_mita_distritos.rds` son **299 distritos** con la geografía del diseño y el
censo colonial de 1572. Ver el [**codebook**](datos/codebook.md) para la descripción de
cada columna y la [**procedencia**](datos/SOURCE.md) de cada archivo.

- También están las versiones `.csv.gz` por si quiere inspeccionar el dato como texto
  plano (mismo contenido).
- Para reconstruir los subsets desde los archivos originales, ver
  [`R/00-construir-datos.R`](R/00-construir-datos.R) (no hace falta para la clase).

**Fuentes:** paquete de réplica de Dell (2010), disponible en la
[página de la autora](https://dell-research-harvard.github.io/projects/498mita). La
muestra de hogares proviene de **MIT OpenCourseWare**, curso *14.75 Political Economy
and Economic Development* (Fall 2012), bajo licencia
[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Este repositorio
**no redistribuye** el paquete crudo: solo un subconjunto derivado y mínimo para el
ejercicio docente. Detalles en [`datos/SOURCE.md`](datos/SOURCE.md).

---

## Lecturas de la sesión

- **Dell, M. (2010).** "The Persistent Effects of Peru's Mining Mita."
  *Econometrica*, 78(6), 1863–1903.
  [DOI: 10.3982/ECTA8121](https://doi.org/10.3982/ECTA8121).
- **Acemoglu, D., Johnson, S., & Robinson, J. A. (2001).** "The Colonial Origins of
  Comparative Development: An Empirical Investigation." *American Economic Review*,
  91(5), 1369–1401.
- **Roland, G. (2016).** *Development Economics*, cap. 9 — historia, instituciones y
  desarrollo.

---

## Para discutir en clase

- ¿Cuánto cambia el efecto al pasar de la ventana de 100 km a la de 50 km? ¿Eso
  fortalece o debilita el resultado?
- ¿Qué otra cosa podría estar saltando en esa misma línea? ¿El balance de 1572 lo
  descarta, o deja el flanco abierto?
- ¿Cómo se conecta el mecanismo de Dell (haciendas → bienes públicos → caminos →
  mercado) con el argumento institucional de AJR (2001) y del capítulo de Roland?

---

*Material del curso Economía del Desarrollo (06230), Universidad ICESI.
Datos: paquete de réplica de Dell (2010); muestra de hogares vía MIT OpenCourseWare.*
