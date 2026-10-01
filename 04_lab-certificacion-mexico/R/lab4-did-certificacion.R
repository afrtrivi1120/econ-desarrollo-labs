# =============================================================================
# LAB 4 — Certificar la tierra y migrar: PROCEDE en los ejidos de México
# Economía del Desarrollo (06230) · Universidad ICESI
#
# Datos: paquete de réplica de de Janvry, A., Emerick, K., Gonzalez-Navarro, M.
#        y Sadoulet, E. (2015), "Delinking Land Rights from Land Use:
#        Certification and Migration in Mexico", American Economic Review
#        105(10), 3125-3149. openICPSR-112931, datos bajo licencia CC BY 4.0.
# Idea: en los ejidos mexicanos el derecho a la parcela se mantenía TRABAJÁNDOLA.
#   Quien se iba por mucho tiempo arriesgaba perderla. Entre 1993 y 2006 el
#   programa PROCEDE entregó certificados a los ejidatarios y rompió ese
#   vínculo. La pregunta: si la tierra ya no exige que uno se quede, ¿la gente
#   se va?
#
# OJO: acá NO hay sorteo. Todos los ejidos se certificaron, pero en años
# distintos, y la identificación sale de comparar a los que se certificaron
# ANTES con los que todavía no. Eso es una diferencia en diferencias con
# ADOPCIÓN ESCALONADA, y depende de un supuesto que no se puede probar:
# sin PROCEDE, la migración habría evolucionado igual en los ejidos tempranos y
# en los tardíos (TENDENCIAS PARALELAS). Las secciones 5 y 6 lo ponen a prueba.
# =============================================================================

# =============================================================================
# 0. PREPARACIÓN
# =============================================================================
# pacman instala lo que falte y carga lo que ya esté: una sola línea para todo.
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, scales, fixest, broom, did)

# Seis subsets de enseñanza, ya listos (ver datos/codebook.md).
hogares     <- read_rds("datos/janvry_hogares.rds")            # Tabla 1 y A4
localidades <- read_rds("datos/janvry_localidades.rds")        # Tabla 2, cols. 1-5
placebo     <- read_rds("datos/janvry_localidades_80_90.rds")  # Tabla 2, col. 6
censo       <- read_rds("datos/janvry_censo_ejidal.rds")       # Tabla 3
procampo    <- read_rds("datos/janvry_procampo.rds")           # Figura 2
satelite    <- read_rds("datos/janvry_satelite.rds")           # Tabla 4 y Figura 1

# El azul del control y el naranja del tratamiento son los mismos de los Labs 2 y 3.
azul    <- "#2c7fb8"
naranja <- "#d95f0e"
colores_cohorte <- c("Certificado en 1997" = "#d95f0e",
                     "Certificado en 1998" = "#fdae61",
                     "Certificado en 1999" = "#a6bddb",
                     "Aún sin certificar en 2000" = "#2c7fb8")

# Saca el coeficiente de una variable de un modelo como una fila de tibble.
fila <- function(modelo, variable, columna) {
  tidy(modelo) |>
    filter(term == variable) |>
    transmute(columna, coef = estimate, ee = std.error, p = p.value,
              n = nobs(modelo))
}

# =============================================================================
# 1. UNA MIRADA A LOS DATOS
# =============================================================================
dim(hogares)     # filas (hogar x año) x columnas
head(hogares)

# Es un PANEL: los mismos hogares, observados cuatro años seguidos.
hogares |>
  summarise(hogares = n_distinct(hogar), ejidos = n_distinct(ejido),
            estados = n_distinct(estado), anios = n_distinct(anio))
# esperado: 7.577 hogares en 127 ejidos de 7 estados, 1997-2000.
# (El paper habla de 195 ejidos empatados; la muestra de la Tabla 1 se queda solo
#  con los certificados DESPUÉS de 1996: los que ya lo estaban en 1997 no tienen
#  ningún "antes" que aportar.)

# El resultado: ¿el hogar ya tiene un migrante permanente? Ojo, es ACUMULADO:
# vale 1 si alguien se fue ESE año o cualquier año anterior de la muestra. Por
# eso solo puede subir con el tiempo.
hogares |>
  group_by(anio) |>
  summarise(hogares = n(), tasa_migrante = mean(migrante))

# El tratamiento: ¿el ejido estaba certificado al INICIO del año? No es más que
# comparar el año de la encuesta con el año en que el ejido terminó PROCEDE.
hogares |>
  count(anio_procede, anio, certificado) |>
  pivot_wider(names_from = anio, values_from = n)
# Un ejido que terminó PROCEDE en 1997 cuenta como certificado desde 1998.

