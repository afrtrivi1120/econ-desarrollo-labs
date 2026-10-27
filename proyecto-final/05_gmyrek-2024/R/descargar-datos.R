# =============================================================================
# descargar-datos.R — Proyecto final · Gmyrek, Winkler y Garganta (2024)
# Baja el paquete de reproducibilidad del Banco Mundial (RR_LAC_2024_168).
#
# Corra este script con ESTA carpeta (05_gmyrek-2024) como directorio de
# trabajo. Lo que baja no se versiona: datos/_crudos/ está en el .gitignore.
#
# Fuente: https://reproducibility.worldbank.org/catalog/168  (BSD-3 modificada)
# Qué trae: el código (Stata 18 y R 4.3.2), los resultados en Excel y los
#   puntajes de exposición de la OIT de 2023 por ocupación ISCO-08
#   (bases/ILO/Gmyrek_Berg_Bescond_scores_2023.csv). ~9 MB comprimido.
# Qué NO trae: los microdatos armonizados de SEDLAC y de la OIT, que son de
#   acceso restringido. Para Colombia los reemplazamos con la GEIH pública:
#   descárguela a mano desde el portal del DANE (ver más abajo).
# =============================================================================

options(timeout = max(1800, getOption("timeout")))
dir.create("datos/_crudos", recursive = TRUE, showWarnings = FALSE)

url     <- "https://reproducibility.worldbank.org/catalog/168/download/469/RR_LAC_2024_168-v01.zip"
destino <- "datos/_crudos/RR_LAC_2024_168-v01.zip"

if (!file.exists(destino)) download.file(url, destino, mode = "wb")
unzip(destino, exdir = "datos/_crudos")

puntajes <- list.files("datos/_crudos", pattern = "Gmyrek_Berg_Bescond_scores_2023\\.csv$",
                       recursive = TRUE, full.names = TRUE)
print(puntajes)

# -----------------------------------------------------------------------------
# GEIH (DANE): descarga manual
#   Portal de microdatos: https://microdatos.dane.gov.co/index.php/catalog/central/about
#   Busque "Gran Encuesta Integrada de Hogares" y el año que va a usar, acepte
#   los términos de uso y guarde los archivos en datos/_crudos/geih/.
#   Cite siempre: "Fuente: DANE, www.dane.gov.co".
# -----------------------------------------------------------------------------
dir.create("datos/_crudos/geih", showWarnings = FALSE)
