%% Script principal: linealización + cálculo de K (RIP)
clear; clc;

%% ------------------ Estados y símbolos ------------------
% x = [beta; betadot; gamma; gammadot], u = voltaje
syms u x1 x2 x3 x4
x = [x1; x2; x3; x4];

% Parámetros simbólicos (diferentes nombres para evitar choques)
syms m2s l1s l2s Js gs Kms Kgs Rms

% Constantes de motor (símbólicas)
P1s = Kgs*Kms/Rms;
P2s = (Kgs^2*Kms^2)/Rms;

%% ------------------ Dinámica del RIP (paper) ------------------
d11 = m2s*l1s^2 + Js;
d12 = m2s*l1s*l2s*cos(x1);
d21 = d12;
d22 = m2s*l2s^2;

c12 = -m2s*l1s*l2s*sin(x1)*x2;
g2  = -m2s*l2s*gs*sin(x1);

den = d11*d22 - d12*d21;

dx1 = x2;
dx3 = x4;
dx2 = ( d21*x2*c12 + d21*(P2s*x4) - d11*g2 )/den + (-d21*P1s/den)*u;
dx4 = (-d22*x2*c12 - d22*(P2s*x4) + d12*g2)/den + ( d22*P1s/den)*u;

F = [dx1; dx2; dx3; dx4];   % f(x)+g(x)u implícito
G = x1;                     % salida: beta

% Jacobianos
A_var = jacobian(F, [x1 x2 x3 x4]);
B_var = jacobian(F, u);
C_var = jacobian(G, [x1 x2 x3 x4]);
D_var = jacobian(G, u);

%% ------------------ Parámetros numéricos (paper) ------------------
m2 = 0.50;
l2 = 0.75;
l1 = 0.12;
J  = 0.003;
Km = 0.104;
Kg = 0.055;
Rm = 1.9;
g  = 9.81;

%% ------------------ Configuración T-S (TODO en radianes) ---------
N = 20;
range_deg   = [-15 15];
centers_rad = deg2rad(linspace(range_deg(1), range_deg(2), N));  % rad
Range_MF    = [centers_rad(1) centers_rad(end)];                 % rad

% Exosistema para seguimiento senoidal y = Hw
S = [0 10; -10 0];
H = [-1 0];                       % convención positiva

% contenedores
A_cell = cell(1,N); B_cell = cell(1,N);
C_cell = cell(1,N); D_cell = cell(1,N);
K_cell = cell(1,N); P_cell = cell(1,N); G_cell = cell(1,N);

% Polos deseados (4 estados). Ajusta si quieres más rapidez.
p = [-30 -1.5 -2.0 -7.3];

%% ------------------ Linealizaciones y ganancias -------------------
for i = 1:N
    % punto de operación
    x1_val = centers_rad(i);  x2_val = 0;  x3_val = 0;  x4_val = 0;  u_val = 0;

    % sustituir TODOS los símbolos por valores numéricos
    params = [x1 x2 x3 x4 u m2s l1s l2s Js gs Kms Kgs Rms];
    vals   = [x1_val x2_val x3_val x4_val u_val m2  l1  l2  J  g  Km  Kg  Rm];

    A_cell{i} = double(subs(A_var, params, vals));
    B_cell{i} = double(subs(B_var, params, vals));
    C_cell{i} = double(subs(C_var, params, vals));
    D_cell{i} = double(subs(D_var, params, vals));

    % Francis: A P + B G = P S,  C P = H
    [P,G] = solve_francis(A_cell{i}, B_cell{i}, C_cell{i}, S, H);
    P_cell{i} = P;   G_cell{i} = G;

    % LQR/place local
    K_cell{i} = place(A_cell{i}, B_cell{i}, p);

    % verificación CP ≈ H
    % disp(C_cell{i}*P);
end

% Arreglos 3D para Simulink
K_array = cat(3, K_cell{:});
P_array = cat(3, P_cell{:});
G_array = cat(3, G_cell{:});

% Para MembershipFunctions (bloque MATLAB System)
N_MF = N;
Range_MF = Range_MF;       %#ok<NASGU>
Centers_MF = centers_rad;  %#ok<NASGU>
