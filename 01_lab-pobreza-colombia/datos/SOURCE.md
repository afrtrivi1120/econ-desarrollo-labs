# Procedencia de los datos

## Fuente original

**Departamento Administrativo Nacional de Estadística (DANE)** — *Medición de Pobreza
Monetaria y Desigualdad*, microdatos anonimizados de la Gran Encuesta Integrada de
Hogares (GEIH).

| Año | Catálogo DANE | Ficha | En el portal | Al descomprimir |
|---|---|---|---|---|
| 2019 | 684 | https://microdatos.dane.gov.co/index.php/catalog/684 | *Personas*, *Hogares* | `Personasd2019.csv`, `Hogaresd2019.csv` |
| 2021 | 733 | https://microdatos.dane.gov.co/index.php/catalog/733 | *Personas*, *Hogares* | `Personas2021.csv`, `Hogares2021.csv` |

> Los nombres de la última columna son los que traen los ZIP del portal al
> abrirlos, y son los que hay que dejar en `datos/_crudos/` si va a rehacer el
> extracto.

Los archivos de **Hogares** traen el ingreso (`ingpcug`), las líneas (`lp`, `li`) y
los indicadores de pobreza (`pobre`, `indigente`); los de **Personas** traen la
demografía (`p6040` edad, `p6020` sexo, `p6210` educación) y el factor de expansión
(`fex_c`). Se unen por `directorio` + `secuencia_p`.

### Detalles de formato de los archivos crudos

- **2019:** CSV con delimitador `;`, decimal `,` (formato europeo), UTF-8.
- **2021:** CSV con delimitador `,`, decimal `.`.

Así es como los publica el DANE, y por eso el lab lee cada año en su propio bloque.

---

## Qué hay en `_crudos/` y por qué

El DANE publica los archivos completos: **137 columnas** el de personas y 25 (2019) o
22 (2021) el de hogares, con cientos de MB por año.
Eso no cabe en un repositorio de git (GitHub rechaza archivos de más de 100 MB).

Lo que se versiona acá es un **extracto crudo**: los mismos cuatro archivos, con

- los **nombres originales** de las columnas (`p6020`, `p6210`, `fex_c`…),
- los **códigos sin recodificar** (1/2 para sexo, 1–6 y 9 para educación),
- el **separador y el decimal originales** de cada año,
- y **todas las filas**,

pero solo con los campos que el lab usa: **11 variables distintas** repartidas en 13
campos, porque `directorio` y `secuencia_p` están en los dos archivos. Al no quitar
ninguna fila, el extracto reproduce exactamente las cifras oficiales del DANE.

```
_crudos/geih-2019-personas.csv.gz   directorio;secuencia_p;clase;p6020;p6040;p6210;fex_c
_crudos/geih-2019-hogares.csv.gz    directorio;secuencia_p;ingpcug;lp;pobre;indigente
_crudos/geih-2021-personas.csv.gz   directorio,secuencia_p,clase,p6020,p6040,p6210,fex_c
_crudos/geih-2021-hogares.csv.gz    directorio,secuencia_p,ingpcug,lp,pobre,indigente
```

### Cómo reconstruir el extracto desde el portal del DANE

La descarga de microdatos del DANE está detrás de un **reCAPTCHA**, así que ese primer
paso hay que hacerlo con un navegador: no se puede automatizar. El resto sí está en código.

1. Entre a la ficha del año ([684](https://microdatos.dane.gov.co/index.php/catalog/684) o
   [733](https://microdatos.dane.gov.co/index.php/catalog/733)) y abra **Obtener
   microdatos**.
2. Descargue y descomprima **Personas** y **Hogares**, y deje los cuatro CSV en
   `datos/_crudos/` con estos nombres exactos (son los que traen los ZIP al abrirlos):

   ```
   datos/_crudos/Personasd2019.csv    datos/_crudos/Hogaresd2019.csv
   datos/_crudos/Personas2021.csv     datos/_crudos/Hogares2021.csv
   ```

   > ⚠️ En 2021 el portal ofrece también **`Hogares_empalmado`**. **No es ese.** Trae
   > `ingpcug` con ajuste a la nueva PET y `fex_c` con empalme de mercado laboral y
   > CNPV 2018, y da cifras distintas de las oficiales de 2021.

3. Haga el recorte: de cada archivo completo quédese **solo con estas columnas** y
   guárdelo comprimido con el nombre que espera el lab.

   | Archivo completo | Columnas que se conservan | Sale como |
   |---|---|---|
   | `Personasd2019.csv` | `directorio`, `secuencia_p`, `clase`, `p6020`, `p6040`, `p6210`, `fex_c` | `geih-2019-personas.csv.gz` |
   | `Hogaresd2019.csv` | `directorio`, `secuencia_p`, `ingpcug`, `lp`, `pobre`, `indigente` | `geih-2019-hogares.csv.gz` |
   | `Personas2021.csv` | las mismas siete de personas | `geih-2021-personas.csv.gz` |
   | `Hogares2021.csv` | las mismas seis de hogares | `geih-2021-hogares.csv.gz` |

   Dos reglas que no se pueden saltar:

   - **Conserve el separador y el decimal de cada año**, tanto al leer como al
     escribir: `;` y `,` en 2019, `,` y `.` en 2021 (los archivos de 2019 además
     traen BOM, así que léalos como UTF-8). El extracto debe verse como se ve la
     fuente.
   - **No quite ninguna fila.** El recorte es de columnas, nunca de filas: es lo
     que hace que el extracto siga reproduciendo las cifras oficiales.

4. Corra el lab. Su bloque de **verificación** le dice si quedó bien: si
   las cifras no dan 35,7 % y 39,3 %, algo se perdió en el camino.

### La cadena completa

```
CSV completos del DANE  ──[recorte de columnas]──▶  _crudos/*.csv.gz  ──[el lab]──▶  .rds
   474 MB, no van al repo         (paso 3)            12 MB, sí van                subset limpio
```

---

## El diccionario de variables

`diccionario-dane/` trae el **diccionario de datos oficial** de ambos catálogos, en
formato DDI (XML), descargado de:

```
https://microdatos.dane.gov.co/index.php/metadata/export/684/ddi
https://microdatos.dane.gov.co/index.php/metadata/export/733/ddi
```

De ahí salen —textualmente— las definiciones y las etiquetas de código que aparecen en
[`codebook.md`](codebook.md) y en el cuaderno. El DANE **no publica un PDF de codebook**;
el DDI es la documentación autorizada.

---

## Transformación

La limpieza está **dentro del lab**, en la sección *Una transformación del microdato*
(`lab1-distribucion-ingreso.qmd` y `R/lab1-distribucion-ingreso.R`): unión
Personas↔Hogares, recodificación a etiquetas legibles y filtrado de filas sin ingreso o
sin peso. Resultado: `geih_pobreza_2019_2021.rds`, **1.467.444 personas**
(756.063 de 2019 y 711.381 de 2021).

> En estos dos años el filtro **no elimina ninguna fila**: el módulo de pobreza del DANE
> viene completo. Se conserva como red de seguridad, no porque haga falta acá.

**Comprobado:** el subset que construye el lab desde `_crudos/` es idéntico
(`all.equal()` $=$ `TRUE`) al `.rds` versionado. La limpieza que se le muestra al
estudiante es la que realmente produjo el archivo.

> El lab **no reescribe** ese archivo en cada corrida —es un artefacto versionado—. Para
> regenerarlo a propósito hay que descomentar la línea de `write_rds()` al final de
> *Una transformación del microdato*.

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
