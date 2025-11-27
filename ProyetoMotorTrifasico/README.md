---

# Proyecto de Control de Motor con MATLAB y Simulink

Version de MATLAB: 2025a

## Integrantes del equipo

* Jaime Emmanuel Valenzuela Valdivia 0236827
* Diego Salvador Rodriguez Hernandez 0254925
* Hector Rogelio Robles Alcala 0244498
* Carmen Nochipa Orozco Olivares 0249041
* Sergio Zhivago Ramos Rivera 0246042
* Juan Pablo Larios Franco 0244215

## Descripcion general del proyecto

Este repositorio contiene los modelos y scripts utilizados en MATLAB y Simulink para el diseño, prueba y validacion del sistema de control de un motor trifasico. El desarrollo incluyo:

* Identificacion de la planta mediante tecnicas de minimos cuadrados
* Implementacion de controladores PID clasico y PID difuso
* Integracion de comunicacion UART con una ESP32 (simulacion y pruebas de intercambio de datos)
* Diseño de un entorno de prueba para validar la respuesta del sistema y la correcta generacion de referencias

El proposito principal del repositorio es documentar el entorno de Simulink utilizado durante las pruebas del control, así como conservar los scripts de identificacion de planta.

## Archivos incluidos

### 1. MainControl_v2.slx

Archivo principal de Simulink utilizado para el control del motor. Es completamente independiente (sin referencias externas).
Incluye:

* Control PID clasico
* Control PID difuso basado en reglas Mamdani
* Modo Debug con monitoreo de tramas UART simuladas para validar el envio y recepcion de datos con la ESP32
* Generacion de referencia, medicion simulada y bloques auxiliares para pruebas

Este archivo fue el utilizado para validar tanto el comportamiento del controlador como la comunicación contra el firmware real del microcontrolador.

### 2. MIN_CUADRADOS_AC.m

Script para estimar la planta mediante metodo de minimos cuadrados, obteniendo una funcion de transferencia discreta (Gz).
Se utiliza para ajustar el modelo matematico a partir de datos experimentales.

### 3. MIN_CUADRADOS_AC2.m

Segundo metodo de identificacion de planta, basado en ajustar un polinomio no lineal a los datos medidos.
Permite obtener un modelo alternativo para comparar precision y robustez.

## Requisitos

* MATLAB 2025a o superior
* Control System Toolbox
* Simulink

## Instrucciones de uso

1. Abrir MATLAB 2025a
2. Colocar todos los archivos del repositorio en la misma carpeta
3. Ejecutar primero cualquiera de los scripts de identificacion si se desea obtener o actualizar el modelo de planta
4. Abrir MainControl_v2.slx y ejecutar la simulacion
5. Seleccionar el modo de control (PID clasico, PID difuso, o Debug)

## Notas

Este repositorio contiene unicamente el entorno de Simulink.
El firmware utilizado en la ESP32 para generar el SPWM y la comunicacion UART se encuentra en otro repositorio.

---
