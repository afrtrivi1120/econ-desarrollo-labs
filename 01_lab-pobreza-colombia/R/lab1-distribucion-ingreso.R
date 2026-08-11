# =============================================================================
# LAB 1 — La distribución del ingreso en Colombia: foto antes/después de la pandemia
# Economía del Desarrollo (06230) · Universidad ICESI
#
# Datos: GEIH — Medición de Pobreza Monetaria y Desigualdad, DANE (2019 y 2021).
# Idea: replicar, con datos de Colombia, las dos lecturas de la sesión —
#   (1) Sala-i-Martin (2006): mirar la DISTRIBUCIÓN del ingreso, no solo el promedio.
#   (2) Banco Mundial (2020): ver QUIÉN es pobre (edad, género, educación).
#
# El lab arranca en la MICRODATA CRUDA del DANE y llega hasta las gráficas, para
# que se vea de dónde sale cada variable y qué se le hizo.
#
# OJO: esto es DESCRIPTIVO (una foto 2019 vs 2021), no causal. No hay
# contrafactual: entre 2019 y 2021 cambió la pandemia, pero también muchas
# otras cosas.
# =============================================================================

# =============================================================================
# 0. PREPARACIÓN
# =============================================================================
# pacman es un gestor de paquetes para R. Su función p_load() revisa qué está
# instalado, instala lo que falte y lo carga, todo en una sola llamada: así el
# lab arranca igual en cualquier computador.
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, scales, data.table, R.utils)
# data.table es un paquete para tablas grandes: lo mismo que un data.frame pero
# más rápido y con menos memoria. Lo usamos solo por fread(), que lee los
# archivos del DANE mucho más rápido que read.csv() y deja fijar a mano el
# separador y el decimal —que no son los mismos en 2019 que en 2021—. R.utils es
# lo que le permite abrir los .csv.gz sin descomprimirlos antes.
# Después pasamos a tibble y seguimos con dplyr.

# =============================================================================
# 1. UNA TRANSFORMACIÓN DEL MICRODATO
# =============================================================================
# El DANE reparte la medición de pobreza en DOS archivos por año:
#   - HOGARES  -> el ingreso, las líneas de pobreza y los indicadores.
#   - PERSONAS -> la demografía: edad, sexo, educación.
# Se unen por directorio + secuencia_p (la llave de vivienda y la de hogar).
# Por eso son cuatro archivos y no dos.

rutas_crudos <- c(
  hogares_2019  = "datos/_crudos/geih-2019-hogares.csv.gz",
  personas_2019 = "datos/_crudos/geih-2019-personas.csv.gz",
  hogares_2021  = "datos/_crudos/geih-2021-hogares.csv.gz",
  personas_2021 = "datos/_crudos/geih-2021-personas.csv.gz"
)

hay_crudos <- all(file.exists(rutas_crudos))

