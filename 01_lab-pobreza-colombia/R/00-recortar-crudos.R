# =============================================================================
# 00-recortar-crudos.R
# De los archivos COMPLETOS del DANE al EXTRACTO que se versiona en el repo.
#
# Esto NO se corre en clase: el extracto ya viene en datos/_crudos/*.csv.gz.
# Se corre una sola vez (o cuando cambien las columnas que usa el lab), y existe
# para que la cadena quede completa y reproducible:
#
#   CSV completos del DANE  ->  extracto .csv.gz  ->  subset limpio
#   (474 MB, no van al repo)    (12 MB, sí va)        (sección 1 del lab)
#
# Entradas esperadas en datos/_crudos/ (se bajan del portal a mano; la descarga
# está detrás de un reCAPTCHA). Ver datos/SOURCE.md:
#   Personasd2019.csv  Hogaresd2019.csv   -> catálogo 684
#   Personas2021.csv   Hogares2021.csv    -> catálogo 733
#
# OJO con 2021: el portal ofrece también "Hogares_empalmado". NO es ese: trae
# ingpcug con ajuste a la nueva PET y fex_c con empalme, y da cifras distintas.
# =============================================================================

# =============================================================================
# 0. PREPARACIÓN
# =============================================================================
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, data.table, R.utils)

# Las columnas que el lab usa. El archivo de personas del DANE trae 137 columnas y el
# de hogares 25 (2019) o 22 (2021); todo lo demás se descarta.
columnas_personas <- c("directorio", "secuencia_p", "clase",
                       "p6020", "p6040", "p6210", "fex_c")
columnas_hogares  <- c("directorio", "secuencia_p",
                       "ingpcug", "lp", "pobre", "indigente")

# Fallamos fuerte si falta alguno: nunca construir un extracto a medias.
originales <- c("datos/_crudos/Personasd2019.csv", "datos/_crudos/Hogaresd2019.csv",
                "datos/_crudos/Personas2021.csv",  "datos/_crudos/Hogares2021.csv")
faltan <- originales[!file.exists(originales)]
if (length(faltan)) {
  stop("Faltan los archivos completos del DANE:\n  ",
       paste(faltan, collapse = "\n  "),
       "\nBájelos del portal (ver datos/SOURCE.md).")
}

# =============================================================================
# 1. AÑO 2019  (separador ";", decimal ",", y los archivos traen BOM)
# =============================================================================
personas_2019 <- fread(
  "datos/_crudos/Personasd2019.csv", sep = ";", dec = ",", encoding = "UTF-8",
  select = columnas_personas
)

hogares_2019 <- fread(
  "datos/_crudos/Hogaresd2019.csv", sep = ";", dec = ",", encoding = "UTF-8",
  select = columnas_hogares
)

# Se escribe con el MISMO separador y decimal del original: el extracto debe
# verse como se ve la fuente, no como a nosotros nos quede cómodo.
fwrite(personas_2019, "datos/_crudos/geih-2019-personas.csv.gz", sep = ";", dec = ",")
fwrite(hogares_2019,  "datos/_crudos/geih-2019-hogares.csv.gz",  sep = ";", dec = ",")

# =============================================================================
# 2. AÑO 2021  (separador ",", decimal ".")
# =============================================================================
personas_2021 <- fread(
  "datos/_crudos/Personas2021.csv", sep = ",", dec = ".", encoding = "UTF-8",
  select = columnas_personas
)

hogares_2021 <- fread(
  "datos/_crudos/Hogares2021.csv", sep = ",", dec = ".", encoding = "UTF-8",
  select = columnas_hogares
)

fwrite(personas_2021, "datos/_crudos/geih-2021-personas.csv.gz", sep = ",", dec = ".")
fwrite(hogares_2021,  "datos/_crudos/geih-2021-hogares.csv.gz",  sep = ",", dec = ".")

# =============================================================================
# 3. VERIFICACIÓN
# =============================================================================
# No se pierde ninguna fila: el extracto recorta COLUMNAS, nunca filas. Por eso
# el lab sigue reproduciendo las cifras oficiales del DANE.
resumen <- tibble(
  archivo = c("personas 2019", "hogares 2019", "personas 2021", "hogares 2021"),
  filas   = c(nrow(personas_2019), nrow(hogares_2019),
              nrow(personas_2021), nrow(hogares_2021))
)
print(resumen)

cat(sprintf("\nPersonas en total: %d  (esperado: 1.467.444)\n",
            nrow(personas_2019) + nrow(personas_2021)))

cat("\nPeso del extracto:\n")
print(file.info(list.files("datos/_crudos", pattern = "\\.csv\\.gz$",
                           full.names = TRUE))["size"])

cat("\nListo. Ahora corra el lab: su sección 1 va del extracto al subset y\n",
    "verifica contra las cifras oficiales (35,7 % y 39,3 %).\n")
