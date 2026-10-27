# 04 — ¿Qué tan expuestas están las ocupaciones a los modelos de lenguaje?

**Eloundou, T., Manning, S., Mishkin, P. y Rock, D. (2024).** "GPTs are GPTs: Labor market impact potential of LLMs." *Science*, 384(6702), 1306–1308. DOI: [10.1126/science.adj0998](https://doi.org/10.1126/science.adj0998)

| Tema | Método | Dónde | Código original | Paquete de réplica |
|---|---|---|---|---|
| Trabajo / cambio tecnológico | Medición (índice de exposición por tareas) | Estados Unidos | Python (Jupyter) + un `.do` de Stata | GitHub `openai/GPTs-are-GPTs`, ~22 MB sin historial git |

> **Advertencia sobre la versión.** En `paper/` está el *preprint* de arXiv, "GPTs are GPTs: An Early Look at the Labor Market Impact Potential of Large Language Models" (arXiv:2303.10130, versión 5, agosto de 2023; DOI: [10.48550/arXiv.2303.10130](https://doi.org/10.48550/arXiv.2303.10130)), que es largo y trae todas las tablas y figuras que se citan aquí. La versión publicada en *Science* ocupa solo tres páginas (1306–1308) y resume. Las páginas que se citan abajo son las del PDF del preprint.

---

## La pregunta

¿Qué parte del trabajo que hoy hacen las personas podría hacerse bastante más rápido con un modelo de lenguaje (LLM) como GPT-4? Los autores no preguntan si la IA "destruye empleos", sino qué tan *expuesta* está cada ocupación: qué fracción de sus tareas podría completarse en al menos la mitad del tiempo, con la misma calidad, usando un LLM o software construido sobre él.

## Por qué nos importa en Economía del Desarrollo

Este método sirvió de modelo al índice de la OIT que luego se aplicó a América Latina y a Colombia (paper 05 de esta lista). Entender cómo se construye, y qué supone, es requisito para leer con criterio cualquier cifra del tipo "X % del empleo está expuesto". Además, el índice se mide sobre las tareas de EE. UU.; llevarlo a un mercado laboral con alta informalidad y otra composición ocupacional es una pregunta de validez externa como las que trabajamos en el curso.

## Datos y diseño

- **Tareas:** base O\*NET 27.2, con 1.016 ocupaciones, 19.265 tareas y 2.087 actividades de trabajo detalladas (DWA) (p. 6).
- **Etiquetas:** cada tarea se clasifica con una rúbrica en E0 (sin exposición), E1 (exposición directa al LLM) o E2 (exposición si se construye software adicional). Las etiquetas vienen de anotadores humanos y de GPT-4 (pp. 7–8).
- **Medidas:** α = E1; β = E1 + 0,5·E2; ζ = E1 + E2. Si no se dice otra cosa, el paper usa β (pp. 8–9).
- **Empleo y salarios:** Occupational Employment Statistics de la BLS (2020 y 2021) y demografía de la CPS (p. 6).

## Estrategia de identificación

No hay un efecto causal que identificar: es un **paper de medición**. La "estrategia" es la construcción del índice: (1) etiquetar tareas con la rúbrica, (2) promediar a nivel de ocupación y (3) cruzar con empleo y salarios. Para validar la medida, los autores comparan etiquetas humanas con las de GPT-4 (Tabla 2, Figura 2) y con índices previos de exposición a la automatización (Sección 5).

> ⚠️ **El supuesto del que depende todo:** que una ocupación puede describirse como un conjunto de tareas separables y que el juicio de los anotadores (y de GPT-4) sobre "ahorro de al menos 50 % del tiempo" es razonable. Los propios autores lo dicen: si la descomposición por tareas no representa bien el trabajo real, "our exposure analysis would largely be invalidated" [invalidaría en buena parte nuestro análisis de exposición] (p. 9). Además, la exposición mide factibilidad técnica, no adopción ni efectos sobre el empleo (p. 3).

## Resultado principal

Según el resumen, cerca del 80 % de la fuerza laboral de EE. UU. podría tener al menos el 10 % de sus tareas afectadas y cerca del 19 % podría ver afectadas al menos la mitad de sus tareas (p. 1). La exposición aumenta con el salario de la ocupación (Figura 4, p. 13) y es casi independiente del tamaño del empleo de la ocupación (p. 12). Las ocupaciones intensivas en ciencia y pensamiento crítico muestran menor exposición; las intensivas en programación y escritura, mayor (Tabla 5, p. 17).

## Qué replicar

- **Resultado objetivo:** la **Figura 4** (gráfico de promedios por intervalos, o *binscatter*, de la exposición β contra el log del salario anual y el log del empleo, con etiquetas humanas y de GPT-4) y, como verificación previa, las medias por ocupación de la **Tabla 3** (p. 12).
- **Dónde está en el paquete:** `data/occ_level.csv` (exposición α, β y ζ por ocupación O\*NET-SOC, humana y GPT-4) + `data/national_May2021_dl.csv` (empleo y salarios BLS, mayo 2021). El código está en `code/gpts_are_gpts_script1.ipynb`, celdas "Merging in BLS data" y "Wage and employment binscatters" (función `generate_binscatter`).
- **Dificultad:** baja-media. Los datos ya vienen agregados por ocupación. Tres trampas que debe documentar: (i) el cuaderno lee la BLS desde una ruta (`../data/bls_oes/oesm21nat/...`) distinta del archivo que trae el repositorio; (ii) el cuaderno usa el log del salario **medio** (`A_MEAN`), mientras el pie de la Figura 4 habla del salario **mediano**; (iii) el cuaderno fija ponderación igual entre tareas, mientras el pie de la figura habla de doble peso a las tareas centrales. Reporte qué elige y por qué.
- **Trabajo en R:** cruzar por los primeros siete caracteres del código SOC con `dplyr`, limpiar los símbolos `*` y `#` de la BLS y reproducir el gráfico con `binsreg` o con `ggplot2` (promedios por veintiles).

## Ideas para el análisis adicional

1. **Exposición del empleo colombiano** — si se aplica β a la estructura ocupacional de Colombia, ¿qué fracción de los ocupados queda en ocupaciones con más de la mitad de sus tareas expuestas? Requiere pasar de SOC a CIUO-08 (la BLS publica la tabla ISCO-08 → SOC 2010, y otra SOC 2010 → SOC 2018) y luego cruzar con la GEIH. ⚠ Verifique en el diccionario de datos de la GEIH del año que use qué clasificación de ocupaciones tiene la variable de oficio; no lo suponga. *Datos:* [BLS, crosswalks SOC](https://www.bls.gov/soc/soccrosswalks.htm); [BLS, SOC 2010 → 2018](https://www.bls.gov/soc/2018/crosswalks.htm); [GEIH 2019, DANE](https://microdatos.dane.gov.co/index.php/catalog/599); [GEIH 2024, DANE](https://microdatos.dane.gov.co/index.php/catalog/819).
2. **Formalidad e informalidad** — el paper advierte que sus datos cubren sobre todo a asalariados en la economía formal (p. 6). Con la GEIH, ¿la exposición difiere entre trabajadores formales e informales de la misma ocupación? *Datos:* GEIH (enlaces arriba).
3. **Robustez frente a otro índice** — ¿qué tan correlacionado está β con el índice AIOE de Felten, Raj y Seamans (2021, *Strategic Management Journal*, DOI: [10.1002/smj.3286](https://doi.org/10.1002/smj.3286)), construido por habilidades y no por tareas? Ambos están en código SOC, así que el cruce es directo. *Datos:* [AIOE-Data/AIOE en GitHub](https://github.com/AIOE-Data/AIOE).

## Para el Escéptico

- **Etiquetas subjetivas y GPT-4 que se califica a sí mismo.** Los anotadores no representan la diversidad ocupacional y GPT-4 es sensible a la redacción del *prompt* (p. 9). ¿Cuánto cambian los resultados al usar la rúbrica 2 en lugar de la 1?
- **Exposición no es efecto.** Una tarea "expuesta" puede complementarse o sustituirse; el índice no distingue (p. 2) y no dice nada sobre cuándo se adopta la tecnología.
- **¿Viaja a Colombia?** Las tareas y su peso dentro de una ocupación vienen de O\*NET (EE. UU.). Un contador en Cali y uno en Chicago pueden tener conjuntos de tareas distintos, y la alta informalidad colombiana cambia quién tiene acceso a herramientas digitales.

## Descargas

- **Paper:** `paper/eloundou2023_arxiv2303.10130.pdf` (preprint de arXiv, CC BY-SA 4.0). La versión de *Science* está en el DOI.
- **Paquete de réplica:** <https://github.com/openai/GPTs-are-GPTs>
- **Script de descarga:** `R/descargar-datos.R` (baja el paquete a `datos/_crudos/`).

## Licencias

Preprint de arXiv: CC BY-SA 4.0. Repositorio `GPTs-are-GPTs`: MIT (Copyright 2024 OpenAI). Repositorio AIOE: sin licencia declarada (úselo solo para análisis; no redistribuya sus archivos). Microdatos GEIH: DANE; cite "Fuente: DANE".