if (hay_crudos) {

  # --- 1.1 Leer el año 2019 --------------------------------------------------
  # OJO: 2019 viene en formato europeo, con separador ";" y decimal ",".
  hogares_2019 <- fread(
    rutas_crudos[["hogares_2019"]], sep = ";", dec = ",", encoding = "UTF-8",
    select = c("directorio", "secuencia_p", "ingpcug", "lp", "pobre", "indigente")
  ) |>
    as_tibble() |>
    rename_with(tolower)   # los encabezados del DANE no siempre vienen igual

  personas_2019 <- fread(
    rutas_crudos[["personas_2019"]], sep = ";", dec = ",", encoding = "UTF-8",
    select = c("directorio", "secuencia_p", "clase", "p6020", "p6040", "p6210", "fex_c")
  ) |>
    as_tibble() |>
    rename_with(tolower)

  # --- 1.2 Leer el año 2021 --------------------------------------------------
  # 2021 viene con separador "," y decimal ".". Por eso los dos años se leen en
  # bloques separados: no es el mismo formato.
  hogares_2021 <- fread(
    rutas_crudos[["hogares_2021"]], sep = ",", dec = ".", encoding = "UTF-8",
    select = c("directorio", "secuencia_p", "ingpcug", "lp", "pobre", "indigente")
  ) |>
    as_tibble() |>
    rename_with(tolower)

  personas_2021 <- fread(
    rutas_crudos[["personas_2021"]], sep = ",", dec = ".", encoding = "UTF-8",
    select = c("directorio", "secuencia_p", "clase", "p6020", "p6040", "p6210", "fex_c")
  ) |>
    as_tibble() |>
    rename_with(tolower)

  # --- 1.3 Mirar el dato crudo ANTES de tocarlo ------------------------------
  # Acá se ve el problema: los nombres no dicen nada (p6020, p6210, fex_c) y las
  # respuestas son códigos numéricos. Sin el diccionario del DANE no se entiende.
  glimpse(personas_2019)
  glimpse(hogares_2019)

  # ¿Qué códigos trae la educación? Siete categorías (1 a 6, más el 9 = no informa)
  # y una fila que el diccionario no anuncia: NA, con 30.467 personas.
  personas_2019 |> count(p6210)

  # ¿Quiénes son esos NA? Niños de 0, 1 y 2 años: al DANE no le pregunta el nivel
  # educativo a menores de tres. No es dato faltante, es diseño del cuestionario.
  personas_2019 |> filter(is.na(p6210)) |> count(p6040)

  # --- 1.4 Unir personas con su hogar ---------------------------------------
  # left_join DESDE personas: queremos una fila por persona, y a cada una le
  # pegamos el ingreso y la pobreza del hogar al que pertenece.
  geih_2019 <- personas_2019 |>
    left_join(hogares_2019, by = c("directorio", "secuencia_p")) |>
    mutate(anio = 2019)

  geih_2021 <- personas_2021 |>
    left_join(hogares_2021, by = c("directorio", "secuencia_p")) |>
    mutate(anio = 2021)

  # --- 1.5 Apilar los dos años ----------------------------------------------
  geih_crudo <- bind_rows(geih_2019, geih_2021)

  # --- 1.6 Recodificar: de códigos del DANE a etiquetas legibles -------------
  # Tres variables se recodifican. Las demás se dejan tal cual.
  geih_crudo <- geih_crudo |>
    mutate(
      # Sexo: 1 = Hombre, 2 = Mujer.
      sexo = factor(p6020, levels = c(1, 2), labels = c("Hombre", "Mujer")),

      # Clase: 1 = Cabecera (urbano), 2 = Resto (centros poblados y rural disperso).
      area = factor(clase, levels = c(1, 2), labels = c("Urbano", "Rural")),

      # Educación: las SIETE categorías del DANE se colapsan a cuatro.
      #   1 Ninguno · 2 Preescolar · 3 Básica primaria · 4 Básica secundaria
      #   5 Media · 6 Superior o universitaria · 9 No sabe / no informa
      educ = case_when(
        p6210 %in% c(1, 2) ~ "Sin educación",
        p6210 == 3         ~ "Primaria",
        p6210 %in% c(4, 5) ~ "Secundaria",
        p6210 == 6         ~ "Superior",
        .default = NA_character_
      ),
      educ = factor(educ, levels = c("Sin educación", "Primaria", "Secundaria", "Superior"))
    )

  # --- 1.7 Quedarnos con lo que usamos y limpiar filas -----------------------
  # directorio y secuencia_p ya cumplieron su función (unir): se van.
  geih <- geih_crudo |>
    select(
      anio,
      fex = fex_c,        # factor de expansión anualizado
      ingpcug,            # ingreso per cápita de la unidad de gasto
      lp,                 # línea de pobreza
      pobre,              # 1 = persona en pobreza monetaria
      indigente,          # 1 = persona en pobreza extrema
      edad = p6040,
      sexo, educ, area
    ) |>
    filter(!is.na(ingpcug), !is.na(fex))   # sin ingreso o sin peso no sirve

  cat(sprintf("\nFilas antes del filtro: %d | después: %d | se fueron: %d\n",
              nrow(geih_crudo), nrow(geih), nrow(geih_crudo) - nrow(geih)))

  # --- 1.8 VERIFICACIÓN: ¿reproducimos las cifras oficiales del DANE? --------
  # Si esto no cuadra, algo se rompió en la limpieza. Es el control de calidad.
  geih |>
    group_by(anio) |>
    summarise(
      pobreza  = round(weighted.mean(pobre, fex) * 100, 1),
      extrema  = round(weighted.mean(indigente, fex) * 100, 1),
      personas_millones = round(sum(fex) / 1e6, 1)
    ) |>
    print()

  cat("Oficial DANE: pobreza 2019=35.7%, 2021=39.3% | extrema 2019=9.6%, 2021=12.2%\n")

  # El subset ya viene guardado en datos/. NO lo reescribimos en cada corrida:
  # es un archivo versionado y no queremos que la clase entera lo modifique.
  # Para regenerarlo a propósito, descomente esta línea:
  # write_rds(geih, "datos/geih_pobreza_2019_2021.rds")

} else {

  # Respaldo: sin los crudos no se puede mostrar la limpieza, pero el análisis sí
  # corre con el subset ya construido.
  message("OJO: no están los archivos de datos/_crudos/. Se salta la sección 1 ",
          "y se carga el subset ya construido. Ver datos/SOURCE.md para bajarlos.")
  geih <- read_rds("datos/geih_pobreza_2019_2021.rds") |> as_tibble()

}

