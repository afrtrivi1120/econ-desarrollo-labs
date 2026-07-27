# Codebook — `geih_pobreza_2019_2021`

Subconjunto de enseñanza derivado de la microdata GEIH–DANE (Pobreza Monetaria),
2019 y 2021. Unidad de observación: **persona**. 1.467.444 filas, 10 columnas.

Cada fila es una persona; el ingreso y la condición de pobreza provienen de **su
hogar** (se unieron Personas + Hogares por `directorio` + `secuencia_p`).

| Columna | Tipo | Descripción | Variable DANE de origen |
|---|---|---|---|
| `anio` | factor | Año de la encuesta (2019 / 2021) | — |
| `fex` | numérico | **Factor de expansión** por persona. Cada fila representa `fex` personas del país. Ponderar SIEMPRE por esta variable. | `fex_c` |
| `ingpcug` | numérico | **Ingreso per cápita de la unidad de gasto** del hogar, pesos corrientes/mes | `ingpcug` |
| `lp` | numérico | **Línea de pobreza** monetaria oficial (pesos/mes), específica del año y dominio | `lp` |
| `pobre` | entero 0/1 | 1 = persona en **pobreza monetaria** (`ingpcug` < `lp`) | `pobre` |
| `indigente` | entero 0/1 | 1 = persona en **pobreza extrema** (`ingpcug` < línea de indigencia) | `indigente` |
| `edad` | entero | Edad en años cumplidos | `p6040` |
| `sexo` | factor | `Hombre` / `Mujer` | `p6020` (1/2) |
| `educ` | factor | Máximo nivel educativo, 4 categorías: `Sin educación`, `Primaria`, `Secundaria`, `Superior`. `NA` si no informa. | `p6210` recodificada |
| `area` | factor | `Urbano` (cabecera) / `Rural` (resto) | `clase` (1/2) |

### Recodificación de `educ` (desde `p6210`)

| `p6210` | Significado | → `educ` |
|---|---|---|
| 1 | Ninguno | Sin educación |
| 2 | Preescolar | Sin educación |
| 3 | Básica primaria | Primaria |
| 4 | Básica secundaria | Secundaria |
| 5 | Media | Secundaria |
| 6 | Superior / universitaria | Superior |
| 9 | No sabe / no informa | `NA` |

### Notas de uso

- **Ponderación:** toda cifra nacional se calcula ponderando por `fex`
  (p. ej. `weighted.mean(pobre, fex)`).
- **Pesos corrientes:** `ingpcug` y `lp` están en pesos de cada año (sin deflactar).
  La tasa de pobreza ya es comparable entre años (cada año usa su propia `lp`); los
  *niveles* de ingreso no se deben comparar directamente sin ajustar por inflación.
- **Educación:** para el perfil educativo del pobre se filtra a personas de 15+ años.

**Fuente:** DANE — Medición de Pobreza Monetaria y Desigualdad (GEIH), microdatos
anonimizados. Cat. 684 (2019) y 733 (2021). «Fuente: DANE, www.dane.gov.co».
