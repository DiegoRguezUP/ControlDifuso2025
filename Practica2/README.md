# Control Óptimo Inverso para Helicóptero 2-DOF  
**Versión de MATLAB: 2025.a**

Este proyecto implementa un controlador de **Control Óptimo Inverso (IOC)** para el helicóptero de dos grados de libertad (Pitch–Yaw).  
El modelo del sistema se obtuvo mediante **identificación por mínimos cuadrados** (modelo discreto con bias).  
El control se divide en dos componentes: **Feedforward (trim)** y **corrección óptima** basada en un horizonte predictivo de dos pasos.

---

## Objetivo
Regular y seguir referencias para los ángulos **Pitch** y **Yaw** de la plataforma utilizando un controlador óptimo que minimiza el error de salida y el esfuerzo de control.

---

## Modelo del Sistema
Se utilizan 4 estados:

\[
x = [\theta, \psi, \dot{\theta}, \dot{\psi}]^\top
\]

y las salidas son:

\[
y = Cx = [\theta, \psi]^\top
\]

El modelo discreto identificado tiene la forma:

\[
x_{k+1} = Ax_k + Bu_k + c
\]

---

## Control Implementado

### 1) **Feedforward (Trim)**
Calcula el voltaje necesario para sostener la referencia \((\theta_{ref}, \psi_{ref})\) compensando gravedad y sesgo:

\[
u_{ff} \approx \arg\min_u \| (I-A)x_{\text{ref}} - c - Bu \|^2
\]

### 2) **Control Óptimo Inverso (IOC)**

La corrección se obtiene minimizando un costo cuadrático predictivo:

\[
J = (y_{k+2} - r)^\top P (y_{k+2}-r) + u^\top R u
\]

La ley de control resultante es:

\[
u_{IOC} = -\frac{1}{2} S^{-1} B_{eff}^\top P\, e_2
\]

donde:

\[
B_{eff} = C(AB + B), \quad 
S = R + \tfrac{1}{2} B_{eff}^\top P B_{eff}
\]

---

## Estructura de Archivos
| Archivo / Bloque | Descripción |
|-----------------|-------------|
| `ss_disc_bias.m` | Modelo discreto identificado por mínimos cuadrados. |
| `trim_from_ls`   | Cálculo del voltaje de equilibrio (feedforward). |
| `inv_opt_ls_2step` | Implementación del control óptimo inverso a 2 pasos. |
| `Simulink Model` | Ensamble completo: referencia → trim → IOC → actuadores. |

---

## Notas
- La matriz de peso **P es 2×2** porque penaliza el **error de salida** \((\theta, \psi)\), no el estado completo.
- Las salidas se saturan a los límites físicos: Pitch ±24 V, Yaw ±15 V.

---

## Autor
Proyecto realizado por **Diego Rodríguez**.  
Para dudas o mejoras, añadir *issues* en el repositorio.