# De acá en adelante el análisis es el mismo, vengan los datos de donde vengan.
geih <- geih |> mutate(anio = factor(anio))   # el año es etiqueta, no número

# =============================================================================
# 2. UNA MIRADA A LOS DATOS
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
# 3. INGRESO POR QUINTIL  (lección de Sala-i-Martin: mirar la distribución)
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
# 4. POBREZA 2019 vs 2021  (el titular del ejercicio)
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
# 5. ¿QUIÉN ES POBRE?  Perfil del pobre  (lección del Banco Mundial, Figura O.5)
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

# --- 5a. Perfil por edad ------------------------------------------------------
# count(wt = fex) suma los factores de expansión: cuenta personas del país,
# no filas de la encuesta.
perfil_edad <- pobres |>
  filter(!is.na(grupo_edad)) |>
  count(anio, grupo_edad, wt = fex, name = "personas") |>
  group_by(anio) |>
  mutate(pct = personas / sum(personas) * 100) |>
  ungroup()

print(perfil_edad)

# --- 5b. Perfil por sexo ------------------------------------------------------
# El mismo patrón de cuatro pasos, cambiando la variable de agrupación.
perfil_sexo <- pobres |>
  filter(!is.na(sexo)) |>
  count(anio, sexo, wt = fex, name = "personas") |>
  group_by(anio) |>
  mutate(pct = personas / sum(personas) * 100) |>
  ungroup()

print(perfil_sexo)

# --- 5c. Perfil por nivel educativo ------------------------------------------
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
# 6. GUARDAR LAS GRÁFICAS (opcional)
# =============================================================================
dir.create("figuras", showWarnings = FALSE)
ggsave("figuras/2a-ingreso-por-quintil.png",   g2a, width = 8, height = 5, dpi = 150)
ggsave("figuras/3-pobreza-antes-despues.png",  g3,  width = 8, height = 5, dpi = 150)
ggsave("figuras/4a-perfil-pobre-edad.png",     g4a, width = 8, height = 5, dpi = 150)
ggsave("figuras/4b-perfil-pobre-educacion.png", g4b, width = 8, height = 5, dpi = 150)

# =============================================================================
# 7. SÍNTESIS (para discutir en clase)
# =============================================================================
# - La pobreza monetaria subió de 35,7% a 39,3% entre 2019 y 2021.
# - El golpe no fue parejo: mirar qué quintil perdió más y cómo cambió la brecha Q5/Q1.
# - El rostro del pobre sigue siendo joven y de baja escolaridad (como en el Banco Mundial).
#
# PARA DISCUTIR: ¿podemos atribuir ESTO a la pandemia?
#   No directamente: es una foto antes/después sin contrafactual. Para acercarnos
#   a un efecto causal necesitaríamos un grupo de comparación o una fuente de
#   variación exógena. Acá solo describimos. (Esa es la frontera de la Unidad 1.)
#
# Y SOBRE LOS DATOS: la sección 1 mostró que "los datos" no llegan limpios. Alguien
#   decidió que Básica secundaria y Media son la misma categoría, y que el 9 del
#   DANE es NA. Esas decisiones cambian los resultados y hay que poder defenderlas.