# =============================================================================
# 2. EL CALENDARIO DE PROCEDE: QUIÉN SE CERTIFICA CUÁNDO
# =============================================================================
# --- 2a. A escala nacional (versión en barras de la Figura 1) ----------------
# La base satelital cubre los 26.481 ejidos que terminaron el programa.
calendario <- satelite |>
  distinct(ejido, anio_procede) |>
  count(anio_procede, name = "ejidos")

print(calendario)

# ¿Qué fracción de los ejidos ya había terminado en 1997?
calendario |>
  summarise(hasta_1997 = sum(ejidos[anio_procede <= 1997]) / sum(ejidos))

g1 <- calendario |>
  mutate(ventana = if_else(anio_procede %in% 1997:1999,
                           "Cambian de estado dentro del panel 1997-2000",
                           "Fuera de esa ventana")) |>
  ggplot(aes(anio_procede, ejidos, fill = ventana)) +
  geom_col(width = 0.8) +
  scale_fill_manual(values = c("Cambian de estado dentro del panel 1997-2000" = naranja,
                               "Fuera de esa ventana" = "grey70")) +
  scale_x_continuous(breaks = seq(1993, 2007, by = 2)) +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
  labs(title = "PROCEDE no llegó a todos al mismo tiempo",
       subtitle = "Ejidos que terminaron la certificación cada año (los 26.481 de la base satelital)",
       x = "Año en que el ejido terminó PROCEDE", y = "Ejidos", fill = NULL,
       caption = "Fuente: de Janvry et al. (2015), datos de réplica (imágenes Landsat + PROCEDE).") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom")
print(g1)

# Más de la mitad de los ejidos ya había terminado en 1997. Esa velocidad, con
# una cola larga hasta 2006, es lo que da la variación: en cualquier año hay
# ejidos certificados y ejidos que todavía esperan.

# --- 2b. En el panel: cuatro grupos de ejidos ---------------------------------
# Con datos de 1997 a 2000, los ejidos del panel se parten en COHORTES según el
# primer año en que aparecen certificados.
hogares <- hogares |>
  mutate(
    primer_anio_cert = if_else(anio_procede <= 1999, anio_procede + 1, 0),
    cohorte = case_when(
      anio_procede == 1997 ~ "Certificado en 1997",
      anio_procede == 1998 ~ "Certificado en 1998",
      anio_procede == 1999 ~ "Certificado en 1999",
      TRUE                 ~ "Aún sin certificar en 2000"
    ),
    cohorte = factor(cohorte, levels = names(colores_cohorte))
  )

hogares |>
  distinct(ejido, cohorte) |>
  count(cohorte, name = "ejidos")

tendencias <- hogares |>
  group_by(cohorte, anio) |>
  summarise(tasa_migrante = mean(migrante), .groups = "drop")

