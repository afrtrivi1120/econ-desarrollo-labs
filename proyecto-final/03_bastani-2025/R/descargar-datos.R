# =============================================================================
# descargar-datos.R — Proyecto final · Bastani et al. (2025), PNAS
# Baja el repositorio de réplica de GitHub a datos/_crudos/.
#
# Corra este script con ESTA carpeta (03_bastani-2025) como directorio de
# trabajo. Lo que baja no se versiona: datos/_crudos/ está en el .gitignore.
#
# Fuente: https://github.com/obastani/GenAICanHarmLearning  (sin licencia declarada)
# Contenido: datos a nivel estudiante (final_data.csv), regresiones principales
# en R (main_regressions/), resultados adicionales en Python y Stata
# (additional_results/) y los chats estudiante–GPT (text_analysis/). ~100 MB.
# =============================================================================

options(timeout = max(1800, getOption("timeout")))
dir.create("datos/_crudos", recursive = TRUE, showWarnings = FALSE)

url     <- "https://github.com/obastani/GenAICanHarmLearning/archive/refs/heads/main.zip"
destino <- "datos/_crudos/GenAICanHarmLearning.zip"

if (!file.exists(destino)) download.file(url, destino, mode = "wb")
unzip(destino, exdir = "datos/_crudos")

# El zip de GitHub se descomprime como GenAICanHarmLearning-main/
print(list.files("datos/_crudos/GenAICanHarmLearning-main"))
