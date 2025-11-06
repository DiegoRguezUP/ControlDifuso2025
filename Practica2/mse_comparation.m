%% === CÁLCULO DE MSE PARA MODELO LS (Pitch y Yaw) ===

% -- Convertir a vector si vienen como timeseries --
if isa(PitchErrorRHONN,'timeseries')
    e_pitch = PitchErrorRHONN.Data;
else
    e_pitch = PitchErrorRHONN;
end

if isa(YawErrorRHONN,'timeseries')
    e_yaw = YawErrorRHONN.Data;
else
    e_yaw = YawErrorRHONN;
end

% -- Asegurar formato columna --
e_pitch = e_pitch(:);
e_yaw   = e_yaw(:);

% -- MSE --
MSE_pitch_LS = mean(e_pitch.^2);
MSE_yaw_LS   = mean(e_yaw.^2);

fprintf('\n=== MSE Modelo RHONN ===\n');
fprintf('Pitch MSE (RHONN): %.6f\n', MSE_pitch_LS);
fprintf('Yaw   MSE (RHONN): %.6f\n', MSE_yaw_LS);
