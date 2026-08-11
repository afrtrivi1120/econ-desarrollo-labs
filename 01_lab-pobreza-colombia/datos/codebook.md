# Codebook — GEIH pobreza monetaria, 2019 y 2021

Este documento cubre las **dos capas** de datos del lab:

1. **Los crudos** (`_crudos/`) — la microdata del DANE tal como la publica, con sus nombres
   y sus códigos originales. Es de donde arranca el lab.
2. **El subset construido** (`geih_pobreza_2019_2021.rds`) — lo que produce la limpieza.

---

## 1. Los datos crudos (`_crudos/`)

La medición de pobreza del DANE reparte la información en **dos archivos por año**:

| Archivo | Unidad | Qué trae |
|---|---|---|
| `geih-<año>-hogares.csv.gz` | **hogar** | el ingreso, las líneas de pobreza y los indicadores |
| `geih-<año>-personas.csv.gz` | **persona** | la demografía (edad, sexo, educación) |

Se unen por `directorio` + `secuencia_p`. Por eso el lab necesita los cuatro archivos:
sin el de personas no hay edad ni educación, y sin el de hogares no hay ingreso ni pobreza.

> ⚠️ **Formato distinto por año.** 2019 viene con delimitador `;` y decimal `,` (formato
> europeo); 2021, con delimitador `,` y decimal `.`. Por eso el lab los lee en dos bloques
> separados y no en uno solo.

### Variables del archivo de **hogares**

| Variable | Definición del DANE (textual) | Códigos |
|---|---|---|
| `directorio` | Llave vivienda | — |
| `secuencia_p` | Llave hogar | — |
| `ingpcug` | Ingreso per cápita de la unidad de gasto **con imputación de arriendo a propietarios y usufructuarios** | pesos corrientes/mes |
| `lp` | Línea de pobreza. *"Valor de la canasta básica de bienes que establece el límite de ingresos por debajo del cual un hogar es considerado en pobreza."* | pesos/mes |
| `pobre` | Pobre=1 No pobre=0 | `0` = No pobre · `1` = Pobre |
| `indigente` | Indigente=1 No indigente=0 | `0` = No indigente · `1` = Indigente |

> El archivo original del DANE trae además `li` (línea de indigencia) y su propio `fex_c`,
> pero el extracto **no los incluye**: el lab no usa la línea de indigencia —le basta la
> bandera `indigente`— y el factor de expansión lo toma del archivo de personas, que es la
> unidad de análisis.

### Variables del archivo de **personas**

| Variable | Definición del DANE (textual) | Códigos |
|---|---|---|
| `directorio` | Llave de vivienda | — |
| `secuencia_p` | Llave de hogar | — |
| `clase` | 1. Cabecera, 2. Resto (centros poblados y área rural dispersa) | `1` = Cabecera · `2` = Resto |
| `p6020` | Sexo | `1` = Hombre · `2` = Mujer |
| `p6040` | ¿Cuántos años cumplidos tiene? | años |
| `p6210` | ¿Cuál es el nivel educativo más alto alcanzado por … y el último año o grado aprobado en este nivel? | `1` Ninguno · `2` Preescolar · `3` Básica primaria (1º–5º) · `4` Básica secundaria (6º–9º) · `5` Media (10º–13º) · `6` Superior o universitaria · `9` No sabe, no informa |
| `fex_c` | Factor de expansión anualizado | — |

> Las definiciones y los códigos de estas dos tablas están tomados **textualmente** del
> diccionario de datos oficial del DANE, que se encuentra en
> [`diccionario-dane/`](diccionario-dane/) (formato DDI). No se escribieron de memoria.

**Ojo con lo que el archivo crudo NO dice.** El DANE publica los archivos completos con
**137 columnas** el de personas y 25 (2019) o 22 (2021) el de hogares; en `_crudos/`
solo están las que el lab usa. Ver
[`SOURCE.md`](SOURCE.md) para saber cómo reconstruir el extracto desde el portal.

---

## 2. El subset construido (`geih_pobreza_2019_2021.rds`)

Unidad de observación: **persona**. 1.467.444 filas, 10 columnas. Cada fila es una persona;
el ingreso y la condición de pobreza provienen de **su hogar**.

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `anio` | factor | Año de la encuesta (2019 / 2021) | se agrega al apilar |
| `fex` | numérico | **Factor de expansión** por persona. Cada fila representa `fex` personas del país. Ponderar SIEMPRE por esta variable. | `fex_c`, renombrada |
| `ingpcug` | numérico | Ingreso per cápita de la unidad de gasto del hogar, pesos corrientes/mes | `ingpcug`, sin cambios |
| `lp` | numérico | Línea de pobreza oficial (pesos/mes), específica del año y el dominio | `lp`, sin cambios |
| `pobre` | entero 0/1 | 1 = persona en **pobreza monetaria** | `pobre`, sin cambios |
| `indigente` | entero 0/1 | 1 = persona en **pobreza extrema** | `indigente`, sin cambios |
| `edad` | entero | Edad en años cumplidos | `p6040`, renombrada |
| `sexo` | factor | `Hombre` / `Mujer` | `p6020` **recodificada** |
| `educ` | factor | Máximo nivel educativo en 4 categorías. `NA` si no informa. | `p6210` **recodificada** |
| `area` | factor | `Urbano` (cabecera) / `Rural` (resto) | `clase` **recodificada** |

### Qué se transforma y qué no

- **Sin cambios** (4): `ingpcug`, `lp`, `pobre`, `indigente`.
- **Solo renombradas** (2): `fex_c` → `fex`, `p6040` → `edad`.
- **Recodificadas** (3): `p6020` → `sexo`, `clase` → `area`, `p6210` → `educ`.
- **Se descartan** (2): `directorio` y `secuencia_p`, que solo sirven para unir los archivos.
- **Se agrega** (1): `anio`, al apilar los dos años.

### La recodificación de `educ` (la única que agrupa categorías)

Las siete categorías del DANE se colapsan a cuatro, estilo Banco Mundial:

| `p6210` | Etiqueta del DANE | → `educ` |
|---|---|---|
| 1 | Ninguno | Sin educación |
| 2 | Preescolar | Sin educación |
| 3 | Básica primaria (1º–5º) | Primaria |
| 4 | Básica secundaria (6º–9º) | Secundaria |
| 5 | Media (10º–13º) | Secundaria |
| 6 | Superior o universitaria | Superior |
| 9 | No sabe, no informa | `NA` |

> Esta es la transformación con más criterio del lab, y conviene poder defenderla. Juntar
> *Ninguno* con *Preescolar* es razonable si lo que interesa es "no alcanzó primaria".
> Juntar *Básica secundaria* con *Media* borra la diferencia entre haber llegado a noveno y
> haberse graduado de bachillerato, que en el mercado laboral colombiano no es menor.

### Notas de uso

- **Ponderación:** toda cifra nacional se calcula ponderando por `fex`
  (p. ej. `weighted.mean(pobre, fex)`).
- **Pesos corrientes:** `ingpcug` y `lp` están en pesos de cada año (sin deflactar). La tasa
  de pobreza sí es comparable entre años (cada año usa su propia `lp`); los *niveles* de
  ingreso, no, sin ajustar por inflación.
- **Educación:** para el perfil educativo del pobre se filtra a personas de 15 años o más.

**Fuente:** DANE — Medición de Pobreza Monetaria y Desigualdad (GEIH), microdatos
anonimizados. Cat. 684 (2019) y 733 (2021). «Fuente: DANE, www.dane.gov.co».
