# =============================================================================
# LAB 1 — La distribución del ingreso en Colombia: foto antes/después de la pandemia
# Economía del Desarrollo (06230) · Universidad Icesi
#
# Datos: GEIH — Medición de Pobreza Monetaria y Desigualdad, DANE (2019 y 2021).
# Idea: replicar, con datos de Colombia, las dos lecturas de la sesión —
#   (1) Sala-i-Martin (2006): mirar la DISTRIBUCIÓN del ingreso, no solo el promedio.
#   (2) Banco Mundial (2020): ver QUIÉN es pobre (edad, género, educación).
#
# OJO: esto es DESCRIPTIVO (una foto 2019 vs 2021), no causal. No hay
# contrafactual: entre 2019 y 2021 cambió la pandemia, pero también muchas
# otras cosas. (Esta es la munición del Escéptico.)
# =============================================================================

# --- 0. Preparación -----------------------------------------------------------
library(data.table)   # manejo de datos
library(ggplot2)      # gráficas
library(scales)       # formato de ejes ($ y %)

# Cargamos el subset de enseñanza (ya viene listo; ~1.47 M personas, 2 años).
# Usamos .rds: carga al instante y sin dependencias extra.
# (En datos/ también está el .csv.gz por si quieres inspeccionarlo como texto.)
geih <- as.data.table(readRDS("datos/geih_pobreza_2019_2021.rds"))
geih[, anio := factor(anio)]

# --- 1. Una mirada a los datos ------------------------------------------------
dim(geih)            # filas (personas) x columnas
head(geih)           # primeras filas
str(geih)            # tipo de cada variable
# fex = factor de expansión: cada fila "representa" a fex personas del país.
# SIEMPRE ponderamos por fex para obtener cifras nacionales.

# ¿A cuántos colombianos representa cada año?
geih[, .(personas_millones = round(sum(fex)/1e6, 1)), by = anio]

# =============================================================================
# 2. INGRESO POR QUINTIL  (lección de Sala-i-Martin: mirar la distribución)
# =============================================================================
# Quintil ponderado: ordenamos a las personas por ingreso y las partimos en
# 5 grupos de igual tamaño POBLACIONAL (20% cada uno).
quintil_ponderado <- function(x, w) {
  o  <- order(x)
  cw <- cumsum(w[o]) / sum(w)                 # proporción de población acumulada
  q  <- cut(cw, breaks = c(-Inf, .2, .4, .6, .8, Inf), labels = paste0("Q", 1:5))
  out <- character(length(x)); out[o] <- as.character(q)
  factor(out, levels = paste0("Q", 1:5))
}

# Asignamos quintil DENTRO de cada año.
geih[, quintil := quintil_ponderado(ingpcug, fex), by = anio]

# OJO: el ingreso está en pesos CORRIENTES de cada año (sin descontar inflación),
# así que la comparación de niveles 2019 vs 2021 mezcla algo de inflación.
# La razón Q5/Q1 y las participaciones (abajo) sí son comparables: son cocientes.
# Ingreso promedio y participación en el ingreso total, por quintil y año.
quintiles <- geih[, .(
  ingreso_medio = weighted.mean(ingpcug, fex),
  ingreso_total = sum(ingpcug * fex)
), by = .(anio, quintil)]
quintiles[, participacion := ingreso_total / sum(ingreso_total), by = anio]
print(quintiles[order(anio, quintil)])

# Gráfica 2a — ingreso promedio por quintil (¿subió o bajó en cada grupo?)
g2a <- ggplot(quintiles, aes(quintil, ingreso_medio, fill = anio)) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = label_dollar(prefix = "$", big.mark = ".", decimal.mark = ",")) +
  labs(title = "Ingreso per cápita promedio por quintil",
       subtitle = "Colombia, 2019 vs 2021 (pesos corrientes)",
       x = "Quintil de ingreso (Q1 = más pobre)", y = "Ingreso mensual",
       fill = "Año", caption = "Fuente: DANE, GEIH (pobreza monetaria).") +
  theme_minimal(base_size = 13)
print(g2a)

# Gráfica 2b — participación en el ingreso total (¿quién se lleva la torta?)
g2b <- ggplot(quintiles, aes(quintil, participacion, fill = anio)) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = label_percent()) +
  labs(title = "Participación en el ingreso total por quintil",
       subtitle = "El Q5 concentra la mayor parte del ingreso",
       x = "Quintil de ingreso", y = "% del ingreso nacional",
       fill = "Año", caption = "Fuente: DANE, GEIH (pobreza monetaria).") +
  theme_minimal(base_size = 13)
print(g2b)

# Razón Q5/Q1: una medida simple de desigualdad. ¿Se amplió la brecha?
razon <- dcast(quintiles, anio ~ quintil, value.var = "ingreso_medio")
razon[, brecha_Q5_Q1 := round(Q5 / Q1, 1)]
print(razon[, .(anio, brecha_Q5_Q1)])

