%% Identificación NARX Polinomial (Grado 2) con Mínimos Cuadrados
% Sistema: Motor AC (Entrada: Frecuencia, Salida: Velocidad Angular)
% Modelo: NARX Polinomial (Na, Nb, d, L=2)
clear all; close all; clc;

% --- 1. CARGA DE DATOS Y PARÁMETROS FIJOS ---
disp(' ');
disp('==================================================');
disp('Carga de Datos desde Archivo CSV');

% **PARÁMETRO CLAVE: TIEMPO DE MUESTREO FIJO**
T_muestreo = 0.001; % ¡VALOR FIJO DE 0.001 segundos!

% **Paso 1: Especificar el nombre del archivo CSV**
% El archivo CSV DEBE contener 2 columnas: [Entrada (Frecuencia), Salida (Velocidad)]
mac = 'mac.csv'; % <--- ¡AJUSTAR ESTE NOMBRE!

% **Paso 2: Cargar los datos del CSV**
try
    datos = readmatrix(mac);
catch
    error(['No se pudo cargar el archivo: ', mac, '. Asegúrese de que esté en el directorio actual.']);
end

u = datos(:, 1);  % Columna 1: Señal de entrada (Frecuencia)
y = datos(:, 2);  % Columna 2: Señal de salida (Velocidad Angular)

% Determinar N y calcular el vector de tiempo (t)
N_muestras = length(u);
if N_muestras ~= length(y)
    error('Los vectores de entrada y salida deben tener la misma longitud.');
end
t = (0:N_muestras-1)' * T_muestreo; 

disp(' ');
disp('--- Parámetros del Modelo NARX Polinomial ---');
Na = input('Ingrese el grado de MEMORIA de la SALIDA (Na, e.g., 2): ');
Nb = input('Ingrese el grado de MEMORIA de la ENTRADA (Nb, e.g., 2): ');
d = input('Ingrese el RETARDO DISCRETO (d, e.g., 1): ');
L = 2; % GRADO DE NO LINEALIDAD FIJO EN 2 (CUADRÁTICO)

% --- 2. CONSTRUCCIÓN DEL VECTOR DE REGRESORES BÁSICOS (Lin) ---
% Vector lineal temporal que contiene todos los términos lineales disponibles
k_inicio = max(Na, Nb + d - 1) + 1; 
N_Phi = N_muestras - k_inicio + 1; % Número de filas en Phi

% Determinar la longitud del vector base lineal (Na + Nb)
longitud_base = Na + Nb;
Phi_Lin = zeros(N_Phi, longitud_base);

% Construir Phi_Lin (Regresores lineales: y(k-i) y u(k-d-j+1))
for k = k_inicio:N_muestras
    fila_actual = k - k_inicio + 1;
    
    % Parte de Salida (y pasadas)
    for i = 1:Na
        Phi_Lin(fila_actual, i) = y(k - i); 
    end
    
    % Parte de Entrada (u pasadas)
    for j = 1:Nb
        Phi_Lin(fila_actual, Na + j) = u(k - d - (j - 1));
    end
end

% --- 3. CONSTRUCCIÓN DE LA MATRIZ DE REGRESORES NO LINEALES (Phi_NARX) ---

% Generar la matriz final Phi_NARX para un polinomio de grado L=2 (Cuadrático)
if L == 2
    
    % 1. Términos Cuadráticos (phi_i * phi_i)
    Phi_Cuad = Phi_Lin.^2;
    
    % 2. Términos de Interacción (phi_i * phi_j), i < j
    num_variables_base = size(Phi_Lin, 2);
    num_interacciones = (num_variables_base * (num_variables_base - 1)) / 2;
    Phi_Inter = zeros(N_Phi, num_interacciones);
    
    col_inter = 1;
    for i = 1:num_variables_base
        for j = i + 1:num_variables_base
            Phi_Inter(:, col_inter) = Phi_Lin(:, i) .* Phi_Lin(:, j);
            col_inter = col_inter + 1;
        end
    end
    
    % Concatenar todos los términos: Lineales, Cuadráticos, Interacción
    Phi_NARX = [Phi_Lin, Phi_Cuad, Phi_Inter];
    disp('Modelo Polinomial NARX de Segundo Grado (L=2) construido.');
else
    error('Este script solo implementa L=2 (Cuadrático).');
end


% --- 4. SOLUCIÓN POR MÍNIMOS CUADRADOS (LS) ---
% Vector de Salidas y(k) (desde k_inicio hasta N_muestras)
Y = y(k_inicio:N_muestras); 

