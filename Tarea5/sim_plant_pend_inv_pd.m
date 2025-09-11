function e_x = sim_plant_pend_inv_pd(x)
%% Simulation plant using Simulink model
% author: Jorge Romero Aragon
% mail: ing.jorgecarlosromero@gmail.com
% date: Aug 27th, 2024
% Inputs:
% - x is a 2x1 vector with the elements Kp and Kd

%% Initializing Lyapunov Matrix using x input
assignin('base','Kp',x(1));
assignin('base','Kd',x(2));

%% Performing simulation using Simulink Model
errorHandler = [];
try
    out = sim('Ejercicio2_CustomFuzzyBlock', ...
    'Solver', 'ode4', ...
    'SolverType', 'Fixed-step', ...
    'FixedStep', '0.01', ...
    'StopTime', '8');
    %% Assigning tracking error
    track_error = out.track_error.data;
catch e
    if isa(e,'MSLException')
			disp('Error detected on simulation');
            errorHandler = e.handles{1};
            if(isempty(errorHandler))
                disp('Terminating simulation');
                error('Terminated correctly');
            end
            %% Assigning tracking error
            track_error = inf;
    end
end

%% Computing Minimum Square Error based on tracking error
e_x = sum(track_error.^2)/size(track_error,1);
end