# =============================================================================
# 3. POBREZA 2019 vs 2021  (el titular del ejercicio)
# =============================================================================
# Pobre = persona cuyo ingreso per cápita del hogar cae bajo la línea oficial.
pobreza <- geih[, .(
  pobreza_pct        = round(weighted.mean(pobre, fex) * 100, 1),
  pobreza_extrema_pct = round(weighted.mean(indigente, fex) * 100, 1)
), by = anio][order(anio)]
print(pobreza)   # esperado: 35.7% (2019) -> 39.3% (2021); extrema 9.6% -> 12.2%

# Gráfica 3 — tasa de pobreza antes/después
pob_long <- melt(pobreza, id.vars = "anio",
                 variable.name = "indicador", value.name = "pct")
pob_long[, indicador := factor(indicador,
         labels = c("Pobreza monetaria", "Pobreza extrema"))]
g3 <- ggplot(pob_long, aes(anio, pct, fill = anio)) +
  geom_col(width = .6) +
  geom_text(aes(label = paste0(pct, "%")), vjust = -0.3, size = 4) +
  facet_wrap(~ indicador, scales = "free_y") +
  labs(title = "La pobreza subió con la pandemia",
       subtitle = "Colombia, % de personas, línea oficial DANE",
       x = NULL, y = "% de la población", fill = "Año",
       caption = "Fuente: DANE, GEIH (pobreza monetaria).") +
  theme_minimal(base_size = 13) + theme(legend.position = "none")
print(g3)

# =============================================================================
# 4. ¿QUIÉN ES POBRE?  Perfil del pobre  (lección del Banco Mundial, Figura O.5)
# =============================================================================
# Composición de la población pobre por característica, ponderada por fex.
# Mostramos: de cada 100 pobres, ¿cuántos son de cada grupo?

# Grupos de edad estilo Banco Mundial.
geih[, grupo_edad := cut(edad,
     breaks = c(-Inf, 14, 24, 34, 44, 54, 64, Inf),
     labels = c("0-14","15-24","25-34","35-44","45-54","55-64","65+"))]

# Helper: composición (%) de los POBRES según una variable de grupo.
perfil_pobres <- function(dat, var) {
  d <- dat[pobre == 1 & !is.na(get(var))]
  d <- d[, .(p = sum(fex)), by = c("anio", var)]
  d[, pct := p / sum(p) * 100, by = anio]
  setnames(d, var, "categoria")
  d[, dimension := var][]
}

perf_edad <- perfil_pobres(geih, "grupo_edad")
perf_sexo <- perfil_pobres(geih, "sexo")
perf_educ <- perfil_pobres(geih[edad >= 15], "educ")  # educación: adultos 15+

print(perf_edad[order(anio, categoria)])
print(perf_sexo[order(anio, categoria)])
print(perf_educ[order(anio, categoria)])

# Gráfica 4a — perfil del pobre por edad
g4a <- ggplot(perf_edad, aes(categoria, pct, fill = anio)) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(title = "El pobre es joven", subtitle = "Composición de los pobres por edad",
       x = "Grupo de edad", y = "% de los pobres", fill = "Año",
       caption = "Fuente: DANE, GEIH (pobreza monetaria).") +
  theme_minimal(base_size = 13)
print(g4a)

# Gráfica 4b — perfil del pobre por nivel educativo (15+)
g4b <- ggplot(perf_educ, aes(categoria, pct, fill = anio)) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(title = "El pobre tiene baja escolaridad",
       subtitle = "Composición de los pobres por nivel educativo (15+ años)",
       x = "Máximo nivel educativo", y = "% de los pobres", fill = "Año",
       caption = "Fuente: DANE, GEIH (pobreza monetaria).") +
  theme_minimal(base_size = 13)
print(g4b)

# Complemento útil: TASA de pobreza por grupo (¿qué grupo tiene más riesgo?)
tasa_por_educ <- geih[edad >= 15 & !is.na(educ),
  .(tasa_pobreza = round(weighted.mean(pobre, fex) * 100, 1)),
  by = .(anio, educ)][order(educ, anio)]
print(tasa_por_educ)

# =============================================================================
# 5. Guardar las gráficas (opcional) ------------------------------------------
# =============================================================================
dir.create("figuras", showWarnings = FALSE)
ggsave("figuras/2a-ingreso-por-quintil.png",  g2a, width = 8, height = 5, dpi = 150)
ggsave("figuras/3-pobreza-antes-despues.png", g3,  width = 8, height = 5, dpi = 150)
ggsave("figuras/4a-perfil-pobre-edad.png",    g4a, width = 8, height = 5, dpi = 150)
ggsave("figuras/4b-perfil-pobre-educacion.png", g4b, width = 8, height = 5, dpi = 150)

# =============================================================================
# 6. Síntesis (para discutir en clase)
# =============================================================================
# - La pobreza monetaria subió de 35.7% a 39.3% entre 2019 y 2021.
# - El golpe no fue parejo: mirar qué quintil perdió más y cómo cambió la brecha Q5/Q1.
# - El rostro del pobre sigue siendo joven y de baja escolaridad (como en el Banco Mundial).
#
# PREGUNTA DEL ESCÉPTICO: ¿podemos atribuir ESTO a la pandemia?
#   No directamente: es una foto antes/después sin contrafactual. Para acercarnos
#   a un efecto causal necesitaríamos un grupo de comparación o una fuente de
#   variación exógena. Aquí solo describimos. (Esa es la frontera de la Unidad 1.)
