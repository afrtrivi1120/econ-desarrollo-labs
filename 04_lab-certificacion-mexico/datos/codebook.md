# Codebook — los seis subsets del Lab 4

Subconjuntos de enseñanza derivados del paquete de réplica de **de Janvry, Emerick,
Gonzalez-Navarro y Sadoulet (2015)**, *Delinking Land Rights from Land Use: Certification
and Migration in Mexico*. Ver [`SOURCE.md`](SOURCE.md) para la procedencia y la licencia.

> **Qué tan «derivados» son.** A diferencia del Lab 3, el paquete ya trae las bases casi
> listas para la regresión. [`../R/00-construir-datos.R`](../R/00-construir-datos.R) hace
> tres cosas: se queda con las columnas que el lab usa, les pone nombres en español y
> **verifica contra el paper** antes de guardar. Las interacciones del do-file (por
> ejemplo «certificado 1993–1999 × año 2000») no se guardan: se construyen en el lab,
> porque construirlas es parte de entender el diseño.

Los identificadores (`hogar`, `ejido`, `localidad`, `municipio`) son **números
anonimizados** del paquete. El acuerdo de confidencialidad de los autores no permite
publicar datos que identifiquen al ejido, así que no hay nombres ni claves de ejido o de
localidad.

---

## `janvry_hogares` — 27.189 filas × 21 columnas

Unidad de observación: **hogar × año**, 1997–2000. Hogares de las encuestas de evaluación
de PROGRESA (ENCEL) en localidades que caen dentro de un ejido, en 7 estados: Guerrero,
Hidalgo, Michoacán, Puebla, Querétaro, San Luis Potosí y Veracruz. Solo ejidos
certificados **después de 1996**. Es exactamente la muestra de la **Tabla 1** del paper:
7.577 hogares en 127 ejidos, panel **desbalanceado** por atrición.

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `hogar` | entero | Identificador del hogar. | `hh_numid` |
| `ejido` | entero | Identificador del ejido (127 distintos). **Nivel al que se agrupan los errores estándar** y del efecto fijo principal. | `ejido_numid` |
| `localidad` | entero | Identificador de la localidad PROGRESA. | `loc_numid` |
| `estado` | entero | Código INEGI del estado: 12 Guerrero, 13 Hidalgo, 16 Michoacán, 21 Puebla, 22 Querétaro, 24 San Luis Potosí, 30 Veracruz. | `entidad` |
| `anio` | entero | Año de la encuesta, 1997 a 2000. | `year` |
| `migrante` | 0/1 | **El resultado.** 1 si el hogar ya tiene un migrante permanente: alguien que se fue del ejido ese año **o cualquier año anterior de la muestra**. Es **acumulado**: para un hogar dado, solo puede subir. | `mig_away` |
| `certificado` | 0/1 | **El tratamiento.** 1 si el ejido estaba certificado **al inicio** del año. Es igual a `anio > anio_procede` (el script de construcción lo comprueba). | `full_titled` |
| `anio_procede` | entero | Año en que el ejido terminó PROCEDE: 1997–2000 o 2002–2006. Define las cohortes. | `procedeyea` |
| `propietario` | 0/1 | 1 si el hogar tiene tierra en el ejido. 499 `NA`. | `hh_ag` |
| `hombres_17a30` | entero | Hombres de 17 a 30 años en el hogar en 1997. 2.457 `NA` (hogares que entraron después de 1997). | `males_17to30_1997` |
| `jefa_mujer` | 0/1 | 1 si la jefatura del hogar en 1997 es femenina. 2.457 `NA`. | `female_head_1997` |
| `edad_jefe` | entero | Edad de quien encabeza el hogar. 710 `NA`. | `age_head` |
| `valor_agricola` | numérico | Valor potencial de una hectárea en el ejido, en **cientos de dólares**: precios del año × rendimientos nacionales de 1995 × composición de cultivos del ejido en 1995 (paper, nota 17). Varía por ejido y año; es el control por los precios de NAFTA. 1.249 `NA`. | `value_ag` |
| `ejidatarios` | entero | Número de ejidatarios (miembros con voto). Fijo por ejido. | `ejidatario` |
| `no_votantes` | entero | Posesionarios + avecindados: residentes sin voto en la asamblea. Construida igual que `outsiders` en el do-file. | `posesionar + avecindado` |
| `area_total` | numérico | Área total del ejido, en hectáreas. | `suptotalnu` |
| `prop_parcelada` | numérico | Área en parcelas individuales / área total. Construida igual que `parcelratio` en el do-file. **Ojo:** en algunos ejidos supera 1 (máximo 2,29); así viene en la fuente y así la usa el paper. | `supparcela / suptotalnu` |
| `latitud`, `longitud` | numérico | Coordenadas de la localidad. | `latitude`, `longitude` |
| `dist_ciudad_km` | numérico | Distancia a la ciudad más cercana con más de 100.000 habitantes, en km. | `nearcity_km` |
| `marginacion` | numérico | Índice de marginación de la localidad (más alto = más marginada). | `iml7954r` |

