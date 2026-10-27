# =============================================================================
# descargar-datos.R — Proyecto final · Brodeur et al. (2026), PNAS
# Baja el paquete de réplica de la versión publicada (GitHub) a datos/_crudos/.
#
# Corra este script con ESTA carpeta (06_brodeur-2026) como directorio de
# trabajo. Lo que baja no se versiona: datos/_crudos/ está en el .gitignore.
#
# Fuente: https://github.com/I4Replication/AI-Games
#   (código con licencia MIT; datos CC BY 4.0, ver LICENSE-data). Todo en R:
#   code/cleaning.R limpia los datos y code/main.R produce la Tabla 2.
#   Pesa ~20 MB.
# El proyecto de OSF (https://osf.io/sz2g8/) guarda el plan de preanálisis y el
# paquete de la versión inicial del paper, que NO reproduce todas las cifras
# de la versión publicada en PNAS. Use el de GitHub.
# =============================================================================

options(timeout = max(1800, getOption("timeout")))
dir.create("datos/_crudos", recursive = TRUE, showWarnings = FALSE)

url     <- "https://github.com/I4Replication/AI-Games/archive/refs/heads/main.zip"
destino <- "datos/_crudos/AI-Games.zip"

if (!file.exists(destino)) download.file(url, destino, mode = "wb")
unzip(destino, exdir = "datos/_crudos")   # queda como AI-Games-main/

print(list.files("datos/_crudos/AI-Games-main"))
