# Proyecto final — La IA y la economía: replicar y extender

**Economía del Desarrollo (06230) · Universidad ICESI · Departamento de Economía**

En el proyecto final usted escoge **un paper**, **replica** en R uno de sus resultados
centrales, lo **expone** en clase y **propone un análisis adicional** que el paper no
hace. Este semestre los seis papers tratan una misma pregunta: **¿qué le está haciendo la
inteligencia artificial (IA) generativa al trabajo, a la educación y al desarrollo?**

Todos los papers de esta carpeta cumplen cuatro condiciones:

1. Son de **2023 en adelante**.
2. Estudian el efecto de la IA sobre el trabajo, la educación o el desarrollo.
3. Tienen **datos y código públicos** para replicar, sin firmar acuerdos de uso.
4. Tienen un **diseño causal**: experimento aleatorizado o diferencias en diferencias.

---

## Los papers

| # | Paper | Tema | Método | Dónde | Dificultad de la réplica |
|---|---|---|---|---|---|
| [**01**](01_noy-zhang-2023/) | Noy y Zhang (2023), *Science* | ChatGPT y la productividad en tareas de escritura | Experimento aleatorizado (RCT) | EE. UU., en línea | Media-alta |
| [**02**](02_delriochanona-2024/) | del Rio-Chanona, Laurentsyeva y Wachs (2024), *PNAS Nexus* | ChatGPT y la caída de Stack Overflow | Diferencias en diferencias | Global | Baja-media (el paquete pesa ~2,9 GB) |
| [**03**](03_bastani-2025/) | Bastani et al. (2025), *PNAS* | IA sin salvaguardas en clase de matemáticas | Experimento aleatorizado por salón | Turquía | Baja |
| [**04**](04_nejad-2026/) | Abbas Nejad, Musillo, Zaccaria y Wicker (2026), *Journal of Labor Economics* | ChatGPT y las cartas de presentación como señal en el mercado laboral | Dos experimentos aleatorizados de campo | Países Bajos | Baja-media |
| [**05**](05_ravanilla-2026/) | Ravanilla (2026), documento de trabajo en SSRN (Social Science Research Network) | IA generativa y empleo en el sector de servicios tercerizados (BPO) | Diferencias en diferencias con exposición y estudio de evento | Filipinas | Media-baja |
| [**06**](06_brodeur-2026/) | Brodeur et al. (2026), *PNAS* | Equipos humanos, asistidos por IA o dirigidos por IA reproduciendo estudios | Experimento aleatorizado | Varios países, incluida Colombia (Bogotá) | Baja-media |

Cada carpeta trae:

- `README.md` — el resumen: la pregunta, los datos, la estrategia de identificación y
  su supuesto clave, el resultado principal y **qué replicar**.
- `paper/` — el PDF, **cuando la licencia permite redistribuirlo**. Si no, el README
  enlaza la versión de la revista y una versión abierta.
- `R/descargar-datos.R` — descarga el paquete de réplica original a `datos/_crudos/`.

> ⚠️ **Advertencia de fuente.** El **05** es un documento de trabajo de un solo autor que no
> ha pasado por revisión de pares. Léalo con más cuidado que un artículo publicado.

---

## Cómo descargar un paper y sus datos

1. **Descargue el repositorio**: `Code → Download ZIP` en GitHub, o
   `git clone https://github.com/afrtrivi1120/econ-desarrollo-labs.git`.
2. **Abra la carpeta del paper como directorio de trabajo** (en Positron o RStudio:
   `File → Open Folder…` sobre, por ejemplo, `proyecto-final/03_bastani-2025`).
3. **Corra el script de descarga**:

   ```r
   source("R/descargar-datos.R")
   ```

   El paquete de réplica queda en `datos/_crudos/`. Esa carpeta **no se versiona**: no
   suba datos crudos a GitHub.

Varios paquetes originales están en **Stata o Python**. Parte del trabajo de réplica es
traducir a R el núcleo del análisis (`tidyverse`, `fixest`, `modelsummary`); el README de
cada paper dice qué hay que traducir.

---

## Qué se espera de usted

| Entrega | Cuándo | Qué |
|---|---|---|
| Propuesta | Semana 8 | 1 página: paper escogido, resultado que va a replicar y pregunta del análisis adicional, con su fuente de datos. |
| Avance | Semana 12 | La réplica corriendo en R y un primer resultado de la extensión. |
| Mini-conferencia | Final del semestre | 10 minutos: el paper, su réplica y su extensión. |
| Informe | Final del semestre | Documento Quarto de 6 páginas, reproducible. |

Reglas de juego:

- **Su réplica debe correr de principio a fin** desde los datos originales, con rutas
  relativas.
- **Reporte diferencias** entre su número y el del paper, y explique de dónde salen.
  Una diferencia bien explicada vale más que un número copiado.
- **Cite todas las fuentes**: el paper, el paquete de réplica y cada base de datos que
  agregue (por ejemplo, "Fuente: DANE, www.dane.gov.co" para la Gran Encuesta Integrada de Hogares, GEIH).
- Respete la **licencia** de cada paquete; está anotada en el README del paper.

---

*Material del curso Economía del Desarrollo (06230), Universidad ICESI. Los papers,
paquetes de réplica y datos pertenecen a sus autores y se usan con fines académicos bajo
las licencias indicadas en cada carpeta.*
