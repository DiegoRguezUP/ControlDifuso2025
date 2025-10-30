%% =================== Minimos cuadrados (Ridge/OLS) ======================
clearvars -except u x rhoon_error;
close all; rng(0);

%% -------- Parámetros --------
Kdel = 5;
use_bias = true;
weights_outputs = [4 1 2 1];
lambdas = logspace(-10, -2, 9);
Kfold   = 5;

%% 1) Leer y normalizar
U = read_ws_signal(u);
X = read_ws_signal(x);
assert(size(U,2)==2 && size(X,2)==4, 'Dimensiones esperadas: u N×2, x N×4.');

% (opcional) ver datos crudos
% figure('Name','X crudo');
% for i = 1:4
%     subplot(4,1,i); plot(X(:,i)); grid on; title(sprintf('X(:,%d)', i));
% end

N = min(size(U,1), size(X,1));
U = U(1:N,:); X = X(1:N,:);
assert(N > Kdel+2, 'Se requieren mas muestras.');

scaleX = max(abs(X),[],1); scaleX(scaleX==0)=1;
scaleU = max(abs(U),[],1); scaleU(scaleU==0)=1;
Xn = X./scaleX;
Un = U./scaleU;

%% 2) Construir Phi y Xp
Nsamp = N - Kdel;
Phi = [];
Xp  = zeros(Nsamp,4);

for idx = 1:Nsamp
    k = idx + Kdel;
    reg = [];

    % retardos lineales
    for d = 1:Kdel
        reg = [reg, Xn(k-d,:), Un(k-d,:)]; %#ok<AGROW>
    end

    % no lineales k-1
    xk1 = Xn(k-1,:);  uk1 = Un(k-1,:);
    theta1 = xk1(1);  dpsi1 = xk1(4);

    tanh_x1 = tanh(xk1);
    sq_x1   = xk1.^2;

    cross_xu1 = zeros(1, 4*2); cc = 1;
    for ii=1:4
        for jj=1:2
            cross_xu1(cc) = xk1(ii)*uk1(jj); cc = cc+1;
        end
    end

    cth1  = cos(theta1);
    sth1  = sin(theta1);
    sth_cth1 = sth1*cth1;
    dpsi2_sth_cth1 = (dpsi1^2)*sth_cth1;
    cross_trig_u1 = [cth1*uk1(1), cth1*uk1(2), sth1*uk1(1), sth1*uk1(2)];

    % no lineales k-2
    xk2 = Xn(k-2,:); dpsi2 = xk2(4);
    theta2 = xk2(1);
    cth2 = cos(theta2); sth2 = sin(theta2);
    sth_cth2 = sth2*cth2;
    dpsi2_sth_cth2 = (dpsi2^2)*sth_cth2;

    % tendencia
    trend = idx / Nsamp;

    if use_bias
        reg = [reg, ...
               tanh_x1, sq_x1, cross_xu1, ...
               cth1, sth1, sth_cth1, dpsi2_sth_cth1, cross_trig_u1, ...
               cth2, sth2, sth_cth2, dpsi2_sth_cth2, ...
               trend, ...
               1];
    else
        reg = [reg, ...
               tanh_x1, sq_x1, cross_xu1, ...
               cth1, sth1, sth_cth1, dpsi2_sth_cth1, cross_trig_u1, ...
               cth2, sth2, sth_cth2, dpsi2_sth_cth2, ...
               trend];
    end

    Phi = [Phi; reg]; %#ok<AGROW>
    Xp(idx,:) = Xn(k,:);
end
M = size(Phi,2);

%% 3) Seleccionar lambda (WLS correcto)
idx_cv = crossval_index(Nsamp, Kfold);
best_lambda = lambdas(1); best_score = inf;

for L = lambdas
    scores = zeros(Kfold,1);
    for kk = 1:Kfold
        tr = (idx_cv ~= kk);
        va = (idx_cv == kk);
        Phi_tr = Phi(tr,:); Y_tr = Xp(tr,:);
        Phi_va = Phi(va,:); Y_va = Xp(va,:);
        ThetaL = zeros(M,4);
        for i = 1:4
            w = weights_outputs(i);
            s = sqrt(w);
            Phi_w = s * Phi_tr;
            y_w   = s * Y_tr(:,i);
            ThetaL(:,i) = (Phi_w'*Phi_w + L*eye(M)) \ (Phi_w' * y_w);
        end
        Yh = Phi_va * ThetaL;
        err = Y_va - Yh;
        wrmse = sqrt(mean( (err.^2).*repmat(weights_outputs, size(err,1),1) , 1 ));
        scores(kk) = mean(wrmse);
    end
    if mean(scores) < best_score
        best_score = mean(scores);
        best_lambda = L;
    end
end

lambda = min(best_lambda, 1e-4);
fprintf('Lambda usado: %.3e\n', lambda);

%% 4) Estimar Theta final
Theta = zeros(M,4);
for i = 1:4
    w = weights_outputs(i);
    s = sqrt(w);
    Phi_w = s * Phi;
    y_w   = s * Xp(:,i);
    Theta(:,i) = (Phi_w'*Phi_w + lambda*eye(M)) \ (Phi_w' * y_w);
end

%% 5) Prediccion one-step y metricas
Xp_pred_n = Phi*Theta;
Xp_pred   = Xp_pred_n .* scaleX;
X_true    = X(Kdel+1:N,:);
E1        = X_true - Xp_pred;      % error LS

