# =============================================================================
# 00-construir-datos.R
# Construye los SUBSETS DE ENSEÑANZA a partir del paquete de réplica de
# de Janvry, Emerick, Gonzalez-Navarro y Sadoulet (2015).
# (Esto NO se corre en clase: ya dejamos los subsets listos en datos/.
#  Se incluye para que el ejercicio sea 100% reproducible.)
#
# Entradas esperadas en datos/_crudos/  (ver datos/SOURCE.md):
#   progresa_hhdata.dta    — nivel HOGAR x AÑO (27.189 x 39). Panel PROGRESA
#                            1997-2000 cruzado con el año de PROCEDE del ejido.
#                            Base de la Tabla 1 y de la Tabla A4.
#   locality_level.dta     — nivel LOCALIDAD x AÑO (71.094 x 16). Censos INEGI
#                            1980, 1990 y 2000. Base de la Tabla 2.
#   ejido_census.dta       — nivel EJIDO (19.713 x 10). Censos ejidales 1991 y
#                            2007 empatados. Base de la Tabla 3.
#   procampo2.dta          — nivel EJIDO x AÑO (32.836 x 8). Beneficiarios y
#                            área de PROCAMPO en 1995 y 2012. Base de la Figura 2.
#   landuse_satellite.dta  — nivel EJIDO x SERIE (79.443 x 10). Área agrícola
#                            según imágenes Landsat. Base de la Tabla 4.
#   (consumption.dta, Tabla 5, no se usa en el lab.)
#
# OJO — EL PAQUETE YA VIENE "CASI LISTO". A diferencia del Lab 3, acá no hay que
# construir los resultados: el do-file del paquete corre las regresiones casi
# directo sobre los .dta. Lo que hace este script es (1) quedarse con las
# columnas que el lab usa, (2) ponerles nombres en español y (3) VERIFICAR que
# los subsets reproducen los números publicados antes de guardar nada.
# =============================================================================

# =============================================================================
# 0. PREPARACIÓN
# =============================================================================
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, haven, fixest)   # haven lee los .dta de Stata

RAW <- Sys.getenv("JANVRY_RAW", "datos/_crudos")

# El ZIP de openICPSR se descomprime en 112931-V1/replication/replication_data/;
# buscamos cada .dta por nombre para no depender de dónde quedó la carpeta.
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

# Falla fuerte y con ayuda: dice qué falta y qué sí hay.
exigir <- function(datos, necesarias, archivo) {
  faltan <- setdiff(necesarias, names(datos))
  if (length(faltan)) {
    stop("Faltan variables en ", archivo, ": ", paste(faltan, collapse = ", "),
         "\nDisponibles:\n  ", paste(names(datos), collapse = ", "))
  }
  invisible(TRUE)
}

# Compara una réplica contra el número publicado y detiene todo si no da.
verificar <- function(nombre, obtenido, publicado, tolerancia) {
  ok <- abs(obtenido - publicado) <= tolerancia
  cat(sprintf("  %-46s réplica %9.4f | publicado %9.4f  %s\n",
              nombre, obtenido, publicado, if (ok) "OK" else "<-- NO DA"))
  if (!ok) stop("La verificación de '", nombre, "' falló. NO se guardan los subsets: ",
                "revise el mapa de variables contra el paquete crudo.")
  invisible(ok)
}

leer <- function(patron) read_dta(buscar(patron)) |> zap_labels() |> as_tibble()

# =============================================================================
# 1. HOGARES PROGRESA (Tabla 1 y Tabla A4)
# =============================================================================
hogares_crudo <- leer("^progresa_hhdata\\.dta$")

exigir(hogares_crudo,
       c("hh_numid", "ejido_numid", "loc_numid", "entidad", "year", "mig_away",
         "full_titled", "procedeyea", "hh_ag", "males_17to30_1997",
         "female_head_1997", "age_head", "value_ag", "ejidatario", "posesionar",
         "avecindado", "suptotalnu", "supparcela", "latitude", "longitude",
         "nearcity_km", "iml7954r"),
       "progresa_hhdata.dta")

