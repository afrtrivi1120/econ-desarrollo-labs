# Procedencia de los datos

## Fuente original

**Departamento Administrativo Nacional de Estadística (DANE)** — *Medición de Pobreza
Monetaria y Desigualdad*, microdatos anonimizados de la Gran Encuesta Integrada de
Hogares (GEIH).

| Año | Catálogo DANE | Ficha | Archivos usados |
|---|---|---|---|
| 2019 | 684 | https://microdatos.dane.gov.co/index.php/catalog/684 | `Personasd.csv`, `Hogaresd.csv` |
| 2021 | 733 | https://microdatos.dane.gov.co/index.php/catalog/733 | `Personas.csv`, `Hogares.csv` |

Los archivos de **Hogares** traen el ingreso (`ingpcug`), las líneas (`lp`, `li`) y
los indicadores de pobreza (`pobre`, `indigente`); los de **Personas** traen la
demografía (`p6040` edad, `p6020` sexo, `p6210` educación). Se unieron por
`directorio` + `secuencia_p`.

### Detalles de formato de los archivos crudos (por si se rebajan de nuevo)

- **2019:** CSV con delimitador `;`, decimal `,` (formato europeo), UTF-8. Departamento = `depto`.
- **2021:** CSV con delimitador `,`, decimal `.`. Departamento = `dpto`.

## Transformación

El subset de enseñanza se construye con [`R/00-construir-datos.R`](../R/00-construir-datos.R):
selección de columnas, unión Personas↔Hogares, recodificación a etiquetas legibles y
filtrado de filas sin ingreso/peso. Resultado: `geih_pobreza_2019_2021.rds`
(y `.csv.gz`), 1.467.444 personas.

## Verificación

El subset reproduce **exactamente** las cifras oficiales de pobreza del DANE
(ponderando por `fex`):

| Año | Pobreza monetaria | Pobreza extrema | Población |
|---|---|---|---|
| 2019 | 35,7 % | 9,6 % | 48,9 M |
| 2021 | 39,3 % | 12,2 % | 49,9 M |

## Licencia / atribución

Microdata anonimizada de uso público (Ley 79 de 1993, reserva estadística). Los
términos del DANE autorizan «el uso, aprovechamiento, transformación y análisis» de la
información con la cita textual obligatoria:

> **«Fuente: Departamento Administrativo Nacional de Estadística: www.dane.gov.co»**

Uso no comercial / académico. El DANE no se responsabiliza por el uso de la información.
Términos: https://www.dane.gov.co/index.php/servicios-al-ciudadano/tramites/transparencia-y-acceso-a-la-informacion-publica/terminos-y-condiciones
