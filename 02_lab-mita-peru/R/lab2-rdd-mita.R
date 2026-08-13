# =============================================================================
# LAB 2 — La mita minera del Perú: una frontera que todavía se nota
# Economía del Desarrollo (06230) · Universidad ICESI
#
# Datos: paquete de réplica de Dell, M. (2010), "The Persistent Effects of
#        Peru's Mining Mita", Econometrica 78(6), 1863-1903.
# Idea: replicar el RDD GEOGRÁFICO de Dell. Entre 1573 y 1812, la Corona
#   española obligó a los pueblos DENTRO de un área definida a enviar la
#   séptima parte de sus hombres adultos a las minas de Potosí y Huancavelica.
#   Los pueblos JUSTO AFUERA quedaron exentos. Doscientos años después de
#   abolida, ¿todavía se ve esa frontera en el consumo de los hogares?
#
# OJO: acá SÍ hacemos una afirmación causal, pero descansa toda en un
# supuesto: CONTINUIDAD en la frontera. Suponemos que todo lo que determina el
# consumo (geografía, cultura, historia previa) varía de forma SUAVE al cruzar
# el límite, y que lo único que salta es haber estado sujeto a la mita.
# Si algo más salta en el mismo lugar, el diseño se cae.
# =============================================================================

# =============================================================================
# 0. PREPARACIÓN
# =============================================================================
# pacman instala lo que falte y carga lo que ya esté: una sola línea para todo.
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, scales, fixest, rdrobust, broom)

# Dos subsets de enseñanza, ya listos (ver datos/codebook.md).
hogares <- read_rds("datos/dell_mita_hogares.rds") |>
  as_tibble()

distritos <- read_rds("datos/dell_mita_distritos.rds") |>
  as_tibble()

# =============================================================================
# 1. UNA MIRADA A LOS DATOS
# =============================================================================
dim(hogares)     # filas (hogares) x columnas
head(hogares)    # primeras filas

# El tratamiento: 1 = distrito sujeto a la mita.
hogares |>
  group_by(mita) |>
  summarise(hogares = n(), distritos = n_distinct(distrito))

# La VARIABLE DE ASIGNACIÓN es la distancia a la frontera CON SIGNO:
#   negativa = fuera de la mita   |   positiva = dentro de la mita
# El tratamiento cambia de golpe en 0; todo lo demás debería variar suave.
hogares |>
  group_by(mita) |>
  summarise(minimo = min(dist_frontera), maximo = max(dist_frontera))

# El resultado: log del consumo del hogar por adulto equivalente.
# Como está en logaritmos, un coeficiente b se lee como exp(b)-1 en porcentaje.
summary(hogares$lhhequiv)

# =============================================================================
# 2. EL MAPA  (¿dónde está la frontera?)
# =============================================================================
# Cada punto es un distrito del sur peruano. El color marca si estuvo sujeto a
# la mita. La frontera es la línea donde los dos colores se tocan: ahí es donde
# vamos a comparar.
distritos <- distritos |>
  mutate(grupo = factor(mita,
                        levels = c(0, 1),
                        labels = c("Fuera de la mita", "Dentro de la mita")))

g1 <- ggplot(distritos, aes(lon, lat, color = grupo)) +
  geom_point(aes(size = frontera == 1), alpha = 0.8) +
  scale_size_manual(values = c(`FALSE` = 1.3, `TRUE` = 2.6), guide = "none") +
  scale_color_manual(values = c("Fuera de la mita" = "#2c7fb8",
                                "Dentro de la mita" = "#d95f0e")) +
  coord_quickmap() +
  labs(title = "La frontera de la mita en el sur del Perú",
       subtitle = "299 distritos; los puntos grandes tocan la frontera (Potosí queda al sureste)",
       x = "Longitud", y = "Latitud", color = NULL,
       caption = "Fuente: datos de réplica de Dell (2010).") +
  theme_minimal(base_size = 13)
