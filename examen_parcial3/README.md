# Control Óptimo Inverso con RHONN  
**Modelo: Doble masa–resorte–amortiguador**  
**Simulink / MATLAB: R2025a**

Este proyecto implementa un esquema de **Control Óptimo Inverso (IOC)** sobre una planta de **doble masa–resorte–amortiguador**, utilizando una **Red Neuronal Recurrente de Alto Orden (RHONN)** como identificador de la dinámica del sistema. El trabajo fue realizado en equipo con **Carmen Nochipa Orozco Olivares**.

La RHONN aprende la dinámica interna del sistema mediante dos filtros EKF independientes (uno por cada estado estimado), y posteriormente el controlador IOC utiliza este modelo neuronal para generar la señal de control que haga seguir al sistema la referencia deseada.

---

## Descripción general del sistema

### ✓ Planta  
Se modela un sistema mecánico formado por dos masas acopladas mediante resortes y amortiguadores. El estado está compuesto por posiciones y velocidades de ambas masas, y la entrada es una fuerza aplicada sobre la primera masa.

### ✓ Identificador RHONN  
La RHONN estima la dinámica utilizando una estructura no lineal con funciones `tanh`. Sus pesos se actualizan en línea mediante dos filtros EKF, cada uno con su propia matriz de covarianza.  
El error entre el estado real y el estimado actualiza los pesos, lo que permite que la red aprenda la dinámica del sistema durante la simulación.

### ✓ Control Óptimo Inverso (IOC)  
El controlador utiliza el modelo neuronal para resolver un problema cuadrático instantáneo y obtener la acción de control.  
Se emplea la matriz de pesos del costo:

\[
P = 
\begin{bmatrix}
1000 & 30 \\
30   & 0.001
\end{bmatrix}
\]

Esta matriz pondera la penalización del error del estado en el control óptimo inverso.

---

## Estructura del modelo Simulink

El archivo `.slx` contiene:

- **Bloque de planta** (dinámica del sistema mecánico)  
- **Bloque RHONN** (estimación de estado y actualización de pesos)  
- **Bloque IOC** (cálculo de la señal de control)  
- **Generador de referencia**  
- **Scopes** para visualizar estados, referencias y señal de control  

---

## Cómo ejecutar el proyecto

1. Asegurar que todos los archivos `.m` estén en el mismo directorio que el modelo `.slx`.  
2. Definir condiciones iniciales de estados, pesos y matrices de covarianza.  
3. Ejecutar el modelo en **MATLAB/Simulink R2025a**.  
4. Visualizar la respuesta del sistema, seguimiento de referencia y convergencia del modelo neuronal.

---

## Notas finales

- La combinación RHONN + IOC permite lograr control óptimo sin conocer exactamente la dinámica, ya que esta se aprende en línea.  
- La calidad del control depende fuertemente de la matriz **P**, la cual en este proyecto se fijó en  
  \[
  \begin{bmatrix}
  1000 & 30 \\
  30   & 0.001
  \end{bmatrix}
  \]  
- El trabajo y modelo fueron desarrollados **en equipo con Carmen Nochipa Orozco Olivares**.
