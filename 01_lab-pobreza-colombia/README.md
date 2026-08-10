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
| **De la microdata cruda al subset** | Qué trae cada archivo del DANE, qué significa cada variable y qué se transforma | — |
| **Una mirada a los datos** | Entender el **factor de expansión** | — |
| **Ingreso por quintil** | 2019 vs 2021 y la brecha Q5/Q1 | `figuras/2a-ingreso-por-quintil.png` |
| **Pobreza 2019 vs 2021** | Tasa monetaria y extrema, antes/después | `figuras/3-pobreza-antes-despues.png` |
| **¿Quién es pobre?** | Perfil por edad y educación (estilo Banco Mundial) | `figuras/4a-…`, `figuras/4b-…` |
| **Síntesis** | Guardar gráficas y cerrar para discutir | — |

> La primera sección es nueva: el lab ya no arranca de un archivo limpio caído del cielo. Se abre
> la microdata del DANE tal como la publica —con nombres como `p6210` y respuestas en
> código— y se muestra cada decisión de limpieza, porque cada una cambia los resultados.

**Resultados que reproduce el código** (cifras oficiales DANE):

- Pobreza monetaria: **35,7 % (2019) → 39,3 % (2021)**.
- Pobreza extrema: **9,6 % (2019) → 12,2 % (2021)**.
- El quintil más rico (Q5) concentra **~57 %** del ingreso.
- El pobre sigue siendo **joven** (entre 34,8 % y 36,1 % de los pobres tiene 0–14 años,
  según el año) y de **baja escolaridad** (entre 87,9 % y 89,5 % de los pobres de 15 años
  o más tiene secundaria o menos).

---

## Cómo correrlo

Necesitas **R** (≥ 4.1). Lo único que hay que instalar a mano es `pacman`:

```r
install.packages("pacman")
```

Los dos scripts de `R/` arrancan con `pacman::p_load(...)`, que instala lo que falte y
carga lo que ya esté: el lab carga `tidyverse, scales, data.table, R.utils` y
`00-recortar-crudos.R` los mismos menos `scales`. (`data.table` entra por `fread()`, que
lee rápido y maneja el decimal con coma de 2019; `R.utils` le permite abrir los `.gz`.)

Hay dos formas equivalentes de trabajar el lab:

**a) Script de R** (para ejecutar por bloques en clase):

```r
source("R/lab1-distribucion-ingreso.R")
```

> En **Positron / RStudio**: abre `R/lab1-distribucion-ingreso.R` y ejecútalo por
> secciones (los bloques `# ===` separan cada parte) para ir mirando los datos en clase.

**b) Cuaderno Quarto** (el mismo análisis, con explicaciones y salida en HTML):

```bash
quarto render lab1-distribucion-ingreso.qmd
```

Abre `lab1-distribucion-ingreso.html` (ya incluido en el repo) para leer el lab con
prosa, tablas y gráficas, sin necesidad de correr nada.

Ambos arrancan en `datos/_crudos/` y corren en pocos segundos. Si esos archivos no
están, el lab lo avisa y sigue con `datos/geih_pobreza_2019_2021.rds`, el subset ya
construido, para que la clase no se caiga.

---

## Los datos

La carpeta `datos/` tiene **tres capas**:

| Qué | Para qué |
|---|---|
| `_crudos/*.csv.gz` | La **microdata del DANE** con sus nombres y códigos originales. Es donde arranca el lab. |
| `geih_pobreza_2019_2021.rds` | El **subset ya construido** (1.467.444 personas). Sirve de respaldo si no están los crudos. |
| `diccionario-dane/*.xml` | El **diccionario oficial** del DANE (formato DDI): de ahí salen, textualmente, las definiciones de cada variable. |

Ver el [**codebook**](datos/codebook.md) para la descripción de cada columna —crudas y
limpias— y la [**procedencia**](datos/SOURCE.md) para saber cómo se bajan y se recortan
los archivos del portal.

> ⚠️ Los archivos de `_crudos/` son un **extracto**: las mismas filas y los mismos
> códigos que publica el DANE, pero solo con las columnas que el lab usa. Los archivos
> completos traen cientos de MB —137 columnas el de personas— y no caben en el
> repositorio. Como no se
> quita ninguna fila, el extracto reproduce exactamente las cifras oficiales.

La cadena de datos queda completa y reproducible en dos pasos:

```
CSV completos del DANE  ──[R/00-recortar-crudos.R]──▶  _crudos/*.csv.gz  ──[sección 1 del lab]──▶  .rds
   474 MB, no van al repo                                12 MB, sí van                         subset limpio
```

`R/00-recortar-crudos.R` **no se corre en clase**: el extracto ya viene listo. Está para
que el recorte no sea un paso a mano perdido en la terminal de alguien.

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