print(g1)

# =============================================================================
# 3. LA GRÁFICA DEL RDD  (el corazón del diseño)
# =============================================================================
# Promediamos el consumo en bins de 10 km de distancia con signo y miramos si
# hay un ESCALÓN en 0. Esta es *la* imagen que hay que saber leer.
resumen_bins <- hogares |>
  mutate(bin = floor(dist_frontera / 10) * 10 + 5) |>   # centro del bin de 10 km
  group_by(bin, mita) |>
  summarise(consumo = mean(lhhequiv), hogares = n(), .groups = "drop")

g2 <- ggplot(resumen_bins, aes(bin, consumo)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40") +
  geom_point(aes(size = hogares, color = factor(mita)), alpha = 0.8) +
  geom_smooth(data = hogares, aes(dist_frontera, lhhequiv, color = factor(mita)),
              method = "lm", formula = y ~ x, se = TRUE) +
  scale_color_manual(values = c("0" = "#2c7fb8", "1" = "#d95f0e"),
                     labels = c("Fuera de la mita", "Dentro de la mita")) +
  scale_size_continuous(range = c(1.5, 6), guide = "none") +
  annotate("text", x = 0, y = max(resumen_bins$consumo), label = "frontera",
           hjust = -0.1, size = 3.5, color = "grey40") +
  labs(title = "El salto en el consumo al cruzar la frontera de la mita",
       subtitle = "Promedio por bin de 10 km; el tamaño del punto es el número de hogares",
       x = "Distancia a la frontera (km, negativa = fuera de la mita)",
       y = "Log del consumo por adulto equivalente", color = NULL,
       caption = "Fuente: ENAHO 2001, datos de réplica de Dell (2010).") +
  theme_minimal(base_size = 13)
print(g2)

# =============================================================================
# 4. LA ESTIMACIÓN  (Tabla II, Panel A, columna 1 del paper)
# =============================================================================
# Dell controla la geografía con un POLINOMIO CÚBICO en longitud y latitud, más
# elevación, pendiente y composición del hogar, y agrega EFECTOS FIJOS DE
# SEGMENTO DE FRONTERA (bfe4_*): así la comparación es *a lo largo* de la
# frontera y no entre regiones distintas del Perú.
# Los errores estándar se agrupan por DISTRITO (71 clústeres).

# Las tres ventanas alrededor de la frontera que usa el paper.
hogares_100 <- hogares |> filter(d_bnd < 100)
hogares_75  <- hogares |> filter(d_bnd < 75)
hogares_50  <- hogares |> filter(d_bnd < 50)

m_latlon_100 <- feols(
  lhhequiv ~ mita +
    x + y + I(x^2) + I(y^2) + I(x * y) + I(x^3) + I(y^3) + I(x^2 * y) + I(x * y^2) +
    elv_sh + slope + infants + children + adults + bfe4_1 + bfe4_2 + bfe4_3,
  data = hogares_100,
  cluster = ~distrito
)

# tidy() saca la tabla de coeficientes como un tibble; nos quedamos con la mita.
tidy(m_latlon_100) |>
  filter(term == "mita")
# esperado: coef ~ -0.284, EE ~ 0.199, no significativo (igual que el paper)

# Del logaritmo al porcentaje: ¿cuánto menos consume un hogar de la mita?
efecto_principal <- tidy(m_latlon_100) |>
  filter(term == "mita") |>
  mutate(
    efecto_pct = (exp(estimate) - 1) * 100,
    hogares    = nobs(m_latlon_100),
    distritos  = n_distinct(hogares_100$distrito)
  ) |>
  select(coeficiente = estimate, ee = std.error, efecto_pct, hogares, distritos)

print(efecto_principal)

# =============================================================================
# 5. ¿AGUANTA EL RESULTADO?  Especificación y ancho de banda
# =============================================================================
# Un RDD no es un botón: hay que elegir (a) cómo se controla la geografía y
# (b) qué tan cerca de la frontera se mira. Dell reporta 3 polinomios x 3
# ventanas. Corremos las nueve regresiones, una por una.

# --- 5a. Cúbica en latitud y longitud (la del paper) --------------------------
# Nota: m_latlon_100 ya quedó estimado arriba.
m_latlon_75 <- feols(
  lhhequiv ~ mita +
    x + y + I(x^2) + I(y^2) + I(x * y) + I(x^3) + I(y^3) + I(x^2 * y) + I(x * y^2) +
    elv_sh + slope + infants + children + adults + bfe4_1 + bfe4_2 + bfe4_3,
  data = hogares_75, cluster = ~distrito
)

m_latlon_50 <- feols(
  lhhequiv ~ mita +
    x + y + I(x^2) + I(y^2) + I(x * y) + I(x^3) + I(y^3) + I(x^2 * y) + I(x * y^2) +
    elv_sh + slope + infants + children + adults + bfe4_1 + bfe4_2 + bfe4_3,
  data = hogares_50, cluster = ~distrito
)

# --- 5b. Cúbica en la distancia a Potosí --------------------------------------
m_potosi_100 <- feols(
  lhhequiv ~ mita + dpot + I(dpot^2) + I(dpot^3) +
    elv_sh + slope + infants + children + adults + bfe4_1 + bfe4_2 + bfe4_3,
  data = hogares_100, cluster = ~distrito
)

m_potosi_75 <- feols(
  lhhequiv ~ mita + dpot + I(dpot^2) + I(dpot^3) +
    elv_sh + slope + infants + children + adults + bfe4_1 + bfe4_2 + bfe4_3,
  data = hogares_75, cluster = ~distrito
)

m_potosi_50 <- feols(
  lhhequiv ~ mita + dpot + I(dpot^2) + I(dpot^3) +
    elv_sh + slope + infants + children + adults + bfe4_1 + bfe4_2 + bfe4_3,
  data = hogares_50, cluster = ~distrito
)

# --- 5c. Cúbica en la distancia a la frontera ---------------------------------
m_frontera_100 <- feols(
  lhhequiv ~ mita + d_bnd + I(d_bnd^2) + I(d_bnd^3) +
    elv_sh + slope + infants + children + adults + bfe4_1 + bfe4_2 + bfe4_3,
  data = hogares_100, cluster = ~distrito
)

m_frontera_75 <- feols(
  lhhequiv ~ mita + d_bnd + I(d_bnd^2) + I(d_bnd^3) +
    elv_sh + slope + infants + children + adults + bfe4_1 + bfe4_2 + bfe4_3,
  data = hogares_75, cluster = ~distrito
)

m_frontera_50 <- feols(
  lhhequiv ~ mita + d_bnd + I(d_bnd^2) + I(d_bnd^3) +
    elv_sh + slope + infants + children + adults + bfe4_1 + bfe4_2 + bfe4_3,
  data = hogares_50, cluster = ~distrito
)

# --- 5d. Juntamos los nueve resultados en una sola tabla ----------------------
# A cada tidy() le pegamos la etiqueta de qué modelo es, y luego apilamos.
rejilla <- bind_rows(
  tidy(m_latlon_100)   |> mutate(especificacion = "Cúbica en lat-lon",        ventana = 100, n = nobs(m_latlon_100)),
  tidy(m_latlon_75)    |> mutate(especificacion = "Cúbica en lat-lon",        ventana = 75,  n = nobs(m_latlon_75)),
  tidy(m_latlon_50)    |> mutate(especificacion = "Cúbica en lat-lon",        ventana = 50,  n = nobs(m_latlon_50)),
  tidy(m_potosi_100)   |> mutate(especificacion = "Cúbica en dist. Potosí",   ventana = 100, n = nobs(m_potosi_100)),
  tidy(m_potosi_75)    |> mutate(especificacion = "Cúbica en dist. Potosí",   ventana = 75,  n = nobs(m_potosi_75)),
  tidy(m_potosi_50)    |> mutate(especificacion = "Cúbica en dist. Potosí",   ventana = 50,  n = nobs(m_potosi_50)),
  tidy(m_frontera_100) |> mutate(especificacion = "Cúbica en dist. frontera", ventana = 100, n = nobs(m_frontera_100)),
  tidy(m_frontera_75)  |> mutate(especificacion = "Cúbica en dist. frontera", ventana = 75,  n = nobs(m_frontera_75)),
  tidy(m_frontera_50)  |> mutate(especificacion = "Cúbica en dist. frontera", ventana = 50,  n = nobs(m_frontera_50))
) |>
  filter(term == "mita") |>                # de cada modelo solo nos interesa la mita
  select(especificacion, ventana,
         coef = estimate, ee = std.error, p = p.value, n) |>
  mutate(coef = round(coef, 3), ee = round(ee, 3), p = round(p, 3))

print(rejilla)
# esperado: todos los coeficientes entre -0.34 y -0.21 (es decir, -29% a -19%);
# los del Panel A no son significativos, los de los otros dos sí.

g3 <- ggplot(rejilla, aes(factor(ventana), coef, color = especificacion)) +
  geom_hline(yintercept = 0, color = "grey50") +
  geom_pointrange(aes(ymin = coef - 1.96 * ee, ymax = coef + 1.96 * ee),
                  position = position_dodge(width = 0.5)) +
  labs(title = "El efecto de la mita no depende de la especificación",
       subtitle = "Coeficiente e intervalo al 95 %, por control de la geografía y ancho de la ventana",
       x = "Ventana alrededor de la frontera (km)",
       y = "Efecto sobre el log del consumo", color = NULL,
       caption = "Fuente: ENAHO 2001, datos de réplica de Dell (2010).") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom")
print(g3)

# --- 5e. El estimador moderno: rdrobust ---------------------------------------
# rdrobust ajusta rectas locales a cada lado y elige el ancho de banda óptimo
# (CCT). Es el estándar hoy, pero acá hay que usarlo con cabeza.
# Ojo: rdrobust no trabaja con tibbles, pide vectores y una matriz.
covariables <- hogares |>
  select(elv_sh, slope, infants, children, adults, bfe4_1, bfe4_2, bfe4_3) |>
  as.matrix()

rd_auto <- rdrobust(hogares$lhhequiv, hogares$dist_frontera, c = 0,
                    covs = covariables, cluster = hogares$distrito)

rd_50 <- rdrobust(hogares$lhhequiv, hogares$dist_frontera, c = 0,
                  covs = covariables, cluster = hogares$distrito, h = 50)

comparacion_rd <- tibble(
  version = c("Ancho de banda óptimo (CCT)", "Ancho de banda fijo, 50 km"),
  h_km    = round(c(rd_auto$bws[1, 1], 50), 1),
  coef    = round(c(rd_auto$coef[1], rd_50$coef[1]), 3),
  ee      = round(c(rd_auto$se[1], rd_50$se[1]), 3),
  n_izq   = c(rd_auto$N_h[1], rd_50$N_h[1]),
  n_der   = c(rd_auto$N_h[2], rd_50$N_h[2])
)

print(comparacion_rd)

# OJO — la cifra del ancho de banda automático es absurda, y la razón es
# importante: la distancia a la frontera está medida a nivel de DISTRITO, así que
# la variable de asignación solo toma 71 valores distintos. El ancho de banda
# automático se va a ~10 km, donde quedan un puñado de distritos por lado, y el
# ajuste explota. El algoritmo no sabe eso; usted sí. Con una ventana razonable
# (50 km) vuelve a dar lo mismo que Dell.

# =============================================================================
# 6. ¿ES CREÍBLE LA FRONTERA?  Pruebas de balance
# =============================================================================
# El supuesto de continuidad no se puede probar, pero sí se puede atacar: si
# algo que NO es la mita salta en la frontera, el diseño está en problemas.
# La receta es la misma de siempre, cambiando lo que va a la izquierda del ~.

# --- 6a. Geografía de hoy: ¿la frontera coincide con un accidente del terreno? -
m_balance_elevacion <- feols(
  elv_sh ~ mita +
    x + y + I(x^2) + I(y^2) + I(x * y) + I(x^3) + I(y^3) + I(x^2 * y) + I(x * y^2) +
    bfe4_1 + bfe4_2 + bfe4_3,
  data = hogares_100, cluster = ~distrito
)

m_balance_pendiente <- feols(
  slope ~ mita +
    x + y + I(x^2) + I(y^2) + I(x * y) + I(x^3) + I(y^3) + I(x^2 * y) + I(x * y^2) +
    bfe4_1 + bfe4_2 + bfe4_3,
  data = hogares_100, cluster = ~distrito
)

balance_geo <- bind_rows(
  tidy(m_balance_elevacion) |> mutate(variable = "elv_sh"),
  tidy(m_balance_pendiente) |> mutate(variable = "slope")
) |>
  filter(term == "mita") |>
  select(variable, coef = estimate, ee = std.error, p = p.value)

print(balance_geo)

# --- 6b. La prueba fuerte: el censo de Toledo de 1572 -------------------------
# Ese censo se levantó UN AÑO ANTES de que empezara la mita. Si los distritos de
# mita ya eran distintos en 1572, la frontera nunca fue "como aleatoria".
# Acá la unidad es el distrito, no el hogar: son 109 distritos con registro.
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
  tidy(m_pre_tributarios) |> mutate(variable = "sh_trib",  n = nobs(m_pre_tributarios)),
  tidy(m_pre_ninos)       |> mutate(variable = "sh_boys",  n = nobs(m_pre_ninos)),
  tidy(m_pre_mujeres)     |> mutate(variable = "sh_women", n = nobs(m_pre_mujeres))
) |>
  filter(term == "mita") |>
  select(variable, coef = estimate, ee = std.error, p = p.value, n)