hogares <- hogares_crudo |>
  transmute(
    hogar          = hh_numid,
    ejido          = ejido_numid,
    localidad      = loc_numid,
    estado         = entidad,
    anio           = year,
    migrante       = mig_away,       # 1 si el hogar ya tuvo un migrante permanente
    certificado    = full_titled,    # 1 si el ejido estaba certificado al INICIO del año
    anio_procede   = procedeyea,     # año en que el ejido terminó PROCEDE
    # Controles de hogar (Tabla 1, cols. 2 y 5)
    propietario    = hh_ag,
    hombres_17a30  = males_17to30_1997,
    jefa_mujer     = female_head_1997,
    edad_jefe      = age_head,
    valor_agricola = value_ag,       # 100 USD/ha, varía por ejido y año
    # Características del ejido (Tabla 1, col. 6). Las dos derivadas se
    # construyen igual que en el do-file: outsiders y parcelratio.
    ejidatarios    = ejidatario,
    no_votantes    = posesionar + avecindado,
    area_total     = suptotalnu,
    prop_parcelada = supparcela / suptotalnu,
    latitud        = latitude,
    longitud       = longitude,
    dist_ciudad_km = nearcity_km,
    marginacion    = iml7954r
  )

# El "certificado" no es otra cosa que el año de PROCEDE comparado con el año
# de la encuesta. Si esto falla, el mapa de variables está mal.
stopifnot(all(hogares$certificado == as.numeric(hogares$anio > hogares$anio_procede)))

# =============================================================================
# 2. LOCALIDADES CENSALES (Tabla 2)
# =============================================================================
# El .dta original APILA dos paneles distintos en el mismo archivo:
#   - 1990 y 2000, con identificador de localidad (cols. 1-5 de la Tabla 2);
#   - 1980 y 1990, SIN identificador de localidad (col. 6, el placebo).
# Las filas de 1990 sirven a los dos. Acá los separamos en dos subsets para que
# se lean solos.
localidades_crudo <- leer("^locality_level\\.dta$")

exigir(localidades_crudo,
       c("loc_id", "ejido_numid", "year", "pobtot", "logpop", "procedeyea",
         "after", "program_after", "value_ag", "mpob90", "maxpob80",
         "year90dummy", "promax_year90", "early_s", "late_s"),
       "locality_level.dta")

# Las interacciones del do-file son funciones del año de PROCEDE. Lo
# comprobamos para poder dejar que el estudiante las construya.
chequeo <- localidades_crudo |>
  filter(!is.na(program_after)) |>
  mutate(cert_93_99 = as.numeric(procedeyea >= 1993 & procedeyea <= 1999))
stopifnot(all(chequeo$program_after == chequeo$cert_93_99 * chequeo$after),
          all(chequeo$early_s == as.numeric(chequeo$procedeyea <= 1996)),
          all(chequeo$late_s  == as.numeric(chequeo$procedeyea %in% 1997:1999)))

localidades <- localidades_crudo |>
  filter(year %in% c(1990, 2000)) |>
  transmute(
    localidad      = loc_id,
    ejido          = ejido_numid,
    anio           = year,
    poblacion      = pobtot,
    log_pob        = logpop,
    anio_procede   = procedeyea,
    pob_1990       = mpob90,          # para la regla de muestra: > 20 habitantes en 1990
    valor_agricola = value_ag
  )

placebo_80_90 <- localidades_crudo |>
  filter(year %in% c(1980, 1990), !is.na(maxpob80)) |>
  transmute(
    ejido          = ejido_numid,
    anio           = year,
    log_pob        = logpop,
    pob_1980       = maxpob80,       # para la regla de muestra: > 20 habitantes en 1980
    cert_93_99_x_1990 = promax_year90 # en el .dta las filas de 1980 no traen el año de
                                      # PROCEDE; la interacción ya viene construida
  )

# =============================================================================
# 3. CENSO EJIDAL 1991-2007 (Tabla 3)
# =============================================================================
censo_crudo <- leer("^ejido_census\\.dta$")
exigir(censo_crudo, c("ESTADO", "muni_numid", "PROCEDEYEA", "years_titled",
                      "young_mig", "improve_seed", "tractor", "lights", "logdist"),
       "ejido_census.dta")

censo_ejidal <- censo_crudo |>
  transmute(
    estado            = ESTADO,
    municipio         = muni_numid,
    anio_procede      = PROCEDEYEA,
    anios_certificado = years_titled,   # años con certificado en 2007
    jovenes_migran    = young_mig,      # 1 = la mayoría de los jóvenes se va del ejido
    semilla_mejorada  = improve_seed,   # 1991
    tractor           = tractor,        # 1991
    electricidad      = lights,         # 1991
    log_dist_pa       = logdist         # distancia a la oficina de la Procuraduría Agraria
  )

# =============================================================================
# 4. PROCAMPO 1995-2012 (Figura 2)
# =============================================================================
# Dos fotos por ejido: 1995 y 2012. El do-file hace la diferencia con l. de
# Stata; acá dejamos el ejido en una sola fila con las dos fotos lado a lado y
# la resta queda para el lab.
procampo_crudo <- leer("^procampo2\\.dta$")
exigir(procampo_crudo, c("ejido_numid", "year", "logbenef", "logarea",
                         "procededat_r", "state_phina_id", "muni_id"),
       "procampo2.dta")

