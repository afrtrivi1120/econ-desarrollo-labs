# =============================================================================
# LAB 2 — La mita minera del Perú: una frontera que todavía se nota
# Economía del Desarrollo (06230) · Universidad Icesi
#
# Datos: paquete de réplica de Dell, M. (2010), "The Persistent Effects of
#        Peru's Mining Mita", Econometrica 78(6), 1863-1903.
# Idea: replicar el RDD GEOGRÁFICO de Dell. Entre 1573 y 1812, la Corona
#   española obligó a los pueblos DENTRO de un área definida a enviar la
#   séptima parte de sus hombres adultos a las minas de Potosí y Huancavelica.
#   Los pueblos JUSTO AFUERA quedaron exentos. Doscientos años después de
#   abolida, ¿todavía se ve esa frontera en el consumo de los hogares?
#
# OJO: aquí SÍ hacemos una afirmación causal, pero descansa toda en un
# supuesto: CONTINUIDAD en la frontera. Suponemos que todo lo que determina el
# consumo (geografía, cultura, historia previa) varía de forma SUAVE al cruzar
# el límite, y que lo único que salta es haber estado sujeto a la mita.
# Si algo más salta en el mismo lugar, el diseño se cae. (Munición del Escéptico.)
# =============================================================================

# --- 0. Preparación -----------------------------------------------------------
library(data.table)   # manejo de datos
library(ggplot2)      # gráficas
library(scales)       # formato de ejes (% y decimales)
library(fixest)       # regresiones con errores estándar agrupados
library(rdrobust)     # RDD local lineal con ancho de banda óptimo

# Dos subsets de enseñanza, ya listos (ver datos/codebook.md).
hogares   <- as.data.table(readRDS("datos/dell_mita_hogares.rds"))
distritos <- as.data.table(readRDS("datos/dell_mita_distritos.rds"))

# --- 1. Una mirada a los datos ------------------------------------------------
dim(hogares)         # filas (hogares) x columnas
head(hogares)        # primeras filas

# El tratamiento: 1 = distrito sujeto a la mita.
hogares[, .(hogares = .N, distritos = uniqueN(distrito)), by = mita][order(mita)]

# La VARIABLE DE ASIGNACIÓN es la distancia a la frontera CON SIGNO:
#   negativa = fuera de la mita   |   positiva = dentro de la mita
# El tratamiento cambia de golpe en 0; todo lo demás debería variar suave.
hogares[, .(min = min(dist_frontera), max = max(dist_frontera)), by = mita][order(mita)]

# El resultado: log del consumo del hogar por adulto equivalente.
# Como está en logaritmos, un coeficiente b se lee como exp(b)-1 en porcentaje.
summary(hogares$lhhequiv)

# =============================================================================
# 2. EL MAPA  (¿dónde está la frontera?)
# =============================================================================
# Cada punto es un distrito del sur peruano. El color marca si estuvo sujeto a
# la mita. La frontera es la línea donde los dos colores se tocan: ahí es donde
# vamos a comparar.
distritos[, grupo := factor(mita, levels = c(0, 1),
                            labels = c("Fuera de la mita", "Dentro de la mita"))]

g1 <- ggplot(distritos, aes(lon, lat, color = grupo)) +
  geom_point(aes(size = frontera == 1), alpha = .8) +
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
bins <- copy(hogares)
bins[, bin := floor(dist_frontera / 10) * 10 + 5]   # centro del bin de 10 km
resumen <- bins[, .(consumo = mean(lhhequiv), n = .N), by = .(bin, mita)]