print(balance_1572)
# esperado: ningún salto significativo -> antes de la mita, los dos lados se
# parecían. Es la mejor defensa del diseño que hay en estos datos.

# Juntamos los dos bloques de balance para graficarlos en el mismo eje.
# Dividimos coef/ee para obtener el estadístico t: así todo queda comparable.
etiquetas <- c(elv_sh = "Elevación", slope = "Pendiente",
               sh_trib = "% tributarios", sh_boys = "% niños", sh_women = "% mujeres")

balance <- bind_rows(
  balance_geo  |> mutate(bloque = "Geografía de hoy"),
  balance_1572 |> mutate(bloque = "Demografía de 1572 (pre-mita)")
) |>
  mutate(
    etiqueta = factor(etiquetas[variable], levels = etiquetas),
    t = coef / ee
  )

g4 <- ggplot(balance, aes(etiqueta, t)) +
  geom_hline(yintercept = c(-1.96, 1.96), linetype = "dashed", color = "grey60") +
  geom_hline(yintercept = 0, color = "grey30") +
  geom_point(size = 3.5, color = "#2c7fb8") +
  facet_wrap(~ bloque, scales = "free_x") +
  coord_cartesian(ylim = c(-3, 3)) +
  labs(title = "Nada más salta en la frontera",
       subtitle = "Estadístico t del salto; entre las líneas punteadas el salto no es significativo",
       x = NULL, y = "t del coeficiente de la mita",
       caption = "Fuente: datos de réplica de Dell (2010); censo de Toledo, 1572.") +
  theme_minimal(base_size = 13)
