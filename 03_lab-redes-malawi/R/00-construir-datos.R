# =============================================================================
# 00-construir-datos.R
# Construye los SUBSETS DE ENSEÑANZA a partir del paquete de réplica de
# Beaman, BenYishay, Magruder y Mobarak (2021).
# (Esto NO se corre en clase: ya dejamos los subsets listos en datos/.
#  Se incluye para que el ejercicio sea 100% reproducible.)
#
# Entradas esperadas en datos/_crudos/  (ver datos/SOURCE.md):
#   mnw_public.dta   — nivel AGRICULTOR x TEMPORADA (20.652 x 294). De acá salen,
#                      construidos, los resultados de aldea de la Tabla 2.
#   panel_seed.dta   — nivel AGRICULTOR CANDIDATO (1.294 x 25). Base de la Tabla 1:
#                      centralidad de los socios que elegiría cada algoritmo.
#   conversation.dta — nivel RESPONDENTE x SOCIO x AÑO (52.814 x 24). Base de la
#                      Tabla 3: ¿con quién habló cada quien de la siembra en hoyos?
#   census.dta       — nivel AGRICULTOR (15.957 x 23). Base de la Tabla A5: el
#                      balance fino, con las 12 variables del censo de redes.
#   ap_vout.dta      — nivel ALDEA x AÑO (402 x 10). Las SIMULACIONES ya corridas
#                      de la Figura 2, bajo aprendizaje simple y complejo.
#
# OJO — EL PAQUETE NO TRAE UN ARCHIVO A NIVEL DE ALDEA. Las dos variables de
# resultado se CONSTRUYEN, y este script replica paso por paso lo que hace
# code/2_table2.do del paquete original. Cualquier atajo acá cambia el número.
# =============================================================================

# =============================================================================
# 0. PREPARACIÓN
# =============================================================================
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, haven, fixest, broom)   # haven lee los .dta de Stata

RAW <- Sys.getenv("BEAMAN_RAW", "datos/_crudos")

# El ZIP de openICPSR se descomprime en 130605-V1/{code,data,output}; buscamos
# cada .dta por nombre para no depender de dónde quedó la carpeta.
buscar <- function(patron) {
  hallazgo <- list.files(RAW, pattern = patron, recursive = TRUE, full.names = TRUE)
  if (!length(hallazgo)) {
    stop("No se encontró '", patron, "' dentro de ", RAW,
         "\nArchivos .dta disponibles:\n  ",
         paste(basename(list.files(RAW, pattern = "\\.dta$", recursive = TRUE)),
               collapse = "\n  "))
  }
  hallazgo[1]
}

ruta_agricultores  <- buscar("^mnw_public\\.dta$")
ruta_candidatos    <- buscar("^panel_seed\\.dta$")
ruta_conversacion  <- buscar("^conversation\\.dta$")
ruta_censo         <- buscar("^census\\.dta$")
ruta_simulaciones  <- buscar("^ap_vout\\.dta$")

# Falla fuerte y con ayuda: dice qué falta y qué sí hay.
exigir <- function(datos, necesarias, archivo) {
  faltan <- setdiff(necesarias, names(datos))
  if (length(faltan)) {
    stop("Faltan variables en ", archivo, ": ", paste(faltan, collapse = ", "),
         "\nDisponibles:\n  ", paste(names(datos), collapse = ", "))
  }
  invisible(TRUE)
}

# =============================================================================
# 1. ALDEAS — construir los resultados de la Tabla 2 desde el microdato
# =============================================================================
# zap_labels() bota las etiquetas de Stata y deja columnas numéricas limpias.
agricultores <- read_dta(ruta_agricultores) |>
  zap_labels() |>
  as_tibble()

exigir(agricultores,
       c("s_v_code", "season", "district", "seed", "s_shadow_farmer",
         "pp_adopted_1yr", "pp_adopted_2yr", "pp_adopted_3yr",
         "t_complex", "t_simple", "t_geo",
         "compost_vbase", "fert_vbase", "pp_vbase", "villagesize"),
       basename(ruta_agricultores))

