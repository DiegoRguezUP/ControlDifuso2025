% COMPARE_MODEL_ERRORS_RMS.m
% Compara el error del RHOON contra el del modelo LS usando RMS (Root Mean Square)

% Si ya están en base, los tomas así (descomenta si quieres forzarlo):
% rhoon_error = evalin('base','rhoon_error');
% ls_error    = evalin('base','ls_error');

% === 1) convertir a matriz N x 4 ===
rhoon_error = to_matrix(rhoon_error);
ls_error    = to_matrix(ls_error);

% recortar al mismo largo
N = min(size(rhoon_error,1), size(ls_error,1));
rhoon_error = rhoon_error(1:N,:);
ls_error    = ls_error(1:N,:);

% === 2) RMS por estado y global ===
rms_rhoon = sqrt(mean(rhoon_error.^2, 1));
rms_ls    = sqrt(mean(ls_error.^2, 1));

rms_rhoon_global = sqrt(mean(rhoon_error(:).^2));
rms_ls_global    = sqrt(mean(ls_error(:).^2));

fprintf('RMS LS por estado:    [%.4e  %.4e  %.4e  %.4e]\n', rms_ls);
fprintf('RMS RHOON por estado: [%.4e  %.4e  %.4e  %.4e]\n', rms_rhoon);
fprintf('RMS LS global:    %.4e\n', rms_ls_global);
fprintf('RMS RHOON global: %.4e\n', rms_rhoon_global);
fprintf('ΔRMS (LS - RHOON): [%.4e  %.4e  %.4e  %.4e]\n', rms_ls - rms_rhoon);

% === 3) Gráfica ===
t = (0:N-1).';
names = {'x_1','x_2','x_3','x_4'};

figure('Name','Comparacion de errores (RMS)','NumberTitle','off','Units','normalized','Position',[0.08 0.08 0.7 0.8]);
for i = 1:4
    subplot(4,1,i);
    plot(t, ls_error(:,i), 'b'); hold on;
    plot(t, rhoon_error(:,i), 'r'); grid on;
    ylabel(names{i});
    if i==1, title('errores (medido - modelo)'); end
    if i==4, xlabel('muestra'); end
    legend('LS','RHOON');
end

% ================= helper =================
function M = to_matrix(sig)
    % acepta: numeric, timeseries, struct de Simulink
    if istimetable(sig)
        M = sig.Variables;
    elseif isa(sig,'timeseries')
        M = sig.Data;
    elseif isstruct(sig) && isfield(sig,'signals') && isfield(sig.signals,'values')
        M = sig.signals.values;
    elseif isnumeric(sig)
        M = sig;
    else
        error('Formato de señal no soportado.');
    end
    M = squeeze(M);
    if size(M,1)==1 && size(M,2)>1
        M = M.';  % dejar N x 4
    end
end
