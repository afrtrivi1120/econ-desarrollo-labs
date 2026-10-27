# 04 — Cartas de presentación escritas con ChatGPT: ¿mejor señal, pero menos informativa?

**Abbas Nejad, K., Musillo, G., Zaccaria, N., & Wicker, T. (2026).** "Labor Market Signals: The Role of Large Language Models." *Journal of Labor Economics*, publicado en línea el 23 de octubre de 2026 (volumen, número y páginas aún sin asignar). DOI: [10.1086/744669](https://doi.org/10.1086/744669). Versión previa: CentER Discussion Paper 2025-003, Universidad de Tilburg, DOI: [10.2139/ssrn.5185035](https://doi.org/10.2139/ssrn.5185035).

| Tema | Método | Dónde | Código original | Paquete de réplica |
|---|---|---|---|---|
| Mercado laboral, señalización e inteligencia artificial (IA) | Dos experimentos aleatorizados + modelo estructural calibrado | Países Bajos (estudiantes de Tilburg y Utrecht); evaluadores en línea, la mayoría residentes en el Reino Unido | Stata (tablas); R y Python (medidas de texto); MATLAB (modelo) | Harvard Dataverse, un `.zip` de 2,8 MB, CC0 1.0 |

---

## La pregunta

Cuando una empresa recibe una carta de presentación, la usa como **señal** de la calidad del candidato. Los modelos de lenguaje grandes (LLM, por *large language models*), como ChatGPT, permiten escribir buenas cartas con poco esfuerzo. El paper pregunta dos cosas: ¿el acceso a un LLM mejora la carta que envía el candidato?, y si todos pueden escribir una buena carta, ¿la carta sigue diciendo algo sobre quién es bueno? Según los autores, los LLM pueden subir la calidad de la señal y, al mismo tiempo, reducir su **capacidad informativa**.

## Por qué nos importa en Economía del Desarrollo

Buena parte de la desigualdad en el acceso al empleo formal pasa por señales: el diploma, la universidad, la hoja de vida (CV) y la capacidad de escribir bien, muchas veces en inglés. Si un LLM le permite a un candidato con menos formación en redacción escribir una carta tan pulida como la de un egresado de una universidad de élite, la tecnología podría **igualar** oportunidades. Pero si con eso las empresas dejan de distinguir a los candidatos, el emparejamiento entre personas y puestos empeora, y las empresas pueden volver a apoyarse en señales más difíciles de imitar, como el nombre de la universidad o las redes de contactos, que suelen favorecer a quienes ya tenían ventaja. En Colombia, donde la redacción formal y el bilingüismo están muy desigualmente distribuidos, esa tensión entre igualar y perder información es central.

## Datos y diseño

**Experimento 1 (candidatos).** Estudiantes de la Universidad de Tilburg (TiU) y de la Universidad de Utrecht (UU) escribieron una carta de presentación para una vacante. La mitad, asignada al azar, pudo usar ChatGPT; la otra mitad no.

- 137 estudiantes: 72 en control y 65 en tratamiento (`Output/2_Appendix/TableA1.xlsx`, fila N).
- Cada carta fue calificada por 2 reclutadores, así que hay 274 evaluaciones (`Output/1_Main_Paper/Table1.tex`, fila Observations). En los datos finales aparecen 4 empresas y 8 reclutadores (`firm_num`, `recruiter_num` en `FinalData_forAnalysis.dta`).
- Los reclutadores califican de 0 a 10 cinco secciones de la carta (formato, introducción, experiencia, motivación y cierre), dan un puntaje total y una probabilidad de invitar a entrevista en escala de 1 a 5. En el código, `highchance` = 1 si esa probabilidad es mayor que 3 (`Code/1_Cleaning/Experiment_1/01_cleaning_dataset.do`).
- El paquete también trae medidas de texto ya calculadas: número de errores (LanguageTool), legibilidad (índices de Flesch) y longitud de palabras.

**Experimento 2 (evaluadores).** 401 evaluadores en línea calificaron cartas reales. Los 401 declaran recursos humanos (RR. HH.) entre sus funciones y 262 residen en el Reino Unido (`Data/Experiment_2/0_Raw_data/demographics_11_11.csv`). Cada uno vio 5 de un conjunto de 12, para un total de 2.005 evaluaciones (`Output/1_Main_Paper/Table3.tex`, fila N). Seis de las 12 cartas fueron escritas con ChatGPT (variable `CL_written_GPT`, construida en `Code/1_Cleaning/Experiment_2/01_cleaning_dataset.do`).

- Los evaluadores se asignaron al azar a tres brazos: control (132), información parcial (132) e información completa (137) (variable `Treatment` de `05_ols_dataset.dta`, etiqueta "0 = control; 1 = partial; 2 = full").
- Los brazos varían en cuánto sabe el evaluador sobre el uso de ChatGPT (p. 16): en el brazo de **control** (sin información) no se le dice nada; en **información parcial** se le dice que algunas cartas se escribieron con ayuda de ChatGPT y se le pide identificar cuáles; en **información completa** se le dice exactamente cuáles.
- El archivo crudo de evaluaciones está fechado en noviembre de 2024 (`HR_Evaluations_November 10, 2024_10.30.xlsx`). Los evaluadores se reclutaron en la plataforma Prolific (p. 15).

**Modelo.** Una sección final calibra un modelo estructural para cuantificar la pérdida de eficiencia en el emparejamiento (código en `Code_Simulation/`, MATLAB). No hace parte de lo que se pide replicar.

Las páginas que se citan son las del documento de trabajo de enero de 2026 que publican los autores (enlace en Descargas); pueden no coincidir con las de la versión de la revista (*Journal of Labor Economics*, JOLE).

## Estrategia de identificación

**Experimento 1.** El acceso a ChatGPT se asignó al azar entre estudiantes, con ambos grupos presentes en cada una de las 16 sesiones de escritura (variable `Session` en `personal_info_dataset.dta`). Por eso la diferencia promedio en el puntaje de la carta entre tratamiento y control estima el efecto causal de **tener acceso** a ChatGPT. La Tabla 1 lo estima por mínimos cuadrados ordinarios (MCO) con controles (puntaje de la hoja de vida, promedio académico, nivel de estudios, edad y género), efectos fijos de empresa × reclutador y de facultad, y errores estándar agrupados por estudiante. Para la probabilidad de entrevista usa un logit ordenado y, para `highchance`, un logit. El paquete trae controles de cumplimiento: historial del navegador (Tablas A10–A13, según los comentarios del código) y una lista de sitios bloqueados (Tabla A31, según el ReadMe).

**Experimento 2.** Aquí lo aleatorio es la **información** que recibe el evaluador, no la carta. Que una carta haya sido escrita con ChatGPT (`CL_written_GPT`) es un rasgo fijo de esas 6 cartas, no un tratamiento asignado al azar. Por eso:

- los coeficientes causales son los de `Partial` y `Full`, que miden el efecto de la información sobre la calificación de las cartas escritas sin ChatGPT;
- los de `part_clGPT` y `full_clGPT` miden cómo esa información cambia la brecha entre cartas con y sin ChatGPT;
- el coeficiente de `CL_written_GPT` por sí solo es descriptivo.

Los errores estándar se agrupan por evaluador.

> ⚠️ **El supuesto del que depende todo:** en el Experimento 1, que la única diferencia sistemática entre las cartas de los dos grupos sea el acceso a ChatGPT. El grupo de control no debe haber usado otro LLM y los reclutadores no deben haber calificado distinto por saber a qué grupo pertenecía cada carta. Si algunos estudiantes de control usaron un LLM a escondidas, el efecto estaría subestimado. Si los reclutadores conocían el grupo, la comparación dejaría de ser limpia. Según los autores, los reclutadores evaluaron cartas de ambos grupos sin conocer el grupo de cada una (pp. 3 y 7).

## Resultado principal

El resumen lo dice así:

> "We find that LLMs enhance signal quality, especially benefiting lower-quality applicants, yet these gains do not boost interview invitations because they are concentrated in standardized, less influential sections of the cover letter. When recruiters learn of LLM usage, they place greater value on high-quality, human-crafted letters. Hence, LLMs reduce the informativeness of signals, potentially increasing inefficiencies in labor market matching as estimated by a calibrated structural model."

Las tablas del paquete lo muestran así:

- **Calidad de la carta (Experimento 1).** El acceso a ChatGPT sube el puntaje total estandarizado en 0,222 desviaciones estándar, con error estándar (EE) de 0,117 (`Output/1_Main_Paper/Table1.tex`, col. 1). Las ganancias están en la introducción (0,253; EE 0,119; col. 3) y el cierre (0,281; EE 0,113; col. 6). No hay efecto distinguible de cero sobre la probabilidad de entrevista (0,249; EE 0,284; col. 7, logit ordenado) ni sobre `highchance` (0,011; EE 0,444; col. 8).
- **Errores de escritura (Experimento 1).** El tratamiento reduce el número de errores en 4,358 (EE 1,341), frente a una media de control de 11,931 (`Output/1_Main_Paper/Table2.tex`, col. 1; N = 137 cartas).
- **Información a los evaluadores (Experimento 2, tercil superior de cartas).** Entre las cartas mejor calificadas, las escritas con ChatGPT obtienen 0,48 desviaciones estándar menos en el brazo de control (EE 0,12; `Output/1_Main_Paper/Table4.tex`, col. 1, `CL_written_GPT`; N = 668). En la muestra completa, los coeficientes análogos son pequeños y no significativos (`Table3.tex`, col. 1).

## Qué replicar

- **Resultado objetivo:** la **Tabla 1, columnas 1–6** (efecto de ChatGPT sobre el puntaje total y por sección, MCO) y la **Tabla 4, columnas 1–6** (efecto de la información sobre la calificación de las cartas del tercil superior, MCO). Si queda tiempo: la Tabla 2 (errores y legibilidad) y las columnas 7–8 de la Tabla 1 (logit ordenado y logit).
- **Dónde está en el paquete:** las cuatro tablas principales salen de `Code/2_Analysis/1_Main_Analysis_code.do`:
  - Tabla 1: `Data/Experiment_1/2_Final/FinalData_forAnalysis.dta`.
  - Tabla 2: el mismo archivo, colapsado por estudiante y unido con `Data/Experiment_1/1_Raw/readability_error_rate.dta` y `word_length.dta`.
  - Tablas 3 y 4: `Data/Experiment_2/1_Final_data/04_fixedeffects_dataset.dta`; la Tabla 4 se limita a `CL_high_tercile == 1`.
  - Resultados publicados: `Output/1_Main_Paper/Table1.tex` a `Table4.tex`.
  - Al preparar esta guía se verificó en R (`fixest`) que la columna 1 de las Tablas 1, 2, 3 y 4 se reproduce con los datos finales, en coeficiente y error estándar al nivel de redondeo publicado.
- **No necesita la API de OpenAI.** Las medidas de texto ya vienen calculadas en los datos:
  - las calificaciones hechas por GPT (Tabla A6) están en `GPTgrades.dta`;
  - los errores y la legibilidad están en `readability_error_rate.dta`;
  - el número de mensajes a ChatGPT está en `Num_of_ChatGPT_prompts.dta`.

  Los textos de las cartas y las conversaciones con ChatGPT **no** están en el paquete (restricciones del comité de ética (IRB) y del Reglamento General de Protección de Datos de la Unión Europea (GDPR), según el ReadMe). Por eso no se pueden recalcular esas medidas ni la Figura 2. Tampoco hace falta.
- **Dificultad:** **baja a media.** Los datos son pequeños (274 y 2.005 filas) y ya están limpios. Tenga en cuenta cuatro trampas:
  1. El código usa `recruiter`, que Stata interpreta como abreviatura de la variable `recruiter_num`. En R hay que escribir el nombre completo.
  2. `gender` (1 = mujer, 2 = hombre, 3 = no binario) entra como control **lineal**, no como variables indicadoras.
  3. En `Table1.tex`, la fila "Control Group Mean" está corrida una columna en las columnas 6–8. El 2,799 de la col. 6 es la media de control de la probabilidad de entrevista y el 0,278 de la col. 7 es la de `highchance`. La causa es que `estadd` se ejecuta antes de `eststo` en esas ramas del código.
  4. La col. 8 (logit) usa 256 observaciones, no 274, porque Stata descarta las que predicen perfectamente el resultado.
- **Trabajo en R:** lea los `.dta` con `haven::read_dta()`. Estime con `fixest::feols()` (efectos fijos `firm_num^recruiter_num + school`, `cluster = ~IDNumber` en el Experimento 1 y `~recruiter_id` en el Experimento 2). Para las columnas 7–8, use `fixest::feglm(family = binomial)` para el logit y `MASS::polr()` u `ordinal::clm()` para el logit ordenado (⚠ el error estándar agrupado del logit ordenado no sale directo en R; repórtelo como limitación). Arme las tablas con `modelsummary`. Las pruebas t de las Tablas 3–4 se hacen con `t.test(..., var.equal = FALSE)`.

## Descargas

- **Paper:** no se redistribuye en este repositorio.
  - Versión publicada en JOLE: <https://doi.org/10.1086/744669> (acceso por la biblioteca de Icesi).
  - Documento de trabajo de enero de 2026, publicado por los autores: <https://twicker97.github.io/JM_documents/ChatGPT.pdf>.
  - Versión previa en SSRN (CentER Discussion Paper 2025-003): <https://doi.org/10.2139/ssrn.5185035>.
- **Paquete de réplica:** <https://doi.org/10.7910/DVN/LPIREO> (Harvard Dataverse, archivo único `ChatGPT_ReplicationPackage.zip`).
- **Script de descarga:** `R/descargar-datos.R` (descarga el paquete a `datos/_crudos/`).

## Licencias

- **Paquete de réplica:** CC0 1.0 (dominio público), según los metadatos de Harvard Dataverse.
- **Paper:** derechos reservados del editor. Según Crossref, el editor de JOLE es University of Chicago Press. La versión de SSRN es la versión previa de los autores. No se redistribuye ninguna de las dos.
