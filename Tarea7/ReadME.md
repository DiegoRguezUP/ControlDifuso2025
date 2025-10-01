# Matlab 2025.a  

## Tarea 7 — Control Takagi-Sugeno + Regulación Lineal en el Péndulo Rotatorio  

En esta práctica se implementó un esquema de control difuso Takagi-Sugeno combinado con regulación lineal (ecuaciones de Francis) para el sistema no lineal del péndulo rotatorio (RIP).  

### Puntos clave
- **Exosistema**:  
  \[
  \dot{w} = \begin{bmatrix}0 & 10 \\ -10 & 0\end{bmatrix}w, \quad H = [1 \; 0]
  \]  
  La salida de referencia es \(r = Hw = w_1\).  

- **Errores encontrados y correcciones**:  
  - Inicialmente se usó una amplitud de \(\pi/2\) en el exosistema, lo que empujaba al péndulo fuera del equilibrio y provocaba divergencias.  
  - Se corrigió fijando una amplitud menor (cercana a la condición de equilibrio).  

- **Polos del regulador**:  
  - Para estabilizar, se asignó un polo con un valor **grande** (dominante) y los demás **más pequeños**, lo cual permitió que el control funcionara de forma estable sin generar oscilaciones excesivas.  

### Resultado
El controlador difuso logró estabilizar el sistema y seguir la referencia senoidal, siempre que:
1. El exosistema se configurara con amplitud moderada.  
2. Los polos se eligieran con una separación adecuada (uno grande y los demás pequeños).  
