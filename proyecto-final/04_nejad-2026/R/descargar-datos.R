# =============================================================================
# descargar-datos.R — Proyecto final · Abbas Nejad, Musillo, Wicker y Zaccaria
# (2026), Journal of Labor Economics
# Baja el paquete de réplica (Harvard Dataverse) a datos/_crudos/.
#
# Corra este script con ESTA carpeta (04_nejad-2026) como directorio de
# trabajo. Lo que baja no se versiona: datos/_crudos/ está en el .gitignore.
#
# Fuente: https://doi.org/10.7910/DVN/LPIREO  (CC0 1.0)
# Contenido: datos de los dos experimentos (.dta y .csv), código de Stata con
# archivo maestro, scripts de R y Python para las medidas de texto y MATLAB
# para la simulación del modelo. Comprimido pesa ~2,8 MB.
# =============================================================================

options(timeout = max(1800, getOption("timeout")))
dir.create("datos/_crudos", recursive = TRUE, showWarnings = FALSE)

url     <- "https://dataverse.harvard.edu/api/access/datafile/13467659"
destino <- "datos/_crudos/ChatGPT_ReplicationPackage.zip"

if (!file.exists(destino)) download.file(url, destino, mode = "wb")

# El paquete trae un archivo de credenciales de un servicio externo que no hace
# falta para replicar; no se extrae.
archivos <- unzip(destino, list = TRUE)$Name
archivos <- archivos[!grepl("openai_key", archivos) & !grepl("^__MACOSX/", archivos)]
unzip(destino, files = archivos, exdir = "datos/_crudos/nejad-2026")

print(list.files("datos/_crudos/nejad-2026", recursive = FALSE))
