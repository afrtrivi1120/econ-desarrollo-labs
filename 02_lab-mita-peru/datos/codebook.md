# Codebook — `dell_mita_hogares` y `dell_mita_distritos`

Subconjuntos de enseñanza derivados del paquete de réplica de **Dell (2010)**, *The
Persistent Effects of Peru's Mining Mita*. Ver [`SOURCE.md`](SOURCE.md) para la
procedencia y la licencia de cada archivo.

---

## `dell_mita_hogares` — 1.478 filas × 18 columnas

Unidad de observación: **hogar** de la ENAHO 2001 (Encuesta Nacional de Hogares del
Perú), en distritos a menos de 100 km de la frontera de la mita. Es exactamente la
muestra de la **Tabla II, Panel A** del paper.

| Columna | Tipo | Descripción | Variable original |
|---|---|---|---|
| `distrito` | entero | Identificador de distrito. **Nivel al que se agrupan los errores estándar** (71 distritos). | `district` |
| `mita` | 0/1 | 1 = el distrito estuvo sujeto a la **mita** (reclutamiento forzoso para las minas, 1573–1812). Es el tratamiento. | `pothuan_mita` |
| `lhhequiv` | numérico | **Log del consumo del hogar por adulto equivalente**, neto de transferencias. Es el resultado. | `lhhequiv` |
| `d_bnd` | numérico | Distancia a la frontera de la mita, en **km**, **sin signo** (siempre positiva). | `d_bnd` |
| `dist_frontera` | numérico | **Variable de asignación con signo**: `d_bnd` negativa fuera de la mita y positiva dentro. Es la que hace visible el salto y la que consume `rdrobust`. | derivada |
| `dpot` | numérico | Distancia a **Potosí** en km (la mina a la que iban los mitayos del sur). | `dpot` |
| `x`, `y` | numérico | Longitud y latitud recentradas, en grados. Con ellas se arma el polinomio cúbico bidimensional. | `x`, `y` |
| `lat`, `lon` | numérico | Coordenadas del distrito (para el mapa). | `lat`, `lon` |
| `elv_sh` | numérico | Elevación en miles de metros. | `elv_sh` |
| `slope` | numérico | Pendiente media del terreno. | `slope` |
| `infants` | entero | Miembros del hogar de 0 a 4 años. | `infants` |
| `children` | entero | Miembros de 5 a 14 años. | `children` |
| `adults` | entero | Miembros adultos. | `adults` |
| `bfe4_1`, `bfe4_2`, `bfe4_3` | 0/1 | **Efectos fijos de segmento de frontera**: la frontera se parte en 4 tramos y estas son 3 dummies (el cuarto es la categoría base). Garantizan que la comparación sea *a lo largo* de la frontera y no entre regiones distintas. | `bfe4_1..3` |

---

## `dell_mita_distritos` — 299 filas × 18 columnas

Unidad de observación: **distrito**. Sirve para dos cosas: dibujar el mapa de la
frontera y hacer el **balance pre-mita** con el censo de Toledo de 1572.

| Columna | Tipo | Descripción | Variable original |
|---|---|---|---|
| `ubigeo` | texto | Código geográfico del distrito (INEI, Perú). | `ubigeo` |
| `mita` | 0/1 | 1 = distrito sujeto a la mita. | `pothuan_mita` |
| `frontera` | 0/1 | 1 = el distrito **toca** la frontera de la mita (67 distritos). | `border` |
| `d_bnd`, `dist_frontera` | numérico | Igual que arriba: distancia sin signo y con signo. | `d_bnd` / derivada |
| `lat`, `lon`, `x`, `y` | numérico | Coordenadas y sus versiones recentradas. | ídem |
| `elv_sh`, `slope` | numérico | Elevación (1.000 m) y pendiente media. | ídem |
| `bfe4_1`, `bfe4_2`, `bfe4_3` | 0/1 | Efectos fijos de segmento de frontera. | ídem |
| `pob1572` | numérico | **Población total registrada en 1572**, censo del virrey Toledo. `NA` para los distritos sin registro (solo 109 lo tienen). | `total_pop` |
| `sh_trib` | numérico | Participación de **tributarios** (hombres adultos que pagaban tributo) en la población de 1572. | `sh_trib` |
| `sh_boys` | numérico | Participación de niños en la población de 1572. | `sh_boys` |
| `sh_women` | numérico | Participación de mujeres en la población de 1572. | `sh_women` |

### Por qué importa el año 1572

El censo de Toledo se levantó **antes** de que empezara la mita (1573). Si las
características de 1572 **saltan** en la frontera, entonces los distritos de mita ya
eran distintos *antes* del tratamiento y el supuesto de continuidad se cae. Si **no**
saltan, es evidencia a favor de que la frontera es "como aleatoria". Es la prueba de
balance con datos pre-tratamiento, y es la mejor defensa del diseño.

---

### Notas de uso

- **Agrupar por distrito.** Los hogares de un mismo distrito comparten la geografía y
  el tratamiento, así que los errores estándar se agrupan por `distrito`
  (`cluster = ~distrito` en `fixest`). Son 71 clústeres: pocos, y por eso las
  estimaciones del Panel A son imprecisas.
- **Interpretar el coeficiente.** Como el resultado está en logaritmos, un coeficiente
  `b` se traduce a porcentaje con `exp(b) - 1`. Por ejemplo, −0,284 → **−24,7 %**.
- **El polinomio no es inocuo.** Dell usa una cúbica en (longitud, latitud). Un
  polinomio global de orden alto puede generar saltos espurios en el borde
  (Gelman & Imbens, 2019): por eso el lab compara tres especificaciones y varios anchos
  de banda en vez de confiar en una sola.

**Fuente:** Dell, M. (2010). The Persistent Effects of Peru's Mining Mita.
*Econometrica*, 78(6), 1863–1903. Datos de hogares vía MIT OpenCourseWare 14.75
(CC BY-NC-SA 4.0).