# --- 1a. El año del experimento no es la temporada -----------------------------
# El distrito 3 (Nkhotakota) entró al estudio un año DESPUÉS que los otros dos,
# así que su "año 2" es la temporada 2013-2014 y no tiene año 3. De ahí salen
# las 141 aldeas de las columnas 2 y 4 del paper.
agricultores <- agricultores |>
  mutate(
    anio = case_when(
      season == "2011-2012" & district <  3 ~ 1,
      season == "2012-2013" & district == 3 ~ 1,
      season == "2012-2013" & district <  3 ~ 2,
      season == "2013-2014" & district == 3 ~ 2,
      season == "2013-2014" & district <  3 ~ 3,
      TRUE ~ NA_real_
    ),
    adopto = case_when(anio == 1 ~ pp_adopted_1yr,
                       anio == 2 ~ pp_adopted_2yr,
                       anio == 3 ~ pp_adopted_3yr,
                       TRUE ~ NA_real_),
    # DOS exclusiones distintas, y la diferencia importa:
    #   "alguna adopción" excluye solo a las SEMILLAS (los dos capacitados).
    #   la TASA excluye además a las SOMBRAS (los que otro algoritmo habría
    #   elegido), para no medir sobre gente seleccionada por centralidad.
    adopto_no_semilla        = if_else(seed != 1, adopto, NA_real_),
    adopto_no_semilla_sombra = if_else(seed != 1 & s_shadow_farmer != 1, adopto, NA_real_)
  )