Las últimas siete son las **características del ejido** que la columna 6 de la Tabla 1
interactúa con el año.

---

## `janvry_localidades` — 54.916 filas × 8 columnas

Unidad: **localidad × año**, censos de población INEGI de **1990 y 2000**. Localidades
cuyo centroide cae dentro de un ejido, en todo el país. Base de la **Tabla 2, cols. 1–5**.

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `localidad` | entero | Identificador de la localidad. | `loc_id` |
| `ejido` | entero | Identificador del ejido. **Efecto fijo y nivel del clúster.** 244 `NA`, que la regresión descarta. | `ejido_numid` |
| `anio` | entero | 1990 o 2000. | `year` |
| `poblacion` | entero | Población total de la localidad. | `pobtot` |
| `log_pob` | numérico | Logaritmo de la población. | `logpop` |
| `anio_procede` | entero | Año en que el ejido terminó PROCEDE. 394 `NA` (197 localidades), que **deben quedar fuera** de la regresión: ver la nota sobre `%in%` más abajo. | `procedeyea` |
| `pob_1990` | entero | Población en 1990, repetida en las dos filas de la localidad. Sirve para la regla de muestra del paper: **más de 20 habitantes en 1990** (nota 14). | `mpob90` |
| `valor_agricola` | numérico | Valor potencial por hectárea, en cientos de dólares (col. 3). Faltante en muchas localidades: por eso la col. 3 tiene N = 24.170. | `value_ag` |

Con el filtro `pob_1990 > 20` y descartando los `NA` quedan **34.656 observaciones de
17.328 localidades**, las del paper.

## `janvry_localidades_80_90` — 32.356 filas × 5 columnas

Unidad: **localidad × año**, censos de **1980 y 1990**. Es el **placebo** de la Tabla 2,
col. 6: la misma comparación una década antes de que PROCEDE existiera.

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `ejido` | entero | Identificador del ejido. | `ejido_numid` |
| `anio` | entero | 1980 o 1990. | `year` |
| `log_pob` | numérico | Logaritmo de la población. 181 `NA`. | `logpop` |
| `pob_1980` | entero | Población en 1980, para la regla de muestra (> 20 habitantes). | `maxpob80` |
| `cert_93_99_x_1990` | 0/1 | 1 si es la fila de 1990 **y** el ejido se certificó en 1993–1999. Viene ya construida porque en el `.dta` las filas de 1980 no traen el año de PROCEDE. | `promax_year90` |

Con `pob_1980 > 20` y descartando faltantes quedan **24.910 observaciones**, las del paper.

---

## `janvry_censo_ejidal` — 19.713 filas × 9 columnas

Unidad: **ejido**. Censos ejidales de INEGI de 1991 y 2007, empatados para el paper con un
algoritmo descrito en su apéndice. Es un **corte transversal**: en 2007 todos los ejidos ya
estaban certificados. Base de la **Tabla 3**.

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `estado` | texto | Nombre del estado (31). **Efecto fijo** de la Tabla 3. | `ESTADO` |
| `municipio` | entero | Identificador del municipio. **Nivel del clúster** de la Tabla 3. | `muni_numid` |
| `anio_procede` | entero | Año de certificación. 43 `NA`. | `PROCEDEYEA` |
| `anios_certificado` | entero | Años con certificado en 2007 (0 a 14). **El regresor de interés.** | `years_titled` |
| `jovenes_migran` | 0/1 | **El resultado.** 1 si la mayoría de los jóvenes del ejido migra: ni se integra a las actividades del ejido ni trabaja en localidades cercanas. | `young_mig` |
| `semilla_mejorada` | 0/1 | El ejido usaba semilla mejorada en 1991. | `improve_seed` |
| `tractor` | 0/1 | El ejido tenía tractores en 1991. | `tractor` |
| `electricidad` | 0/1 | El ejido tenía electricidad en 1991. | `lights` |
| `log_dist_pa` | numérico | Log de la distancia entre el ejido y la oficina de la Procuraduría Agraria. 84 `NA`. | `logdist` |

