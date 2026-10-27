# =============================================================================
# descargar-datos.R — Proyecto final · Eloundou, Manning, Mishkin y Rock (2024)
# Baja de GitHub los datos de exposición a los LLM (GPTs are GPTs) y, para
# robustez, el índice AIOE de Felten, Raj y Seamans.
#
# Corra este script con ESTA carpeta (04_eloundou-2024) como directorio de
# trabajo. Lo que baja no se versiona: datos/_crudos/ está en el .gitignore.
#
# Fuentes:
#   https://github.com/openai/GPTs-are-GPTs  (licencia MIT; ~30 MB)
#   https://github.com/AIOE-Data/AIOE        (sin licencia declarada; ~75 MB)
# Ojo: ambos usan códigos de ocupación SOC de EE. UU.
# =============================================================================

options(timeout = max(1800, getOption("timeout")))
dir.create("datos/_crudos", recursive = TRUE, showWarnings = FALSE)

repos <- c(
  "GPTs-are-GPTs" = "https://github.com/openai/GPTs-are-GPTs/archive/refs/heads/main.zip",
  "AIOE"          = "https://github.com/AIOE-Data/AIOE/archive/refs/heads/main.zip"
)

for (nombre in names(repos)) {
  destino <- file.path("datos/_crudos", paste0(nombre, ".zip"))
  if (!file.exists(destino)) download.file(repos[[nombre]], destino, mode = "wb")
  unzip(destino, exdir = "datos/_crudos")   # queda como <nombre>-main/
}

print(list.files("datos/_crudos/GPTs-are-GPTs-main/data"))
