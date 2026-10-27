# 05 — IA generativa y brecha digital: ¿amortiguador o cuello de botella en América Latina?

**Gmyrek, P., Winkler, H. y Garganta, S. (2024).** "Buffer or Bottleneck? Employment Exposure to Generative AI and the Digital Divide in Latin America." *ILO Working Paper* 121. Ginebra: OIT y Banco Mundial. DOI: [10.54394/TFZY7681](https://doi.org/10.54394/TFZY7681). Publicado también como *World Bank Policy Research Working Paper* 10863, DOI: [10.1596/1813-9450-10863](https://doi.org/10.1596/1813-9450-10863)

| Tema | Método | Dónde | Código original | Paquete de réplica |
|---|---|---|---|---|
| Trabajo / brecha digital / desigualdad | Medición (imputación de un índice de exposición a microdatos de hogares) | 16 países de América Latina y el Caribe (ALC) con SEDLAC; Colombia como ejemplo | Stata + R | World Bank Reproducible Research Repository, RR_LAC_2024_168, zip de ~9 MB |

---

## La pregunta

¿Qué fracción del empleo latinoamericano está expuesta a la IA generativa, quiénes son esos trabajadores y cuántos de ellos no podrán aprovechar la tecnología porque no usan un computador en el trabajo? La pregunta de fondo está en el título: ¿la brecha digital protege a los trabajadores de la automatización (amortiguador) o les impide ganar productividad (cuello de botella)?

## Por qué nos importa en Economía del Desarrollo

Casi toda la evidencia sobre IA y empleo viene de países ricos. Este trabajo adapta la medición a países con alta informalidad y acceso digital desigual, que es la situación de Colombia. Conecta cambio tecnológico, brecha de género e informalidad, y usa a Colombia (GEIH 2019) como ejemplo del análisis dentro de un país.

## Datos y diseño

- **Índice de exposición:** puntajes de Gmyrek, Berg y Bescond (2023, "GBB"; *Generative AI and jobs: a global analysis of potential effects on job quantity and quality*, OIT, DOI: [10.54394/FHEM8239](https://doi.org/10.54394/FHEM8239)) para los 436 grupos ocupacionales de CIUO-08 a 4 dígitos, construidos pidiéndole a GPT-4 calificar 3.123 tareas (Recuadro 1, p. 16). Con la media y la desviación estándar de cada ocupación se clasifica en "automatización", "aumento" (*augmentation*), "la gran incógnita" o no expuesta.
- **Microdatos:** encuestas de hogares armonizadas de SEDLAC para 16 países, unas 900.000 observaciones (p. 16). Para Colombia: GEIH 2019, con 756.063 observaciones, 316.870 usadas para exposición (Tabla A1, p. 41).
- **Uso de computador:** un logit estimado en PIAAC (OCDE) predice la probabilidad de usar computador en el trabajo según ocupación a 2 dígitos, edad, sexo, educación y variables de país (ecuación 1, p. 20); esa probabilidad se imputa en SEDLAC.

## Estrategia de identificación

Es un **paper de medición**, no causal. El reto es empalmar fuentes: Colombia solo tiene ocupación a 2 dígitos de CIUO-08 en SEDLAC, así que los autores calculan, con microdatos de la OIT a 4 dígitos, qué fracción de cada grupo de 2 dígitos cae en cada categoría (por sexo) y luego imputan esas fracciones a cada persona de la GEIH (pp. 17–18).

> ⚠️ **El supuesto del que depende todo:** que una misma ocupación tiene la misma exposición en un país rico y en uno de ingreso medio, y que usar computador en el trabajo es un requisito mínimo para beneficiarse de la IA generativa (pp. 10 y 22). Si las tareas de un mismo oficio cambian con el desarrollo, o si la gente usa la IA desde el celular, las cifras de exposición y de brecha estarían sesgadas en una dirección que los propios autores no pueden precisar (nota 24, p. 22).

## Resultado principal

Entre 30 % y 40 % del empleo en ALC está expuesto de alguna forma, y solo entre 2 % y 5 % cae en la categoría de automatización (p. 7). La exposición se concentra en empleos urbanos, formales, con más educación y mayores ingresos. En Colombia, entre las mujeres el 5,5 % del empleo está en automatización, el 11,3 % en aumento y el 22,5 % en la gran incógnita; la automatización es mayor en mujeres (5,5 %) que en hombres (1,6 %) y en zonas urbanas (3,9 %) que rurales (0,8 %) (Figura 12, pp. 29–30). La brecha digital pesa: el potencial de aumento no aprovechado equivale al 6,24 % del empleo femenino y al 6,22 % del masculino en la región (p. 29).

## Qué replicar

- **Resultado objetivo:** el panel de Colombia de la **Figura 12** (p. 30), en dos niveles.
  - *Nivel A (seguro):* reconstruir en R la Figura 12 de Colombia a partir de los resultados agregados del paquete.
  - *Nivel B (la réplica de verdad):* reconstruir la exposición total por sexo y zona (sin la partición por computador) desde los microdatos públicos de la GEIH 2019 y comparar con 5,5 / 1,6 y 3,9 / 0,8.
- **Dónde está en el paquete:** `Results/Results_AI_LAC_FINAL.xlsx`, hoja `AI_SEDLAC_PIAAC_CPU` (insumo de la Figura 12) y hoja `AI_CPU_ISCO2d` (fracciones por grupo de 2 dígitos para Colombia, que sirven de puente para el Nivel B). El código es el bloque `Figure12` de `Task2.Buffer_or_Bottlenect_ALL_PLOTS.Rmd`; la imputación original está en `dofiles/est_isco08_2d_mchILOWB.do` (ocupados de 15 a 64 años, ponderados). Los puntajes GBB están en `bases/ILO/Gmyrek_Berg_Bescond_scores_2023.csv`.
- **Dificultad:** **alta**. (i) Los microdatos SEDLAC y de la OIT son restringidos y no vienen en el paquete. (ii) El zip descargado no trae varios archivos auxiliares que el `.Rmd` lee al inicio, así que no compila tal cual: hay que reescribir el bloque. (iii) El diccionario del DANE para la GEIH 2019 indica que la variable `OFICIO` se codifica con la Clasificación Nacional de Ocupaciones del SENA de 1970, a 2 dígitos; para llegar a CIUO-08 necesita una tabla de correspondencia. SEDLAC hizo esa armonización internamente y el paquete no la incluye. ⚠ No se verificó que exista una correspondencia pública CNO-70 → CIUO-08: búsquela y documente cada decisión. (iv) Las fracciones de `AI_CPU_ISCO2d` no distinguen sexo; espere diferencias frente al paper.
- **Trabajo en R:** `readxl` y `tidyverse` para el Nivel A; `haven` o `readr` para la GEIH, cruce con la tabla de correspondencia y promedios ponderados por el factor de expansión.

## Ideas para el análisis adicional

1. **Índice 2025** — la OIT refinó el índice en 2025 con cuatro gradientes de exposición (WP 140, incluido en `paper/`; Tabla A1 del anexo, p. 48). ¿Cambia el perfil de exposición de Colombia? ⚠ Si usa una GEIH reciente, verifique en su diccionario qué clasificación de ocupaciones usa antes de cruzar a 4 dígitos. *Datos:* [GEIH 2024, DANE](https://microdatos.dane.gov.co/index.php/catalog/819).
2. **Informalidad y exposición en Colombia** — ¿los informales están menos expuestos dentro de la misma ocupación? ¿Cómo cambia la brecha entre ciudades? *Datos:* [GEIH 2019, DANE](https://microdatos.dane.gov.co/index.php/catalog/599).
3. **Brecha digital entre países** — ¿la exposición total de cada país (hoja `AI_LAC`) se explica por el acceso a internet o solo por el ingreso? *Datos:* WDI del Banco Mundial vía el paquete [`WDI`](https://cran.r-project.org/package=WDI): `IT.NET.USER.ZS` (usuarios de internet, fuente UIT) y `NY.GDP.PCAP.PP.KD`.

## Para el Escéptico

- **Una cadena larga de imputaciones.** Puntaje de GPT-4 → fracciones a 2 dígitos con datos de la OIT → logit estimado en PIAAC, que incluye solo cuatro países latinoamericanos (p. 20) → GEIH. Cada eslabón suma error, y el texto del paper no reporta intervalos de confianza ni errores estándar para estas cifras.
- **El computador como umbral.** Si la IA generativa se usa desde el celular, la "brecha" sobrestima lo que se pierde. Los autores hacen una prueba de robustez con computador en el hogar (Figura A5).
- **¿Colombia 2019 sigue siendo Colombia?** La GEIH 2019 es anterior a la pandemia y a la difusión masiva de ChatGPT; el acceso a internet en Colombia ha crecido desde entonces (compruébelo con `IT.NET.USER.ZS`).

## Descargas

- **Paper:** `paper/gmyrek2024_ilo_wp121.pdf` (CC BY 3.0 IGO). Material de extensión: `paper/ilo_wp140_indice_2025.pdf` (CC BY 4.0, DOI [10.54394/HETP0387](https://doi.org/10.54394/HETP0387)).
- **Paquete de réplica:** <https://reproducibility.worldbank.org/catalog/168>
- **Script de descarga:** `R/descargar-datos.R` (baja el paquete a `datos/_crudos/`).

## Licencias

Paper: CC BY 3.0 IGO (OIT y Banco Mundial). WP 140: CC BY 4.0 (OIT). Código del paquete: BSD de 3 cláusulas modificada (Copyright 2024, Gmyrek, Winkler y Garganta). Microdatos SEDLAC y de la OIT: restringidos, no incluidos. Microdatos GEIH: DANE; cite la fuente.
