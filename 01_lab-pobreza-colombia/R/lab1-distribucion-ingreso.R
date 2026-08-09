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
# otras cosas.
# =============================================================================

# =============================================================================
# 0. PREPARACIÓN
# =============================================================================
# pacman instala lo que falte y carga lo que ya esté: una sola línea para todo.
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, scales)

# Cargamos el subset de enseñanza (ya viene listo; ~1,47 M personas, 2 años).
# Usamos .rds: carga al instante y sin dependencias extra.
# (En datos/ también está el .csv.gz por si quiere inspeccionarlo como texto.)
geih <- read_rds("datos/geih_pobreza_2019_2021.rds") |>
  as_tibble() |>
  mutate(anio = factor(anio))   # el año es una etiqueta, no un número con el que operar

# =============================================================================
# 1. UNA MIRADA A LOS DATOS
# =============================================================================
dim(geih)        # filas (personas) x columnas
head(geih)       # primeras filas
glimpse(geih)    # tipo de cada variable

# fex = factor de expansión: cada fila "representa" a fex personas del país.
# SIEMPRE ponderamos por fex para obtener cifras nacionales.

# ¿A cuántos colombianos representa cada año?
geih |>
  group_by(anio) |>
  summarise(personas_millones = round(sum(fex) / 1e6, 1))

# =============================================================================
# 2. INGRESO POR QUINTIL  (lección de Sala-i-Martin: mirar la distribución)
# =============================================================================
# Un quintil ponderado parte a la población en 5 grupos de igual tamaño (20 %
# cada uno). Lo armamos en tres pasos que se pueden leer de corrido:
#   1. ordenamos a las personas de la más pobre a la más rica,
#   2. acumulamos su peso poblacional,
#   3. cortamos ese acumulado en 20 %, 40 %, 60 % y 80 %.
geih <- geih |>
  group_by(anio) |>                       # los quintiles se arman DENTRO de cada año
  arrange(ingpcug, .by_group = TRUE) |>
  mutate(
    poblacion_acumulada = cumsum(fex) / sum(fex),
    quintil = cut(
      poblacion_acumulada,
      breaks = c(-Inf, 0.2, 0.4, 0.6, 0.8, Inf),
      labels = c("Q1", "Q2", "Q3", "Q4", "Q5")
    )
  ) |>
  ungroup()

# Revisión rápida: los cinco grupos deben pesar ~20 % de la población cada uno.
geih |>
  group_by(anio, quintil) |>
  summarise(personas = sum(fex), .groups = "drop") |>
  group_by(anio) |>
  mutate(peso_pct = round(personas / sum(personas) * 100, 1)) |>
  ungroup()

# OJO: el ingreso está en pesos CORRIENTES de cada año (sin descontar inflación),
# así que la comparación de niveles 2019 vs 2021 mezcla algo de inflación.
# La razón Q5/Q1 y las participaciones (abajo) sí son comparables: son cocientes.

# Ingreso promedio y participación en el ingreso total, por quintil y año.
quintiles <- geih |>
  group_by(anio, quintil) |>
  summarise(
    ingreso_medio = weighted.mean(ingpcug, fex),
    ingreso_total = sum(ingpcug * fex),
    .groups = "drop"
  ) |>
  group_by(anio) |>
  mutate(participacion = ingreso_total / sum(ingreso_total)) |>
  ungroup()

print(quintiles)

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
# Pasamos los quintiles de filas a columnas para poder dividir Q5 entre Q1.
brecha <- quintiles |>
  select(anio, quintil, ingreso_medio) |>
  pivot_wider(names_from = quintil, values_from = ingreso_medio) |>
  mutate(brecha_Q5_Q1 = round(Q5 / Q1, 1)) |>
  select(anio, brecha_Q5_Q1)

print(brecha)

# =============================================================================
# 3. POBREZA 2019 vs 2021  (el titular del ejercicio)
# =============================================================================
# Pobre = persona cuyo ingreso per cápita del hogar cae bajo la línea oficial.
# Como pobre e indigente son 0/1, su promedio ponderado ES la tasa de pobreza.
pobreza <- geih |>
  group_by(anio) |>
  summarise(
    pobreza_pct         = round(weighted.mean(pobre, fex) * 100, 1),
    pobreza_extrema_pct = round(weighted.mean(indigente, fex) * 100, 1)
  )

print(pobreza)   # esperado: 35,7% (2019) -> 39,3% (2021); extrema 9,6% -> 12,2%

# Para graficar los dos indicadores juntos los pasamos a formato largo:
# una fila por año y por indicador.
pobreza_larga <- pobreza |>
  pivot_longer(
    cols = c(pobreza_pct, pobreza_extrema_pct),
    names_to = "indicador",
    values_to = "pct"
  ) |>
  mutate(indicador = factor(
    indicador,
    levels = c("pobreza_pct", "pobreza_extrema_pct"),
    labels = c("Pobreza monetaria", "Pobreza extrema")
  ))

# Gráfica 3 — tasa de pobreza antes/después
g3 <- ggplot(pobreza_larga, aes(anio, pct, fill = anio)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = paste0(pct, "%")), vjust = -0.3, size = 4) +
  facet_wrap(~ indicador, scales = "free_y") +
  labs(title = "La pobreza subió con la pandemia",
       subtitle = "Colombia, % de personas, línea oficial DANE",
       x = NULL, y = "% de la población", fill = "Año",
       caption = "Fuente: DANE, GEIH (pobreza monetaria).") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none")
