# Lab 1 — La distribución del ingreso en Colombia: una foto antes y después de la pandemia

**Economía del Desarrollo (06230) · Universidad Icesi · Departamento de Economía**

Este laboratorio usa las encuestas de hogares de Colombia (**GEIH–DANE**) de **2019** y
**2021** para mirar, con datos reales, dos cosas que vimos en las lecturas de la sesión:

1. **La distribución del ingreso** (no solo el promedio) — en la línea de
   Sala-i-Martin (2006): el promedio esconde quién gana qué.
2. **Quién es pobre** — edad, género y nivel educativo — replicando el perfil del
   pobre del informe del **Banco Mundial (2020)**, *Poverty and Shared Prosperity*.

La pregunta de fondo: **¿cómo se ve la distribución del ingreso colombiano antes
(2019) y después (2021) del choque de la pandemia?**

> ⚠️ **Esto es descriptivo, no causal.** Es una *foto* antes/después. Entre 2019 y
> 2021 cambió la pandemia, pero también muchas otras cosas (precios, política social,
> migración…). No hay grupo de comparación ni contrafactual, así que **no podemos
> atribuir los cambios a la pandemia**. Esa frontera —de la descripción a la
> causalidad— es justamente el hilo de la Unidad 1.

---

## ¿Qué vamos a ver en clase?

| Sección | Qué hacemos | Gráfica |
|---|---|---|
| 1 | Mirar los datos y entender el **factor de expansión** | — |
| 2 | **Ingreso por quintil** 2019 vs 2021 y la brecha Q5/Q1 | `figuras/2a-ingreso-por-quintil.png` |
| 3 | **Tasa de pobreza** monetaria y extrema, antes/después | `figuras/3-pobreza-antes-despues.png` |
| 4 | **Perfil del pobre** por edad y educación (estilo Banco Mundial) | `figuras/4a-…`, `figuras/4b-…` |
| 5–6 | Guardar gráficas y **síntesis** para discutir | — |

**Resultados que reproduce el código** (cifras oficiales DANE):

- Pobreza monetaria: **35,7 % (2019) → 39,3 % (2021)**.
- Pobreza extrema: **9,6 % (2019) → 12,2 % (2021)**.
- El quintil más rico (Q5) concentra **~57 %** del ingreso.
- El pobre sigue siendo **joven** (≈36 % de los pobres tiene 0–14 años) y de **baja
  escolaridad** (≈88 % tiene secundaria o menos).

---

## Cómo correrlo

Necesitas **R** (≥ 4.1). Lo único que hay que instalar a mano es `pacman`:

```r
install.packages("pacman")
```

El script arranca con `pacman::p_load(tidyverse, scales)`, que instala lo que falte y
carga lo que ya esté.

Hay dos formas equivalentes de trabajar el lab:

**a) Script de R** (para ejecutar por bloques en clase):

```r
source("R/lab1-distribucion-ingreso.R")
```

> En **Positron / RStudio**: abre `R/lab1-distribucion-ingreso.R` y ejecútalo por
> secciones (los bloques `# ===` separan cada parte) para ir mirando los datos en clase.

**b) Cuaderno Quarto** (mismo contenido, con explicaciones y salida en HTML):

```bash
quarto render lab1-distribucion-ingreso.qmd
```

Abre `lab1-distribucion-ingreso.html` (ya incluido en el repo) para leer el lab con
prosa, tablas y gráficas, sin necesidad de correr nada.

Ambos cargan `datos/geih_pobreza_2019_2021.rds` y corren en pocos segundos.

---

## Los datos

`datos/geih_pobreza_2019_2021.rds` es un **subconjunto de enseñanza** ya limpio:
1.467.444 personas (2019 + 2021) y solo las variables que necesitamos. Ver el
[**codebook**](datos/codebook.md) para la descripción de cada columna y la
[**procedencia**](datos/SOURCE.md) de la fuente.

- También está `datos/geih_pobreza_2019_2021.csv.gz` por si quieres inspeccionar el
  dato como texto plano (mismo contenido).
- Para reconstruir el subset desde la microdata cruda del DANE, ver
  [`R/00-construir-datos.R`](R/00-construir-datos.R) (no hace falta para la clase).

**Fuente:** Departamento Administrativo Nacional de Estadística (DANE) —
*Medición de Pobreza Monetaria y Desigualdad*, microdatos anonimizados de la GEIH
([2019, cat. 684](https://microdatos.dane.gov.co/index.php/catalog/684) ·
[2021, cat. 733](https://microdatos.dane.gov.co/index.php/catalog/733)).
Uso académico con la cita obligatoria: **«Fuente: DANE, www.dane.gov.co»**.

---

## Lecturas de la sesión

- **Sala-i-Martin, X. (2006).** "The World Distribution of Income: Falling Poverty
  and… Convergence, Period." *Quarterly Journal of Economics*, 121(2), 351–397.
- **World Bank (2020).** *Poverty and Shared Prosperity 2020: Reversals of Fortune.*
  Washington, DC: World Bank.

---

## Para discutir en clase

- ¿Por qué *no* podemos llamar a esto "el efecto de la pandemia"? ¿Qué necesitaríamos
  para acercarnos a un efecto causal?
- ¿La desigualdad (brecha Q5/Q1) subió o bajó? ¿Qué le falta a esa medida?
- ¿El perfil del pobre en Colombia se parece al de la Figura O.5 del Banco Mundial?

---

*Material del curso Economía del Desarrollo (06230), Universidad Icesi. Datos: DANE.*
