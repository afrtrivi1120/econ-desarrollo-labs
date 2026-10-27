# =============================================================================
# descargar-datos.R — Proyecto final · Appel, McCrory, Tamkin et al. (2025)
# Baja de Hugging Face la versión del Anthropic Economic Index que usa el
# informe (release_2025_09_15): datos de uso por país, PIB, población en edad
# de trabajar, documentación y código.
#
# Corra este script con ESTA carpeta (06_appel-2025) como directorio de
# trabajo. Lo que baja no se versiona: datos/_crudos/ está en el .gitignore.
#
# Fuente: https://huggingface.co/datasets/Anthropic/EconomicIndex  (MIT)
# Peso total de la versión: ~60 MB en 38 archivos.
# =============================================================================

if (!require("pacman")) install.packages("pacman")
pacman::p_load(jsonlite)

options(timeout = max(1800, getOption("timeout")))
dir.create("datos/_crudos", recursive = TRUE, showWarnings = FALSE)

version <- "release_2025_09_15"
api     <- paste0("https://huggingface.co/api/datasets/Anthropic/EconomicIndex/tree/main/",
                  version, "?recursive=true")

archivos <- fromJSON(api)
archivos <- archivos$path[archivos$type == "file"]

for (ruta in archivos) {
  destino <- file.path("datos/_crudos", ruta)
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  if (!file.exists(destino)) {
    url <- paste0("https://huggingface.co/datasets/Anthropic/EconomicIndex/resolve/main/",
                  utils::URLencode(ruta))
    download.file(url, destino, mode = "wb", quiet = TRUE)
  }
}

cat("Archivos descargados:", length(archivos), "\n")
cat("Empiece por:", file.path("datos/_crudos", version, "data_documentation.md"), "\n")
