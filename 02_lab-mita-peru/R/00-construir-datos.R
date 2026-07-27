# =============================================================================
# 00-construir-datos.R
# Construye los SUBSETS DE ENSEÑANZA a partir de los archivos originales de la
# réplica de Dell (2010).
# (Esto NO se corre en clase: ya dejamos los subsets listos en datos/.
#  Se incluye para que el ejercicio sea 100% reproducible.)
#
# Entradas esperadas en datos/_crudos/  (ver datos/SOURCE.md):
#   mitaData.dta   — hogares de la ENAHO 2001 a menos de 100 km de la frontera.
#                    Distribuido por MIT OpenCourseWare 14.75 (CC BY-NC-SA 4.0).
#   gis_dist.dta   — 299 distritos con la geografía del diseño RD (Dell 2010).
#   dem1572.dta    — censo de Toledo (1572), ANTERIOR a la mita: 109 distritos.
#
# Los dos últimos vienen del paquete de réplica de Dell; ninguno se versiona.
# =============================================================================

library(haven)        # lectura de archivos .dta de Stata
library(data.table)   # manejo de datos

RAW <- Sys.getenv("MITA_RAW", "datos/_crudos")

# Los archivos distritales llegaron dentro de un paquete de réplica de terceros;
# los buscamos por nombre en cualquier subcarpeta de datos/_crudos/.
buscar <- function(nombre) {
  hits <- list.files(RAW, pattern = paste0("^", nombre, "$"),
                     recursive = TRUE, full.names = TRUE)
  if (length(hits) == 0) stop("No se encontró ", nombre, " dentro de ", RAW)
  hits[1]
}

# Lee un .dta y devuelve un data.table sin etiquetas de Stata.
leer_dta <- function(ruta) as.data.table(zap_labels(read_dta(ruta)))

# =============================================================================
# 1. HOGARES — la muestra de la Tabla II, Panel A de Dell
# =============================================================================
hog <- leer_dta(buscar("mitaData.dta"))

# Fallar fuerte si falta alguna variable: nunca rellenar a mano.
necesarias_hog <- c("lhhequiv", "pothuan_mita", "d_bnd", "x", "y", "lat", "lon",
                    "elv_sh", "slope", "infants", "children", "adults",
                    "bfe4_1", "bfe4_2", "bfe4_3", "dpot", "district")
faltan <- setdiff(necesarias_hog, names(hog))
if (length(faltan)) stop("Faltan variables en mitaData.dta: ", paste(faltan, collapse = ", "))

hogares <- hog[, .(
  distrito   = district,          # identificador de distrito (nivel de clúster)
  mita       = pothuan_mita,      # 1 = distrito sujeto a la mita
  lhhequiv,                       # log del consumo del hogar por adulto equivalente
  d_bnd,                          # distancia a la frontera de la mita (km, sin signo)
  dpot,                           # distancia a Potosí (km)
  x, y,                           # longitud y latitud recentradas (grados)
  # Los archivos originales guardan lat/lon en valor absoluto; el sur del Perú
  # está en latitud y longitud NEGATIVAS, así que les devolvemos el signo para
  # que el mapa quede orientado como el mundo real.
  lat = -lat, lon = -lon,         # coordenadas del distrito
  elv_sh,                         # elevación (1.000 m)
  slope,                          # pendiente media
  infants, children, adults,      # composición del hogar
  bfe4_1, bfe4_2, bfe4_3          # efectos fijos de segmento de frontera (4 segmentos)
)]

# Variable de asignación CON SIGNO: negativa fuera de la mita, positiva dentro.
# Es la que hace visible la discontinuidad y la que consume rdrobust.
hogares[, dist_frontera := d_bnd * (2 * mita - 1)]

# =============================================================================
# 2. DISTRITOS — geografía del diseño (299) + censo de Toledo de 1572 (109)
# =============================================================================
gis <- leer_dta(buscar("gis_dist.dta"))
dem <- leer_dta(buscar("dem1572.dta"))

