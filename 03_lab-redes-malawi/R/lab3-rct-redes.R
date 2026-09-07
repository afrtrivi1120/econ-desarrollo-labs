# =============================================================================
# LAB 3 — Redes sociales y adopción de tecnología en Malawi
# Economía del Desarrollo (06230) · Universidad ICESI
#
# Datos: paquete de réplica de Beaman, L., BenYishay, A., Magruder, J. y
#        Mobarak, A. M. (2021), "Can Network Theory-Based Targeting Increase
#        Technology Adoption?", American Economic Review 111(6), 1918-1943.
#        openICPSR-130605, licencia CC BY 4.0.
# Idea: replicar el EXPERIMENTO. En 200 aldeas de Malawi se capacitó a dos
#   agricultores para que difundieran la siembra en hoyos. Lo que se aleatorizó
#   no fue el programa, sino la REGLA PARA ELEGIR A ESOS DOS: el criterio del
#   extensionista (Benchmark), la cercanía geográfica (Geo), o dos algoritmos
#   de teoría de redes (contagio Simple y contagio Complejo).
#   La pregunta: ¿importa A QUIÉN se le cuenta primero?
#
# OJO: acá el supuesto de identificación viene con el DISEÑO. La aleatorización
# hace comparables a los cuatro grupos, así que no tenemos que defender una
# continuidad como en el Lab 2. Pero eso NO es gratis: quedan la atrición (el
# año 3 pierde un distrito entero, 200 -> 141 aldeas), los posibles derrames
# entre aldeas vecinas, y el hecho de que cuatro brazos son varias comparaciones
# a la vez. Un RCT resuelve el problema de la selección, no todos los problemas.
# =============================================================================

# =============================================================================
# 0. PREPARACIÓN
# =============================================================================
# pacman instala lo que falte y carga lo que ya esté: una sola línea para todo.
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, scales, fixest, broom)

# Dos subsets de enseñanza, ya listos (ver datos/codebook.md).
aldeas <- read_rds("datos/beaman_redes_aldeas.rds") |>
  as_tibble()

socios <- read_rds("datos/beaman_redes_socios.rds") |>
  as_tibble()

# Paleta de los cuatro brazos: el azul del control y el naranja del tratamiento
# titular son los mismos del Lab 2; los dos intermedios quedan en tonos suaves.
colores_brazo <- c("Benchmark" = "#2c7fb8", "Geo"    = "#a6bddb",
                   "Simple"    = "#fdae61", "Complejo" = "#d95f0e")

# =============================================================================
# 1. UNA MIRADA A LOS DATOS
# =============================================================================
dim(aldeas)      # filas (aldeas) x columnas
head(aldeas)     # primeras filas

# El tratamiento: cuál de las cuatro reglas de selección le tocó a cada aldea.
# Benchmark es la categoría OMITIDA: contra ella se leen los tres coeficientes.
aldeas |>
  count(brazo)

# La aleatorización se hizo POR SEPARADO dentro de cada distrito (estrato).
# Por eso el distrito entra después como efecto fijo: no es un control
# cosmético, es parte del diseño.
aldeas |>
  count(distrito, brazo) |>
  pivot_wider(names_from = brazo, values_from = n)

# El resultado principal: ¿arrancó la difusión? 1 = al menos un agricultor
# NO-semilla adoptó la siembra en hoyos. Ojo con la exclusión: los dos
# capacitados no cuentan; si contaran, todas las aldeas darían 1 por diseño.
summary(aldeas$adopcion_alguna_a2)

# El año 3 no cubre Nkhotakota: la muestra cae de 200 a 141 aldeas.
aldeas |>
  group_by(distrito) |>
  summarise(aldeas = n(), en_el_ano_3 = sum(en_a3))