% Solución eficiente y estable: theta_hat = inv(Phi' * Phi) * Phi' * Y
P = Phi_NARX' * Phi_NARX; 
R = Phi_NARX' * Y;   
theta_hat = P \ R; 

% Número de parámetros totales
num_parametros_final = length(theta_hat);

% --- 5. RESULTADOS Y ANÁLISIS ---
disp(' ');
disp('==================================================');
disp('RESULTADOS DE LA IDENTIFICACIÓN POLINOMIAL NARX');
disp(['Grado de Memoria de la Salida (Na): ', num2str(Na)]);
disp(['Grado de Memoria de la Entrada (Nb): ', num2str(Nb)]);
disp(['Retardo Discreto (d): ', num2str(d)]);
disp(['Grado de No Linealidad (L): ', num2str(L)]);
disp(['Número de Parámetros Estimados: ', num2str(num_parametros_final)]);
disp('--------------------------------------------------');

disp('Vector de Coeficientes Estimados (theta_hat):');
disp(theta_hat);

% --- 6. GRÁFICOS Y VALIDACIÓN ---
% Calcular la salida predicha y el error
y_predicha = Phi_NARX * theta_hat;
y_real = y(k_inicio:N_muestras);
t_plot = t(k_inicio:N_muestras); 
error_pred = y_real - y_predicha;

% Calcular Porcentaje de Ajuste (Fit)
y_media = mean(y_real);
error_norm = norm(y_real - y_predicha); 
y_norm = norm(y_real - y_media); 
Fit_Porcentaje = 100 * (1 - (error_norm / y_norm));

disp(['Porcentaje de Ajuste (Fit \%): ', num2str(Fit_Porcentaje, '%.2f'), ' %']);
disp('==================================================');

figure;
subplot(2,1,1);
plot(t_plot, y_real, 'b'); 
hold on;
plot(t_plot, y_predicha, 'r--');
title('Salida Real vs. Salida Predicha (Modelo NARX Polinomial)');
legend('Salida Real y(k)', 'Salida Predicha \^{y}(k)');
xlabel('Tiempo (s)');
ylabel('Velocidad Angular ($\omega$)');
grid on;

subplot(2,1,2);
plot(t_plot, error_pred);
title('Error de Predicción e(k)');
xlabel('Tiempo (s)');
ylabel('Error');
grid on;

% --- 5.5. VISUALIZACIÓN DEL POLINOMIO ESTIMADO ---
disp(' ');
disp('--------------------------------------------------');
disp('EXPRESIÓN ESTIMADA DEL POLINOMIO NARX y(k) = ...');

% 1. Definir los nombres de las variables básicas (términos y y u)
variables = {};
% Términos de salida pasados (y(k-1), y(k-2), ...)
for i = 1:Na
    variables{end+1} = ['y(k-', num2str(i), ')'];
end
% Términos de entrada pasados (u(k-d), u(k-d-1), ...)
for j = 1:Nb
    variables{end+1} = ['u(k-', num2str(d + j - 1), ')'];
end

% 2. Generar todos los términos (lineales, cuadráticos, interacción)
regresores = {};
num_variables_base = length(variables);

% --- TÉRMINOS LINEALES ---
for i = 1:num_variables_base
    regresores{end+1} = variables{i};
end

% --- TÉRMINOS CUADRÁTICOS y de INTERACCIÓN (Solo si L=2) ---
if L == 2
    for i = 1:num_variables_base
        for j = i:num_variables_base
            if i == j
                % Cuadráticos: y^2, u^2
                regresores{end+1} = [variables{i}, '^2'];
            else
                % Interacción: y*u, y*y, u*u
                regresores{end+1} = [variables{i}, '*', variables{j}];
            end
        end
    end
end

% 3. Construir la expresión final
polinomio_str = 'y(k) = ';
for m = 1:num_parametros_final
    % Obtener el coeficiente (con 4 decimales para claridad)
    coef = theta_hat(m);
    
    % Determinar el signo del término
    if m == 1
        % El primer término no lleva signo (+) inicial
        signo_str = '';
    elseif coef >= 0
        signo_str = ' + ';
    else
        signo_str = ' - ';
    end
    
    % Concatenar el término: [Signo] [|Coeficiente|] * [Regresor]
    polinomio_str = [polinomio_str, signo_str, num2str(abs(coef), '%.4f'), '*', regresores{m}];
end

disp(polinomio_str);
disp('--------------------------------------------------');