necesarias_gis <- c("ubigeo", "pothuan_mita", "d_bnd", "lat", "lon", "x", "y",
                    "elv_sh", "slope", "border", "bfe4_1", "bfe4_2", "bfe4_3")
faltan <- setdiff(necesarias_gis, names(gis))
if (length(faltan)) stop("Faltan variables en gis_dist.dta: ", paste(faltan, collapse = ", "))

# Del censo de 1572 nos quedamos con la composición demográfica PRE-mita:
# si estas variables saltan en la frontera, el supuesto de continuidad falla.
pre <- dem[, .(ubigeo,
               pob1572     = total_pop,   # población total registrada en 1572
               sh_trib,                   # participación de tributarios
               sh_boys,                   # participación de niños
               sh_women)]                 # participación de mujeres

distritos <- merge(
  gis[, .(ubigeo,
          mita     = pothuan_mita,
          frontera = border,              # 1 = distrito que toca la frontera
          d_bnd,
          lat = -lat, lon = -lon,         # signo real: sur del Perú
          x, y,
          elv_sh, slope,
          bfe4_1, bfe4_2, bfe4_3)],
  pre, by = "ubigeo", all.x = TRUE)

distritos[, dist_frontera := d_bnd * (2 * mita - 1)]

# =============================================================================
# 3. VERIFICACIÓN — ¿reproducimos la Tabla II de Dell?
# =============================================================================
# Tabla II, Panel A, col. 1: cúbica en longitud y latitud, muestra < 100 km,
# errores estándar agrupados por distrito.
suppressMessages(library(fixest))

m <- feols(
  lhhequiv ~ mita + x + y + I(x^2) + I(y^2) + I(x * y) +
    I(x^3) + I(y^3) + I(x^2 * y) + I(x * y^2) +
    elv_sh + slope + infants + children + adults + bfe4_1 + bfe4_2 + bfe4_3,
  data = hogares[d_bnd < 100], cluster = ~distrito)

ct <- coeftable(m)["mita", ]
cat("\n--- Verificación contra Dell (2010), Tabla II, Panel A, col. 1 ---\n")
cat(sprintf("Coeficiente de la mita: %.3f (EE %.3f)  ->  %.1f%% de consumo\n",
            ct[1], ct[2], (exp(ct[1]) - 1) * 100))
cat(sprintf("N = %d hogares en %d distritos\n", nobs(m), uniqueN(hogares[d_bnd < 100]$distrito)))
cat("Publicado (Dell 2010, p. 1879): la mita reduce el consumo ~25%;\n")
cat("en el Panel A los coeficientes NO son estadísticamente significativos.\n")

# --- Balance pre-mita: el censo de 1572 no debería saltar en la frontera ------
cat("\n--- Balance pre-mita (censo de Toledo, 1572) ---\n")
for (v in c("sh_trib", "sh_boys", "sh_women")) {
  f <- as.formula(paste(v, "~ mita + x + y + I(x^2) + I(y^2) + I(x*y) +",
                        "I(x^3) + I(y^3) + I(x^2*y) + I(x*y^2) +",
                        "elv_sh + slope + bfe4_1 + bfe4_2 + bfe4_3"))
  mb <- feols(f, data = distritos[d_bnd < 100 & !is.na(sh_trib)], vcov = "hetero")
  cb <- coeftable(mb)["mita", ]
  cat(sprintf("  %-9s coef = %7.4f  EE = %6.4f  p = %.3f\n", v, cb[1], cb[2], cb[4]))
}

# =============================================================================
# 4. GUARDAR LOS SUBSETS
# =============================================================================
saveRDS(hogares,   "datos/dell_mita_hogares.rds")
fwrite(hogares,    "datos/dell_mita_hogares.csv.gz")
saveRDS(distritos, "datos/dell_mita_distritos.rds")
fwrite(distritos,  "datos/dell_mita_distritos.csv.gz")

cat(sprintf("\nGuardado: hogares %d x %d | distritos %d x %d\n",
            nrow(hogares), ncol(hogares), nrow(distritos), ncol(distritos)))
