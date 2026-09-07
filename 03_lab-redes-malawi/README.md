# Lab 3 — Redes sociales y adopción de tecnología en Malawi: a quién le cuentan primero

**Economía del Desarrollo (06230) · Universidad ICESI · Departamento de Economía**

La **siembra en hoyos** es una técnica barata de conservación de suelo y agua que aumenta
el rendimiento en terrenos secos. En Malawi el servicio de extensión agrícola lleva años
tratando de difundirla y casi nadie la usa.

En **200 aldeas** de tres distritos semiáridos, un programa capacitó a **dos agricultores
por aldea** para que la enseñaran a sus vecinos. Lo que se aleatorizó no fue el programa
—todas las aldeas lo recibieron— sino **la regla para elegir a esos dos**: el criterio del
extensionista (*Benchmark*), la cercanía geográfica (*Geo*), o dos algoritmos de teoría de
redes (*contagio simple* y *contagio complejo*).

Este laboratorio replica en R el experimento de **Beaman, BenYishay, Magruder y Mobarak
(2021)** para responder: **con el mismo programa y el mismo presupuesto, ¿cambia algo
elegir distinto a quién le cuentan primero?**

Es el primer lab del semestre con un **experimento aleatorizado (RCT)**, la herramienta
que resuelve el problema de la selección sin pedirle nada al investigador.

> ⚠️ **Acá el supuesto viene con el diseño, pero no sale gratis.** Los cuatro grupos son
> comparables porque hubo un sorteo, y un sorteo no deja nada por fuera: ni lo observable
> ni lo que no se observa. Eso es lo que compra un RCT, y es mucho. Lo que **no** compra:
> el año 3 pierde un distrito entero (200 → 141 aldeas), un agricultor de una aldea tratada
> le puede contar a un vecino de una aldea de comparación, y cuatro brazos por dos
> resultados por dos años son muchas pruebas a la vez. Las secciones 3, 6 y 7 miran esos
> tres flancos de frente.

---

## ¿Qué vamos a ver en clase?

| Sección | Qué hacemos | Gráfica |
|---|---|---|
| 1 | Los datos: los cuatro brazos, el resultado y los estratos del sorteo | — |
| 2 | ¿Mordió el tratamiento? La **centralidad** de los elegidos por cada algoritmo | `figuras/1-centralidad-por-brazo.png` |
| 3 | ¿Funcionó la aleatorización? Pruebas de **balance** en línea base | `figuras/2-balance-aleatorizacion.png` |
| 4 | La **diferencia de medias**: el estimador más honesto de un experimento | `figuras/3-adopcion-por-brazo.png` |
| 5 | La **regresión** (Tabla 2 del paper) y sus cuatro columnas | — |
| 6 | ¿Aguanta? Controles, **inferencia por aleatorización** y la atrición del año 3 | `figuras/4-inferencia-aleatorizacion.png` |
| 7 | **Simple contra complejo**: lo que el titular no dice | — |
| 8–9 | Guardar gráficas y **síntesis** para discutir | — |

**Los números del paper que el código replica:**

- Elegir a los dos capacitados con el algoritmo de **contagio complejo** sube la
  probabilidad de que la difusión arranque en **25,2 puntos porcentuales** (EE 0,093),
  sobre una base de **42 %** en el brazo Benchmark.
- La muestra es de **200 aldeas** en **3 distritos**, con 50 aldeas por brazo.
- En el año 3 el efecto sube a **30,4 puntos** (EE 0,101), pero sobre **141 aldeas**: la
  medición no cubrió Nkhotakota.
- Sobre la **tasa** de adopción el efecto es de **3,6 puntos** sobre una base de 3,8 %: el
  targeting logra que la difusión empiece en muchas más aldeas, pero donde empieza sigue
  siendo un fenómeno pequeño.
- **No se puede rechazar que los tres algoritmos den lo mismo**: contagio simple contra
  complejo da p = 0,300, y complejo contra geográfico p = 0,102.

