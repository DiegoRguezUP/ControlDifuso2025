%% Script principal: linealización + cálculo de K (Furuta)
clear; clc;

% ===============================
% Parâmetros numéricos (ajusta a tu equipo)
% ===============================
g   = 9.81;     % [m/s^2]
m2  = 0.50;     % [kg]   masa del péndulo
l1  = 0.12;     % [m]    brazo desde eje base
l2  = 0.75;     % [m]    distancia del CoM del péndulo al pivote
J   = 0.003;    % [kg*m^2] inercia equivalente en eje base (motor+brazo)

b_beta  = 0.0;  % [N*m*s/rad] fricción viscosa en junta del péndulo
b_gamma = 0.0;  % [N*m*s/rad] fricción viscosa en eje base

% Modelo eléctrico del motor (del paper): tau1 = P1*u - P2*gamma_dot
Kg = 1.0;       % relación de engranes
Km = 1.0;       % [N*m/A] (y V*s/rad en SI)
Rm = 1.0;       % [Ohm]
P1 = (Kg*Km)/Rm;
P2 = (Kg*Km)^2/Rm;

% ===============================
% Sistema simbólico (no lineal)
% ===============================
syms u x1 x2 x3 x4 real
% x1=beta, x2=betadot, x3=gamma, x4=gammadot
x = [x1; x2; x3; x4];

% Matriz de inercia D(q) con q=[gamma; beta]
d11 = m2*l1^2 + J;
d12 =  m2*l1*l2*cos(x1);
d21 =  d12;
d22 =  m2*l2^2;

% Término Coriolis/centrífugo relevante
c12 = -m2*l1*l2*sin(x1)*x2;

% Gravedad
g2  = -m2*l2*g*sin(x1);

% Par del motor en eje base
tau1 = P1*u - P2*x4;

% Ecuaciones:
% d11*ddgamma + d12*ddbeta + c12*x2 + b_gamma*x4 = tau1
% d21*ddgamma + d22*ddbeta + b_beta*x2 + g2     = 0
Delta = d11*d22 - d12*d21;

rhs1 = tau1 - c12*x2 - b_gamma*x4;
rhs2 = -g2   - b_beta*x2;

ddgamma = ( d22*rhs1 - d12*rhs2)/Delta;
ddbeta  = (-d21*rhs1 + d11*rhs2)/Delta;

% Dinámica de estados
dx1 = x2;
dx2 = ddbeta;
dx3 = x4;
dx4 = ddgamma;

dx = [dx1; dx2; dx3; dx4];

% ===============================
% Salida
% ===============================
G = x1;      % y = beta (ángulo del péndulo)
% --- Si quieres usar la auxiliar del paper, usa en su lugar:
% G = x1 + x3;   % y = beta + gamma

% ===============================
% Jacobianos (linealización)
% ===============================
A_var = jacobian(dx, x);   % 4x4
B_var = jacobian(dx, u);   % 4x1
C_var = jacobian(G,  x);   % 1x4
D_var = jacobian(G,  u);   % 1x1  (será 0)

% ===============================
% Configuración T-S
% ===============================
N = 10;                      % número de funciones de membresía
range = [-15 15];          % rango de ángulos en grados (para beta)
centers = linspace(range(1), range(2), N); % en grados

% Exosistema senoidal (w-dot = S w, y_ref = H w)
S = [0 10; -10 0];   % frecuencia 10 rad/s
H = [1 0];          % salida = senoidal

% Contenedores
A_cell = cell(1,N);
B_cell = cell(1,N);
C_cell = cell(1,N);
D_cell = cell(1,N);
K_cell = cell(1,N);
P_cell = cell(1,N);
G_cell = cell(1,N);

% Polos deseados (4 estados -> 4 polos)
p = [-4 -5 -6 -7];   % ajusta según tu planta/actuador

% ===============================
% Calcular linealizaciones y K
% ===============================
for i = 1:N
    % Punto de operación (centros) — solo barremos beta
    beta_i  = centers(i)*pi/180;  % rad
    betad_i = 0;
    gamma_i = 0;
    gammad_i = 0;
    u_i     = 0;

    % Evaluar Jacobianos en el punto
    Ai = double(subs(A_var, [x1 x2 x3 x4 u], [beta_i betad_i gamma_i gammad_i u_i]));
    Bi = double(subs(B_var, [x1 x2 x3 x4 u], [beta_i betad_i gamma_i gammad_i u_i]));
    Ci = double(subs(C_var, [x1 x2 x3 x4 u], [beta_i betad_i gamma_i gammad_i u_i]));
    Di = double(subs(D_var, [x1 x2 x3 x4 u], [beta_i betad_i gamma_i gammad_i u_i]));

    A_cell{i} = Ai;
    B_cell{i} = Bi;
    C_cell{i} = Ci;
    D_cell{i} = Di;

    % Resolver ecuaciones de Francis para seguimiento/rechazo
    % (asumiendo que tu función solve_francis admite (A,B,C,S,H))
    [P,G] = solve_francis(Ai, Bi, Ci, S, H);
    P_cell{i} = P;
    G_cell{i} = G;

    % Ganancia por asignación de polos
    % (A - B*K) con K de 1x4
    K_cell{i} = place(Ai, Bi, p);

    % Opcional: checar rango relativo (observabilidad/controlabilidad) aquí
    % rank(ctrb(Ai,Bi)), rank(obsv(Ai,Ci))
end

% ===============================
% Convertir a arreglos 3D para Simulink
% ===============================
K_array = cat(3, K_cell{:});   % [1x4xN]
P_array = cat(3, P_cell{:});   % [4x2xN] (típicamente)
G_array = cat(3, G_cell{:});   % [1x2xN]
A_array = cat(3, A_cell{:});   % [4x4xN]
B_array = cat(3, B_cell{:});   % [4x1xN]
C_array = cat(3, C_cell{:});   % [1x4xN]
D_array = cat(3, D_cell{:});   % [1x1xN]

% (Si tu bloque de funciones de membresía necesita A,B,C,D además de K,P,G,
% ya están listos en *_array.)

% ===============================
% Ejecutar modelo en Simulink (si aplica)
% ===============================
% sim('BloqueFuncionesMembresia.slx');
