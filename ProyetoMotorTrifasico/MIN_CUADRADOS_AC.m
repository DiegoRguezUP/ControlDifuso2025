%% Identificación por Mínimos Cuadrados (LS) con Ts Fijo (0.001s)
% Sistema: Motor AC (Entrada: Frecuencia, Salida: Velocidad Angular)
% Modelo: ARX(Na, Nb, d)





clear all; close all; clc;

disp(' ');
disp('==================================================');
disp('Carga de Datos desde Archivo CSV');

% **PARÁMETRO CLAVE: TIEMPO DE MUESTREO FIJO**
T_muestreo = 0.001; 

mac = 'mac.csv'; 

try
    datos = readmatrix(mac);
catch
    error(['No se pudo cargar el archivo: ', mac, '. Asegúrese de que esté en el directorio actual.']);
end

u = datos(:, 1);  %  (Frecuencia)
y = datos(:, 2);  %  (Velocidad Angular)

% Determinar N y calcular el vector de tiempo (t)
N_muestras = length(u);
if N_muestras ~= length(y)
    error('Los vectores de entrada y salida deben tener la misma longitud.');
end
t = (0:N_muestras-1)' * T_muestreo; % Vector de tiempo calculado

% Solicitar los grados del modelo al usuario
disp(' ');
disp('--- Parámetros del Modelo ARX(Na, Nb, d) ---');
Na = input('Ingrese el grado del DENOMINADOR (Na, e.g., 2): ');
Nb = input('Ingrese el grado del NUMERADOR (Nb, e.g., 2): ');
d = input('Ingrese el RETARDO DISCRETO (d, e.g., 1): ');

% Verificación de la suficiencia de muestras
num_parametros = Na + Nb;
if N_muestras <= num_parametros
    error(['El número de muestras (', num2str(N_muestras), ') debe ser mayor que el número de parámetros a estimar (', num2str(num_parametros), ').']);
end

% . CONSTRUCCIÓN DE LA MATRIZ DE REGRESORES (Phi) y VECTOR Y 
% El retardo máximo es: max(Na, Nb + d - 1)
k_inicio = max(Na, Nb + d - 1) + 1; 

% Vector de Salidas y(k) (desde k_inicio hasta N_muestras)
Y = y(k_inicio:N_muestras); 
Phi = zeros(length(Y), num_parametros);

for k = k_inicio:N_muestras
    fila_actual = k - k_inicio + 1;
    
    % Parte Autorregresiva (y pasadas) -> Coeficientes a1, a2, ..., a_Na
    % Se usan con signo negativo: -y(k-i)
    for i = 1:Na
        Phi(fila_actual, i) = -y(k - i); 
    end
    
    % Parte de Entrada (u pasadas) -> Coeficientes b1, b2, ..., b_Nb
    % Se usan con signo positivo: u(k - d), u(k - d - 1), ...
    for j = 1:Nb
        % Índice de tiempo para u: k - d - (j - 1)
        Phi(fila_actual, Na + j) = u(k - d - (j - 1));
    end
end

% --- 3. SOLUCIÓN POR MÍNIMOS CUADRADOS (LS) ---
% Solución eficiente y estable usando el operador \ (backslash) de MATLAB
P = Phi' * Phi; 
R = Phi' * Y;   
theta_hat = P \ R; 

% --- 4. RESULTADOS Y FUNCIÓN DE TRANSFERENCIA ---
disp(' ');
disp('==================================================');
disp('RESULTADOS DE LA IDENTIFICACIÓN POR MÍNIMOS CUADRADOS');
disp(['Grado del Denominador (Na): ', num2str(Na)]);
disp(['Grado del Numerador (Nb): ', num2str(Nb)]);
disp(['Retardo Discreto (d): ', num2str(d)]);
disp(['Número de Muestras (N): ', num2str(N_muestras)]);
disp(['Tiempo de Muestreo (T): ', num2str(T_muestreo, '%.4f'), ' segundos']);
disp('--------------------------------------------------');

% Extraer los coeficientes estimados
a_hat = theta_hat(1:Na);
b_hat = theta_hat(Na+1:end);

disp('Vector de Coeficientes Estimados (theta_hat):');
disp(theta_hat);

% --- IMPRIMIR FUNCIÓN DE TRANSFERENCIA (tf) ---
% Denominador: A(z) = 1 + a1*z^-1 + a2*z^-2 + ...
A_tf = [1, a_hat']; 

% Numerador: B(z) = b1*z^-d + b2*z^-(d+1) + ...
% Número de ceros iniciales es d-1 (para incluir el retardo)
ceros_iniciales = zeros(1, d - 1);
B_tf = [ceros_iniciales, b_hat'];

% Asegurar la misma longitud para la función tf()
len = max(length(A_tf), length(B_tf));
A_tf = [A_tf, zeros(1, len - length(A_tf))];
B_tf = [B_tf, zeros(1, len - length(B_tf))];

% Crear la función de transferencia en tiempo discreto
Gz = tf(B_tf, A_tf, T_muestreo);
disp(' ');
disp('FUNCIÓN DE TRANSFERENCIA IDENTIFICADA (G(z)):');
disp(Gz);
disp('==================================================');

% --- 5. GRÁFICOS ---
% Calcular la salida predicha y el error
y_predicha = Phi * theta_hat;
y_real = y(k_inicio:N_muestras);
t_plot = t(k_inicio:N_muestras); 
error_pred = y_real - y_predicha;

figure;
subplot(2,1,1);
plot(t_plot, y_real, 'b'); 
hold on;
plot(t_plot, y_predicha, 'r--');
title('Salida Real (Medida) vs. Salida Predicha');
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