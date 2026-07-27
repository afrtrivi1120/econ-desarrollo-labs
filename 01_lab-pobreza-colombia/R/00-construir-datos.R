# =============================================================================
# 00-construir-datos.R
# Construye el SUBSET DE ENSEÑANZA a partir de la microdata cruda del DANE.
# (Esto NO se corre en clase: ya dejamos el subset listo en datos/.
#  Se incluye para que el ejercicio sea 100% reproducible.)
#
# Fuente: DANE — Medición de Pobreza Monetaria y Desigualdad
#   2019: https://microdatos.dane.gov.co/index.php/catalog/684
#   2021: https://microdatos.dane.gov.co/index.php/catalog/733
# Los archivos crudos (Personas + Hogares de cada año) van en datos/_crudos/.
# =============================================================================

library(data.table)   # lectura rápida de CSV grandes

# Carpeta con los CSV crudos del DANE (Personas/Hogares 2019 y 2021).
RAW <- Sys.getenv("GEIH_RAW", "datos/_crudos")

# --- Helper: lee Personas + Hogares de un año y los une por hogar -------------
# El ingreso y la pobreza viven en HOGARES; la demografía en PERSONAS.
# Se unen por directorio + secuencia_p (identificador del hogar).
cargar_anio <- function(anio, f_personas, f_hogares, sep, dec, depto) {
  # Solo leemos las columnas necesarias (los archivos traen 137 columnas).
  per <- fread(file.path(RAW, f_personas), sep = sep, dec = dec,
               select = c("directorio","secuencia_p","clase",
                          "p6020","p6040","p6210","fex_c"),
               encoding = "UTF-8")
  hog <- fread(file.path(RAW, f_hogares), sep = sep, dec = dec,
               select = c("directorio","secuencia_p","ingpcug","lp",
                          "pobre","indigente"),
               encoding = "UTF-8")

  # Unimos a cada persona el ingreso y la pobreza de su hogar.
  d <- merge(per, hog, by = c("directorio","secuencia_p"), all.x = TRUE)
  d[, anio := anio]
  d
}

d19 <- cargar_anio(2019, "Personasd.csv", "Hogaresd.csv", sep = ";", dec = ",", depto = "depto")
d21 <- cargar_anio(2021, "Personas.csv",  "Hogares.csv",  sep = ",", dec = ".", depto = "dpto")

geih <- rbindlist(list(d19, d21))

# --- Recodificación a etiquetas legibles --------------------------------------
geih[, sexo := factor(p6020, levels = c(1, 2), labels = c("Hombre", "Mujer"))]

# Área: 1 = Cabecera (urbano), 2 = Resto (rural)
geih[, area := factor(clase, levels = c(1, 2), labels = c("Urbano", "Rural"))]

# Nivel educativo (p6210), colapsado a 4 categorías estilo Banco Mundial.
#   1 Ninguno · 2 Preescolar · 3 Primaria · 4 Secundaria · 5 Media · 6 Superior · 9 NS/NR
geih[, educ := fcase(
  p6210 %in% c(1, 2), "Sin educación",
  p6210 == 3,         "Primaria",
  p6210 %in% c(4, 5), "Secundaria",
  p6210 == 6,         "Superior",
  default = NA_character_)]
geih[, educ := factor(educ, levels = c("Sin educación","Primaria","Secundaria","Superior"))]

# --- Subset final de enseñanza ------------------------------------------------
sub <- geih[, .(anio,
                fex = fex_c,        # factor de expansión (personas)
                ingpcug,            # ingreso per cápita de la unidad de gasto
                lp,                 # línea de pobreza monetaria (DANE)
                pobre,              # 1 = persona en pobreza monetaria
                indigente,          # 1 = persona en pobreza extrema
                edad = p6040,
                sexo, educ, area)]
sub <- sub[!is.na(ingpcug) & !is.na(fex)]   # quitamos filas sin ingreso/peso

# --- VERIFICACIÓN: la pobreza ponderada debe reproducir la cifra oficial -------
chk <- sub[, .(pobreza = round(weighted.mean(pobre, fex) * 100, 1),
               extrema = round(weighted.mean(indigente, fex) * 100, 1),
               personas = round(sum(fex)/1e6, 1)), by = anio][order(anio)]
print(chk)
cat("\nOficial DANE (referencia): pobreza 2019=35.7%, 2021=39.3% | extrema 2019=9.6%, 2021=12.2%\n")

# --- Guardar subset -----------------------------------------------------------
saveRDS(sub, "datos/geih_pobreza_2019_2021.rds")
fwrite(sub, "datos/geih_pobreza_2019_2021.csv.gz")  # versión CSV comprimida
cat("\nSubset guardado:", nrow(sub), "filas x", ncol(sub), "columnas\n")