# =============================================================================
# 2. CUATRO FORMAS DE ELEGIR A QUIÉN CAPACITAR  (Tabla 1 del paper)
# =============================================================================
# Antes de mirar resultados hay que preguntarse si el tratamiento MORDIÓ: ¿de
# verdad los algoritmos eligieron gente distinta?
#
# OJO CON LA UNIDAD. Acá `tipo` NO es el brazo que recibió la aldea: es el
# algoritmo que elegiría a ESE agricultor. Si su aldea recibió ese brazo lo
# capacitaron (SEMILLA); si no, quedó como contrafactual observable (SOMBRA).
# Por eso la comparación es limpia: se comparan los elegidos de cada algoritmo
# en TODAS las aldeas, no solo donde ese algoritmo se aplicó.
#
# Las dos medidas de qué tan conectado está alguien:
#   grado          = con cuánta gente habla.
#   centralidad_ev = qué tan conectada es la gente con la que habla
#                    (centralidad de vector propio).
#
# Y cada una tiene su PROPIO rango: el socio más central por vector propio no
# es siempre el de mayor grado, así que hay dos columnas de rango.
tabla_centralidad <- bind_rows(
  socios |>
    filter(rango_ev <= 2) |>
    summarise(valor = mean(centralidad_ev, na.rm = TRUE), n = n(),
              .by = c(tipo, rango_ev)) |>
    rename(rango = rango_ev) |>
    mutate(medida = "Centralidad de vector propio"),
  socios |>
    filter(rango_grado <= 2) |>
    summarise(valor = mean(grado, na.rm = TRUE), n = n(),
              .by = c(tipo, rango_grado)) |>
    rename(rango = rango_grado) |>
    mutate(medida = "Grado (número de contactos)")
)

# Reordenada para que se lea igual que la Tabla 1 del paper.
tabla_centralidad |>
  select(medida, tipo, rango, valor) |>
  pivot_wider(names_from = rango, values_from = valor, names_prefix = "socio_") |>
  arrange(medida, tipo)
# esperado (Tabla 1):
#   vector propio -> Complejo 0,28/0,19 | Simple 0,27/0,07 | Geo 0,15/0,10 | Benchmark 0,21/0,13
#   grado         -> Complejo 17,49/13,39 | Simple 16,59/6,70 | Geo 9,48/6,34 | Benchmark 13,29/9,80

# --- 2a. Una trampa de réplica que vale la pena mirar de frente ---------------
# El do-file original ordena con `egen rank(), track` de Stata, que a los
# empatados les da a TODOS el rango menor y salta el siguiente: 1, 1, 3. El
# equivalente en R es rank(..., ties.method = "min"), y así se construyó
# `rango_ev` en R/00-construir-datos.R.
#
# Con ties.method = "first" —el reflejo natural, porque parece dar igual— el
# grado del brazo complejo pasa de 17,49 a 18,08. No falla nada, no hay
# advertencia: simplemente la tabla deja de ser la del paper. Es la clase de
# detalle que decide si una réplica sirve o no.

