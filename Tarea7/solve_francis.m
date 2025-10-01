function [P,G] = solve_francis(A,B,C,S,H)
% Resuelve las ecuaciones de Francis:
%   A*P + B*G = P*S
%   C*P = H
%
% Entradas:
%   A (n x n)
%   B (n x m)
%   C (p x n)
%   S (r x r)
%   H (p x r)
%
% Salidas:
%   P (n x r)
%   G (m x r)

    [n,~] = size(A);
    [~,m] = size(B);
    [p,~] = size(C);
    [r,~] = size(S);

    % Ecuación 1: A*P + B*G - P*S = 0
    % -> (I_r ⊗ A - S' ⊗ I_n) vec(P) + (I_r ⊗ B) vec(G) = 0
    M1_P = kron(eye(r), A) - kron(S', eye(n));
    M1_G = kron(eye(r), B);

    % Ecuación 2: C*P - H = 0
    % -> (I_r ⊗ C) vec(P) = vec(H)
    M2_P = kron(eye(r), C);
    rhs2 = reshape(H, [], 1);

    % Construir sistema lineal
    Zg = zeros(size(M2_P,1), size(M1_G,2));
    Aeq = [M1_P, M1_G;
           M2_P, Zg];
    beq = [zeros(n*r,1); rhs2];

    % Resolver
    sol = Aeq \ beq;

    % Extraer P y G
    vecP = sol(1:n*r);
    vecG = sol(n*r+1:end);

    P = reshape(vecP, n, r);
    G = reshape(vecG, m, r);
end
