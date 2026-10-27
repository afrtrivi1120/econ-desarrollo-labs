# 01 — ChatGPT y la productividad de profesionales en tareas de escritura

**Noy, S. y Zhang, W. (2023).** "Experimental evidence on the productivity effects of generative artificial intelligence." *Science*, 381(6654), 187–192. DOI: [10.1126/science.adh2586](https://doi.org/10.1126/science.adh2586)

| Tema | Método | Dónde | Código original | Paquete de réplica |
|---|---|---|---|---|
| Trabajo / productividad | Experimento aleatorizado en línea (preregistrado) | Estados Unidos (plataforma Prolific) | Stata (+ Python auxiliar) | OSF `xd7qw`, ~10 MB comprimido |

---

## La pregunta

¿Qué le pasa a la productividad de un trabajador calificado cuando puede usar ChatGPT en una tarea de escritura propia de su oficio? Los autores miden cuánto tarda en terminarla y qué tan buena queda, y preguntan si la herramienta cierra o amplía la brecha entre trabajadores buenos y malos.

## Por qué nos importa en Economía del Desarrollo

La productividad laboral es el motor del ingreso per cápita, y buena parte del empleo calificado en Colombia (gerencia, mercadeo, recursos humanos, consultoría) consiste en producir textos como los de este experimento. Si una herramienta gratuita reduce el tiempo de esas tareas y favorece más a los menos productivos, cambia la discusión sobre capital humano, desigualdad dentro de las ocupaciones y brechas de adopción tecnológica entre países. Es, además, un experimento aleatorizado limpio, el método de la Unidad 5.

## Datos y diseño

Participan 453 profesionales con título universitario reclutados en Prolific (pp. 1 y 3), de seis ocupaciones: mercadeo, redacción de propuestas de financiación, consultoría, análisis de datos, recursos humanos y gerencia (p. 3). El experimento se hizo entre el 27 de enero y el 21 de febrero de 2023, con GPT-3.5 (p. 3). Cada persona hizo dos tareas de 20 a 30 minutos, con bonificación según la calidad; cada texto lo calificaron, sin conocer el grupo, tres evaluadores de la misma ocupación en una escala de 1 a 7 (p. 3). La versión de trabajo de marzo de 2023 reporta otra muestra (444 personas): use la del manuscrito publicado.

## Estrategia de identificación

El 50 % de los participantes fue asignado al azar al tratamiento (p. 3). Entre la primera y la segunda tarea, los tratados se registraron en ChatGPT y podían usarlo en la segunda; los controles se registraron en Overleaf, para igualar el costo del registro (p. 3). La regresión usa como resultado el **cambio** de cada persona entre la tarea 1 y la 2, contra una variable indicadora de tratamiento, con efectos fijos de ocupación × orden de tarea y de esquema de incentivos; para las calificaciones agrega efectos fijos de evaluador y agrupa errores por persona (nota de la Figura 1, p. 12).

> ⚠️ **El supuesto del que depende todo:** que, gracias al sorteo, los grupos solo difieren en el acceso a ChatGPT en la segunda tarea. Fallaría si la deserción selectiva cambia la composición de los grupos (6 % en control y 11 % en tratamiento, p. 3) o si muchos controles usaron ChatGPT por su cuenta (entre 10 y 20 %, p. 4), lo que diluye el contraste.

## Resultado principal

Los tratados tardaron 11 minutos menos (0,75 desviaciones estándar) en la segunda tarea, frente a un control que tardó en promedio 27 minutos, y su calificación subió 0,45 desviaciones estándar (p. 4); el resumen del paper lo presenta como 40 % menos tiempo y 18 % más calidad (p. 1). La desigualdad se reduce: la correlación entre la nota de la tarea 1 y la de la tarea 2 es 0,41 en el control y 0,14 en el tratamiento (p. 5). Ganan más quienes empezaron peor. Casi todos los tratados entregaron el texto de ChatGPT con pocas ediciones (p. 5).

## Qué replicar

- **Resultado objetivo:** Figura 1, paneles A y B (p. 12): efecto sobre el tiempo (−0,75 desviaciones estándar) y sobre la calificación (0,41 desviaciones estándar) en los esquemas de incentivos "lineal" y "convexo". El texto dice 0,45 y la figura 0,41 desviaciones estándar: explique de dónde sale la diferencia.
- **Dónde está en el paquete:** `code/4 - main text figures.do`, bloques `foreach sample in all linconv exact` (regresiones) y `foreach loop in noexact yesexact all` (gráficas `sc_did_*.pdf`). Antes corren `code/1 - employment data.do`, `code/2 - clean.do` y `code/3 - grade cleaning_jul21.do` (la ReadMe del 21-07-2023 pide esta versión). Insumos: `raw/fullsurvey.csv`, `raw/employmentdata.csv`, `raw/grading_long_complete.csv`, `raw/grading.xlsx`, `raw/grading_retry.xlsx`.
- **Dificultad:** media-alta — datos pequeños, pero la limpieza en Stata es larga (filtros de muestra, control de calidad de evaluadores, cambio de formato).
- **Trabajo en R:** limpieza con `tidyverse` y `readxl`; estimación con `fixest::feols()`; reescalar por la desviación estándar pretratamiento; gráficas con `ggplot2` y tablas con `modelsummary`.

## Descargas

- **Paper:** no se puede redistribuir (copyright de *Science*). Versión editorial: [doi.org/10.1126/science.adh2586](https://doi.org/10.1126/science.adh2586). Versión de trabajo abierta (marzo de 2023, muestra distinta): [Noy_Zhang_1_0.pdf](https://economics.mit.edu/sites/default/files/inline-files/Noy_Zhang_1_0.pdf).
- **Paquete de réplica:** [osf.io/xd7qw](https://osf.io/xd7qw).
- **Script de descarga:** `R/descargar-datos.R` (descarga el paquete a `datos/_crudos/`).

## Licencias

Paper: © AAAS (*Science*); no se incluye en el repositorio. Paquete de réplica en OSF: público, **sin licencia declarada**; úselo con fines académicos y cite el paper.