# La diferencia entre los algoritmos NO está en el primer socio, está en el SEGUNDO.
g1 <- ggplot(tabla_centralidad, aes(factor(rango), valor, fill = tipo)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  facet_wrap(~ medida, scales = "free_y") +
  scale_fill_manual(values = colores_brazo) +
  scale_x_discrete(labels = c("1" = "Socio más central", "2" = "Segundo socio")) +
  labs(title = "La diferencia entre los algoritmos está en el SEGUNDO socio",
       subtitle = "Promedio de los dos socios que elegiría cada algoritmo, en las 200 aldeas",
       x = NULL, y = NULL, fill = NULL,
       caption = "Fuente: Beaman et al. (2021), datos de réplica; réplica de la Tabla 1.") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom")
print(g1)

# Lectura: el contagio SIMPLE supone que basta un contacto adoptante para
# convencerse, así que gasta su segundo socio en la periferia. El contagio
# COMPLEJO supone que hace falta ver a DOS vecinos adoptar, así que pone a los
# dos socios en el centro y con contactos en común. Geo, que usa distancia en
# vez de red, no acierta ni con el primero.

# =============================================================================
# 3. ¿FUNCIONÓ LA ALEATORIZACIÓN?  Pruebas de balance
# =============================================================================
# Acá está la diferencia con el Lab 2. Allá el supuesto de continuidad no se
# podía probar, solo atacar. Acá el supuesto lo garantiza el SORTEO. Pero un
# sorteo puede salir torcido por azar, así que igual se verifica: regresamos
# cada característica de LÍNEA BASE sobre los brazos y pedimos que no pase nada.
covariables_base <- c("compost_base", "fertilizante_base", "hoyos_base", "tam_aldea")

# Una función que hace el mismo ejercicio para cualquier variable: cambia lo que
# va a la IZQUIERDA del ~, igual que en el balance del Lab 2.
balancear <- function(variable) {
  m <- feols(as.formula(paste(variable, "~ complex + simple + geo | distrito")),
             data = aldeas, cluster = ~aldea, notes = FALSE)
  conjunta <- wald(m, "complex|simple|geo", print = FALSE)
  tidy(m) |>
    filter(term %in% c("complex", "simple", "geo")) |>
    transmute(variable, brazo = term, coef = estimate, ee = std.error,
              p = p.value, p_conjunta = conjunta$p)
}

balance <- map_dfr(covariables_base, balancear)
print(balance, n = 12)
# esperado: ningún salto sistemático; los p_conjunta cómodamente por encima
# de 0,10. Si alguno saliera bajo, no invalida el experimento —con 12 pruebas
# alguna sale "significativa" por azar—, pero hay que decirlo y controlarlo.

# OJO — lo que este balance NO alcanza a ver. El paper corre el mismo ejercicio
# a nivel de AGRICULTOR con 12 variables del censo de redes (su Tabla A5) y
# encuentra una diferencia incómoda: las fincas de las aldeas Benchmark son más
# grandes. Los autores reportan que controlar por eso no cambia nada. Nuestro
# subset es a nivel de aldea, así que ese chequeo hay que leerlo en el paper.

# Dividimos coef/ee para obtener el estadístico t: así variables medidas en
# unidades distintas quedan comparables en un mismo eje. Misma receta del Lab 2.
etiquetas_base <- c(compost_base      = "% usa compost",
                    fertilizante_base = "% usa fertilizante",
                    hoyos_base        = "% ya siembra en hoyos",
                    tam_aldea         = "Tamaño de la aldea")

g2 <- balance |>
  mutate(etiqueta = factor(etiquetas_base[variable], levels = etiquetas_base),
         brazo    = factor(str_to_title(brazo),
                           levels = c("Geo", "Simple", "Complex"),
                           labels = c("Geo", "Simple", "Complejo")),
         t = coef / ee) |>
  ggplot(aes(etiqueta, t, color = brazo)) +
  geom_hline(yintercept = c(-1.96, 1.96), linetype = "dashed", color = "grey60") +
  geom_hline(yintercept = 0, color = "grey30") +
  geom_point(size = 3, position = position_dodge(width = 0.5)) +
  scale_color_manual(values = colores_brazo) +
  coord_cartesian(ylim = c(-3, 3)) +
  labs(title = "Nada se desbalanceó en la línea base",
       subtitle = "Cada punto es la diferencia contra Benchmark, en unidades de error estándar",
       x = NULL, y = "t del coeficiente del brazo", color = NULL,
       caption = "Fuente: Beaman et al. (2021), datos de réplica.") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom")
print(g2)

# =============================================================================
# 4. LA DIFERENCIA DE MEDIAS  (el estimador más honesto de un RCT)
# =============================================================================
# Antes de cualquier regresión: en un experimento el efecto es una RESTA. Si la
# aleatorización funcionó, comparar promedios crudos ya es un estimador
# insesgado. Todo lo que viene después es ganar precisión, no arreglar sesgo.
medias_brazo <- aldeas |>
  group_by(brazo) |>
  summarise(aldeas   = n(),
            adopcion = mean(adopcion_alguna_a2),
            ee       = sd(adopcion_alguna_a2) / sqrt(n()),
            .groups  = "drop")

print(medias_brazo)
# esperado: Benchmark ~0,420 (el paper reporta media 0,420 y DE 0,499).
# Es decir: en 3 de cada 5 aldeas del grupo de comparación, DOS AÑOS después de
# la capacitación, no había adoptado NADIE fuera de los dos capacitados.

g3 <- ggplot(medias_brazo, aes(brazo, adopcion, fill = brazo)) +
  geom_col(width = 0.65) +
  geom_errorbar(aes(ymin = adopcion - 1.96 * ee, ymax = adopcion + 1.96 * ee),
                width = 0.15, color = "grey30") +
  geom_hline(yintercept = medias_brazo$adopcion[medias_brazo$brazo == "Benchmark"],
             linetype = "dashed", color = "grey40") +
  scale_fill_manual(values = colores_brazo, guide = "none") +
  scale_y_continuous(labels = label_percent()) +
  labs(title = "En la mayoría de las aldeas la difusión nunca arrancó",
       subtitle = "Aldeas con al menos un adoptante no-semilla en el año 2; la línea es el nivel Benchmark",
       x = NULL, y = "Aldeas donde alguien adoptó",
       caption = "Fuente: Beaman et al. (2021), datos de réplica.") +
  theme_minimal(base_size = 13)
print(g3)

# La resta cruda contra Benchmark, sin ningún control:
medias_brazo |>
  mutate(diferencia = adopcion - adopcion[brazo == "Benchmark"]) |>
  select(brazo, aldeas, adopcion, diferencia)

# =============================================================================
# 5. LA REGRESIÓN  (Tabla 2 del paper)
# =============================================================================
# La regresión hace lo mismo que la resta, con dos añadidos: absorbe los EFECTOS
# FIJOS DE DISTRITO (los estratos del sorteo) y ajusta por los controles que
# entraron en la rutina de re-aleatorización, más el tamaño de la aldea y su
# cuadrado. Los EE se agrupan por aldea.
#
# OJO CON EL CLÚSTER: acá hay UNA fila por aldea, así que agrupar por aldea es
# lo mismo que pedir errores robustos a heterocedasticidad. No hay nada que
# agrupar. El paper lo declara así y lo repetimos por fidelidad, pero conviene
# saber qué está haciendo de verdad la línea que uno escribe.
m_a2_alguna <- feols(
  adopcion_alguna_a2 ~ complex + simple + geo +
    compost_base + fertilizante_base + hoyos_base + tam_aldea + I(tam_aldea^2) | distrito,
  data = aldeas, cluster = ~aldea
)

# tidy() saca la tabla de coeficientes como un tibble; nos quedamos con los brazos.
tidy(m_a2_alguna) |>
  filter(term %in% c("complex", "simple", "geo"))
# esperado: complex 0,252 (0,093) | simple 0,155 (0,100) | geo 0,107 (0,096)

# El titular, en la unidad en que se lee: puntos porcentuales sobre una base de 42 %.
efecto_principal <- tidy(m_a2_alguna) |>
  filter(term == "complex") |>
  mutate(media_benchmark = mean(aldeas$adopcion_alguna_a2[aldeas$brazo == "Benchmark"]),
         efecto_pp       = estimate * 100,
         aldeas          = nobs(m_a2_alguna)) |>
  select(coeficiente = estimate, ee = std.error, p = p.value,
         media_benchmark, efecto_pp, aldeas)

print(efecto_principal)
# LECTURA: elegir a los dos capacitados con el algoritmo de contagio COMPLEJO
# sube en ~25 PUNTOS PORCENTUALES la probabilidad de que la difusión arranque,
# sobre una base de 42 %. Es más de la mitad del nivel del grupo de comparación,
# y no costó un peso más: es el mismo programa, con otra lista de invitados.

# --- 5a. Las otras tres columnas de la Tabla 2 --------------------------------
# Cambian dos cosas y nada más: el resultado (¿arrancó? vs. ¿qué tan rápido?)
# y el año (el 3 pierde Nkhotakota).
m_a3_alguna <- feols(
  adopcion_alguna_a3 ~ complex + simple + geo +
    compost_base + fertilizante_base + hoyos_base + tam_aldea + I(tam_aldea^2) | distrito,
  data = aldeas, cluster = ~aldea
)

m_a2_tasa <- feols(
  tasa_adopcion_a2 ~ complex + simple + geo +
    compost_base + fertilizante_base + hoyos_base + tam_aldea + I(tam_aldea^2) | distrito,
  data = aldeas, cluster = ~aldea
)

m_a3_tasa <- feols(
  tasa_adopcion_a3 ~ complex + simple + geo +
    compost_base + fertilizante_base + hoyos_base + tam_aldea + I(tam_aldea^2) | distrito,
  data = aldeas, cluster = ~aldea
)

# A cada tidy() le pegamos la etiqueta de qué columna es y apilamos con bind_rows().
tabla2 <- bind_rows(
  tidy(m_a2_alguna) |> mutate(columna = "(1) ¿Arrancó? — año 2", n = nobs(m_a2_alguna)),
  tidy(m_a3_alguna) |> mutate(columna = "(2) ¿Arrancó? — año 3", n = nobs(m_a3_alguna)),
  tidy(m_a2_tasa)   |> mutate(columna = "(3) Tasa — año 2",      n = nobs(m_a2_tasa)),
  tidy(m_a3_tasa)   |> mutate(columna = "(4) Tasa — año 3",      n = nobs(m_a3_tasa))
) |>
  filter(term %in% c("complex", "simple", "geo")) |>
  select(columna, brazo = term, coef = estimate, ee = std.error, p = p.value, n) |>
  mutate(coef = round(coef, 3), ee = round(ee, 3), p = round(p, 3))

print(tabla2, n = 12)
# esperado (Tabla 2): col 1 complex 0,252 (0,093), simple 0,155 (0,100), geo 0,107 (0,096), n=200
#                     col 2 complex 0,304 (0,101), simple 0,189 (0,111), geo 0,188 (0,110), n=141
#                     col 3 complex 0,036 (0,016), simple 0,036 (0,017), geo 0,038 (0,027), n=200
#                     col 4 complex 0,036 (0,026), simple 0,006 (0,022), geo 0,013 (0,034), n=141

# =============================================================================
# 6. ¿AGUANTA EL RESULTADO?
# =============================================================================
# --- 6a. Con controles y sin controles ---------------------------------------
# En un experimento los controles NO deberían mover el punto: si el sorteo
# funcionó, están incorrelacionados con el tratamiento y solo bajan el ruido.
# Que el coeficiente salte al agregarlos es señal de alarma, no de rigor.
m_pelado <- feols(adopcion_alguna_a2 ~ complex + simple + geo,
                  data = aldeas, vcov = "hetero")

m_solo_ef <- feols(adopcion_alguna_a2 ~ complex + simple + geo | distrito,
                   data = aldeas, cluster = ~aldea)

comparacion_controles <- bind_rows(
  tidy(m_pelado)     |> mutate(especificacion = "1. Solo los brazos"),
  tidy(m_solo_ef)    |> mutate(especificacion = "2. + efectos fijos de distrito"),
  tidy(m_a2_alguna)  |> mutate(especificacion = "3. + controles (Tabla 2)")
) |>
  filter(term == "complex") |>
  select(especificacion, coef = estimate, ee = std.error, p = p.value)

print(comparacion_controles)
# esperado: el coeficiente se mueve poco y el error estándar baja un poco.
# Eso es exactamente lo que uno quiere ver en un RCT.

# --- 6b. Inferencia por aleatorización ----------------------------------------
# El valor p de la regresión sale de una fórmula asintótica. En un experimento
# hay algo mejor: repetir el sorteo. Volvemos a repartir los brazos DENTRO de
# cada distrito (como se hizo de verdad), estimamos otra vez y guardamos el
# coeficiente. Eso construye la distribución del efecto SI EL TRATAMIENTO NO
# HICIERA NADA. Después miramos qué tan raro es el número que observamos.
set.seed(2026)

una_permutacion <- function() {
  permutada <- aldeas |>
    group_by(distrito) |>
    mutate(brazo_p = sample(brazo)) |>       # re-sorteo dentro del estrato
    ungroup() |>
    mutate(complex_p = as.integer(brazo_p == "Complejo"),
           simple_p  = as.integer(brazo_p == "Simple"),
           geo_p     = as.integer(brazo_p == "Geo"))

  coef(feols(
    adopcion_alguna_a2 ~ complex_p + simple_p + geo_p +
      compost_base + fertilizante_base + hoyos_base + tam_aldea + I(tam_aldea^2) | distrito,
    data = permutada, notes = FALSE
  ))[["complex_p"]]
}

nulos <- map_dbl(1:2000, \(i) una_permutacion())

coef_observado <- coef(m_a2_alguna)[["complex"]]
p_aleatorizacion <- mean(abs(nulos) >= abs(coef_observado))

cat(sprintf("\nCoeficiente observado: %.3f\n", coef_observado))
cat(sprintf("p de la regresión:            %.3f\n",
            tidy(m_a2_alguna) |> filter(term == "complex") |> pull(p.value)))
cat(sprintf("p por inferencia de aleatorización (2.000 sorteos): %.3f\n", p_aleatorizacion))
# esperado: los dos p muy parecidos. Cuando difieren, el de aleatorización es
# el que hay que creer: no le pide normalidad a nada.

g4 <- ggplot(tibble(nulos = nulos), aes(nulos)) +
  geom_histogram(bins = 40, fill = "#a6bddb", color = "white") +
  geom_vline(xintercept = coef_observado, color = "#d95f0e", linewidth = 1) +
  annotate("text", x = coef_observado, y = Inf, label = " efecto observado",
           hjust = 0, vjust = 1.8, size = 3.5, color = "#d95f0e") +
  labs(title = "El efecto observado no se parece a lo que produce el azar",
       subtitle = "2.000 re-sorteos de los brazos dentro de cada distrito",
       x = "Coeficiente del brazo Complejo bajo la hipótesis nula",
       y = "Número de sorteos",
       caption = "Fuente: Beaman et al. (2021), datos de réplica; cálculo propio.") +
  theme_minimal(base_size = 13)
print(g4)

# --- 6c. La atrición del año 3 ------------------------------------------------
# El año 3 no es una muestra más pequeña al azar: es 200 aldeas MENOS UN DISTRITO
# ENTERO. Nkhotakota desaparece completo.
aldeas |>
  group_by(distrito) |>
  summarise(aldeas = n(), en_el_ano_3 = sum(en_a3))

# El coeficiente del año 3 (0,304) NO es comparable con el del año 2 (0,252):
# no solo pasó un año, también cambió el país que estamos mirando. Para
# compararlos hay que correr el año 2 sobre las MISMAS aldeas del año 3.
m_a2_muestra_a3 <- feols(
  adopcion_alguna_a2 ~ complex + simple + geo +
    compost_base + fertilizante_base + hoyos_base + tam_aldea + I(tam_aldea^2) | distrito,
  data = filter(aldeas, en_a3 == 1), cluster = ~aldea
)

bind_rows(
  tidy(m_a2_alguna)     |> mutate(muestra = "Año 2, las 200 aldeas",       n = nobs(m_a2_alguna)),
  tidy(m_a2_muestra_a3) |> mutate(muestra = "Año 2, solo las del año 3",   n = nobs(m_a2_muestra_a3)),
  tidy(m_a3_alguna)     |> mutate(muestra = "Año 3, las mismas aldeas",    n = nobs(m_a3_alguna))
) |>
  filter(term == "complex") |>
  select(muestra, coef = estimate, ee = std.error, n)

# =============================================================================
# 7. SIMPLE CONTRA COMPLEJO  (lo que el titular no dice)
# =============================================================================
# El titular del paper es "Complejo > Benchmark". La pregunta interesante es
# otra: ¿le ganó el contagio complejo al simple? Para eso no sirve mirar si cada
# coeficiente es significativo por separado; hay que probar la DIFERENCIA.
#
# La varianza de una diferencia no es la suma de las varianzas: hay que restarle
# dos veces la covarianza. Por eso vamos a la matriz de varianzas del modelo.
prueba_igualdad <- function(modelo, a, b) {
  V  <- vcov(modelo)
  # Con errores agrupados, los grados de libertad son el número de clústeres
  # menos 1 (acá 199). Usar la t y no la normal cambia el tercer decimal —y es
  # justo lo que hace falta para que dé el número publicado.
  gl <- degrees_freedom(modelo, "t")
  diferencia <- coef(modelo)[[a]] - coef(modelo)[[b]]
  ee <- sqrt(V[a, a] + V[b, b] - 2 * V[a, b])
  tibble(comparacion = paste(a, "=", b),
         diferencia  = diferencia,
         ee          = ee,
         p           = 2 * pt(-abs(diferencia / ee), df = gl))
}

igualdades <- bind_rows(
  prueba_igualdad(m_a2_alguna, "simple",  "complex"),
  prueba_igualdad(m_a2_alguna, "complex", "geo"),
  prueba_igualdad(m_a2_alguna, "simple",  "geo")
)

print(igualdades)
# esperado (Tabla 2, col. 1): simple=complex p = 0,300 | complex=geo p = 0,102 |
# simple=geo p = 0,623. Iguales a los publicados hasta el tercer decimal.
#
# LEA ESTO CON CUIDADO: no se puede rechazar que los tres algoritmos den lo
# mismo. Lo que el experimento muestra con firmeza es que ALGUNA regla de
# selección le gana a dejar que el extensionista elija a dedo. Cuál de las tres
# es la mejor, estos datos no lo resuelven: 50 aldeas por brazo no alcanzan para
# distinguir 0,252 de 0,155.
#
# Que el paper se titule por el contagio complejo es una decisión de énfasis
# defendible —es el coeficiente más grande y el que la teoría predecía— pero el
# lector tiene que ver la prueba de igualdad para calibrar cuánto creerle.

# =============================================================================
# 8. GUARDAR LAS GRÁFICAS Y LOS NÚMEROS TITULARES
# =============================================================================
dir.create("figuras", showWarnings = FALSE)
ggsave("figuras/1-centralidad-por-brazo.png",    g1, width = 8, height = 5, dpi = 150)
ggsave("figuras/2-balance-aleatorizacion.png",   g2, width = 8, height = 5, dpi = 150)
ggsave("figuras/3-adopcion-por-brazo.png",       g3, width = 8, height = 5, dpi = 150)
ggsave("figuras/4-inferencia-aleatorizacion.png", g4, width = 8, height = 5, dpi = 150)

# results.json: los números que el deck de la sesión cita, resueltos desde
# la corrida real y no escritos a mano.
coefs_a2 <- tidy(m_a2_alguna)

writeLines(sprintf(
  paste0('{\n  "any_adoption_complex": %.4f,\n  "any_adoption_complex_se": %.4f,\n',
         '  "any_adoption_simple": %.4f,\n  "any_adoption_geo": %.4f,\n',
         '  "benchmark_mean": %.4f,\n  "p_simple_igual_complex": %.4f,\n',
         '  "p_aleatorizacion_complex": %.4f,\n  "n_aldeas": %d,\n  "n_distritos": %d\n}'),
  coefs_a2$estimate[coefs_a2$term == "complex"],
  coefs_a2$std.error[coefs_a2$term == "complex"],
  coefs_a2$estimate[coefs_a2$term == "simple"],
  coefs_a2$estimate[coefs_a2$term == "geo"],
  mean(aldeas$adopcion_alguna_a2[aldeas$brazo == "Benchmark"]),
  igualdades$p[igualdades$comparacion == "simple = complex"],
  p_aleatorizacion,
  nobs(m_a2_alguna),
  n_distinct(aldeas$distrito)), "results.json")

# =============================================================================
# 9. SÍNTESIS (para discutir en clase)
# =============================================================================
# - Elegir a los dos capacitados con el algoritmo de contagio COMPLEJO sube
#   ~25 puntos porcentuales la probabilidad de que la difusión arranque, sobre
#   una base de 42% en el grupo de comparación. Mismo programa, mismo
#   presupuesto, otra lista de invitados.
# - El resultado no depende de los controles y sobrevive a la inferencia por
#   aleatorización: el sorteo es el que está haciendo el trabajo.
# - Pero NO se puede rechazar que los tres algoritmos den lo mismo. La lección
#   robusta es "targetear con algún criterio de red le gana al criterio del
#   extensionista", no "el contagio complejo es el mejor algoritmo".
#
# PARA DISCUTIR: ¿por qué acá SÍ podemos hablar de causalidad sin pelear?
#   Porque el sorteo hace comparables a los grupos ANTES del tratamiento: no
#   hay que defender ningún supuesto sobre lo que no se observa. Eso es lo que
#   compra un RCT, y es mucho.
#
# Y OJO CON LO QUE EL SORTEO NO COMPRA:
#   - ATRICIÓN: el año 3 pierde un distrito completo. La muestra de 141 aldeas
#     ya no es la que se aleatorizó.
#   - DERRAMES: si un agricultor de una aldea Complejo le cuenta a un primo de
#     una aldea Benchmark, el "control" queda contaminado y el efecto medido se
#     queda corto.
#   - COMPARACIONES MÚLTIPLES: cuatro brazos, dos resultados y dos años son
#     muchas pruebas. Con suficientes celdas, algo sale significativo.
#   - VALIDEZ EXTERNA: es la siembra en hoyos, en tres distritos semiáridos de
#     Malawi, con una red social medida casa por casa. Nada garantiza que el
#     mismo algoritmo funcione con otra tecnología u otro país. Y medir la red
#     completa de una aldea es caro: la pregunta de política no es solo si
#     funciona, sino si compensa lo que cuesta.
