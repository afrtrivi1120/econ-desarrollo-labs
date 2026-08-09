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
demografía (`p6040` edad, `p6020` sexo, `p6210` educación) y el factor de expansión
(`fex_c`). Se unen por `directorio` + `secuencia_p`.

### Detalles de formato de los archivos crudos

- **2019:** CSV con delimitador `;`, decimal `,` (formato europeo), UTF-8.
- **2021:** CSV con delimitador `,`, decimal `.`.

Esa diferencia **no es un descuido**: es como los publica el DANE, y por eso el lab lee
cada año en su propio bloque.

---

## Qué hay en `_crudos/` y por qué

El DANE publica los archivos completos, con **137 columnas** y cientos de MB por año.
Eso no cabe en un repositorio de git (GitHub rechaza archivos de más de 100 MB).

Lo que se versiona acá es un **extracto crudo**: los mismos cuatro archivos, con

- los **nombres originales** de las columnas (`p6020`, `p6210`, `fex_c`…),
- los **códigos sin recodificar** (1/2 para sexo, 1–6 y 9 para educación),
- el **separador y el decimal originales** de cada año,
- y **todas las filas**,

pero solo con las **13 columnas que el lab usa**. Al no quitar ninguna fila, el extracto
reproduce exactamente las cifras oficiales del DANE.

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
   `datos/_crudos/` con los nombres que trae el portal:

   ```
   datos/_crudos/Personasd2019.csv    datos/_crudos/Hogaresd2019.csv
   datos/_crudos/Personas2021.csv     datos/_crudos/Hogares2021.csv
   ```

   > ⚠️ En 2021 el portal ofrece también **`Hogares_empalmado`**. **No es ese.** Trae
   > `ingpcug` con ajuste a la nueva PET y `fex_c` con empalme de mercado laboral y
   > CNPV 2018, y da cifras distintas de las oficiales de 2021.

3. Corra el recorte:

   ```r
   source("R/00-recortar-crudos.R")
   ```

   Lee los cuatro archivos completos, se queda con las 13 columnas que el lab usa y
   escribe los `.csv.gz` **conservando el separador y el decimal de cada año**. No quita
   ninguna fila.

4. Corra el lab. El bloque de **verificación** de su sección 1 le dice si quedó bien: si
   las cifras no dan 35,7 % y 39,3 %, algo se perdió en el camino.

### La cadena completa

```
CSV completos del DANE  ──[R/00-recortar-crudos.R]──▶  _crudos/*.csv.gz  ──[sección 1 del lab]──▶  .rds
   474 MB, no van al repo                                12 MB, sí van                         subset limpio
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

La limpieza está **dentro del lab**, en la sección *De la microdata cruda al subset*
(`lab1-distribucion-ingreso.qmd` y `R/lab1-distribucion-ingreso.R`): unión
Personas↔Hogares, recodificación a etiquetas legibles y filtrado de filas sin ingreso o
sin peso. Resultado: `geih_pobreza_2019_2021.rds` (y `.csv.gz`), **1.467.444 personas**
(756.063 de 2019 y 711.381 de 2021).

> En estos dos años el filtro **no elimina ninguna fila**: el módulo de pobreza del DANE
> viene completo. Se conserva como red de seguridad, no porque haga falta acá.

**Comprobado:** el subset que construye el lab desde `_crudos/` es idéntico
(`all.equal()` $=$ `TRUE`) al `.rds` versionado. La limpieza que se le muestra al
estudiante es la que realmente produjo el archivo.

> El lab **no reescribe** ese archivo en cada corrida —es un artefacto versionado—. Para
> regenerarlo a propósito hay que descomentar las dos líneas de `write_*` al final de la
> sección 1.

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