procampo <- procampo_crudo |>
  transmute(ejido = ejido_numid, anio = year,
            log_productores = logbenef, log_area = logarea,
            anio_procede = as.integer(format(procededat_r, "%Y")),
            estado = state_phina_id, municipio = muni_id) |>
  pivot_wider(names_from = anio, values_from = c(log_productores, log_area),
              names_sep = "_")

# =============================================================================
# 5. IMÁGENES SATELITALES (Tabla 4)
# =============================================================================
satelite_crudo <- leer("^landuse_satellite\\.dta$")
exigir(satelite_crudo, c("ejidoid", "series", "procedeyea", "titled", "lnagri"),
       "landuse_satellite.dta")

# Series II, III y IV de INEGI = imágenes de 1993, 2002 y 2007 (paper, p. 3133).
satelite <- satelite_crudo |>
  transmute(ejido = ejidoid,
            anio  = c(`2` = 1993, `3` = 2002, `4` = 2007)[as.character(series)],
            anio_procede = procedeyea,
            certificado  = titled,
            log_area_agricola = lnagri)
stopifnot(!anyNA(satelite$anio))

# =============================================================================
# 6. VERIFICACIÓN CONTRA EL PAPER (si algo no da, no se guarda nada)
# =============================================================================
cat("\n--- Verificación contra los números publicados ---\n")

t1 <- feols(migrante ~ certificado | ejido + anio, hogares, cluster = ~ejido)
verificar("Tabla 1 col. 1: coeficiente", coef(t1)[["certificado"]], 0.0149, 0.00005)
verificar("Tabla 1 col. 1: error estándar", se(t1)[["certificado"]], 0.0061, 0.00005)
verificar("Tabla 1 col. 1: observaciones", nobs(t1), 27189, 0)
verificar("Tabla 1: media de la variable dependiente", mean(hogares$migrante), 0.053, 0.0005)

loc <- localidades |>
  filter(pob_1990 > 20) |>
  mutate(despues = as.numeric(anio == 2000),
         # OJO: con `%in%` un año de PROCEDE faltante da FALSE y la localidad
         # entra como control; con la comparación queda NA y sale de la muestra,
         # que es lo que hace Stata. Es la diferencia entre -0,0401 y -0,0404.
         cert_93_99_x_2000 = as.numeric(anio_procede >= 1993 & anio_procede <= 1999) * despues)
t2 <- feols(log_pob ~ despues + cert_93_99_x_2000 | ejido, loc, cluster = ~ejido)
verificar("Tabla 2 col. 2: certificado x 2000", coef(t2)[["cert_93_99_x_2000"]], -0.0404, 0.00005)
verificar("Tabla 2 col. 2: observaciones", nobs(t2), 34656, 0)

t3 <- feols(jovenes_migran ~ anios_certificado | estado, censo_ejidal, cluster = ~municipio)
verificar("Tabla 3 col. 1: años certificado", coef(t3)[["anios_certificado"]], 0.0035, 0.00005)
verificar("Tabla 3 col. 1: observaciones", nobs(t3), 19670, 0)

t4 <- feols(log_area_agricola ~ certificado | ejido + anio, satelite,
            cluster = ~ejido, fixef.rm = "none")
verificar("Tabla 4 col. 1: certificado", coef(t4)[["certificado"]], 0.0013, 0.00005)
verificar("Tabla 4 col. 1: observaciones", nobs(t4), 63392, 0)

# =============================================================================
# 7. GUARDAR LOS SUBSETS
# =============================================================================
# write_rds NO comprime por defecto: sin compress = "gz" los .rds pesan mucho
# más que su .csv.gz y se quedan así en el historial de git para siempre.
guardar <- function(datos, nombre) {
  write_rds(datos, file.path("datos", paste0(nombre, ".rds")), compress = "gz")
  write_csv(datos, file.path("datos", paste0(nombre, ".csv.gz")))
  cat(sprintf("  %-28s %7s filas x %2d columnas\n", nombre,
              format(nrow(datos), big.mark = ","), ncol(datos)))
}

cat("\n--- Guardado ---\n")
guardar(hogares,       "janvry_hogares")
guardar(localidades,   "janvry_localidades")
guardar(placebo_80_90, "janvry_localidades_80_90")
guardar(censo_ejidal,  "janvry_censo_ejidal")
guardar(procampo,      "janvry_procampo")
guardar(satelite,      "janvry_satelite")
