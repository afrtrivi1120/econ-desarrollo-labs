# Procedencia de los datos

## Paper replicado

**Dell, M. (2010).** "The Persistent Effects of Peru's Mining Mita."
*Econometrica*, **78**(6), 1863–1903. DOI: [10.3982/ECTA8121](https://doi.org/10.3982/ECTA8121).

Paquete de réplica original (página de la autora):
<https://dell-research-harvard.github.io/projects/498mita> → `files1.zip`, `files2.zip`,
`files3.zip` y el [apéndice de datos](https://scholar.harvard.edu/files/dell/files/100103mita_datappendix_small_0.pdf).

## Fuentes de los archivos crudos

| Archivo | Contenido | De dónde salió |
|---|---|---|
| `mitaData.dta` | 1.478 hogares de la ENAHO 2001 a menos de 100 km de la frontera de la mita; es la muestra de la Tabla II, Panel A | MIT OpenCourseWare, curso **14.75 *Political Economy and Economic Development*, Fall 2012**, recurso "Dataset: mitaData.dta" ([enlace](https://ocw.mit.edu/courses/14-75-political-economy-and-economic-development-fall-2012/resources/mitadata/)) |
| `gis_dist.dta` | 299 distritos con la geografía del diseño RD (distancia a la frontera, elevación, pendiente, segmentos de frontera, coordenadas) | Paquete de réplica de Dell (2010) |
| `dem1572.dta` | Censo de Toledo de **1572**, anterior a la mita: población y composición demográfica de 109 distritos | Paquete de réplica de Dell (2010) |

> ⚠ **Sobre la descarga.** `scholar.harvard.edu` responde **403** (protección anti-bot de
> Akamai) a todo el dominio desde varias redes, así que `files1-3.zip` no siempre se
> pueden bajar de forma automática. `gis_dist.dta` y `dem1572.dta` llegaron a este
> ejercicio dentro del paquete de réplica de otro trabajo sobre la frontera de la mita
> (apellidos y migración, 2021), cuyo `readme.pdf` declara explícitamente que esos
> archivos fueron obtenidos del sitio de Melissa Dell. La cadena queda documentada aquí
> por transparencia; la fuente autoritativa sigue siendo la página de la autora.

## Transformación

Los subsets de enseñanza se construyen con
[`R/00-construir-datos.R`](../R/00-construir-datos.R): selección de columnas, nombres
en español donde no rompe el puente con el paper, y construcción de la **variable de
asignación con signo** (`dist_frontera` = distancia a la frontera, negativa fuera de la
mita y positiva dentro).

| Subset | Filas × columnas | Qué es |
|---|---|---|
| `dell_mita_hogares.rds` / `.csv.gz` | 1.478 × 18 | Hogares de la ENAHO 2001; unidad de análisis de la estimación principal |
| `dell_mita_distritos.rds` / `.csv.gz` | 299 × 18 | Distritos; sirve para el mapa y para el balance pre-mita de 1572 |

## Verificación

El subset reproduce la **Tabla II, Panel A, columna 1** de Dell (2010) — cúbica en
longitud y latitud, muestra a menos de 100 km de la frontera, errores estándar
agrupados por distrito:

| | Réplica | Publicado |
|---|---|---|
| Coeficiente de la mita | **−0,284** (EE 0,199) | ~−25 % de consumo |
| Significancia (Panel A) | no significativo | «not statistically significant» (p. 1879) |
| Observaciones | 1.478 hogares, 71 distritos | ídem |

Los Paneles B (cúbica en distancia a Potosí) y C (cúbica en distancia a la frontera)
también replican: coeficientes entre −0,22 y −0,34, significativos al 1 % o 5 %, tal
como reporta el paper.

## Licencia / atribución

- **`mitaData.dta`**: distribuido por MIT OpenCourseWare bajo
  **[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)** (uso no
  comercial, atribución, misma licencia). Atribución requerida:
  > **«MIT OpenCourseWare, 14.75 Political Economy and Economic Development, Fall 2012»**
- **`gis_dist.dta` y `dem1572.dta`**: el paquete de réplica de Dell (2010) **no declara
  una licencia explícita** → veredicto **`unknown`**. Por eso este repositorio
  **no redistribuye los archivos crudos** (viven en `datos/_crudos/`, ignorado por git),
  solo un subconjunto derivado y mínimo de las columnas necesarias para el ejercicio
  docente, con atribución completa. Si la autora o los titulares lo solicitan, se retira.

En cualquier uso, la cita obligatoria es la del paper:

> Dell, M. (2010). The Persistent Effects of Peru's Mining Mita. *Econometrica*, 78(6), 1863–1903.
