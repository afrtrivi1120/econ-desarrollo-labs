# Laboratorios de R — Economía del Desarrollo

**Economía del Desarrollo (06230) · Universidad Icesi · Departamento de Economía**

Este repositorio reúne **todos los laboratorios del semestre**. Cada lab es una
**réplica guiada** de uno de los papers que discutimos en clase: abrimos los datos
reales, corremos el código por bloques y discutimos qué se puede y qué **no** se puede
concluir con ellos.

El hilo que los une es la **inferencia causal aplicada**: cada lab agrega una
herramienta más al kit, y cada uno tiene un supuesto de identificación que el
**Escéptico** debe atacar.

---

## Los labs

| Lab | Sesión | Tema | Método | Paper / fuente |
|---|---|---|---|---|
| [**1**](01_lab-pobreza-colombia/) | 1 | Distribución del ingreso y pobreza en Colombia | Medición y descripción | Sala-i-Martin (2006) · Banco Mundial (2020) · datos GEIH–DANE |
| [**2**](02_lab-mita-peru/) | 2 | La *mita* minera del Perú y sus efectos persistentes | Regresión discontinua (RDD) geográfica | Dell (2010), *Econometrica* |
| 3 | 5–6 | Capital humano, tierra y trabajo | Panel con efectos fijos | *(en preparación)* |
| 4 | 7–8 | Titulación y seguridad de la tenencia | Diferencias en diferencias (DiD) | *(en preparación)* |
| 5 | 9–10 | Crédito, riesgo y seguros | Experimentos aleatorizados (RCT) | *(en preparación)* |
| 6 | 11–12 | Migración e informalidad | Estructural vs. forma reducida | *(en preparación)* |

---

## Cómo correr un lab

Necesita **R ≥ 4.1** y, opcionalmente, **Quarto** para los cuadernos. Los paquetes de
todo el semestre se instalan una sola vez:

```r
install.packages(c("data.table", "ggplot2", "scales", "fixest", "rdrobust"))
```

> ⚠️ **Abra la carpeta del lab como directorio de trabajo**, no la raíz del repositorio.
> Los scripts cargan los datos con rutas relativas (`datos/…`), así que si corre el
> Lab 2 parado en la raíz no va a encontrar los archivos. En **Positron / RStudio**:
> `File → Open Folder…` sobre `02_lab-mita-peru`, o bien `setwd("02_lab-mita-peru")`.

Cada lab se puede trabajar de dos formas equivalentes:

**a) Script de R** — para ejecutar por bloques en clase. Los separadores `# ===`
marcan cada sección:

```r
source("R/lab2-rdd-mita.R")
```

**b) Cuaderno Quarto** — el mismo contenido con prosa, tablas y gráficas:

```bash
quarto render lab2-rdd-mita.qmd
```

El `.html` ya viene renderizado en cada carpeta, así que puede leer el lab completo
sin correr nada.

---

## Roles de la sesión

En cada sesión rotan tres roles, y el lab es el momento en que los tres se encuentran:

- **Replicador** — lidera el lab y reporta un hallazgo concreto de la corrida.
- **Escéptico** — ataca el supuesto de identificación: ¿por qué *deberíamos* creer que
  esto es causal? ¿Qué lo rompería?
- **Comentarista** — conecta lo que salió en pantalla con el paper y con las lecturas
  de la sesión.

---

## Los datos

Cada lab trae un **subconjunto de enseñanza** ya limpio en su carpeta `datos/`, junto
con dos documentos:

- `datos/codebook.md` — qué significa cada columna.
- `datos/SOURCE.md` — de dónde salieron los datos, con qué licencia y cómo se
  reconstruye el subset desde la fuente original.

La microdata cruda **no** se versiona (vive en `datos/_crudos/`, ignorada por git):
pesa demasiado y en varios casos su licencia no permite redistribuirla. El script
`R/00-construir-datos.R` de cada lab documenta la transformación completa.

---

*Material del curso Economía del Desarrollo (06230), Universidad Icesi.
Cada lab cita su propia fuente de datos en `datos/SOURCE.md`.*
