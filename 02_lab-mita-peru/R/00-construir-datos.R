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

# =============================================================================
# 0. PREPARACIÓN
# =============================================================================
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, haven, fixest, broom)   # haven lee los .dta de Stata

RAW <- Sys.getenv("MITA_RAW", "datos/_crudos")

# Los archivos distritales llegaron dentro de un paquete de réplica de terceros,
# así que no sabemos en qué subcarpeta quedaron: los buscamos por nombre.
ruta_hogares  <- list.files(RAW, pattern = "^mitaData\\.dta$", recursive = TRUE, full.names = TRUE)[1]
ruta_gis      <- list.files(RAW, pattern = "^gis_dist\\.dta$", recursive = TRUE, full.names = TRUE)[1]
ruta_dem1572  <- list.files(RAW, pattern = "^dem1572\\.dta$",  recursive = TRUE, full.names = TRUE)[1]

if (is.na(ruta_hogares))  stop("No se encontró mitaData.dta dentro de ", RAW)
if (is.na(ruta_gis))      stop("No se encontró gis_dist.dta dentro de ", RAW)
if (is.na(ruta_dem1572))  stop("No se encontró dem1572.dta dentro de ", RAW)

# =============================================================================
# 1. HOGARES — la muestra de la Tabla II, Panel A de Dell
# =============================================================================
# zap_labels() bota las etiquetas de Stata y deja columnas numéricas limpias.
hog_crudo <- read_dta(ruta_hogares) |>
  zap_labels() |>
  as_tibble()

# Fallar fuerte si falta alguna variable: nunca rellenar a mano.
necesarias_hog <- c("lhhequiv", "pothuan_mita", "d_bnd", "x", "y", "lat", "lon",
                    "elv_sh", "slope", "infants", "children", "adults",
                    "bfe4_1", "bfe4_2", "bfe4_3", "dpot", "district")
faltan <- setdiff(necesarias_hog, names(hog_crudo))
if (length(faltan)) stop("Faltan variables en mitaData.dta: ", paste(faltan, collapse = ", "))

hogares <- hog_crudo |>
  select(
    distrito   = district,          # identificador de distrito (nivel de clúster)
    mita       = pothuan_mita,      # 1 = distrito sujeto a la mita
    lhhequiv,                       # log del consumo del hogar por adulto equivalente
    d_bnd,                          # distancia a la frontera de la mita (km, sin signo)
    dpot,                           # distancia a Potosí (km)
    x, y,                           # longitud y latitud recentradas (grados)
    lat, lon,                       # coordenadas del distrito
    elv_sh,                         # elevación (1.000 m)
    slope,                          # pendiente media
    infants, children, adults,      # composición del hogar
    bfe4_1, bfe4_2, bfe4_3          # efectos fijos de segmento de frontera (4 segmentos)
  ) |>
  mutate(
    # Los archivos originales guardan lat/lon en valor absoluto; el sur del Perú
    # está en latitud y longitud NEGATIVAS, así que les devolvemos el signo para
    # que el mapa quede orientado como el mundo real.
    lat = -lat,
    lon = -lon,
    # Variable de asignación CON SIGNO: negativa fuera de la mita, positiva dentro.
    # Es la que hace visible la discontinuidad y la que consume rdrobust.
    dist_frontera = d_bnd * (2 * mita - 1)
  )

# =============================================================================
# 2. DISTRITOS — geografía del diseño (299) + censo de Toledo de 1572 (109)
# =============================================================================
gis_crudo <- read_dta(ruta_gis) |>
  zap_labels() |>
  as_tibble()

dem_crudo <- read_dta(ruta_dem1572) |>
  zap_labels() |>
  as_tibble()

necesarias_gis <- c("ubigeo", "pothuan_mita", "d_bnd", "lat", "lon", "x", "y",
                    "elv_sh", "slope", "border", "bfe4_1", "bfe4_2", "bfe4_3")
faltan <- setdiff(necesarias_gis, names(gis_crudo))
if (length(faltan)) stop("Faltan variables en gis_dist.dta: ", paste(faltan, collapse = ", "))

# Del censo de 1572 nos quedamos con la composición demográfica PRE-mita:
# si estas variables saltan en la frontera, el supuesto de continuidad falla.
pre_mita <- dem_crudo |>
  select(
    ubigeo,
    pob1572 = total_pop,   # población total registrada en 1572
    sh_trib,               # participación de tributarios
    sh_boys,               # participación de niños
    sh_women               # participación de mujeres
  )