print(g4)

# =============================================================================
# 7. ¿POR QUÉ PERSISTE?  El mecanismo que propone Dell
# =============================================================================
# El resultado es raro: la mita se abolió en 1812 y su efecto sigue ahí en 2001.
# ¿Por cuál canal viaja doscientos años? El argumento de Dell, en cuatro pasos:
#
#   1. HACIENDAS. Fuera de la mita se formaron grandes haciendas; dentro, la
#      Corona lo impidió para no competir por la mano de obra. Resultado: hoy
#      hay MENOS tierra en manos de propietarios grandes en los distritos de mita.
#   2. BIENES PÚBLICOS. Los hacendados tenían poder político y capital para
#      exigirle al Estado carreteras y escuelas; las comunidades campesinas
#      dispersas no. Dell encuentra menos escolaridad en zonas de mita
#      (Tabla VII: -1,5 años en 2001).
#   3. CAMINOS. Los distritos de mita quedaron peor conectados a la red vial
#      (Tabla VIII).
#   4. MERCADO. Sin caminos, los hogares de mita venden menos y producen para
#      autoconsumo (Tabla IX): agricultura de subsistencia en vez de mercado.
#
# Es decir: la mita no dejó una herida directa, sino que EMPUJÓ A LA REGIÓN POR
# UN CAMINO INSTITUCIONAL DISTINTO, y ese camino se reprodujo solo.