print(g3)

# =============================================================================
# 4. ¿QUIÉN ES POBRE?  Perfil del pobre  (lección del Banco Mundial, Figura O.5)
# =============================================================================
# Mostramos la COMPOSICIÓN de la población pobre: de cada 100 pobres, ¿cuántos
# hay en cada grupo? Es distinto de la TASA de pobreza (eso lo vemos al final).

# Grupos de edad estilo Banco Mundial.
geih <- geih |>
  mutate(grupo_edad = cut(
    edad,
    breaks = c(-Inf, 14, 24, 34, 44, 54, 64, Inf),
    labels = c("0-14", "15-24", "25-34", "35-44", "45-54", "55-64", "65+")
  ))

# Nos quedamos solo con las personas pobres: el resto del bloque es sobre ellas.
pobres <- geih |> filter(pobre == 1)

# --- 4a. Perfil por edad ------------------------------------------------------
# count(wt = fex) suma los factores de expansión: cuenta personas del país,
# no filas de la encuesta.
perfil_edad <- pobres |>
  filter(!is.na(grupo_edad)) |>
  count(anio, grupo_edad, wt = fex, name = "personas") |>
  group_by(anio) |>
  mutate(pct = personas / sum(personas) * 100) |>
  ungroup()

print(perfil_edad)

# --- 4b. Perfil por sexo ------------------------------------------------------
# El mismo patrón de cuatro pasos, cambiando la variable de agrupación.
perfil_sexo <- pobres |>
  filter(!is.na(sexo)) |>
  count(anio, sexo, wt = fex, name = "personas") |>
  group_by(anio) |>
  mutate(pct = personas / sum(personas) * 100) |>
  ungroup()

print(perfil_sexo)

# --- 4c. Perfil por nivel educativo ------------------------------------------
# Acá filtramos a 15+ años: la educación de un niño de 6 años no dice nada.
perfil_educ <- pobres |>
  filter(edad >= 15, !is.na(educ)) |>
  count(anio, educ, wt = fex, name = "personas") |>
  group_by(anio) |>
  mutate(pct = personas / sum(personas) * 100) |>
  ungroup()

print(perfil_educ)

# Gráfica 4a — perfil del pobre por edad
g4a <- ggplot(perfil_edad, aes(grupo_edad, pct, fill = anio)) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(title = "El pobre es joven",
       subtitle = "Composición de los pobres por edad",
       x = "Grupo de edad", y = "% de los pobres", fill = "Año",
       caption = "Fuente: DANE, GEIH (pobreza monetaria).") +
  theme_minimal(base_size = 13)
print(g4a)

# Gráfica 4b — perfil del pobre por nivel educativo (15+)
g4b <- ggplot(perfil_educ, aes(educ, pct, fill = anio)) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(title = "El pobre tiene baja escolaridad",
       subtitle = "Composición de los pobres por nivel educativo (15+ años)",
       x = "Máximo nivel educativo", y = "% de los pobres", fill = "Año",
       caption = "Fuente: DANE, GEIH (pobreza monetaria).") +
  theme_minimal(base_size = 13)
print(g4b)

# Complemento útil: la TASA de pobreza por nivel educativo. La composición dice
# cuántos pobres hay en cada grupo; la tasa dice qué grupo tiene más riesgo.
tasa_por_educ <- geih |>
  filter(edad >= 15, !is.na(educ)) |>
  group_by(anio, educ) |>
  summarise(tasa_pobreza = round(weighted.mean(pobre, fex) * 100, 1),
            .groups = "drop") |>
  arrange(educ, anio)

print(tasa_por_educ)

# =============================================================================
# 5. GUARDAR LAS GRÁFICAS (opcional)
# =============================================================================
dir.create("figuras", showWarnings = FALSE)
ggsave("figuras/2a-ingreso-por-quintil.png",   g2a, width = 8, height = 5, dpi = 150)
ggsave("figuras/3-pobreza-antes-despues.png",  g3,  width = 8, height = 5, dpi = 150)
ggsave("figuras/4a-perfil-pobre-edad.png",     g4a, width = 8, height = 5, dpi = 150)
ggsave("figuras/4b-perfil-pobre-educacion.png", g4b, width = 8, height = 5, dpi = 150)

# =============================================================================
# 6. SÍNTESIS (para discutir en clase)
# =============================================================================
# - La pobreza monetaria subió de 35,7% a 39,3% entre 2019 y 2021.
# - El golpe no fue parejo: mirar qué quintil perdió más y cómo cambió la brecha Q5/Q1.
# - El rostro del pobre sigue siendo joven y de baja escolaridad (como en el Banco Mundial).
#
# PARA DISCUTIR: ¿podemos atribuir ESTO a la pandemia?
#   No directamente: es una foto antes/después sin contrafactual. Para acercarnos
#   a un efecto causal necesitaríamos un grupo de comparación o una fuente de
#   variación exógena. Acá solo describimos. (Esa es la frontera de la Unidad 1.)