% MSE por estado y global (LS)
mse_ls_por_estado = mean(E1.^2, 1);      % 1x4
mse_ls_global     = mean(E1(:).^2);      % escalar

fprintf('MSE LS por estado: [%.4e  %.4e  %.4e  %.4e]\n', mse_ls_por_estado);
fprintf('MSE LS global: %.4e\n', mse_ls_global);

%% 5.5) Comparar contra RHOON (solo numeros)
mse_rhoon_por_estado = [];
mse_rhoon_global = [];
if exist('rhoon_error','var') && ~isempty(rhoon_error)
    RHO = read_ws_signal(rhoon_error);
    if size(RHO,2)~=4 && size(RHO,1)==4
        RHO = RHO.';
    end
    RHO = RHO( Kdel+1 : Kdel+Nsamp , : );
    mse_rhoon_por_estado = mean(RHO.^2, 1);
    mse_rhoon_global     = mean(RHO(:).^2);
    fprintf('MSE RHOON por estado: [%.4e  %.4e  %.4e  %.4e]\n', mse_rhoon_por_estado);
    fprintf('MSE RHOON global: %.4e\n', mse_rhoon_global);

    diff_mse = mse_ls_por_estado - mse_rhoon_por_estado;
    fprintf('MSE(LS) - MSE(RHOON): [%.4e  %.4e  %.4e  %.4e]\n', diff_mse);
else
    disp('rhoon_error no existe en workspace, no se comparó.');
end

%% (opcional) grafica de salida vs predicho
tvec = (Kdel+1:N)';
figure('Name','One-step: Medido vs Predicho','NumberTitle','off');
for i=1:4
    subplot(4,1,i);
    plot(tvec, X_true(:,i), 'b-', 'LineWidth',1.05); hold on;
    plot(tvec, Xp_pred(:,i), 'r--', 'LineWidth',1.05); grid on;
    if i==1, title('One-step: Medido vs. Predicho'); end
end
legend('Medido','Predicho');

%% 7) Exportar
assignin('base','Theta_base', Theta);
assignin('base','lambda_ridge', lambda);
assignin('base','scaleX', scaleX);
assignin('base','scaleU', scaleU);
assignin('base','mse_ls_por_estado', mse_ls_por_estado);
assignin('base','mse_ls_global', mse_ls_global);
if ~isempty(mse_rhoon_por_estado)
    assignin('base','mse_rhoon_por_estado', mse_rhoon_por_estado);
    assignin('base','mse_rhoon_global', mse_rhoon_global);
end
fprintf('Listo.\n');

%% helpers ...
function M = read_ws_signal(sig)
    if istimetable(sig)
        M = sig.Variables;
    elseif isa(sig, 'timeseries')
        M = sig.Data;
    elseif isstruct(sig) && isfield(sig,'signals') && isfield(sig.signals,'values')
        M = sig.signals.values;
    elseif isnumeric(sig)
        M = sig;
    else
        error('Formato no reconocido para u/x. Provee matriz, timeseries o struct de Simulink.');
    end
    M = squeeze(M);
    if size(M,1)==1 && size(M,2) > 1, M = M.'; end
end

function idx = crossval_index(N,K)
    rng(0); perm = randperm(N); idx = zeros(N,1);
    base = floor(N/K); s = 1;
    for k=1:K
        if k < K, sel = perm(s:s+base-1); else, sel = perm(s:end); end
        idx(sel) = k; s = s + base;
    end
end

%% 8) Estimar matrices A,B,C,D y bias c  (modelo lineal discreto)
fprintf('\n--- Estimando A,B,C,D (modelo lineal discreto) ---\n');

% Usamos solo el retardo más reciente (k-1)
Nsamp_lin = N - 1;
Phi_lin = zeros(Nsamp_lin, 4 + 2 + 1);   % [x(k-1)  u(k-1)  1]
Xp_lin  = zeros(Nsamp_lin, 4);           % objetivo x(k)

for k = 2:N
    Phi_lin(k-1,:) = [ Xn(k-1,:), Un(k-1,:), 1 ];  % regresores normalizados
    Xp_lin(k-1,:)  = Xn(k,:);                      % objetivo normalizado
end

% Resolver ridge lineal (puedes usar lambda mismo que antes)
lambda_lin = min(lambda, 1e-6);
Theta_lin = (Phi_lin' * Phi_lin + lambda_lin * eye(size(Phi_lin,2))) \ (Phi_lin' * Xp_lin);

% Extraer A,B,c en forma normalizada
A_n = Theta_lin(1:4,:)';   % 4x4
B_n = Theta_lin(5:6,:)';   % 4x2
c_n = Theta_lin(7,:)';     % 4x1

% Desnormalizar a unidades originales
A = diag(scaleX) * A_n * diag(1./scaleX);
B = diag(scaleX) * B_n * diag(1./scaleU);
c = diag(scaleX) * c_n;

% C y D (salida = estado)
C = eye(4);
D = zeros(4,2);

% Crear el sistema discreto
Ts = 1;  % cambia si conoces tu periodo de muestreo real
sys_ident = ss(A, B, C, D, Ts);

% Mostrar resultados
disp('Matriz A = '); disp(A);
disp('Matriz B = '); disp(B);
disp('Bias c = ');  disp(c);

% Guardar en workspace
assignin('base','A_ident',A);
assignin('base','B_ident',B);
assignin('base','C_ident',C);
assignin('base','D_ident',D);
assignin('base','c_ident',c);
assignin('base','sys_ident',sys_ident);
fprintf('Matrices A,B,C,D,c y sys_ident guardadas en workspace.\n');
