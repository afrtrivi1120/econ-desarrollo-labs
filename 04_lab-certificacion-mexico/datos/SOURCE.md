# Procedencia de los datos

## Paper replicado

**de Janvry, A., Emerick, K., Gonzalez-Navarro, M. y Sadoulet, E. (2015).** "Delinking
Land Rights from Land Use: Certification and Migration in Mexico." *American Economic
Review*, **105**(10), 3125–3149. DOI:
[10.1257/aer.20130853](https://doi.org/10.1257/aer.20130853).
(Cita verificada contra Crossref con `dev_econ/scripts/check-citation.sh`.)

Paquete de réplica: depósito **openICPSR-112931**, *Replication data for: Delinking Land
Rights from Land Use: Certification and Migration in Mexico*, versión V1,
<https://www.openicpsr.org/openicpsr/project/112931/version/V1/view>
(DOI [10.3886/E112931V1](https://doi.org/10.3886/E112931V1)).

Apéndice en línea (Tabla A4, usada en la sección 5 del lab):
<https://www.aeaweb.org/articles/materials/4456>.

## Fuentes de los archivos crudos

El ZIP se descomprime en `112931-V1/` con un `LICENSE.txt` y una carpeta `replication/`
que trae un `ReadMe.pdf`, un único do-file (`20130853_replication_code.do`, que corre todas
las tablas y figuras) y seis `.dta` en `replication_data/`:

| Archivo | Filas × columnas | Contenido | Nivel | Alimenta |
|---|---|---|---|---|
| `progresa_hhdata.dta` | 27.189 × 39 | Panel PROGRESA (ENCEL) 1997–2000 cruzado con el año de PROCEDE del ejido | hogar × año | Tablas 1, 6, A1, A3, A4, A5 |
| `locality_level.dta` | 71.094 × 16 | Población de las localidades en los censos INEGI 1980, 1990 y 2000 | localidad × año | Tablas 2 y A2 |
| `ejido_census.dta` | 19.713 × 10 | Censos ejidales 1991 y 2007 empatados | ejido | Tabla 3 |
| `landuse_satellite.dta` | 79.443 × 10 | Área agrícola según imágenes Landsat (series II–IV de INEGI) | ejido × imagen | Tabla 4 |
| `procampo2.dta` | 32.836 × 8 | Beneficiarios y área de PROCAMPO en 1995 y 2012 | ejido × año | Figuras 2 y A3 |
| `consumption.dta` | 26.874 × 14 | Consumo de los hogares PROGRESA | hogar × ronda | Tabla 5 (no se usa en el lab) |

> ⚠ **Los datos vienen anonimizados.** Según el `ReadMe.pdf`, el acuerdo de
> confidencialidad de los autores no permite distribuir datos identificables a nivel de
> ejido. Los identificadores son números sin nombres ni claves geográficas
> del ejido, así que no se pueden cruzar con otras fuentes.

> ⚠ **`locality_level.dta` apila dos paneles.** Las filas de 1990 y 2000 traen
> identificador de localidad y sirven a las cols. 1–5 de la Tabla 2. Las de 1980 **no
> traen** identificador de localidad ni año de PROCEDE, y solo sirven al placebo (col. 6)
> junto con las de 1990. El script de construcción los separa en dos subsets.

> ⚠ **La Tabla 6 no corre con el paquete tal como viene.** El do-file usa una variable
> `pobre` que no existe en `progresa_hhdata.dta` (sí existe `pobre_1997`). El lab no
> replica la Tabla 6, así que no hizo falta resolverlo; se deja anotado para quien quiera
> extender.

> ⚠ **Sobre la descarga.** `openicpsr.org` está detrás de Cloudflare y responde **403** a
> `curl`. Además, la descarga exige **iniciar sesión** (cuenta gratuita de ICPSR) y
> **aceptar los términos de uso** del depósito. No se puede automatizar: hay que abrir la
> página en un navegador, entrar con la cuenta, aceptar los términos y usar el botón
> *Download this project*. El ZIP se descomprime en `datos/_crudos/` (ignorado por git).

## Transformación

Los subsets de enseñanza se construyen con
[`R/00-construir-datos.R`](../R/00-construir-datos.R): selección de columnas, nombres en
español, dos variables derivadas en la base de hogares (`no_votantes` y `prop_parcelada`,
construidas igual que `outsiders` y `parcelratio` en el do-file), y la separación de la base
de localidades en sus dos paneles. PROCAMPO se reorganiza para dejar las dos fotos (1995 y
2012) en una sola fila por ejido.

El script busca los `.dta` por nombre dentro de `datos/_crudos/`, sin importar en qué
subcarpeta hayan quedado, **se detiene** si falta una variable (e imprime los nombres que
sí existen) y comprueba dos identidades antes de seguir: que `certificado` es exactamente
`anio > anio_procede`, y que las interacciones de la Tabla 2 son funciones del año de
PROCEDE. Al final **verifica diez números contra el paper** y, si alguno no da, no guarda
nada.

| Subset | Filas × columnas | Qué es |
|---|---|---|
| `janvry_hogares.rds` / `.csv.gz` | 27.189 × 21 | Panel de hogares; unidad del resultado titular |
| `janvry_localidades.rds` / `.csv.gz` | 54.916 × 8 | Localidades en 1990 y 2000 |
| `janvry_localidades_80_90.rds` / `.csv.gz` | 32.356 × 5 | Localidades en 1980 y 1990 (placebo) |
| `janvry_censo_ejidal.rds` / `.csv.gz` | 19.713 × 9 | Censo ejidal 2007 con controles de 1991 |
| `janvry_procampo.rds` / `.csv.gz` | 18.437 × 8 | PROCAMPO, 1995 y 2012 lado a lado |
| `janvry_satelite.rds` / `.csv.gz` | 79.443 × 5 | Área agrícola por imagen satelital |

## Verificación

**Todos los resultados que el lab replica coinciden con los publicados.** Los
coeficientes son iguales en los cuatro decimales y las N son exactas.

**Tabla 1** — efecto de la certificación sobre P(hogar con migrante):

| Columna | Réplica | Publicado | N |
|---|---|---|---|
| (1) Efectos fijos de ejido y año | **0,0149** (0,0061) | **0,0149** (0,0061) | 27.189 |
| (2) + controles de hogar y valor agrícola | 0,0147 (0,0065) | 0,0147 (0,0066) | 23.421 |
| (3) Efectos fijos de hogar | 0,0153 (0,0062) | 0,0153 (0,0062) | 27.189 |
| (4) Año × estado | 0,0172 (0,0058) | 0,0172 (0,0059) | 27.189 |
| (5) Características del hogar × año | 0,0157 (0,0063) | 0,0157 (0,0063) | 24.533 |
| (6) Características del ejido × año | 0,0130 (0,0062) | 0,0130 (0,0062) | 27.189 |

Media de la variable dependiente: 0,053. Las diferencias en el cuarto decimal de dos EE
salen del ajuste por grados de libertad (ver [`codebook.md`](codebook.md), «Los grados de
libertad deciden la Tabla A4»). Con `ssc(fixef.K = "full")` desaparecen.

**Tabla 2** — población de las localidades, 1990–2000:

| Columna | Réplica | Publicado | N |
|---|---|---|---|
| (1) Población | −3,6893 (1,1485) | −3,6893 (1,1485) | 34.656 |
| (2) ln población | **−0,0404** (0,0128) | **−0,0404** (0,0128) | 34.656 |
| (3) + valor agrícola | −0,0341 (0,0167) | −0,0341 (0,0167) | 24.170 |
| (4) × años certificado | −0,0206 (0,0195); −0,0054 (0,0039) | −0,0206 (0,0195); −0,0054 (0,0039) | 34.656 |
| (5) Temprano / tardío | −0,0592 (0,0144); −0,0196 (0,0151) | −0,0592 (0,0144); −0,0196 (0,0151) | 34.656 |
| (6) Placebo 1980–1990 | −0,0082 (0,0148) | −0,0082 (0,0148) | 24.910 |

**Otras tablas y figuras:**

| Tabla / figura | Réplica | Publicado |
|---|---|---|
| **Tabla 3**, cols. 1–2 | 0,0035 (0,0013), N = 19.670; 0,0039 (0,0013), N = 19.600 | iguales |
| **Tabla 4**, col. 1 | 0,0013 (0,0093), N = 63.392 | igual |
| **Tabla A4**, cols. 1–3 | py99 −0,0011; py00 −0,0040 / −0,0087; py01 −0,0131 / −0,0102 / 0,0015; p conjunta 0,190 y 0,493; N = 111, 187, 225 | iguales |
| **Tabla A4**, col. 4 | 0,0018 (0,0150), −0,0021 (0,0107), −0,0015 (0,0089); N = 406 | iguales, con `ssc(fixef.K = "full")` y `fixef.rm = "none"` |
| **Figura 2** | área por productor +0,103 / +0,124 / +0,067 en los certificados en 1993 / 1994 / 1995; productores entre −0,10 y −0,15 en 1993–1997 | mismo patrón; el paper describe «alrededor de 10 %» para los certificados en 1995 o antes |

El lab agrega dos estimaciones que **no** están en el paper: el estudio de evento de Sun y
Abraham (2021) y el estimador de Callaway y Sant'Anna (2021). Sus números salen de la
corrida y se guardan en [`../results.json`](../results.json).

## Licencia / atribución

El `LICENSE.txt` del depósito declara dos licencias:

- **[Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0)**
  para «bases de datos, imágenes, tablas, texto y cualquier otro objeto». Veredicto
  **`redistributable`**: los datos se pueden redistribuir, incluso modificados, siempre
  que se dé atribución.
- **BSD de 3 cláusulas modificada** para el código (el do-file). El lab no redistribuye el
  do-file; lo traduce a R.

Aun así, este repositorio **no versiona el paquete crudo** (vive en `datos/_crudos/`,
ignorado por git): solo el subconjunto derivado y mínimo que el ejercicio docente
necesita, con la atribución completa. Es la misma política de los Labs 2 y 3.

En cualquier uso, la cita obligatoria es la del paper:

> de Janvry, A., Emerick, K., Gonzalez-Navarro, M. y Sadoulet, E. (2015). Delinking Land
> Rights from Land Use: Certification and Migration in Mexico. *American Economic Review*,
> 105(10), 3125–3149.

Y la del depósito de datos:

> de Janvry, Alain, Kyle Emerick, Marco Gonzalez-Navarro y Elisabeth Sadoulet. Replication
> data for: Delinking Land Rights from Land Use: Certification and Migration in Mexico.
> Nashville, TN: American Economic Association [publisher], 2015. Ann Arbor, MI:
> Inter-university Consortium for Political and Social Research [distributor], 2019-10-12.
> https://doi.org/10.3886/E112931V1