g2 <- ggplot(tendencias, aes(anio, tasa_migrante, color = cohorte)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  scale_color_manual(values = colores_cohorte) +
  scale_y_continuous(labels = label_percent(accuracy = 1)) +
  labs(title = "La migración sube en todos lados; la pregunta es dónde sube MÁS",
       subtitle = "Hogares con un migrante permanente, por cohorte de certificación",
       x = NULL, y = "Hogares con migrante", color = NULL,
       caption = "Fuente: de Janvry et al. (2015), panel PROGRESA 1997-2000.") +
  guides(color = guide_legend(nrow = 2)) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom")
print(g2)

# Cómo se lee: el NIVEL de cada línea no dice nada (los ejidos difieren en mil
# cosas fijas: lejanía, tamaño, tradición migratoria). Lo que importa es la
# PENDIENTE: ¿se empina la línea de un ejido después de que se certifica, más de
# lo que se empinan las de los que aún no se certifican?

# =============================================================================
# 3. EL RESULTADO TITULAR  (Tabla 1, columna 1)
# =============================================================================
# --- 3a. Antes de la regresión: un DiD de 2x2 hecho a mano --------------------
# La cohorte certificada en 1998 cambia de estado entre 1998 y 1999. Los que
# siguen sin certificar en 2000 no cambian. La diferencia en diferencias:
dd <- hogares |>
  filter(anio %in% c(1998, 1999),
         cohorte %in% c("Certificado en 1998", "Aún sin certificar en 2000")) |>
  group_by(cohorte, anio) |>
  summarise(tasa = mean(migrante), .groups = "drop") |>
  pivot_wider(names_from = anio, values_from = tasa, names_prefix = "a") |>
  mutate(cambio = a1999 - a1998)

print(dd)
cat(sprintf("\nDiD 2x2 = %.4f\n", diff(rev(dd$cambio))))
# La resta de las dos restas: lo que cambió la cohorte tratada MENOS lo que
# cambió el control en el mismo año. El "menos" se lleva todo lo que le pasó a
# todos en 1999 (una crisis, una sequía, el dólar).

# --- 3b. La regresión de efectos fijos: ecuación (1) del paper ----------------
# y_ijt = δ Certif_jt + γ_j + α_t + ε_ijt
#   γ_j: efecto fijo de EJIDO (todo lo fijo del ejido)
#   α_t: efecto fijo de AÑO   (todo lo que le pasa a todos en t)
# Los EE se agrupan por ejido: el tratamiento se asigna a nivel de ejido.
m_titular <- feols(migrante ~ certificado | ejido + anio,
                   data = hogares, cluster = ~ejido)
summary(m_titular)
# esperado (Tabla 1, col. 1): 0,0149 (0,0061), N = 27.189

media_dep <- mean(hogares$migrante)
efecto_relativo <- coef(m_titular)[["certificado"]] / media_dep

cat(sprintf("\nEfecto: %.4f sobre una media de %.3f -> %+.0f%% \n",
            coef(m_titular)[["certificado"]], media_dep, 100 * efecto_relativo))
# LECTURA: tener el certificado sube 1,5 PUNTOS la probabilidad de que el hogar
# tenga un migrante. Parece poco, pero sobre una base de 5,3 % es un aumento de
# 28 %. Esa es la cifra del resumen del paper.

# =============================================================================
# 4. ¿AGUANTA?  Las otras cinco columnas de la Tabla 1
# =============================================================================
# Cada columna ataca una amenaza distinta. Lea la pregunta antes que el número.

# (2) ¿Es que los hogares cambiaron, o que NAFTA cambió los precios agrícolas?
m2 <- feols(migrante ~ certificado + propietario + hombres_17a30 + jefa_mujer +
              edad_jefe + valor_agricola | ejido + anio,
            data = hogares, cluster = ~ejido)

# (3) ¿Y si el efecto fijo de ejido no basta? Uno por HOGAR.
#     fixef.rm = "none" deja los hogares observados un solo año, como Stata.
m3 <- feols(migrante ~ certificado | hogar + anio,
            data = hogares, cluster = ~ejido, fixef.rm = "none")

# (4) ¿Y si cada estado tuvo su propia evolución? Año x estado.
m4 <- feols(migrante ~ certificado | ejido + estado^anio,
            data = hogares, cluster = ~ejido)

# (5) ¿Y si los hogares con más jóvenes migraban más con el tiempo de todos
#     modos? Características del hogar x año.
m5 <- feols(migrante ~ certificado + propietario + hombres_17a30 + jefa_mujer + edad_jefe +
              i(anio, propietario, 1997) + i(anio, hombres_17a30, 1997) +
              i(anio, jefa_mujer, 1997) + i(anio, edad_jefe, 1997) | ejido + anio,
            data = hogares, cluster = ~ejido)

# (6) LA MÁS IMPORTANTE. PROCEDE llegó antes a ciertos ejidos (más cerca de las
#     ciudades, por ejemplo). Si esos ejidos iban a migrar más de todos modos,
#     el efecto es falso. Características del ejido x año.
m6 <- feols(migrante ~ certificado +
              i(anio, ejidatarios, 1997) + i(anio, area_total, 1997) +
              i(anio, no_votantes, 1997) + i(anio, latitud, 1997) +
              i(anio, longitud, 1997) + i(anio, dist_ciudad_km, 1997) +
              i(anio, prop_parcelada, 1997) + i(anio, marginacion, 1997) | ejido + anio,
            data = hogares, cluster = ~ejido)

tabla1 <- bind_rows(
  fila(m_titular, "certificado", "(1) Efectos fijos de ejido y año"),
  fila(m2, "certificado", "(2) + controles de hogar y valor agrícola"),
  fila(m3, "certificado", "(3) Efectos fijos de hogar"),
  fila(m4, "certificado", "(4) Año x estado"),
  fila(m5, "certificado", "(5) Características del hogar x año"),
  fila(m6, "certificado", "(6) Características del ejido x año")
)
print(tabla1)
# esperado (Tabla 1): 0,0149 (0,0061) | 0,0147 (0,0066) | 0,0153 (0,0062) |
#                     0,0172 (0,0059) | 0,0157 (0,0063) | 0,0130 (0,0062)
#                     N = 27.189 | 23.421 | 27.189 | 27.189 | 24.533 | 27.189
# Los coeficientes coinciden en los cuatro decimales. Algún EE difiere en el
# cuarto (0,0065 contra 0,0066; 0,0058 contra 0,0059): Stata y fixest no cuentan
# igual los grados de libertad cuando hay efectos fijos (ver la sección 5a).
# Con 27.189 observaciones no cambia nada.

# LECTURA: el coeficiente se mueve entre 0,013 y 0,017 en las seis columnas. Ni
# los controles ni las tendencias específicas lo borran. Pero ojo con lo que
# esto NO prueba: todas son la misma comparación con más cosas a la derecha.
# Si hay algo que no se observa y que cambió justo con PROCEDE, ninguna columna
# lo ve.

# =============================================================================
# 5. ¿TENDENCIAS PARALELAS?  (Tabla A4 y estudio de evento)
# =============================================================================
# El supuesto no se puede probar, pero sí se puede ATACAR por su lado visible:
# ANTES de certificarse, ¿los ejidos tempranos y los tardíos se movían igual?
# Si PROCEDE llegó primero adonde la migración ya venía subiendo, el DiD
# confunde esa tendencia con un efecto.

# --- 5a. Tabla A4: cambios pre-programa según el año de PROCEDE ---------------
# Se colapsa a nivel de ejido x año y se miran SOLO los años antes de certificarse.
ejido_anio <- hogares |>
  group_by(ejido, anio_procede, anio) |>
  summarise(migrante = mean(migrante), .groups = "drop") |>
  arrange(ejido, anio) |>
  group_by(ejido) |>
  # El cambio contra el año anterior, solo si el año anterior existe (como l. en Stata)
  mutate(cambio = if_else(lag(anio) == anio - 1, migrante - lag(migrante), NA_real_)) |>
  ungroup() |>
  mutate(py99 = anio_procede == 1999, py00 = anio_procede == 2000,
         py01 = anio_procede > 2000)

pre <- ejido_anio |> filter(!is.na(cambio), anio <= anio_procede)

a4_1 <- feols(cambio ~ py99 + py00 + py01, data = filter(pre, anio == 1998), vcov = "hetero")
a4_2 <- feols(cambio ~ py00 + py01 | anio, cluster = ~ejido,
              data = filter(pre, anio <= 1999, anio_procede >= 1999))
a4_3 <- feols(cambio ~ py01 | anio, cluster = ~ejido,
              data = filter(pre, anio <= 2000, anio_procede >= 2000))

etable(a4_1, a4_2, a4_3, digits = 4)
# esperado (Tabla A4, cols. 1-3): py99 -0,0011 | py00 -0,0040, -0,0087 |
#   py01 -0,0131, -0,0102, 0,0015; N = 111, 187, 225

p_pre_1 <- wald(a4_1, keep = "py", print = FALSE)$p
p_pre_2 <- wald(a4_2, keep = "py", print = FALSE)$p
cat(sprintf("\np conjunta, col. 1: %.3f | col. 2: %.3f\n", p_pre_1, p_pre_2))
# esperado: 0,190 y 0,493. No se rechaza que el año de PROCEDE no prediga los
# cambios de migración ANTES del programa.

# Col. 4: ¿hubo una caída justo antes de certificarse ("Ashenfelter dip")? Si los
# hogares se quedaron a cuidar la parcela mientras pasaba PROCEDE, el "efecto"
# podría ser solo la vuelta a lo normal.
a4_4 <- feols(migrante ~ anio_de + anio_antes + dos_antes | anio + ejido,
              data = ejido_anio |>
                filter(anio <= anio_procede) |>
                mutate(anio_de    = as.numeric(anio == anio_procede),
                       anio_antes = as.numeric(anio == anio_procede - 1),
                       dos_antes  = as.numeric(anio == anio_procede - 2)),
              fixef.rm = "none",
              # Stata (`reg` con dummies de ejido) cuenta los 127 efectos fijos
              # como parámetros al corregir los EE por muestra pequeña; fixest,
              # por defecto, no. Con 27.189 observaciones da igual; con 406 y
              # 127 efectos fijos, los EE cambian en un 20 %.
              vcov = vcov_cluster(~ejido, ssc = ssc(fixef.K = "full")))
summary(a4_4)
# esperado (Tabla A4, col. 4): 0,0018 (0,0150) | -0,0021 (0,0107) | -0,0015 (0,0089); N = 406
# Sin la línea de `ssc`, los coeficientes son los mismos pero los EE salen
# 0,0124 / 0,0089 / 0,0074: más chicos y, por eso, demasiado optimistas.

# OJO, que es lo que el Escéptico debe decir: "no rechazar" no es "probar". Los
# EE son del mismo tamaño que el efecto que estamos buscando (0,015). Con 127
# ejidos, una pre-tendencia de ese tamaño pasaría sin ser detectada.

# --- 5b. El estudio de evento -------------------------------------------------
# En vez de UN coeficiente, uno por cada año relativo a la certificación. Los
# coeficientes ANTES de 0 son la prueba visual de tendencias paralelas; los de
# DESPUÉS muestran cómo se acumula el efecto. Usamos sunab() (Sun y Abraham,
# 2021), que compara cada cohorte solo contra quienes no están tratados.
hogares <- hogares |>
  mutate(cohorte_sa = if_else(primer_anio_cert == 0, 10000, primer_anio_cert))

m_evento <- feols(migrante ~ sunab(cohorte_sa, anio) | ejido + anio,
                  data = hogares, cluster = ~ejido)
summary(m_evento)

evento <- tidy(m_evento) |>
  mutate(t = as.integer(str_extract(term, "-?\\d+$"))) |>
  select(t, coef = estimate, ee = std.error) |>
  bind_rows(tibble(t = -1L, coef = 0, ee = 0)) |>
  arrange(t)
print(evento)

g3 <- ggplot(evento, aes(t, coef)) +
  geom_hline(yintercept = 0, color = "grey40") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey50") +
  geom_errorbar(aes(ymin = coef - 1.96 * ee, ymax = coef + 1.96 * ee),
                width = 0.12, color = ifelse(evento$t < 0, azul, naranja)) +
  geom_point(size = 3, color = ifelse(evento$t < 0, azul, naranja)) +
  scale_x_continuous(breaks = -3:2) +
  scale_y_continuous(labels = label_number(decimal.mark = ",")) +
  labs(title = "Antes de certificarse, nada claro; después, el efecto se acumula",
       subtitle = "Estudio de evento (Sun y Abraham), año -1 como referencia; IC al 95 %",
       x = "Años desde la certificación", y = "Efecto sobre P(hogar con migrante)",
       caption = "Fuente: de Janvry et al. (2015), datos de réplica; cálculo propio.") +
  theme_minimal(base_size = 13)
print(g3)

# Cómo se lee: el año -3 solo existe para la cohorte de 2000 y el -2 para dos
# cohortes; por eso sus intervalos son tan anchos. Los puntos de antes son
# NEGATIVOS, aunque no significativos: si algo, los ejidos tratados migraban un
# poco MENOS antes. El Escéptico puede preguntar si eso es una tendencia que
# ya venía subiendo.

# =============================================================================
# 6. EL PROBLEMA DEL TWFE CON ADOPCIÓN ESCALONADA  (Callaway y Sant'Anna)
# =============================================================================
# La regresión de la sección 3 promedia MUCHAS comparaciones 2x2, y no todas
# son limpias. Cuando la cohorte de 1999 se certifica, el TWFE usa como
# "control" a la cohorte de 1998, que ya estaba tratada. Si el efecto CRECE con
# el tiempo (y acá crece: el resultado es acumulado), esa comparación resta
# parte del efecto y puede sesgar el promedio. Es la crítica de Goodman-Bacon
# (2021) y de Callaway y Sant'Anna (2021), posterior al paper.
#
# La solución de Callaway y Sant'Anna: estimar un efecto por cada cohorte g y
# cada año t, ATT(g,t), usando como control SOLO a quienes todavía no están
# tratados, y después promediar.
set.seed(2026)   # los intervalos simultáneos salen de un bootstrap
cs <- att_gt(yname = "migrante", tname = "anio", idname = "hogar",
             gname = "primer_anio_cert", data = as.data.frame(hogares),
             panel = TRUE, allow_unbalanced_panel = TRUE,
             control_group = "notyettreated", clustervars = "ejido",
             est_method = "reg", base_period = "universal")
summary(cs)

cs_simple   <- aggte(cs, type = "simple")
cs_dinamico <- aggte(cs, type = "dynamic")
cs_simple
cs_dinamico

comparacion <- tibble(
  estimador = c("TWFE (paper, Tabla 1 col. 1)",
                "Sun y Abraham (promedio post)",
                "Callaway y Sant'Anna (no aún tratados)"),
  att = c(coef(m_titular)[["certificado"]],
          summary(m_evento, agg = "ATT")$coeftable["ATT", "Estimate"],
          cs_simple$overall.att),
  ee  = c(se(m_titular)[["certificado"]],
          summary(m_evento, agg = "ATT")$coeftable["ATT", "Std. Error"],
          cs_simple$overall.se)
)
print(comparacion)

g4 <- comparacion |>
  mutate(estimador = fct_rev(fct_inorder(estimador))) |>
  ggplot(aes(att, estimador)) +
  geom_vline(xintercept = 0, color = "grey40") +
  geom_errorbar(aes(xmin = att - 1.96 * ee, xmax = att + 1.96 * ee),
                width = 0.15, orientation = "y", color = naranja) +
  geom_point(size = 3.5, color = naranja) +
  scale_x_continuous(labels = label_number(decimal.mark = ",")) +
  labs(title = "Con estimadores modernos el efecto se achica",
       subtitle = "Efecto sobre P(hogar con migrante); IC al 95 %. El de Callaway y Sant'Anna toca el cero",
       x = "Efecto promedio", y = NULL,
       caption = "Fuente: de Janvry et al. (2015), datos de réplica; cálculo propio.") +
  theme_minimal(base_size = 13) +
  theme(plot.title.position = "plot")
print(g4)

# LECTURA HONESTA. El signo y el orden de magnitud sobreviven: los tres
# estimadores dicen que certificar aumentó la migración en algo más de un punto.
# Pero el punto baja de 0,015 a cerca de 0,011, y el intervalo de Callaway y
# Sant'Anna toca el cero. Con 127 ejidos y solo un año antes del tratamiento
# para la primera cohorte, los datos de hogares no dan para mucho más. Por eso
# importa que el paper NO descanse en una sola base: la sección 7 mira otras dos.

# =============================================================================
# 7. OTRAS DOS BASES, EL MISMO SIGNO  (Tablas 2 y 3)
# =============================================================================
# --- 7a. Población de las localidades: censos 1990 y 2000 (Tabla 2) ----------
# Otra unidad (la localidad), otra fuente (el censo), otro período y TODO el
# país, no solo localidades pobres. Solo dos años: antes (1990) y después (2000).
# Regla de muestra del paper (nota 14): localidades con más de 20 habitantes en
# 1990, porque las muy pequeñas desaparecen o se reagrupan.
loc <- localidades |>
  filter(pob_1990 > 20) |>
  mutate(
    despues = as.numeric(anio == 2000),
    # OJO con los faltantes: `anio_procede %in% 1993:1999` le da FALSE a una
    # localidad SIN año de PROCEDE y la mete como control. La comparación deja
    # NA y la localidad sale, que es lo que hace Stata. Con %in% el coeficiente
    # de la col. 2 da -0,0401 en vez de -0,0404: el tipo de error que no avisa.
    cert_93_99 = as.numeric(anio_procede >= 1993 & anio_procede <= 1999),
    cert_x_2000 = cert_93_99 * despues,
    anios_cert  = if_else(anio_procede < 2000, 2000 - anio_procede, 0),
    cert_x_2000_x_anios = cert_x_2000 * anios_cert,
    temprano_x_2000 = as.numeric(anio_procede <= 1996) * despues,
    tardio_x_2000   = as.numeric(anio_procede %in% 1997:1999) * despues
  )

t2_1 <- feols(poblacion ~ despues + cert_x_2000 | ejido, loc, cluster = ~ejido)
t2_2 <- feols(log_pob ~ despues + cert_x_2000 | ejido, loc, cluster = ~ejido)
t2_3 <- feols(log_pob ~ despues + cert_x_2000 + valor_agricola | ejido, loc, cluster = ~ejido)
t2_4 <- feols(log_pob ~ despues + cert_x_2000 + cert_x_2000_x_anios | ejido, loc, cluster = ~ejido)
t2_5 <- feols(log_pob ~ despues + temprano_x_2000 + tardio_x_2000 | ejido, loc, cluster = ~ejido)

# Col. 6, el PLACEBO: la misma comparación una década antes, 1980-1990, cuando
# PROCEDE no existía. Si los futuros certificados ya perdían población más
# rápido, aparecería acá.
t2_6 <- feols(log_pob ~ I(anio == 1990) + cert_93_99_x_1990 | ejido,
              data = filter(placebo, pob_1980 > 20), cluster = ~ejido)

etable(t2_1, t2_2, t2_3, t2_4, t2_5, t2_6, digits = 4, fitstat = ~n)
# esperado (Tabla 2): año 2000 -9,63 | -0,2069 ...
#   certificado x 2000: -3,689 (1,149) | -0,0404 (0,0128) | -0,0341 (0,0167) | -0,0206 (0,0195)
#   temprano -0,0592 (0,0144), tardío -0,0196 (0,0151)
#   placebo 1980-1990: -0,0082 (0,0148)
#   N = 34.656 en cols. 1, 2, 4, 5; 24.170 en col. 3; 24.910 en col. 6

# ¿El efecto temprano es distinto del tardío? (el paper dice que sí)
V <- vcov(t2_5)
dif <- coef(t2_5)[["temprano_x_2000"]] - coef(t2_5)[["tardio_x_2000"]]
ee_dif <- sqrt(V["temprano_x_2000", "temprano_x_2000"] + V["tardio_x_2000", "tardio_x_2000"] -
                 2 * V["temprano_x_2000", "tardio_x_2000"])
cat(sprintf("\nTemprano - tardío = %.4f (EE %.4f), p = %.3f\n", dif, ee_dif,
            2 * pt(-abs(dif / ee_dif), df = degrees_freedom(t2_5, "t"))))

# LECTURA: las localidades de ejidos certificados en 1993-1999 perdieron 4 %
# más de población que las de ejidos certificados después, y la pérdida es
# mayor donde el certificado llevaba más años. El placebo da cero: antes de
# PROCEDE, las dos poblaciones evolucionaban igual. Esta es, de hecho, la
# prueba de tendencias paralelas MÁS convincente del paper.

# --- 7b. El censo ejidal 2007 (Tabla 3) ---------------------------------------
# La tercera base es la más débil: es un CORTE TRANSVERSAL. En 2007 todos ya
# estaban certificados, así que solo se compara cuántos AÑOS llevaba cada uno.
t3_1 <- feols(jovenes_migran ~ anios_certificado | estado, censo, cluster = ~municipio)
t3_2 <- feols(jovenes_migran ~ anios_certificado + semilla_mejorada + tractor +
                electricidad + log_dist_pa | estado, censo, cluster = ~municipio)
etable(t3_1, t3_2, digits = 4, fitstat = ~n)
# esperado (Tabla 3): 0,0035 (0,0013) | 0,0039 (0,0013); N = 19.670 | 19.600
# Sin efecto fijo de ejido, esta regresión es tan buena como el supuesto de que
# los ejidos tempranos y tardíos eran iguales en todo lo demás. Sirve como
# coherencia con lo anterior, no como prueba independiente.

# =============================================================================
# 8. ¿Y LA TIERRA?  Migración sin abandono: consolidación  (Figura 2 y Tabla 4)
# =============================================================================
# Si la gente se va, ¿la tierra queda baldía? Ese es el temor clásico. El paper
# dice que no: los que se quedan cultivan la tierra de los que se fueron.

# --- 8a. PROCAMPO, 1995 contra 2012 (Figura 2) --------------------------------
# Diferencia larga por ejido, contra el año en que se certificó. La categoría de
# referencia son los ejidos certificados en 2005 o después.
procampo <- procampo |>
  mutate(d_productores = log_productores_2012 - log_productores_1995,
         d_area        = log_area_2012 - log_area_1995,
         d_area_x_prod = (log_area_2012 - log_productores_2012) -
                         (log_area_1995 - log_productores_1995),
         anio_cert     = pmin(anio_procede, 2005))

m_fig2 <- feols(c(d_productores, d_area, d_area_x_prod) ~ i(anio_cert, ref = 2005) | estado,
                data = procampo, cluster = ~municipio)
etable(m_fig2, digits = 3)

fig2 <- map_dfr(1:3, function(k) {
  tidy(m_fig2[[k]]) |>
    mutate(panel = c("Cambio en log de productores", "Cambio en log del área",
                     "Cambio en log del área por productor")[k],
           anio = as.integer(str_extract(term, "\\d{4}")))
}) |>
  mutate(panel = fct_inorder(panel))

g5 <- ggplot(fig2, aes(anio, estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
  geom_errorbar(aes(ymin = estimate - 1.96 * std.error, ymax = estimate + 1.96 * std.error),
                width = 0.3, color = azul) +
  geom_point(size = 2.5, color = naranja) +
  facet_wrap(~ panel) +
  scale_x_continuous(breaks = c(1993, 1996, 1999, 2002)) +
  scale_y_continuous(labels = label_number(decimal.mark = ",")) +
  labs(title = "Menos productores, la misma área: las fincas se agrandaron",
       subtitle = "Cambio 1995-2012 según el año de certificación, contra los certificados en 2005 o después",
       x = "Año en que el ejido terminó PROCEDE", y = "Coeficiente",
       caption = "Fuente: de Janvry et al. (2015), datos de réplica (PROCAMPO); réplica de la Figura 2.") +
  theme_minimal(base_size = 12)
print(g5)

# Cómo se lee: los ejidos certificados primero (1993-1997) perdieron entre 10 y
# 15 % de sus productores, pero NO perdieron área cultivada. Resultado: el área
# por productor subió alrededor de 10 %. Es la consolidación que predice la
# teoría cuando se abre el mercado de tierras.

# --- 8b. Imágenes satelitales, 1993-2002-2007 (Tabla 4, col. 1) ---------------
t4 <- feols(log_area_agricola ~ certificado | ejido + anio,
            data = satelite, cluster = ~ejido, fixef.rm = "none")
summary(t4)
# esperado (Tabla 4, col. 1): 0,0013 (0,0093), N = 63.392
# Un cero bien medido: certificar no cambió el área cultivada del ejido.

# =============================================================================
# 9. GUARDAR LAS GRÁFICAS Y LOS NÚMEROS TITULARES
# =============================================================================
dir.create("figuras", showWarnings = FALSE)
ggsave("figuras/1-calendario-procede.png",     g1, width = 8, height = 5, dpi = 150)
ggsave("figuras/2-tendencias-por-cohorte.png", g2, width = 8, height = 5, dpi = 150)
ggsave("figuras/3-estudio-de-evento.png",      g3, width = 8, height = 5, dpi = 150)
ggsave("figuras/4-twfe-vs-callaway-santanna.png", g4, width = 8, height = 4.5, dpi = 150)
ggsave("figuras/5-consolidacion-procampo.png", g5, width = 10, height = 4.5, dpi = 150)

# results.json: los números que el deck de la sesión cita, resueltos desde
# la corrida real y no escritos a mano.
jsonlite::write_json(list(
  certif_coef       = round(coef(m_titular)[["certificado"]], 4),
  certif_se         = round(se(m_titular)[["certificado"]], 4),
  n_obs             = nobs(m_titular),
  n_hogares         = n_distinct(hogares$hogar),
  n_ejidos          = n_distinct(hogares$ejido),
  media_dep         = round(media_dep, 4),
  efecto_relativo   = round(efecto_relativo, 3),
  certif_coef_col6  = round(coef(m6)[["certificado"]], 4),
  p_pretendencias   = round(p_pre_1, 3),
  sunab_att         = round(comparacion$att[2], 4),
  sunab_att_se      = round(comparacion$ee[2], 4),
  cs_att            = round(cs_simple$overall.att, 4),
  cs_att_se         = round(cs_simple$overall.se, 4),
  pob_log_coef      = round(coef(t2_2)[["cert_x_2000"]], 4),
  pob_log_se        = round(se(t2_2)[["cert_x_2000"]], 4),
  pob_placebo_coef  = round(coef(t2_6)[["cert_93_99_x_1990"]], 4),
  n_localidades     = nobs(t2_2) / 2,
  jovenes_coef      = round(coef(t3_1)[["anios_certificado"]], 4),
  area_agricola_coef = round(coef(t4)[["certificado"]], 4),
  area_x_prod_1994  = round(coef(m_fig2[[3]])[["anio_cert::1994"]], 3)
), "results.json", auto_unbox = TRUE, pretty = TRUE)

# =============================================================================
# 10. SÍNTESIS (para discutir en clase)
# =============================================================================
# - Certificar la tierra subió 1,5 puntos (28 %) la probabilidad de que un hogar
#   ejidal tuviera un migrante permanente. El resultado aguanta controles,
#   efectos fijos de hogar y tendencias por estado y por características del
#   ejido.
# - Otra base, otra unidad, otro período: las localidades de ejidos
#   certificados perdieron 4 % más de población, más cuanto antes se
#   certificaron, y el placebo 1980-1990 da cero.
# - La tierra no se abandonó: menos productores, la misma área, fincas más
#   grandes. Migración y consolidación son dos caras del mismo mercado que se
#   abre.
# - Con los estimadores modernos de DiD escalonado, el efecto en hogares se
#   achica y pierde precisión. El signo sobrevive; la precisión de la Tabla 1,
#   no del todo. La fuerza del paper está en que tres bases independientes
#   apuntan para el mismo lado.
#
# PARA DISCUTIR: ¿por qué deberíamos creer que esto es causal si no hubo sorteo?
#   Porque el orden de llegada de PROCEDE no parece correlacionado con la
#   migración ANTES del programa (Tabla A4, placebo de la Tabla 2). Pero eso se
#   ve en lo observable. El Escéptico pregunta: ¿qué determinó el orden? Si
#   PROCEDE llegó primero a los ejidos más organizados o mejor conectados,
#   ¿no son esos también los que tienen redes de migración que maduran justo
#   en esos años?
#
# Y LA CONEXIÓN CON LA SESIÓN:
#   - Besley y Ghatak (2010): este es el canal de "dejar de vigilar con el
#     cuerpo". Cuando el derecho no depende de estar, el trabajo se libera.
#   - Goldstein et al. (2018): en Benín, demarcar sin certificar cambió la
#     inversión; acá certificar cambió la asignación del trabajo.
#   - Galán (2024): en Colombia, la tierra de la reforma de 1968 tampoco "ató"
#     a las familias al campo. ¿Qué tienen en común los dos casos?
