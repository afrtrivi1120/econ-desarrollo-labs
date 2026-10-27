# 03 — IA generativa sin salvaguardas: practicar mejor, aprender menos

**Bastani, H., Bastani, O., Sungu, A., Ge, H., Kabakcı, Ö. y Mariman, R. (2025).** "Generative AI without guardrails can harm learning: Evidence from high school mathematics." *Proceedings of the National Academy of Sciences*, 122(26), e2422633122. DOI: [10.1073/pnas.2422633122](https://doi.org/10.1073/pnas.2422633122)

| Tema | Método | Dónde | Código original | Paquete de réplica |
|---|---|---|---|---|
| Educación / capital humano | Experimento aleatorizado por salón (preregistrado), tres brazos | Turquía (un colegio de secundaria) | R (regresiones), Python y Stata (análisis adicionales) | GitHub `obastani/GenAICanHarmLearning`, ~100 MB |

---

## La pregunta

Un tutor basado en GPT-4 ayuda a resolver ejercicios, pero ¿ayuda a aprender? Los autores comparan estudiantes de matemáticas que practican con un chat tipo ChatGPT, con un tutor que no regala la respuesta o solo con libro y cuaderno, y luego miden su desempeño en un examen sin ayuda.

## Por qué nos importa en Economía del Desarrollo

El capital humano es un determinante central del desarrollo, y en Colombia se discute cómo llevar IA a las aulas. Este paper separa dos cosas que se suelen confundir: el desempeño *con* la herramienta (productividad) y lo que queda *sin* ella (aprendizaje). Si una tecnología sube lo primero y baja lo segundo, una política que solo mire resultados inmediatos puede deteriorar el capital humano.

## Datos y diseño

El experimento se hizo en un colegio de secundaria en Turquía durante el semestre de otoño del año escolar 2023–2024: cuatro sesiones de 90 minutos en unos cincuenta salones de grados 9.º, 10.º y 11.º, con cerca de 1.000 estudiantes (p. 2). Cada sesión tiene tres partes: repaso del profesor, práctica (donde actúa el tratamiento) y un examen individual sin libros ni computador, con problemas muy parecidos a los de la práctica (p. 2). La práctica y el examen cuentan para la nota; califican evaluadores independientes y se guardan todos los mensajes con los tutores (p. 3). La muestra principal excluye los cursos de honores y tiene 2.848 observaciones estudiante–sesión (Tabla 1, p. 4).

## Estrategia de identificación

Cada salón se asignó a uno de tres brazos: control (libro y apuntes, sin dispositivos), **GPT Base** (chat tipo ChatGPT con GPT-4) o **GPT Tutor** (el mismo chat, con instrucciones de dar pistas sin revelar la respuesta y con las soluciones y errores comunes que aportaron profesores) (pp. 2–3). Como en este colegio los estudiantes se asignan al azar a los salones (excepto los de honores), la asignación al brazo es aleatoria (p. 3). La ecuación (1) regresa el puntaje normalizado (0 a 1) sobre los dos brazos, el promedio del año anterior y efectos fijos de sesión, evaluador, grado y profesor, con errores agrupados por salón, la unidad de aleatorización (p. 3). Son estimaciones de intención de tratar (p. 4).

> ⚠️ **El supuesto del que depende todo:** que los salones de los tres brazos solo difieren en la herramienta usada durante la práctica. Fallaría si la composición de los salones no fuera realmente aleatoria, si la asistencia cambiara según el brazo o si el tratamiento conjunto (computador portátil + video + IA) hiciera algo distinto de lo que se le atribuye a la IA.

## Resultado principal

En la práctica, GPT Base sube el puntaje 0,137 y GPT Tutor 0,361 (sobre 1), frente a una media de control de 0,284: mejoras de 48 % y 127 % (Tabla 1, p. 4; p. 1). En el examen sin ayuda, GPT Base **baja** el puntaje en 0,054, un 17 % de la media del control; GPT Tutor no se distingue del control (−0,004) (Tabla 1, p. 4). El mecanismo propuesto es la "muleta": con GPT Base los estudiantes piden la respuesta y la copian. GPT Base acierta solo el 51 % de las veces en los 57 problemas de práctica (p. 5), y los estudiantes no perciben que aprendieron menos (p. 4).

## Qué replicar

- **Resultado objetivo:** Tabla 1 (p. 4), columnas (1) práctica y (2) examen. Como segundo paso, la Tabla 2 (p. 6): interacción entre brazo y tasa de error de GPT Base, a nivel de problema.
- **Dónde está en el paquete:** Tabla 1: `main_regressions/main_analysis.R` (primer bloque) con `main_regressions/final_data.csv`. Tabla 2: `main_regressions/problem_level_analysis.R` con `problem_part2.csv`, `problem_part3.csv`, `problem_mapping.csv` y `gpt_answers_full.csv`. Ojo: el README del repositorio dice que `final_data.csv` está en la raíz, pero está en `main_regressions/`; y `text_analysis/data/raw/question_list.csv` no viene en UTF-8, así que al leerlo indique la codificación (por ejemplo, `locale = locale(encoding = "latin1")` en `readr`).
- **Dificultad:** baja para la Tabla 1 (el código ya está en R y los datos son pequeños); media para la Tabla 2 (hay que entender el emparejamiento práctica–examen).
- **Trabajo en R:** pasar de `lm()` + `sandwich::vcovCL()` + `stargazer` a `fixest::feols()` con efectos fijos (`| teacher + Session + Grader + Year`) y `cluster = ~Class`; tablas con `modelsummary`.

## Descargas

- **Paper:** `paper/bastani2025_pnas.pdf` (CC BY-NC-ND 4.0). Corrección: `paper/bastani2025_correccion.pdf` ([10.1073/pnas.2518204122](https://doi.org/10.1073/pnas.2518204122)); corrige únicamente la afiliación de Osbert Bastani; la nota no modifica datos, tablas ni conclusiones.
- **Paquete de réplica:** [github.com/obastani/GenAICanHarmLearning](https://github.com/obastani/GenAICanHarmLearning).
- **Script de descarga:** `R/descargar-datos.R` (descarga el paquete a `datos/_crudos/`).

## Licencias

Paper y corrección: CC BY-NC-ND 4.0 (se redistribuyen sin modificación). Repositorio de datos y código: **sin licencia declarada**; los autores piden citar el paper.
