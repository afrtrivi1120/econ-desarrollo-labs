# 06 — ¿Puede la IA verificar la investigación? Equipos humanos, asistidos por IA y dirigidos por IA

**Brodeur, A., Valenta, D., … et al. (2026).** "AI-assisted teams outperform AI-led teams but not human-only teams in assessing research reproducibility in quantitative social science." *Proceedings of the National Academy of Sciences*, 123(22), e2524747123. DOI: [10.1073/pnas.2524747123](https://doi.org/10.1073/pnas.2524747123)

| Tema | Método | Dónde | Código original | Paquete de réplica |
|---|---|---|---|---|
| Inteligencia artificial (IA) y productividad en trabajo de alta calificación; verificación de la ciencia | Experimento aleatorizado (equipos asignados a tres brazos) | Siete eventos en 2024: Toronto, Ottawa, Sheffield, Cornell, Bogotá, Tilburg y uno virtual | R (versión PNAS); Stata + R (versión inicial, en el Open Science Framework (OSF)) | GitHub `I4Replication/AI-Games`, ~17 MB (datos ~1 MB) |

---

## La pregunta

¿Ayuda ChatGPT a verificar si un artículo empírico se puede reproducir? Los autores comparan tres formas de trabajo: equipos de solo humanos, equipos asistidos por IA (usan ChatGPT como herramienta) y equipos dirigidos por IA (ChatGPT hace el trabajo con mínima supervisión humana). Miden quién reproduce los resultados, quién encuentra más errores de código y quién propone mejores pruebas de robustez.

## Por qué nos importa en Economía del Desarrollo

Es un experimento sobre productividad de la IA en una tarea de alta calificación, no en atención al cliente ni en ocupaciones de baja calificación (p. 2). Verificar un artículo cuesta: en 10 revistas de economía de primer nivel, cerca de USD 365 por estudio, y en la American Economic Association, unos USD 750 por artículo (p. 8). Si la IA autónoma reproduce una parte de los resultados, podría servir como filtro barato donde no alcanza el presupuesto para una revisión humana (resumen, p. 2), una restricción típica de universidades y entidades públicas en países como Colombia. Además, uno de los eventos fue en Bogotá, y usted hará en este curso exactamente la tarea que estudian: reproducir un artículo en R.

## Datos y diseño

- **Participantes:** 288 investigadores asignados a 103 equipos: 33 de solo humanos (92 investigadores), 35 asistidos por IA (93) y 35 dirigidos por IA (103) (pp. 2 y 4). Eran estudiantes de maestría y doctorado, posdoctorandos, profesores e investigadores con doctorado de organizaciones no académicas (p. 3).
- **Eventos:** siete "AI replication games" entre febrero y noviembre de 2024, incluido un piloto (p. 3). Los nombres de las sedes vienen de la variable `game` del paquete; el evento de Bogotá fue el 4 de octubre de 2024 (documento de trabajo IZA DP 17645, versión previa del artículo, Tabla S1).
- **Tarea:** cada equipo recibió un artículo publicado (12 estudios en total, algunos reutilizados), su paquete de réplica y capturas de las tablas a reproducir. Cada equipo tuvo siete horas para (i) reproducir resultados, (ii) detectar errores de código y (iii) proponer y ejecutar hasta dos pruebas de robustez (p. 3). Cada evento incluyó dos estudios con errores de código conocidos por los organizadores (p. 3).
- **IA:** suscripción de pago de ChatGPT (GPT-4 y luego GPT-4o, entre otros modelos) para los brazos con IA (p. 3).
- **Unidad de análisis:** el equipo (103 observaciones en la Tabla 2).

## Estrategia de identificación

La aleatorización se hizo en dos pasos dentro de cada evento: primero se asignó a cada participante a un equipo de tres, condicionando en su software preferido (Stata o R) y en su modalidad (presencial o virtual); después se asignó cada equipo a uno de los tres brazos (p. 3). Como el brazo es aleatorio, la diferencia de medias entre brazos estima el efecto causal de cada forma de trabajar. La Tabla 2 lo estima por mínimos cuadrados ordinarios (MCO) con el brazo de solo humanos como categoría omitida y controles por número de integrantes, efectos fijos de evento por software, efectos fijos del cargo máximo y mínimo del equipo y efectos fijos de modalidad (nota de la Tabla 2, p. 5). En el código (`code/main.R`) los errores estándar son robustos a heterocedasticidad.

> ⚠️ **El supuesto del que depende todo:** que cada brazo cumplió su protocolo. Los equipos dirigidos por IA no podían leer el artículo ni consultar datos o código, y los autores dependían de su integridad para que así fuera (p. 4). Si algunos "hicieron trampa", la brecha entre brazos estaría subestimada; si los equipos de solo humanos se esforzaron más por saberse observados (efecto Hawthorne, que los autores reconocen en la p. 8), estaría sobreestimada.

## Resultado principal

Los equipos de solo humanos y los asistidos por IA reproducen casi siempre: 94 % (31/33) y 91 % (32/35), frente a 37 % (13/35) de los dirigidos por IA (p. 4). En la Tabla 2, columna 1 (p. 5), ser un equipo dirigido por IA reduce la probabilidad de reproducir en 0,593 (error estándar 0,090) frente a solo humanos; la diferencia entre asistidos por IA y solo humanos es pequeña y no significativa (−0,018; error estándar 0,063). En errores mayores, los equipos de solo humanos encontraron en promedio 1,70, frente a 0,74 de los asistidos por IA y 0,23 de los dirigidos por IA (p. 6). Conclusión: la IA como asistente no empeoró la reproducción, pero tampoco la mejoró, y se asoció con menos errores mayores detectados.

## Qué replicar

- **Resultado objetivo:** la **Tabla 2** (p. 5), al menos la columna 1 (reproducción) y la columna 3 (errores mayores): MCO del resultado sobre los brazos con los controles descritos. Como paso previo, la Tabla 1 (medias por brazo, p. 5).
- **Dónde está en el paquete (GitHub, versión PNAS):** `code/cleaning.R` construye `data/AI games.rds` a partir de `data/AI games.xlsx` (hojas `Master`, `Errors` y `all known errors by paper`); `code/main.R` estima la Tabla 2 y escribe `output/tables/main.tex`; `code/branches.R` produce la Tabla 1. Todo se corre desde `code/master.R`. Al preparar esta guía se verificó que la especificación de `main.R`, aplicada a `data/AI games.rds`, reproduce los coeficientes y errores estándar de las columnas 1 y 3.
- **Dificultad:** **baja a media**. Son 103 filas y el código ya está en R. Lo difícil es la limpieza: `cleaning.R` lee fórmulas de Excel, agrega la hoja de errores por equipo y descarta el equipo `4R` de Cornell y los equipos de 2025. ⚠ No use el paquete de OSF llamado "initial submission Nature": reproduce las columnas 1 y 4–7 de la Tabla 2, pero no las columnas 2 y 3 (errores), porque los errores se recodificaron después. ⚠ En la Tabla 1, los valores entre paréntesis se describen como errores estándar, pero corresponden a desviaciones estándar (0,242 para una proporción de 0,939 con 33 equipos).
- **Trabajo en R:** no basta con correr `master.R`. Reescriba usted la cadena: lectura con `readxl`, limpieza con `tidyverse`, estimación con `fixest::feols` (efectos fijos y `vcov = "hetero"`) y tabla con `modelsummary`. Compare sus cifras con la Tabla 2. Como extensión, la Figura 1 (curvas de Kaplan–Meier del tiempo hasta reproducir) se hace con el paquete `survival`.

## Descargas

- **Paper:** no se incluye en el repositorio; las copias de la versión publicada llevan una marca de descarga. Es de acceso abierto en PNAS: <https://doi.org/10.1073/pnas.2524747123>.
- **Paquete de réplica:** <https://github.com/I4Replication/AI-Games> (versión de la publicación en PNAS, solo en R, recomendada). El proyecto en OSF, <https://osf.io/sz2g8/>, guarda el plan de preanálisis, los materiales de capacitación y el paquete de la versión inicial (Stata + R).
- **Script de descarga:** `R/descargar-datos.R` (descarga el paquete a `datos/_crudos/`).

## Licencias

Paper: Creative Commons Atribución-NoComercial-SinDerivadas 4.0 (CC BY-NC-ND 4.0) (p. 2). Repositorio en GitHub: código bajo licencia MIT; datos y figuras generadas bajo CC BY 4.0 (`LICENSE` y `LICENSE-data`). Proyecto en OSF: licencia MIT (titular: Abel Brodeur, 2025). El paper declara "no restrictions on sharing or reuse" para datos, código y materiales (p. 9).