g2 <- ggplot(resumen, aes(bin, consumo)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40") +
  geom_point(aes(size = n, color = factor(mita)), alpha = .8) +
  geom_smooth(data = hogares, aes(dist_frontera, lhhequiv, color = factor(mita)),
              method = "lm", formula = y ~ x, se = TRUE) +
  scale_color_manual(values = c("0" = "#2c7fb8", "1" = "#d95f0e"),
                     labels = c("Fuera de la mita", "Dentro de la mita")) +
  scale_size_continuous(range = c(1.5, 6), guide = "none") +
  annotate("text", x = 0, y = max(resumen$consumo), label = "frontera",
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

CUBICA   <- "x + y + I(x^2) + I(y^2) + I(x*y) + I(x^3) + I(y^3) + I(x^2*y) + I(x*y^2)"
CONTROLES <- "elv_sh + slope + infants + children + adults + bfe4_1 + bfe4_2 + bfe4_3"

m_principal <- feols(
  as.formula(paste("lhhequiv ~ mita +", CUBICA, "+", CONTROLES)),
  data = hogares[d_bnd < 100], cluster = ~distrito)

print(coeftable(m_principal)["mita", ])
# esperado: coef ~ -0.284, EE ~ 0.199, no significativo (igual que el paper)

# Del logaritmo al porcentaje: ¿cuánto menos consume un hogar de la mita?
b <- coef(m_principal)["mita"]
cat(sprintf("\nEfecto de la mita: %.1f%% de consumo (coef = %.3f)\n",
            (exp(b) - 1) * 100, b))
cat(sprintf("N = %d hogares en %d distritos\n",
            nobs(m_principal), uniqueN(hogares[d_bnd < 100]$distrito)))

# =============================================================================
# 5. ¿AGUANTA EL RESULTADO?  Especificación y ancho de banda
# =============================================================================
# Un RDD no es un botón: hay que elegir (a) cómo se controla la geografía y
# (b) qué tan cerca de la frontera se mira. Dell reporta 3 polinomios x 3
# ventanas. Replicamos la rejilla completa.

especificaciones <- list(
  "Cúbica en lat-lon"     = CUBICA,
  "Cúbica en dist. Potosí" = "dpot + I(dpot^2) + I(dpot^3)",
  "Cúbica en dist. frontera" = "d_bnd + I(d_bnd^2) + I(d_bnd^3)")

rejilla <- rbindlist(lapply(names(especificaciones), function(nom) {
  rbindlist(lapply(c(100, 75, 50), function(h) {
    m <- feols(as.formula(paste("lhhequiv ~ mita +", especificaciones[[nom]],
                                "+", CONTROLES)),
               data = hogares[d_bnd < h], cluster = ~distrito)
    ct <- coeftable(m)["mita", ]
    data.table(especificacion = nom, ventana = h,
               coef = ct[1], ee = ct[2], p = ct[4], n = nobs(m))
  }))
}))
print(rejilla)
# esperado: todos los coeficientes entre -0.34 y -0.21 (es decir, -29% a -19%);
# los del Panel A no son significativos, los de los otros dos sí.

g3 <- ggplot(rejilla, aes(factor(ventana), coef, color = especificacion)) +
  geom_hline(yintercept = 0, color = "grey50") +
  geom_pointrange(aes(ymin = coef - 1.96 * ee, ymax = coef + 1.96 * ee),
                  position = position_dodge(width = .5)) +
  labs(title = "El efecto de la mita no depende de la especificación",
       subtitle = "Coeficiente e intervalo al 95 %, por control de la geografía y ancho de la ventana",
       x = "Ventana alrededor de la frontera (km)",
       y = "Efecto sobre el log del consumo", color = NULL,
       caption = "Fuente: ENAHO 2001, datos de réplica de Dell (2010).") +
  theme_minimal(base_size = 13) + theme(legend.position = "bottom")
print(g3)

# --- 5b. El estimador moderno: rdrobust ---------------------------------------
# rdrobust ajusta rectas locales a cada lado y elige el ancho de banda óptimo
# (CCT). Es el estándar hoy, pero aquí hay que usarlo con cabeza.
covariables <- as.matrix(hogares[, .(elv_sh, slope, infants, children, adults,
                                     bfe4_1, bfe4_2, bfe4_3)])

rd_auto <- rdrobust(hogares$lhhequiv, hogares$dist_frontera, c = 0,
                    covs = covariables, cluster = hogares$distrito)
cat(sprintf("\nrdrobust con ancho de banda ÓPTIMO: h = %.1f km, coef = %.2f, N = %d/%d\n",
            rd_auto$bws[1, 1], rd_auto$coef[1], rd_auto$N_h[1], rd_auto$N_h[2]))

# OJO — esa cifra es absurda, y la razón es importante: la distancia a la
# frontera está medida a nivel de DISTRITO, así que la variable de asignación
# solo toma 71 valores distintos. El ancho de banda automático se va a ~10 km,
# donde quedan un puñado de distritos por lado, y el ajuste explota. El
# algoritmo no sabe eso; usted sí. Con una ventana razonable vuelve a la vida:
rd_50 <- rdrobust(hogares$lhhequiv, hogares$dist_frontera, c = 0,
                  covs = covariables, cluster = hogares$distrito, h = 50)
cat(sprintf("rdrobust con h = 50 km fijo:        coef = %.3f (EE %.3f)\n",
            rd_50$coef[1], rd_50$se[1]))

# =============================================================================
# 6. ¿ES CREÍBLE LA FRONTERA?  Pruebas de balance
# =============================================================================
# El supuesto de continuidad no se puede probar, pero sí se puede atacar: si
# algo que NO es la mita salta en la frontera, el diseño está en problemas.

# --- 6a. Geografía: ¿la frontera coincide con un accidente del terreno? -------
balance_geo <- rbindlist(lapply(c("elv_sh", "slope"), function(v) {
  m <- feols(as.formula(paste(v, "~ mita +", CUBICA, "+ bfe4_1 + bfe4_2 + bfe4_3")),
             data = hogares[d_bnd < 100], cluster = ~distrito)
  ct <- coeftable(m)["mita", ]
  data.table(variable = v, coef = ct[1], ee = ct[2], p = ct[4])
}))
print(balance_geo)

# --- 6b. La prueba fuerte: el censo de Toledo de 1572 -------------------------
# Ese censo se levantó UN AÑO ANTES de que empezara la mita. Si los distritos de
# mita ya eran distintos en 1572, la frontera nunca fue "como aleatoria".
pre <- distritos[d_bnd < 100 & !is.na(sh_trib)]
balance_1572 <- rbindlist(lapply(c("sh_trib", "sh_boys", "sh_women"), function(v) {
  m <- feols(as.formula(paste(v, "~ mita +", CUBICA,
                              "+ elv_sh + slope + bfe4_1 + bfe4_2 + bfe4_3")),
             data = pre, vcov = "hetero")
  ct <- coeftable(m)["mita", ]
  data.table(variable = v, coef = ct[1], ee = ct[2], p = ct[4], n = nobs(m))
}))
print(balance_1572)
# esperado: ningún salto significativo -> antes de la mita, los dos lados se
# parecían. Es la mejor defensa del diseño que hay en estos datos.

etiquetas <- c(elv_sh = "Elevación", slope = "Pendiente",
               sh_trib = "% tributarios", sh_boys = "% niños", sh_women = "% mujeres")

balance <- rbind(
  balance_geo[,  .(bloque = "Geografía de hoy",        variable, coef, ee)],
  balance_1572[, .(bloque = "Demografía de 1572 (pre-mita)", variable, coef, ee)])
balance[, etiqueta := factor(etiquetas[variable], levels = etiquetas)]

g4 <- ggplot(balance, aes(etiqueta, coef / ee)) +
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
# ¿Por cuál canal viaja doscientos años? El argumento de Dell (Tablas VI a IX
# del paper, que NO están en este subset de enseñanza):
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
#
# NOTA DE HONESTIDAD: este bloque NO se replica aquí. Las variables de haciendas,
# caminos, educación y participación en el mercado están en los archivos
# `files1-3.zip` del paquete original (ver datos/SOURCE.md), que no pudimos
# descargar. Lo que sí replicamos es el efecto sobre el consumo y las pruebas de
# balance. Decir "no tengo el dato" es parte del oficio.

# =============================================================================
# 8. Guardar las gráficas y los números titulares -----------------------------
# =============================================================================
dir.create("figuras", showWarnings = FALSE)
ggsave("figuras/1-frontera-mita.png",       g1, width = 8, height = 5, dpi = 150)
ggsave("figuras/2-salto-consumo.png",       g2, width = 8, height = 5, dpi = 150)
ggsave("figuras/3-especificaciones.png",    g3, width = 8, height = 5, dpi = 150)
ggsave("figuras/4-balance-frontera.png",    g4, width = 8, height = 5, dpi = 150)

# results.json: los números que el deck de la sesión cita, resueltos desde
# la corrida real y no escritos a mano.
ct <- coeftable(m_principal)["mita", ]
writeLines(sprintf(
  '{\n  "rdd_mita_jump": %.4f,\n  "rdd_mita_se": %.4f,\n  "rdd_mita_pct": %.1f,\n  "n_obs": %d,\n  "n_clusters": %d,\n  "bw_km": 100\n}',
  ct[1], ct[2], (exp(ct[1]) - 1) * 100,
  nobs(m_principal), uniqueN(hogares[d_bnd < 100]$distrito)), "results.json")

# =============================================================================
# 9. Síntesis (para discutir en clase)
# =============================================================================
# - Los hogares de distritos que estuvieron sujetos a la mita consumen ~25% menos
#   que sus vecinos de justo al otro lado de la frontera, casi 200 años después
#   de abolida la institución.
# - El resultado sobrevive a tres formas de controlar la geografía y a tres
#   ventanas: no es un artefacto de la especificación.
# - Nada más salta en la frontera: ni la geografía de hoy, ni la demografía de
#   1572. Eso es lo que sostiene la interpretación causal.
#
# PREGUNTA DEL ESCÉPTICO: ¿por qué deberíamos creer que esto es causal?
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