# --- 1b. Colapsar a aldea x año ------------------------------------------------
aldea_anio <- agricultores |>
  filter(anio %in% c(2, 3)) |>
  group_by(s_v_code, anio) |>
  summarise(
    # 1 si adoptó AL MENOS UNO que no fuera semilla.
    adopcion_alguna = as.integer(sum(adopto_no_semilla, na.rm = TRUE) > 0),
    # proporción de no-semillas y no-sombras que adoptaron.
    tasa_adopcion   = mean(adopto_no_semilla_sombra, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(tasa_adopcion = if_else(is.nan(tasa_adopcion), NA_real_, tasa_adopcion))

# --- 1c. Lo que no cambia entre años -------------------------------------------
# OJO: 32 filas del microdato traen en blanco el brazo y las variables de aldea.
# Son constantes dentro de cada aldea una vez que se ignoran esos vacíos, y
# ninguna aldea se queda sin valor, así que tomamos el PRIMER VALOR NO VACÍO.
# Con first() a secas, una aldea que empiece con una de esas filas se queda sin
# tratamiento y el sorteo aparece roto donde no lo está.
primero_valido <- function(x) x[which(!is.na(x))[1]]

aldea_fija <- agricultores |>
  group_by(s_v_code) |>
  summarise(across(c(district, t_complex, t_simple, t_geo,
                     compost_vbase, fert_vbase, pp_vbase, villagesize),
                   primero_valido),
            .groups = "drop")

aldeas <- aldea_anio |>
  pivot_wider(names_from = anio, values_from = c(adopcion_alguna, tasa_adopcion),
              names_glue = "{.value}_a{anio}") |>
  left_join(aldea_fija, by = "s_v_code") |>
  select(
    aldea    = s_v_code,        # identificador de aldea (nivel de clúster)
    distrito = district,        # estrato del sorteo; el 3 es Nkhotakota
    complex  = t_complex,       # brazo de contagio complejo
    simple   = t_simple,        # brazo de contagio simple
    geo      = t_geo,           # brazo geográfico; Benchmark = los tres en 0
    adopcion_alguna_a2, adopcion_alguna_a3,
    tasa_adopcion_a2,   tasa_adopcion_a3,
    compost_base      = compost_vbase,     # controles de la re-aleatorización
    fertilizante_base = fert_vbase,
    hoyos_base        = pp_vbase,
    tam_aldea         = villagesize
  ) |>
  mutate(
    # Una sola variable legible con los cuatro brazos. El orden de los niveles
    # importa: Benchmark va primero porque es la categoría omitida.
    brazo = factor(
      case_when(complex == 1 ~ "Complejo",
                simple  == 1 ~ "Simple",
                geo     == 1 ~ "Geo",
                TRUE         ~ "Benchmark"),
      levels = c("Benchmark", "Geo", "Simple", "Complejo")
    ),
    en_a3 = as.integer(!is.na(adopcion_alguna_a3))
  ) |>
  arrange(aldea)

# Un brazo y solo uno por aldea: si esto falla, el mapa de tratamientos está mal.
stopifnot(all(aldeas$complex + aldeas$simple + aldeas$geo <= 1))

# --- 1d. Las simulaciones de la Figura 2 ---------------------------------------
# ap_vout.dta trae, para cada aldea y año, qué FRACCIÓN de veces la difusión
# arrancaría según dos modelos teóricos, simulados sobre la red real de la aldea:
#   SL (simple learning)  — basta un vecino informado para adoptar.
#   CL (complex learning) — hacen falta dos.
# Cada modelo trae una columna por algoritmo de selección; a cada aldea le
# corresponde la del brazo que efectivamente recibió.
simulaciones <- read_dta(ruta_simulaciones) |>
  zap_labels() |>
  as_tibble()

exigir(simulaciones,
       c("s_v_code", "year",
         paste0("any_adopters_", rep(c("simple", "complex", "geo", "control"), each = 2),
                "seed_", c("SL", "CL"))),
       basename(ruta_simulaciones))

sim_larga <- simulaciones |>
  inner_join(select(aldeas, aldea, brazo, en_a3), by = c("s_v_code" = "aldea")) |>
  # El año 3 solo existe donde se midió: si no se filtra, las medias del año 3
  # se calculan sobre 200 aldeas en vez de 141 y dejan de ser las de la figura.
  filter(year == 2 | (year == 3 & en_a3 == 1)) |>
  mutate(
    sim_complejo = case_when(brazo == "Simple"   ~ any_adopters_simpleseed_CL,
                             brazo == "Complejo" ~ any_adopters_complexseed_CL,
                             brazo == "Geo"      ~ any_adopters_geoseed_CL,
                             TRUE                ~ any_adopters_controlseed_CL),
    sim_simple   = case_when(brazo == "Simple"   ~ any_adopters_simpleseed_SL,
                             brazo == "Complejo" ~ any_adopters_complexseed_SL,
                             brazo == "Geo"      ~ any_adopters_geoseed_SL,
                             TRUE                ~ any_adopters_controlseed_SL)
  ) |>
  select(aldea = s_v_code, year, sim_simple, sim_complejo)

aldeas <- aldeas |>
  left_join(
    sim_larga |>
      pivot_wider(names_from = year, values_from = c(sim_simple, sim_complejo),
                  names_glue = "{.value}_a{year}"),
    by = "aldea"
  )

# =============================================================================
# 2. SOCIOS — los candidatos de cada algoritmo (Tabla 1)
# =============================================================================
# "Socio" = quien un algoritmo elegiría como punto de entrada de la información.
# OJO con la unidad: el tipo NO es el brazo que recibió la aldea. Cada fila dice
# qué algoritmo elegiría a ESE agricultor; si su aldea recibió ese brazo lo
# capacitaron (semilla), y si no quedó como contrafactual observable (sombra).
candidatos <- read_dta(ruta_candidatos) |>
  zap_labels() |>
  as_tibble()

exigir(candidatos,
       c("s_v_code", "simple_type", "complex_type", "geo_type", "control_type",
         "eig", "deg", "seed", "s_shadow_farmer"),
       basename(ruta_candidatos))

# En el paquete cada fila tiene exactamente UN tipo activo.
stopifnot(all(candidatos$simple_type + candidatos$complex_type +
              candidatos$geo_type + candidatos$control_type == 1))

socios <- candidatos |>
  mutate(
    tipo = factor(
      case_when(complex_type == 1 ~ "Complejo",
                simple_type  == 1 ~ "Simple",
                geo_type     == 1 ~ "Geo",
                TRUE              ~ "Benchmark"),
      levels = c("Benchmark", "Geo", "Simple", "Complejo")
    )
  ) |>
  # El paquete trae 201 aldeas acá y 200 en la muestra analítica: nos quedamos
  # con las 200 para que las dos tablas hablen del mismo experimento.
  filter(s_v_code %in% aldeas$aldea) |>
  group_by(s_v_code, tipo) |>
  mutate(
    # OJO CON LOS EMPATES. El do-file usa `egen rank(), track` de Stata, que a
    # los empatados les da a TODOS el rango menor y salta el siguiente (1,1,3).
    # El equivalente en R es ties.method = "min". Con "first" —el reflejo
    # natural— la Tabla 1 da 18,08 en vez de 17,49: la réplica se rompe en
    # silencio. Y el rango se calcula POR MEDIDA: el socio más central por
    # vector propio no siempre es el de mayor grado.
    rango_ev    = rank(-eig, ties.method = "min"),
    rango_grado = rank(-deg, ties.method = "min")
  ) |>
  ungroup() |>
  left_join(select(aldeas, aldea, distrito, brazo), by = c("s_v_code" = "aldea")) |>
  select(
    aldea      = s_v_code,
    distrito, brazo,                 # dónde está y qué recibió su aldea
    tipo,                            # qué algoritmo lo elegiría
    es_semilla = seed,               # 1 = lo capacitaron de verdad
    es_sombra  = s_shadow_farmer,    # 1 = contrafactual no capacitado
    centralidad_ev = eig,
    grado          = deg,
    rango_ev, rango_grado
  ) |>
  arrange(aldea, tipo, rango_ev)

# =============================================================================
# 3. CONVERSACIONES — ¿de qué habló la gente? (Tabla 3)
# =============================================================================
# Una fila por (respondente, socio del que se le preguntó, año). La encuesta solo
# pregunta por SOCIOS: unos capacitados y otros sombra. Eso monta un segundo
# experimento adentro del primero — cuál de esos socios resultó capacitado es
# aleatorio— y permite leer el efecto de la capacitación sobre las conversaciones.
conversacion <- read_dta(ruta_conversacion) |>
  zap_labels() |>
  as_tibble()

exigir(conversacion,
       c("s_v_code", "district", "year", "seed", "s_shadow_farmer", "trained",
         "pitorprep", "s_target", "c_target", "g_target",
         "compost_vbase", "fert_vbase", "pp_vbase", "villagesize"),
       basename(ruta_conversacion))

conversaciones <- conversacion |>
  # Se excluyen semillas y sombras: interesa qué oyeron los VECINOS.
  filter(seed == 0, s_shadow_farmer == 0) |>
  select(
    aldea    = s_v_code,
    distrito = district,
    anio     = year,
    capacitado = trained,        # 1 = el socio por el que se pregunta fue capacitado
    hablaron   = pitorprep,      # 1 = reportan haber hablado de siembra en hoyos
    socio_simple   = s_target,   # de qué algoritmo era socio ese contacto
    socio_complejo = c_target,
    socio_geo      = g_target,
    compost_base      = compost_vbase,
    fertilizante_base = fert_vbase,
    hoyos_base        = pp_vbase,
    tam_aldea         = villagesize
  ) |>
  filter(!is.na(hablaron), !is.na(capacitado), !is.na(tam_aldea)) |>
  arrange(aldea, anio)

# =============================================================================
# 4. CENSO — el balance fino, a nivel de agricultor (Tabla A5)
# =============================================================================
# El balance de aldea usa 4 variables; el paper hace el suyo con 12 del censo de
# redes, a nivel de agricultor. Es donde aparece la única diferencia incómoda.
censo_crudo <- read_dta(ruta_censo) |>
  zap_labels() |>
  as_tibble()

# OJO: los do-files usan nombres ABREVIADOS que Stata completa solo. Acá van los
# nombres reales: `provganyu` es `provganyu_intro` y `useganyu` es `useganyu_intro`.
variables_censo <- c("housing_pc1", "assets_pc1", "livestock_pc1", "basal_qty_adj",
                     "topfert_qty_adj", "adults", "num_children", "farmsize_adj",
                     "land_own", "yield", "provganyu_intro", "useganyu_intro")

exigir(censo_crudo,
       c("numvill", "district", "seed_shadow", "t_complex", "t_simple", "t_geo",
         "pp_vbase", "fert_vbase", "compost_vbase", variables_censo),
       basename(ruta_censo))

censo <- censo_crudo |>
  filter(seed_shadow == 0) |>       # ni semillas ni sombras: la población de base
  select(
    aldea    = numvill,
    distrito = district,
    complex = t_complex, simple = t_simple, geo = t_geo,
    all_of(variables_censo),
    compost_base      = compost_vbase,
    fertilizante_base = fert_vbase,
    hoyos_base        = pp_vbase
  ) |>
  rename(                            # nombres legibles para las 12 de la Tabla A5
    vivienda_pc      = housing_pc1,
    activos_pc       = assets_pc1,
    ganado_pc        = livestock_pc1,
    fert_basal       = basal_qty_adj,
    fert_cobertura   = topfert_qty_adj,
    adultos          = adults,
    ninos            = num_children,
    tam_finca        = farmsize_adj,
    tierra_propia    = land_own,
    rendimiento      = yield,
    presta_ganyu     = provganyu_intro,
    usa_ganyu        = useganyu_intro
  ) |>
  mutate(brazo = factor(case_when(complex == 1 ~ "Complejo",
                                  simple  == 1 ~ "Simple",
                                  geo     == 1 ~ "Geo",
                                  TRUE         ~ "Benchmark"),
                        levels = c("Benchmark", "Geo", "Simple", "Complejo"))) |>
  arrange(aldea)

# =============================================================================
# 5. VERIFICACIÓN — ¿reproducimos las tablas de Beaman et al.?
# =============================================================================
# Tabla 2, columna 1: "alguna adopción no-semilla" en el año 2, sobre las 200
# aldeas, con los tres controles de la re-aleatorización, tamaño de aldea y su
# cuadrado, y efectos fijos de distrito. EE agrupados por aldea.
m_principal <- feols(
  adopcion_alguna_a2 ~ complex + simple + geo +
    compost_base + fertilizante_base + hoyos_base + tam_aldea + I(tam_aldea^2) | distrito,
  data = aldeas, cluster = ~aldea
)

efecto <- tidy(m_principal) |>
  filter(term %in% c("complex", "simple", "geo")) |>
  select(brazo = term, coef = estimate, ee = std.error, p = p.value)

cat("\n--- Verificación contra Beaman et al. (2021), Tabla 2, col. 1 ---\n")
print(efecto)
cat(sprintf("Media del brazo Benchmark: %.3f (publicado: 0,420)\n",
            mean(aldeas$adopcion_alguna_a2[aldeas$brazo == "Benchmark"])))
cat(sprintf("Aldeas: %d (publicado: 200) | en el año 3: %d (publicado: 141)\n",
            nobs(m_principal), sum(aldeas$en_a3)))
cat("Publicado: complex 0,252 (0,093) | simple 0,155 (0,100) | geo 0,107 (0,096)\n")

# --- Tabla 1: centralidad de los dos socios de cada tipo -----------------------
tabla1 <- socios |>
  summarise(
    eig1 = mean(centralidad_ev[rango_ev == 1], na.rm = TRUE),
    eig2 = mean(centralidad_ev[rango_ev == 2], na.rm = TRUE),
    deg1 = mean(grado[rango_grado == 1], na.rm = TRUE),
    deg2 = mean(grado[rango_grado == 2], na.rm = TRUE),
    .by = tipo
  ) |>
  arrange(tipo)

cat("\n--- Verificación contra la Tabla 1 ---\n")
print(as.data.frame(tabla1), digits = 4)
cat("Publicado: complejo 0,28/0,19 y 17,49/13,39 | simple 0,27/0,07 y 16,59/6,70\n")
cat("           geo 0,15/0,10 y 9,48/6,34        | benchmark 0,21/0,13 y 13,29/9,80\n")

# --- Tabla 3: ¿hablaron más con los capacitados? -------------------------------
tabla3 <- map_dfr(1:3, function(y) {
  muestra <- filter(conversaciones, anio == y)
  m <- feols(hablaron ~ capacitado + socio_simple + socio_complejo + socio_geo +
               compost_base + fertilizante_base + hoyos_base + tam_aldea + I(tam_aldea^2) | distrito,
             data = muestra, cluster = ~aldea, notes = FALSE)
  tibble(anio = y, coef = coef(m)[["capacitado"]], ee = se(m)[["capacitado"]], n = nobs(m))
})

cat("\n--- Verificación contra la Tabla 3 ---\n")
print(as.data.frame(tabla3), digits = 3)
cat("Publicado: 0,037 (0,008) | 0,050 (0,008) | 0,064 (0,009); n = 15.115 / 16.704 / 11.607\n")

# --- Tabla A5: el balance fino, 12 variables -----------------------------------
balance_censo <- map_dfr(
  c("vivienda_pc", "activos_pc", "ganado_pc", "fert_basal", "fert_cobertura",
    "adultos", "ninos", "tam_finca", "tierra_propia", "rendimiento",
    "presta_ganyu", "usa_ganyu"),
  function(v) {
    m <- feols(as.formula(paste(v, "~ complex + simple + geo +",
                                "hoyos_base + fertilizante_base + compost_base | distrito")),
               data = censo, cluster = ~aldea, notes = FALSE)
    tibble(variable = v, p_conjunta = wald(m, "complex|simple|geo", print = FALSE)$p,
           n = nobs(m))
  })

cat("\n--- Verificación contra la Tabla A5 (balance a nivel de agricultor) ---\n")
print(as.data.frame(balance_censo), digits = 3)
cat(sprintf("Variables con p conjunta < 0,10: %d (publicado: 2 de 12, vivienda y tam_finca)\n",
            sum(balance_censo$p_conjunta < 0.10)))

# --- Figura 2: simulaciones contra datos ---------------------------------------
cat("\n--- Verificación contra la Figura 2 (medias por brazo) ---\n")
print(as.data.frame(
  aldeas |>
    summarise(sim_complejo_a2 = mean(sim_complejo_a2, na.rm = TRUE),
              sim_simple_a2   = mean(sim_simple_a2,   na.rm = TRUE),
              real_a2         = mean(adopcion_alguna_a2),
              .by = brazo) |>
    arrange(brazo)), digits = 3)
cat("Publicado (año 2): sim complejo 0,37/0,42/0,33/0,72 | sim simple 0,80/0,81/0,94/0,92\n")
cat("                   real 0,42/0,52/0,56/0,68   (orden Benchmark, Geo, Simple, Complejo)\n")

# --- La puerta: si el número titular no da, no se guarda nada ------------------
titular   <- coef(m_principal)[["complex"]]
objetivo  <- 0.252
tolerancia <- 0.01
if (abs(titular - objetivo) > tolerancia || nobs(m_principal) != 200) {
  stop(sprintf(paste0("El titular se salió de la tolerancia (%.4f contra %.3f ± %.3f) ",
                      "o el N no es 200 (%d). NO se guardan los subsets: revise el mapa ",
                      "de variables contra el paquete crudo."),
               titular, objetivo, tolerancia, nobs(m_principal)))
}

# =============================================================================
# 6. GUARDAR LOS SUBSETS
# =============================================================================
# write_rds NO comprime por defecto: sin compress="gz" estos .rds pesan 10 veces
# más que su .csv.gz y se quedan así en el historial de git para siempre.
write_rds(aldeas, "datos/beaman_redes_aldeas.rds", compress = "gz")
write_csv(aldeas, "datos/beaman_redes_aldeas.csv.gz")   # write_csv comprime si termina en .gz
write_rds(socios, "datos/beaman_redes_socios.rds", compress = "gz")
write_csv(socios, "datos/beaman_redes_socios.csv.gz")
write_rds(conversaciones, "datos/beaman_redes_conversaciones.rds", compress = "gz")
write_csv(conversaciones, "datos/beaman_redes_conversaciones.csv.gz")
write_rds(censo, "datos/beaman_redes_censo.rds", compress = "gz")
write_csv(censo, "datos/beaman_redes_censo.csv.gz")

cat(sprintf(paste0("\nGuardado: aldeas %d x %d | socios %d x %d\n",
                   "          conversaciones %d x %d | censo %d x %d\n"),
            nrow(aldeas), ncol(aldeas), nrow(socios), ncol(socios),
            nrow(conversaciones), ncol(conversaciones), nrow(censo), ncol(censo)))
