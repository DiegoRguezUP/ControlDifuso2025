function out = heli_ls_ident(u, x)
% Poner esto en la terminal para obtener resultados
%out = heli_ls_ident(u, x);
%A = out.A;
%B = out.B;
%c = out.c;
%
% H E L I _ L S _ I D E N T
% Identificación por mínimos cuadrados (ridge) del helicóptero 2DOF.
% ENTRA:
%   u : N x 2  (entradas)  -> [Vp, Vy]
%   x : N x 4  (estados)   -> [theta, psi, dtheta, dpsi]
%
% SALE (struct out):
%   out.Theta_base
%   out.lambda_ridge
%   out.scaleX, out.scaleU
%   out.Kdel
%   out.mse_ls_por_estado
%   out.mse_ls_global
%   out.A, out.B, out.C, out.D, out.c, out.sys_ident
%
% Uso:
%   out = heli_ls_ident(u, x);
%   A = out.A; B = out.B; ...

    % -------- Parámetros --------
    Kdel = 5;
    use_bias = true;
    weights_outputs = [4 1 2 1];
    lambdas = logspace(-10, -2, 9);
    Kfold   = 5;

    % 1) Leer y normalizar
    U = read_ws_signal(u);
    X = read_ws_signal(x);
    assert(size(U,2)==2 && size(X,2)==4, 'Dimensiones esperadas: u N×2, x N×4.');

    N = min(size(U,1), size(X,1));
    U = U(1:N,:); X = X(1:N,:);
    assert(N > Kdel+2, 'Se requieren mas muestras.');

    scaleX = max(abs(X),[],1); scaleX(scaleX==0)=1;
    scaleU = max(abs(U),[],1); scaleU(scaleU==0)=1;
    Xn = X./scaleX;
    Un = U./scaleU;

    % 2) Construir Phi y Xp
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

    % 3) Seleccionar lambda (WLS correcto)
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

    % 4) Estimar Theta final
    Theta = zeros(M,4);
    for i = 1:4
        w = weights_outputs(i);
        s = sqrt(w);
        Phi_w = s * Phi;
        y_w   = s * Xp(:,i);
        Theta(:,i) = (Phi_w'*Phi_w + lambda*eye(M)) \ (Phi_w' * y_w);
    end

    % 5) Predicción one-step y métricas (LS)
    Xp_pred_n = Phi*Theta;
    Xp_pred   = Xp_pred_n .* scaleX;
    X_true    = X(Kdel+1:N,:);
    E1        = X_true - Xp_pred;

    mse_ls_por_estado = mean(E1.^2, 1);
    mse_ls_global     = mean(E1(:).^2);

    % 6) Estimar A,B,C,D,c (lineal)
    Nsamp_lin = N - 1;
    Phi_lin = zeros(Nsamp_lin, 4 + 2 + 1);
    Xp_lin  = zeros(Nsamp_lin, 4);
    for k = 2:N
        Phi_lin(k-1,:) = [ Xn(k-1,:), Un(k-1,:), 1 ];
        Xp_lin(k-1,:)  = Xn(k,:);
    end
    lambda_lin = min(lambda, 1e-6);
    Theta_lin = (Phi_lin' * Phi_lin + lambda_lin * eye(size(Phi_lin,2))) \ (Phi_lin' * Xp_lin);

    A_n = Theta_lin(1:4,:)';    % 4x4
    B_n = Theta_lin(5:6,:)';    % 4x2
    c_n = Theta_lin(7,:)';      % 4x1

    A = diag(scaleX) * A_n * diag(1./scaleX);
    B = diag(scaleX) * B_n * diag(1./scaleU);
    c = diag(scaleX) * c_n;

    C = eye(4);
    D = zeros(4,2);
    Ts = 1;   % ajústalo si conoces tu Ts real
    sys_ident = ss(A, B, C, D, Ts);

    % ----- empaquetar salida -----
    out = struct();
    out.Theta_base   = Theta;
    out.lambda_ridge = lambda;
    out.scaleX       = scaleX;
    out.scaleU       = scaleU;
    out.Kdel         = Kdel;
    out.mse_ls_por_estado = mse_ls_por_estado;
    out.mse_ls_global     = mse_ls_global;
    out.A = A; out.B = B; out.C = C; out.D = D; out.c = c;
    out.sys_ident = sys_ident;

end

% ========= helpers locales =========
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
        error('Formato no reconocido para u/x.');
    end
    M = squeeze(M);
    if size(M,1)==1 && size(M,2)>1, M = M.'; end
end

function idx = crossval_index(N,K)
    rng(0); perm = randperm(N); idx = zeros(N,1);
    base = floor(N/K); s = 1;
    for k=1:K
        if k < K, sel = perm(s:s+base-1); else, sel = perm(s:end); end
        idx(sel) = k; s = s + base;
    end
end
