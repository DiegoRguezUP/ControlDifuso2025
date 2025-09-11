clear all
clc

% === Parámetros de PSO ===
num_particles = 15;       % Número de partículas
num_iterations = 50;      % Iteraciones máximas
dim = 2;                  % Dimensión [Kp, Kd]
x_min = [0 0]; x_max = [40 30];
C1 = 1.5; C2 = 1.5; w = 0.6;

% === Inicialización ===
S = rand(num_particles, dim) .* (x_max - x_min) + x_min;
V = zeros(num_particles, dim);
pBest = S; 
pBest_cost = inf(num_particles, 1);
gBest = zeros(1, dim); 
gBest_cost = inf;
cost_values = zeros(num_particles,1);

for i = 1:num_particles
    cost = sim_plant_pend_inv_pd(S(i,:));
    pBest_cost(i) = cost;
    cost_values(i) = cost;
    if cost < gBest_cost
        gBest_cost = cost;
        gBest = S(i,:);
    end
end

% === Configurar gráfico ===
figure;
hold on; grid on;
xlabel('Parámetros (Kp/Kd)');
ylabel('Costo');
title('Evolución de partículas PSO');
scatter_kp = scatter(S(:,1), cost_values, 50, 'b', 'filled');
scatter_kd = scatter(S(:,2), cost_values, 50, 'r', 'filled');
legend('Kp','Kd');

% === Variables para parada temprana ===
no_improve_count = 0;       % Contador de iteraciones sin mejora
best_cost_history = gBest_cost;

% === Bucle principal ===
for iter = 1:num_iterations
    prev_best = gBest_cost; % Guardar mejor costo anterior
    
    for j = 1:num_particles
        % Actualizar velocidad y posición
        G1 = rand(1, dim); G2 = rand(1, dim);
        V(j,:) = w*V(j,:) + C1 .* G1 .* (pBest(j,:) - S(j,:)) + C2 .* G2 .* (gBest - S(j,:));
        S(j,:) = S(j,:) + V(j,:);
        S(j,:) = max(S(j,:), x_min);
        S(j,:) = min(S(j,:), x_max);

        % Evaluar costo
        cost = sim_plant_pend_inv_pd(S(j,:));
        cost_values(j) = cost;

        % Actualizar mejores
        if cost < pBest_cost(j)
            pBest_cost(j) = cost;
            pBest(j,:) = S(j,:);
        end
        if cost < gBest_cost
            gBest_cost = cost;
            gBest = S(j,:);
        end
    end

    % === Actualizar gráfico ===
    set(scatter_kp, 'XData', S(:,1), 'YData', cost_values);
    set(scatter_kd, 'XData', S(:,2), 'YData', cost_values);
    drawnow limitrate;

    fprintf('Iteración %d: Mejor Costo = %.4f\n', iter, gBest_cost);

    % === Verificar mejora ===
    if abs(prev_best - gBest_cost) < 1e-6 % Sin mejora significativa
        no_improve_count = no_improve_count + 1;
    else
        no_improve_count = 0; % Se reinicia si hubo mejora
    end
    
    % === Parada temprana ===
    if no_improve_count >= 5
        fprintf('No hubo mejora en 5 iteraciones consecutivas. Terminando...\n');
        break;
    end
end

fprintf('\nMejores parámetros: Kp = %.4f, Kd = %.4f\n', gBest(1), gBest(2));
