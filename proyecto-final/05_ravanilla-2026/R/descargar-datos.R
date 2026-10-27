# =============================================================================
# descargar-datos.R — Proyecto final · Ravanilla (2026), SSRN
# Baja el paquete de réplica (Harvard Dataverse) a datos/_crudos/.
#
# Corra este script con ESTA carpeta (05_ravanilla-2026) como directorio de
# trabajo. Lo que baja no se versiona: datos/_crudos/ está en el .gitignore.
#
# Fuente: https://doi.org/10.7910/DVN/L5M1NK  (CC0 1.0)
# Contenido: paneles construidos a partir de la Labor Force Survey de
# Filipinas (Data/), libro de códigos (Codebook.txt), código de Stata 18
# (Code/master.do) y Python para las figuras, y todos los resultados (Output/).
# El archivo de Dataverse es un .zip que contiene otro .zip; este script abre
# los dos. Comprimido pesa ~13,5 MB.
# =============================================================================

options(timeout = max(1800, getOption("timeout")))
dir.create("datos/_crudos", recursive = TRUE, showWarnings = FALSE)

url     <- "https://dataverse.harvard.edu/api/access/datafile/14122727"
destino <- "datos/_crudos/dataverse_deposit_upload.zip"

if (!file.exists(destino)) download.file(url, destino, mode = "wb")
unzip(destino, exdir = "datos/_crudos")

# Zip interno
interno <- list.files("datos/_crudos", pattern = "^dataverse_deposit\\.zip$",
                      recursive = TRUE, full.names = TRUE)[1]
unzip(interno, exdir = "datos/_crudos")

print(list.files("datos/_crudos/dataverse_deposit"))
