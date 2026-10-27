# =============================================================================
# descargar-datos.R — Proyecto final · Noy y Zhang (2023), Science
# Baja el paquete de réplica original (OSF) a datos/_crudos/.
#
# Corra este script con ESTA carpeta (01_noy-zhang-2023) como directorio de
# trabajo. Lo que baja no se versiona: datos/_crudos/ está en el .gitignore.
#
# Fuente: https://osf.io/xd7qw  (público; sin licencia declarada)
# Contenido: raw/ (encuestas y calificaciones en .csv), code/ (Stata .do y
# Python), ado/, ReadMe en PDF. Comprimido pesa ~10 MB; descomprimido ~67 MB.
# =============================================================================

options(timeout = max(1800, getOption("timeout")))
dir.create("datos/_crudos", recursive = TRUE, showWarnings = FALSE)

url     <- "https://files.osf.io/v1/resources/xd7qw/providers/osfstorage/?zip="
destino <- "datos/_crudos/noy-zhang-2023-osf.zip"

if (!file.exists(destino)) download.file(url, destino, mode = "wb")
unzip(destino, exdir = "datos/_crudos/noy-zhang-2023")

# Verificación rápida: deben aparecer las carpetas raw/ y code/
print(list.files("datos/_crudos/noy-zhang-2023"))
