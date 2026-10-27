# =============================================================================
# descargar-datos.R — Proyecto final · del Rio-Chanona, Laurentsyeva y Wachs
# (2024), PNAS Nexus
# Baja el paquete de réplica (Zenodo).
#
# Corra este script con ESTA carpeta (02_delriochanona-2024) como directorio de
# trabajo. Lo que baja no se versiona: datos/_crudos/ está en el .gitignore.
#
# ⚠️ PESO: el paquete de réplica pesa ~2,9 GB. Bájelo con buena conexión y
#    verifique que tiene espacio en disco antes de correr.
#
# Fuente: https://zenodo.org/records/12670482  (CC BY 4.0)
# =============================================================================

options(timeout = max(7200, getOption("timeout")))
dir.create("datos/_crudos", recursive = TRUE, showWarnings = FALSE)

url_rep     <- "https://zenodo.org/records/12670482/files/replication.zip?download=1"
destino_rep <- "datos/_crudos/replication.zip"

if (!file.exists(destino_rep)) download.file(url_rep, destino_rep, mode = "wb")
unzip(destino_rep, exdir = "datos/_crudos/delriochanona-2024")
print(list.files("datos/_crudos/delriochanona-2024", recursive = FALSE))
