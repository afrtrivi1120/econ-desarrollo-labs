# =============================================================================
# descargar-datos.R — Proyecto final · del Rio-Chanona, Laurentsyeva y Wachs
# (2024), PNAS Nexus
# Baja el paquete de réplica (Zenodo) y, si se pide, los volcados de Stack
# Overflow en español y portugués para el análisis adicional.
#
# Corra este script con ESTA carpeta (02_delriochanona-2024) como directorio de
# trabajo. Lo que baja no se versiona: datos/_crudos/ está en el .gitignore.
#
# ⚠️ PESO: el paquete de réplica pesa ~2,9 GB. Bájelo con buena conexión y
#    verifique que tiene espacio en disco antes de correr.
#
# Fuentes:
#   Paquete de réplica: https://zenodo.org/records/12670482  (CC BY 4.0)
#   Volcados de Stack Exchange: https://archive.org/details/stackexchange
#   (snapshot de abril de 2024; licencia CC BY-SA del contenido de Stack Exchange)
# =============================================================================

options(timeout = max(7200, getOption("timeout")))
dir.create("datos/_crudos", recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. Paquete de réplica (~2,9 GB)
# -----------------------------------------------------------------------------
url_rep     <- "https://zenodo.org/records/12670482/files/replication.zip?download=1"
destino_rep <- "datos/_crudos/replication.zip"

if (!file.exists(destino_rep)) download.file(url_rep, destino_rep, mode = "wb")
unzip(destino_rep, exdir = "datos/_crudos/delriochanona-2024")
print(list.files("datos/_crudos/delriochanona-2024", recursive = FALSE))

# -----------------------------------------------------------------------------
# 2. (Opcional) Stack Overflow en español y portugués — análisis adicional
#    Cambie a TRUE solo si va a hacer esa extensión. Vienen comprimidos en .7z;
#    para abrirlos necesita 7-Zip (Windows) o `brew install sevenzip` (macOS).
# -----------------------------------------------------------------------------
BAJAR_VOLCADOS <- FALSE

if (BAJAR_VOLCADOS) {
  volcados <- c(
    "es.stackoverflow.com.7z",   # ~528 MB
    "pt.stackoverflow.com.7z"    # ~457 MB
  )
  for (v in volcados) {
    destino <- file.path("datos/_crudos", v)
    if (!file.exists(destino)) {
      download.file(paste0("https://archive.org/download/stackexchange/", v),
                    destino, mode = "wb")
    }
  }
}
