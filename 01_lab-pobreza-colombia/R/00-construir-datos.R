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

# =============================================================================
# 0. PREPARACIÓN
# =============================================================================
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, data.table)
# data.table entra solo por fread(): los CSV del DANE traen 137 columnas y
# millones de filas, y con select = ... leemos únicamente las 7 que usamos.
# Después de leer pasamos a tibble y seguimos con dplyr.

# Carpeta con los CSV crudos del DANE (Personas/Hogares 2019 y 2021).
RAW <- Sys.getenv("GEIH_RAW", "datos/_crudos")

# El ingreso y la pobreza viven en HOGARES; la demografía, en PERSONAS.
# Se unen por directorio + secuencia_p (identificador del hogar).
# Ojo: los archivos de 2019 y 2021 vienen con separadores distintos, por eso
# los leemos en dos bloques separados en vez de meterlos en un solo molde.

# =============================================================================
# 1. AÑO 2019  (CSV separado por ";" y decimal ",")
# =============================================================================
personas_2019 <- fread(
  file.path(RAW, "Personasd.csv"), sep = ";", dec = ",", encoding = "UTF-8",
  select = c("directorio", "secuencia_p", "clase", "p6020", "p6040", "p6210", "fex_c")
) |>
  as_tibble()

hogares_2019 <- fread(
  file.path(RAW, "Hogaresd.csv"), sep = ";", dec = ",", encoding = "UTF-8",
  select = c("directorio", "secuencia_p", "ingpcug", "lp", "pobre", "indigente")
) |>
  as_tibble()

# A cada persona le pegamos el ingreso y la pobreza de su hogar.
geih_2019 <- personas_2019 |>
  left_join(hogares_2019, by = c("directorio", "secuencia_p")) |>
  mutate(anio = 2019)

# =============================================================================
# 2. AÑO 2021  (CSV separado por "," y decimal ".")
# =============================================================================
personas_2021 <- fread(
  file.path(RAW, "Personas.csv"), sep = ",", dec = ".", encoding = "UTF-8",
  select = c("directorio", "secuencia_p", "clase", "p6020", "p6040", "p6210", "fex_c")
) |>
  as_tibble()

hogares_2021 <- fread(
  file.path(RAW, "Hogares.csv"), sep = ",", dec = ".", encoding = "UTF-8",
  select = c("directorio", "secuencia_p", "ingpcug", "lp", "pobre", "indigente")
) |>
  as_tibble()

geih_2021 <- personas_2021 |>
  left_join(hogares_2021, by = c("directorio", "secuencia_p")) |>
  mutate(anio = 2021)

# =============================================================================
# 3. APILAR LOS DOS AÑOS Y RECODIFICAR
# =============================================================================
geih <- bind_rows(geih_2019, geih_2021)

geih <- geih |>
  mutate(
    # Sexo: 1 = hombre, 2 = mujer.
    sexo = factor(p6020, levels = c(1, 2), labels = c("Hombre", "Mujer")),

    # Área: 1 = cabecera (urbano), 2 = resto (rural).
    area = factor(clase, levels = c(1, 2), labels = c("Urbano", "Rural")),

    # Nivel educativo (p6210), colapsado a 4 categorías estilo Banco Mundial:
    #   1 Ninguno · 2 Preescolar · 3 Primaria · 4 Secundaria · 5 Media
    #   6 Superior · 9 No sabe / no informa
    educ = case_when(
      p6210 %in% c(1, 2) ~ "Sin educación",
      p6210 == 3         ~ "Primaria",
      p6210 %in% c(4, 5) ~ "Secundaria",
      p6210 == 6         ~ "Superior",
      .default = NA_character_
    ),
    educ = factor(educ, levels = c("Sin educación", "Primaria", "Secundaria", "Superior"))
  )

# =============================================================================
# 4. SUBSET FINAL DE ENSEÑANZA
# =============================================================================
sub <- geih |>
  select(
    anio,
    fex = fex_c,        # factor de expansión (personas)
    ingpcug,            # ingreso per cápita de la unidad de gasto
    lp,                 # línea de pobreza monetaria (DANE)
    pobre,              # 1 = persona en pobreza monetaria
    indigente,          # 1 = persona en pobreza extrema
    edad = p6040,
    sexo, educ, area
  ) |>
  filter(!is.na(ingpcug), !is.na(fex))   # quitamos filas sin ingreso o sin peso

# =============================================================================
# 5. VERIFICACIÓN: la pobreza ponderada debe reproducir la cifra oficial
# =============================================================================
chequeo <- sub |>
  group_by(anio) |>
  summarise(
    pobreza  = round(weighted.mean(pobre, fex) * 100, 1),
    extrema  = round(weighted.mean(indigente, fex) * 100, 1),
    personas = round(sum(fex) / 1e6, 1)
  )

print(chequeo)
cat("\nOficial DANE (referencia): pobreza 2019=35.7%, 2021=39.3% | extrema 2019=9.6%, 2021=12.2%\n")

# =============================================================================
# 6. GUARDAR EL SUBSET
# =============================================================================
write_rds(sub, "datos/geih_pobreza_2019_2021.rds")
write_csv(sub, "datos/geih_pobreza_2019_2021.csv.gz")   # write_csv comprime solo si el nombre termina en .gz

cat("\nSubset guardado:", nrow(sub), "filas x", ncol(sub), "columnas\n")
