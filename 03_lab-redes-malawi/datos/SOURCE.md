# Procedencia de los datos

## Paper replicado

**Beaman, L., BenYishay, A., Magruder, J. y Mobarak, A. M. (2021).** "Can Network
Theory-Based Targeting Increase Technology Adoption?" *American Economic Review*,
**111**(6), 1918–1943. DOI: [10.1257/aer.20200295](https://doi.org/10.1257/aer.20200295).

Paquete de réplica: depósito **openICPSR-130605**, *Data and Code for: Can Network
Theory-based Targeting Increase Technology Adoption?*, versión V1 (2021-05-24),
<https://www.openicpsr.org/openicpsr/project/130605/version/V1/view>. El depósito trae
tres carpetas —`code/`, `data/`, `output/`— y un `ReadMe.pdf`.

## Fuentes de los archivos crudos

El ZIP se descomprime en `130605-V1/` con tres carpetas (`code/`, `data/`, `output/`) y un
`ReadMe.pdf`. El lab usa **los cinco** `.dta` de `data/`:

| Archivo | Contenido | Nivel | Alimenta |
|---|---|---|---|
| `data/mnw_public.dta` | 20.652 × 294. El microdato del experimento: adopción por temporada, brazo de la aldea, controles de línea base, marcas de semilla y sombra | agricultor × temporada | Tabla 2 |
| `data/panel_seed.dta` | 1.294 × 25. Los agricultores candidatos de cada algoritmo, con centralidad de vector propio y grado | agricultor candidato | Tabla 1 |
| `data/conversation.dta` | 52.814 × 24. Quién reportó haber hablado de siembra en hoyos con qué socio, por año | respondente × socio × año | Tabla 3 |
| `data/census.dta` | 15.957 × 23. El censo de línea base con las 12 variables del balance fino | agricultor | Tabla A5 |
| `data/ap_vout.dta` | 402 × 10. Simulaciones ya corridas de la difusión sobre la red real de cada aldea, bajo aprendizaje simple y complejo | aldea × año | Figura 2 |

> ⚠ **Los do-files usan nombres de variable abreviados.** Stata los completa solo cuando
> no hay ambigüedad, así que el código del paquete escribe `pp_adopted_1y`, `s_shadow`,
> `provganyu` y `useganyu` para variables que en los `.dta` se llaman `pp_adopted_1yr`,
> `s_shadow_farmer`, `provganyu_intro` y `useganyu_intro`. En R hay que escribir el nombre
> completo; si no, el script falla —lo cual está bien— o, peor, casa con otra columna.

> ⚠ **El paquete no trae un archivo a nivel de aldea.** Las dos variables de resultado de
> la Tabla 2 —«alguna adopción no-semilla» y la tasa de adopción— **se construyen** en
> `code/2_table2.do` a partir del microdato. Cualquier atajo en esa construcción cambia el
> número: por eso [`R/00-construir-datos.R`](../R/00-construir-datos.R) la replica paso por
> paso en vez de improvisar un colapso.

> ⚠ **Sobre la descarga.** `openicpsr.org` está detrás de Cloudflare y responde **403** a
> `curl`; un navegador automatizado recibe la pantalla de verificación anti-bot. Además, la
> descarga exige **iniciar sesión** (cuenta gratuita de ICPSR) y **aceptar los términos de
> uso** del depósito. No se puede automatizar: hay que abrir la página en un navegador,
> entrar con la cuenta, aceptar los términos y usar el botón *Download this project*. El
> ZIP se descomprime en `datos/_crudos/` (ignorado por git).

## Transformación

Los subsets de enseñanza se construyen con
[`R/00-construir-datos.R`](../R/00-construir-datos.R): selección de columnas, nombres en
español donde no rompe el puente con el paper, y dos variables derivadas —`brazo`, que
junta los tres dummies de tratamiento en un factor legible con `Benchmark` como base, y
`en_a3`, que marca la atrición del año 3—.

El script busca los `.dta` por nombre dentro de `datos/_crudos/`, sin importar en qué
subcarpeta hayan quedado, y **se detiene** si falta una variable, imprimiendo los nombres
que sí existen. Nunca rellena una columna a mano.

| Subset | Filas × columnas | Qué es |
|---|---|---|
| `beaman_redes_aldeas.rds` / `.csv.gz` | 200 × 19 | Las aldeas del experimento; unidad de la estimación principal. Incluye las simulaciones de la Figura 2 |
| `beaman_redes_socios.rds` / `.csv.gz` | 1.248 × 10 | Socios (semillas y sombras); verifica que los algoritmos eligieron gente distinta |
| `beaman_redes_conversaciones.rds` / `.csv.gz` | 43.525 × 12 | Pares respondente-socio; el mecanismo de la Tabla 3 |
| `beaman_redes_censo.rds` / `.csv.gz` | 14.909 × 21 | Censo de línea base; el balance fino de la Tabla A5 |

## Verificación

El subset reproduce la **Tabla 2, columna 1** del paper — «alguna adopción no-semilla» en
el año 2, las 200 aldeas, con los controles de la re-aleatorización, tamaño de aldea y su
cuadrado, y efectos fijos de distrito:

| | Réplica | Publicado |
|---|---|---|
| Contagio complejo | **0,2523** (EE 0,0928) | **0,252** (EE 0,093) |
| Contagio simple | 0,1547 (EE 0,1004) | 0,155 (EE 0,100) |
| Geográfico | 0,1066 (EE 0,0964) | 0,107 (EE 0,096) |
| Media del brazo Benchmark | 0,420 | 0,420 |
| Observaciones | 200 aldeas (141 en el año 3) | 200 (141) |

Las tres pruebas de igualdad de coeficientes también dan los valores publicados hasta el
tercer decimal: simple = complejo **0,300**, complejo = geo **0,102**, simple = geo
**0,623**. Para eso hay que usar la **t** con 199 grados de libertad (clústeres − 1); con
la normal darían 0,298, 0,100 y 0,622.

La **Tabla 1** también replica exacto —grado 17,491 / 13,392 en el brazo complejo contra
17,49 / 13,39 publicados—, pero solo si los empates se resuelven con
`rank(..., ties.method = "min")`, el equivalente de `egen rank(), track` de Stata. Ver
[`codebook.md`](codebook.md), sección «Los empates deciden la Tabla 1».

El lab replica además, y también exacto:

| Tabla / figura | Réplica | Publicado |
|---|---|---|
| **Tabla 3** — efecto de capacitar sobre las conversaciones | 0,0369 (0,0076) · 0,0503 (0,0075) · 0,0640 (0,0095); n = 15.115 / 16.704 / 11.607 | 0,037 (0,008) · 0,050 (0,008) · 0,064 (0,009); mismas n |
| **Tabla A5** — balance con 12 variables de agricultor | 2 de 12 con p conjunta < 0,10: vivienda 0,057 y tamaño de finca 0,071 | «10 de 12 sin diferencias»; el tamaño de finca es el caso señalado, significativo al 10 % |
| **Figura 2** — simulaciones contra datos, año 2 | simple 0,803 / 0,810 / 0,943 / 0,923 · complejo 0,371 / 0,425 / 0,332 / 0,715 | 0,80 / 0,81 / 0,94 / 0,92 · 0,37 / 0,42 / 0,33 / 0,72 |

Las columnas 2 a 4 (año 3 con 141 aldeas, y tasa de adopción en ambos años) también se
corren en el lab y se contrastan contra los valores publicados en los comentarios
`# esperado:` de [`R/lab3-rct-redes.R`](../R/lab3-rct-redes.R).

## Licencia / atribución

El depósito openICPSR-130605 declara explícitamente
**[Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0)**
→ veredicto **`redistributable`**: se puede redistribuir, incluso modificado y con fines
comerciales, siempre que se dé atribución.

Aun así, este repositorio **no versiona el paquete crudo** (pesa de más y vive en
`datos/_crudos/`, ignorado por git): solo el subconjunto derivado y mínimo que el
ejercicio docente necesita, con la atribución completa. Es la misma política del Lab 2,
acá por economía de espacio y no por restricción legal.

En cualquier uso, la cita obligatoria es la del paper:

> Beaman, L., BenYishay, A., Magruder, J. y Mobarak, A. M. (2021). Can Network
> Theory-Based Targeting Increase Technology Adoption? *American Economic Review*, 111(6),
> 1918–1943.

Y la del depósito de datos:

> Beaman, Lori, Ariel BenYishay, Jeremy Magruder y Ahmed Mushfiq Mobarak. Data and Code
> for: Can Network Theory-based Targeting Increase Technology Adoption? Nashville, TN:
> American Economic Association [publisher], 2021. Ann Arbor, MI: Inter-university
> Consortium for Political and Social Research [distributor]. openICPSR-130605.