---

## `janvry_procampo` — 18.437 filas × 8 columnas

Unidad: **ejido**, con las dos fotos (1995 y 2012) **lado a lado**. Registros del programa
de pagos PROCAMPO: cuántos productores cobraron y por cuánta área. Base de la **Figura 2**.

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `ejido` | entero | Identificador del ejido. | `ejido_numid` |
| `anio_procede` | entero | Año en que el ejido terminó PROCEDE (1993–2007). Extraído de la fecha de certificación. | `procededat_r` |
| `estado` | entero | Identificador del estado. **Efecto fijo** de la Figura 2. | `state_phina_id` |
| `municipio` | entero | Identificador del municipio. **Nivel del clúster.** | `muni_id` |
| `log_productores_1995`, `_2012` | numérico | Log del número de beneficiarios de PROCAMPO en el ejido. | `logbenef` |
| `log_area_1995`, `_2012` | numérico | Log del área cubierta por PROCAMPO en el ejido. | `logarea` |

Un ejido sin registro en uno de los dos años tiene `NA` en esas columnas y sale de la
regresión: quedan **14.399 ejidos** con las dos fotos. En el lab, la categoría de
referencia son los ejidos certificados en 2005 o después (`pmin(anio_procede, 2005)`),
igual que en el do-file.

---

## `janvry_satelite` — 79.443 filas × 5 columnas

Unidad: **ejido × imagen**. Mapas de uso del suelo de INEGI (series II, III y IV), basados
en imágenes Landsat, cruzados con los límites digitales de los **26.481 ejidos** que
terminaron PROCEDE. Base de la **Tabla 4** y de la versión en barras de la **Figura 1**.

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `ejido` | entero | Identificador del ejido. | `ejidoid` |
| `anio` | entero | Año de la imagen: 1993 (serie II), 2002 (serie III) o 2007 (serie IV). | `series` |
| `anio_procede` | entero | Año en que el ejido terminó PROCEDE (1993–2007; 2 ejidos en 2007). | `procedeyea` |
| `certificado` | 0/1 | 1 si el ejido estaba certificado en la fecha de la imagen. | `titled` |
| `log_area_agricola` | numérico | Log del área agrícola del ejido. 16.051 `NA`, así vienen en la fuente; la regresión los descarta. | `lnagri` |

---

## Notas de uso

### `%in%` y los faltantes deciden la Tabla 2

Para marcar los ejidos certificados en 1993–1999 hay que escribir
`anio_procede >= 1993 & anio_procede <= 1999`. Con `anio_procede %in% 1993:1999`, que
parece lo mismo, una localidad **sin** año de PROCEDE recibe `FALSE` y entra a la
regresión como control. Con la comparación recibe `NA` y sale, que es lo que hace Stata.
La diferencia: −0,0401 contra −0,0404 en la col. 2. No hay error ni advertencia.

### Los grados de libertad deciden la Tabla A4

Stata, al correr `reg` con dummies de ejido, cuenta los efectos fijos como parámetros al
corregir los errores estándar por muestra pequeña. `fixest`, por defecto, no. Con 27.189
observaciones la diferencia aparece en el cuarto decimal; en la col. 4 de la Tabla A4
(406 observaciones, 127 efectos fijos) cambia los EE en un 20 %. Para reproducir el
número publicado: `vcov = vcov_cluster(~ejido, ssc = ssc(fixef.K = "full"))`.

### Singletons

`fixest` elimina por defecto las observaciones que quedan solas en su efecto fijo; `xtreg`
de Stata no. Para que la N coincida con la publicada en la Tabla 1 col. 3 (efecto fijo de
hogar) y en la Tabla 4, el lab usa `fixef.rm = "none"`. Los coeficientes no cambian.