distritos <- gis_crudo |>
  select(
    ubigeo,
    mita     = pothuan_mita,
    frontera = border,              # 1 = distrito que toca la frontera
    d_bnd,
    lat, lon,
    x, y,
    elv_sh, slope,
    bfe4_1, bfe4_2, bfe4_3
  ) |>
  left_join(pre_mita, by = "ubigeo") |>
  mutate(
    lat = -lat,                     # signo real: sur del Perú
    lon = -lon,
    dist_frontera = d_bnd * (2 * mita - 1)
  ) |>
  arrange(ubigeo)

# =============================================================================
# 3. VERIFICACIÓN — ¿reproducimos la Tabla II de Dell?
# =============================================================================
# Tabla II, Panel A, col. 1: cúbica en longitud y latitud, muestra < 100 km,
# errores estándar agrupados por distrito.
hogares_100 <- hogares |> filter(d_bnd < 100)

m_principal <- feols(
  lhhequiv ~ mita +
    x + y + I(x^2) + I(y^2) + I(x * y) + I(x^3) + I(y^3) + I(x^2 * y) + I(x * y^2) +
    elv_sh + slope + infants + children + adults + bfe4_1 + bfe4_2 + bfe4_3,
  data = hogares_100, cluster = ~distrito
)

efecto <- tidy(m_principal) |>
  filter(term == "mita") |>
  mutate(
    efecto_pct = (exp(estimate) - 1) * 100,
    hogares    = nobs(m_principal),
    distritos  = n_distinct(hogares_100$distrito)
  ) |>
  select(coeficiente = estimate, ee = std.error, efecto_pct, hogares, distritos)

cat("\n--- Verificación contra Dell (2010), Tabla II, Panel A, col. 1 ---\n")
print(efecto)
cat("Publicado (Dell 2010, p. 1879): la mita reduce el consumo ~25%;\n")
cat("en el Panel A los coeficientes NO son estadísticamente significativos.\n")

# --- Balance pre-mita: el censo de 1572 no debería saltar en la frontera ------
# Tres regresiones explícitas, una por variable demográfica de 1572.
distritos_1572 <- distritos |>
  filter(d_bnd < 100, !is.na(sh_trib))

m_pre_tributarios <- feols(
  sh_trib ~ mita +
    x + y + I(x^2) + I(y^2) + I(x * y) + I(x^3) + I(y^3) + I(x^2 * y) + I(x * y^2) +
    elv_sh + slope + bfe4_1 + bfe4_2 + bfe4_3,
  data = distritos_1572, vcov = "hetero"
)

m_pre_ninos <- feols(
  sh_boys ~ mita +
    x + y + I(x^2) + I(y^2) + I(x * y) + I(x^3) + I(y^3) + I(x^2 * y) + I(x * y^2) +
    elv_sh + slope + bfe4_1 + bfe4_2 + bfe4_3,
  data = distritos_1572, vcov = "hetero"
)

m_pre_mujeres <- feols(
  sh_women ~ mita +
    x + y + I(x^2) + I(y^2) + I(x * y) + I(x^3) + I(y^3) + I(x^2 * y) + I(x * y^2) +
    elv_sh + slope + bfe4_1 + bfe4_2 + bfe4_3,
  data = distritos_1572, vcov = "hetero"
)

balance_1572 <- bind_rows(
  tidy(m_pre_tributarios) |> mutate(variable = "sh_trib"),
  tidy(m_pre_ninos)       |> mutate(variable = "sh_boys"),
  tidy(m_pre_mujeres)     |> mutate(variable = "sh_women")
) |>
  filter(term == "mita") |>
  select(variable, coef = estimate, ee = std.error, p = p.value)

cat("\n--- Balance pre-mita (censo de Toledo, 1572) ---\n")
print(balance_1572)
cat("Esperado: ningún salto significativo.\n")

# =============================================================================
# 4. GUARDAR LOS SUBSETS
# =============================================================================
write_rds(hogares,   "datos/dell_mita_hogares.rds")
write_csv(hogares,   "datos/dell_mita_hogares.csv.gz")     # write_csv comprime si el nombre termina en .gz
write_rds(distritos, "datos/dell_mita_distritos.rds")
write_csv(distritos, "datos/dell_mita_distritos.csv.gz")

cat(sprintf("\nGuardado: hogares %d x %d | distritos %d x %d\n",
            nrow(hogares), ncol(hogares), nrow(distritos), ncol(distritos)))