Ese último punto es el que hay que llevarse. Lo que el experimento muestra con firmeza es
que **alguna** regla de selección le gana al criterio del extensionista; cuál de las tres
es la mejor, estos datos no lo resuelven.

---

## Cómo correrlo

Necesita **R** (≥ 4.1). Lo único que hay que instalar a mano es `pacman`:

```r
install.packages("pacman")
```

El script arranca con `pacman::p_load(tidyverse, scales, fixest, broom)`, que instala lo
que falte y carga lo que ya esté.

Hay dos formas equivalentes de trabajar el lab:

**a) Script de R** (para ejecutar por bloques en clase):

```r
source("R/lab3-rct-redes.R")
```

> En **Positron / RStudio**: abra la carpeta `03_lab-redes-malawi` como directorio de
> trabajo y ejecute `R/lab3-rct-redes.R` por secciones (los bloques `# ===` separan cada
> parte) para ir mirando los datos en clase.

**b) Cuaderno Quarto** (mismo contenido, con explicaciones y salida en HTML):

```bash
quarto render lab3-rct-redes.qmd
```

Abra `lab3-rct-redes.html` (ya incluido en el repo) para leer el lab con prosa, tablas y
gráficas, sin necesidad de correr nada.

La parte más pesada es la **inferencia por aleatorización** de la sección 6: son 2.000
re-sorteos con su regresión, y toma unos pocos segundos. Todo lo demás es instantáneo.

---

## Los datos

`datos/beaman_redes_aldeas.rds` son las **200 aldeas** del experimento —la muestra exacta
de la Tabla 2 del paper—, y `datos/beaman_redes_socios.rds` son los **agricultores
socios**: los que cada algoritmo elegiría, con su centralidad en la red de la aldea. Ver
el [**codebook**](datos/codebook.md) para la descripción de cada columna y la
[**procedencia**](datos/SOURCE.md) de cada archivo.

- También están las versiones `.csv.gz` por si quiere inspeccionar el dato como texto
  plano (mismo contenido).
- Para reconstruir los subsets desde el paquete original, ver
  [`R/00-construir-datos.R`](R/00-construir-datos.R) (no hace falta para la clase).

**Fuentes:** depósito **openICPSR-130605**, bajo licencia
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0). La descarga **no se puede
automatizar**: exige cuenta de ICPSR y aceptar los términos de uso desde un navegador.
Este repositorio no versiona el paquete crudo, solo el subconjunto derivado y mínimo para
el ejercicio docente. Detalles en [`datos/SOURCE.md`](datos/SOURCE.md).

---

## Lecturas de la sesión

- **Beaman, L., BenYishay, A., Magruder, J. y Mobarak, A. M. (2021).** "Can Network
  Theory-Based Targeting Increase Technology Adoption?" *American Economic Review*,
  111(6), 1918–1943. [DOI: 10.1257/aer.20200295](https://doi.org/10.1257/aer.20200295).
- **Todaro, M. P. y Smith, S. C. (2020).** *Economic Development*, 13.ª ed., cap. 9 —
  transformación agrícola y desarrollo rural.
- **Pachón, F. A. (2021).** "Distribución de la propiedad rural en Colombia en el siglo
  XXI." *Revista de Economia e Sociologia Rural*, 60(4), e242402.
  [DOI: 10.1590/1806-9479.2021.242402](https://doi.org/10.1590/1806-9479.2021.242402).

---

## Para discutir en clase

- ¿Qué es exactamente lo que compra la aleatorización, y qué **no** compra? Compare con lo
  que hubo que defender en el Lab 2.
- Medir la red social completa de una aldea —quién habla con quién, casa por casa— es
  caro. Con lo que muestra la sección 7, ¿recomendaría pagar por medirla?
- El efecto sobre la tasa de adopción es de 3,6 puntos sobre una base de 3,8 %. ¿Eso es un
  éxito? ¿Cómo se conecta con el argumento de Todaro y Smith sobre por qué la
  transformación agrícola es lenta?

---

*Material del curso Economía del Desarrollo (06230), Universidad ICESI.
Datos: Beaman et al. (2021), openICPSR-130605 (CC BY 4.0).*