# =============================================================================
# 8. GUARDAR LAS GRÁFICAS Y LOS NÚMEROS TITULARES
# =============================================================================
dir.create("figuras", showWarnings = FALSE)
ggsave("figuras/1-frontera-mita.png",    g1, width = 8, height = 5, dpi = 150)
ggsave("figuras/2-salto-consumo.png",    g2, width = 8, height = 5, dpi = 150)
ggsave("figuras/3-especificaciones.png", g3, width = 8, height = 5, dpi = 150)
ggsave("figuras/4-balance-frontera.png", g4, width = 8, height = 5, dpi = 150)

# results.json: los números que el deck de la sesión cita, resueltos desde
# la corrida real y no escritos a mano.
writeLines(sprintf(
  '{\n  "rdd_mita_jump": %.4f,\n  "rdd_mita_se": %.4f,\n  "rdd_mita_pct": %.1f,\n  "n_obs": %d,\n  "n_clusters": %d,\n  "bw_km": 100\n}',
  efecto_principal$coeficiente, efecto_principal$ee, efecto_principal$efecto_pct,
  efecto_principal$hogares, efecto_principal$distritos), "results.json")

# =============================================================================
# 9. SÍNTESIS (para discutir en clase)
# =============================================================================
# - Los hogares de distritos que estuvieron sujetos a la mita consumen ~25% menos
#   que sus vecinos de justo al otro lado de la frontera, casi 200 años después
#   de abolida la institución.
# - El resultado sobrevive a tres formas de controlar la geografía y a tres
#   ventanas: no es un artefacto de la especificación.
# - Nada más salta en la frontera: ni la geografía de hoy, ni la demografía de
#   1572. Eso es lo que sostiene la interpretación causal.
#
# PARA DISCUTIR: ¿por qué deberíamos creer que esto es causal?
#   Todo descansa en la CONTINUIDAD: que hogares justo dentro y justo fuera sean
#   comparables en todo salvo la mita. Lo que la rompería: que la frontera
#   coincida con otra discontinuidad preexistente (un límite étnico, un piso
#   ecológico, la frontera de las haciendas), o que la gente se haya mudado de un
#   lado al otro por razones ligadas al ingreso. El balance de 1572 ayuda, pero
#   no cubre todo: solo mide lo que ese censo alcanzó a registrar.
#
# Y OJO CON LA VALIDEZ EXTERNA: esto es un efecto LOCAL, en la frontera. No es
#   "el efecto de la mita en el Perú", es el efecto en los distritos que quedaron
#   al borde del área de reclutamiento.
