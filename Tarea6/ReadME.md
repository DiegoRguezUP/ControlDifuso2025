# MATLAB 2025.a — Bloque de funciones de membresía en Simulink

Implementación de un bloque **MATLAB Function** que calcula los grados de pertenencia de un valor escalar para un conjunto de funciones (trapecios en extremos y triángulos intermedios), distribuidas uniformemente en un rango.

## Uso

* **Entrada**: `valor` (desde *Switches* o *Slider Gain/Knob*).
* **Parámetros (recomendado como máscara)**:

  * `N` (número de funciones, p. ej. 5)
  * `rango = [min max]` (p. ej. `[-15 15]`)
* **Salida**: `mu` (vector `1×N` con los grados de pertenencia).

## Pasos rápidos

1. Inserta un **MATLAB Function** en Simulink y pega la función `eval_mf(valor)` con `N` y `rango` definidos dentro del bloque o como **mask parameters**.
2. Asegura que la **dimensión de salida** sea fija (`1×N`).

   * Opción simple: fija `N` dentro del código.
   * Opción GUI: en *Symbols*, establece `mu` con tamaño `[1 N]`.
3. Conecta el control de entrada (switches/slider) al puerto `valor`.

## Nota

Si `N` varía durante la simulación, habilita **Variable Size** y define un **límite superior** (p. ej. `1×10`). Para la mayoría de prácticas, salida fija `1×N` evita errores de compilación.
