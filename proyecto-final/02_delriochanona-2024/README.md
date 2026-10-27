# 02 — ChatGPT y el conocimiento público: la caída de Stack Overflow

**del Rio-Chanona, R. M., Laurentsyeva, N. y Wachs, J. (2024).** "Large language models reduce public knowledge sharing on online Q&A platforms." *PNAS Nexus*, 3(9), pgae400. DOI: [10.1093/pnasnexus/pgae400](https://doi.org/10.1093/pnasnexus/pgae400)

| Tema | Método | Dónde | Código original | Paquete de réplica |
|---|---|---|---|---|
| Bienes públicos digitales / tecnología | Diferencias en diferencias (DiD) con plataformas de comparación + estudio de eventos | Global (Stack Overflow vs. foros en ruso, chino y de matemáticas) | Stata + Python (Jupyter) | Zenodo `12670482`, un solo `.zip` de ~2,9 GB |

---

## La pregunta

Cuando un programador le pregunta a ChatGPT en vez de publicar su duda en un foro, la respuesta queda en una conversación privada y no en un repositorio público. ¿Redujo ChatGPT la producción de conocimiento público en Stack Overflow, el mayor foro de preguntas y respuestas de programación? ¿Desplazó solo las preguntas fáciles o malas, o también contenido valioso?

## Por qué nos importa en Economía del Desarrollo

Stack Overflow es un bien público: no rival, no excluible y gratuito para cualquier programador con internet, incluidos los de Colombia. Si los modelos de lenguaje desplazan esa producción, el conocimiento pasa del dominio público a bases de datos privadas, con efectos sobre la difusión tecnológica, la formación de capital humano y la competencia en el sector (pp. 8–10). Además, es un DiD transparente con muy pocas unidades, ideal para discutir tendencias paralelas (Unidad 4).

## Datos y diseño

Los datos vienen de los volcados públicos de Stack Exchange en archive.org (Stack Overflow, su versión en ruso, Mathematics y Math Overflow) y de Segmentfault, un foro chino de programación (pp. 2–3). Solo Stack Overflow tiene 58 millones de publicaciones (p. 3). El análisis principal agrega a nivel plataforma–semana entre enero de 2022 y mayo de 2023: 48 semanas antes del lanzamiento de ChatGPT y 25 después (p. 3). También usa los votos de cada publicación, la experiencia previa del autor y las etiquetas de lenguaje de programación.

## Estrategia de identificación

Diferencias en diferencias: Stack Overflow es la plataforma tratada; las cuatro de comparación están menos expuestas a ChatGPT, porque este no estaba disponible oficialmente en Rusia ni en China, o porque entonces resolvía mal matemáticas avanzadas (p. 2). La ecuación es Log(Posts) = efectos fijos de plataforma + efectos fijos de semana + β × (Stack Overflow × post-ChatGPT), con tratamiento desde la semana del 27 de noviembre de 2022 y errores agrupados por mes (p. 3). Un estudio de eventos con un coeficiente por semana permite revisar tendencias previas (p. 3; Figura 2).

> ⚠️ **El supuesto del que depende todo:** sin ChatGPT, la actividad en Stack Overflow habría evolucionado igual que en las plataformas de comparación. Fallaría si estas también fueron afectadas (VPN en Rusia y China, mejoras en matemáticas), lo que según los autores sesga el efecto hacia cero (p. 3), o si hubo otro choque propio de Stack Overflow en esas semanas.

## Resultado principal

Seis meses después del lanzamiento, la actividad en Stack Overflow cayó 25 % frente a las plataformas de comparación (p. 1); el efecto promedio del periodo posterior es de 15 % (1 − e^−0,163) (p. 4; Tabla 1, p. 5). La calidad medida por votos no cambia, y la caída ocurre entre usuarios inexpertos, con experiencia y expertos; solo los usuarios nuevos caen poco (pp. 5 y 7). Los lenguajes más usados, como Python y JavaScript, caen más (p. 6). Los autores leen el 25 % como una cota inferior (p. 7).

## Qué replicar

- **Resultado objetivo:** Tabla 1, columna (1) (p. 5): coeficiente de Stack Overflow × Post-GPT sobre el logaritmo de publicaciones semanales. Segundo paso: la Figura 2 (p. 6), el estudio de eventos semana a semana.
- **Dónde está en el paquete:** `replication/04_DID_posts.do`, que llama a `replication/codes/did1.do` y lee `replication/data/time_series_from_2016-11-01.csv`. Produce `tables/did_table_baseline_2022.tex` (Tabla 1) y `plots/event_log_posts40_2022.pdf` (Figura 2). La `readme.txt` del paquete numera las tablas distinto (incluye las del suplemento).
- **Dificultad:** baja-media — el panel tiene 370 observaciones (Tabla 1); lo pesado es descargar el `.zip` de ~2,9 GB, porque Zenodo no permite descargar archivos sueltos.
- **Trabajo en R:** `fixest::feols()` con el logaritmo de publicaciones, la interacción Stack Overflow × post-ChatGPT, efectos fijos de plataforma y semana, y `cluster` por mes (Tabla 1); interacciones semana × Stack Overflow con `i()` e `iplot()` (Figura 2); `modelsummary` para la tabla.

## Ideas para el análisis adicional

1. **⭐ ¿También cayó Stack Overflow en español?** — Hay versiones de Stack Overflow en español y portugués, con la misma estructura de datos. Colombia y la mayor parte de América Latina no están entre los lugares donde, según el paper, ChatGPT no estaba disponible (p. 2), así que esas comunidades se pueden tratar como unidades *tratadas* (verifique la disponibilidad por país antes de afirmarlo). Construya la serie semanal de publicaciones de es.stackoverflow.com y pt.stackoverflow.com entre enero de 2022 y mayo de 2023 (la ventana del paper: después los controles dejan de ser válidos, p. 7) y estime el DiD contra las mismas plataformas de comparación. ¿La caída es mayor o menor que en inglés? Si hay menos datos de entrenamiento en español, el mecanismo del paper (más caída donde hay más datos, p. 6) predice una caída menor. *Datos:* [volcados de Stack Exchange en archive.org](https://archive.org/details/stackexchange): `es.stackoverflow.com.7z` (~528 MB) y `pt.stackoverflow.com.7z` (~457 MB), corte de abril de 2024; se abren con 7-Zip y `Posts.xml` debe leerse por partes.
2. **Desarrolladores latinoamericanos en la encuesta de 2023** — El paquete trae la encuesta de desarrolladores de Stack Overflow de 2023 (89.184 respuestas de 185 países, p. 3). Reestime la relación entre usar ChatGPT y visitar o contribuir a Stack Overflow (`08_SO_survey_results.do`) solo para América Latina o Colombia, con `fixest::feglm()`. Revise antes cuántos encuestados hay por país. *Datos:* `data/stack-overflow-developer-survey-2023.zip`, dentro del paquete.
3. **¿Se programa menos o solo se pregunta menos?** — Compare la serie trimestral de desarrolladores activos y *git pushes* en Colombia con la actividad de es.stackoverflow.com. Si la programación sigue creciendo mientras las preguntas caen, hay sustitución del foro, no menos actividad. *Datos:* [GitHub Innovation Graph](https://github.com/github/innovationgraph) (`developers.csv`, `git_pushes.csv`; por economía y trimestre desde 2020; CC0).

## Para el Escéptico

- **Controles contaminados:** en Rusia y China se accede a ChatGPT por VPN, y los autores reconocen que no pueden medir cuánto (p. 8). Con controles parcialmente tratados, ¿qué mide β?
- **Pocas unidades:** una plataforma tratada, cuatro de comparación y errores agrupados por mes en una ventana corta. Haga inferencia por permutación: asigne el "tratamiento" a cada plataforma de comparación y vea si el coeficiente de Stack Overflow es atípico.
- **¿Viaja a Colombia?** Muchos programadores colombianos preguntan en español, en grupos cerrados o en comunidades locales que no quedan en ningún volcado público. Una caída en Stack Overflow no implica necesariamente menos conocimiento compartido aquí.

## Descargas

- **Paper:** `paper/delriochanona2024_pnasnexus.pdf` (CC BY 4.0).
- **Paquete de réplica:** [zenodo.org/records/12670482](https://zenodo.org/records/12670482).
- **Script de descarga:** `R/descargar-datos.R` (baja el paquete a `datos/_crudos/` y, si se activa, los volcados en español y portugués).

## Licencias

Paper: CC BY 4.0. Paquete de réplica (Zenodo): CC BY 4.0. Volcados de Stack Exchange: CC BY-SA 4.0, con atribución obligatoria a la red Stack Exchange. GitHub Innovation Graph: CC0 1.0.
