%% Glide Range by Flight Regime
% Inputs:
%   L_D_hyp  = L/D in hypersonic regime
%   L_D_sup  = L/D in supersonic regime
%   L_D_sub  = L/D in subsonic regime
%
% Outputs:
%   R_hyp    = hypersonic glide range (m)
%   R_sup    = supersonic glide range (m)
%   R_sub    = subsonic glide range (m)
%   R_total  = total glide range (m)

clear; clc;

%% ---------------- INPUTS ----------------
L_D_hyp = 1.2;   % example
L_D_sup = 1.5;   % example
L_D_sub = 4.0;   % example

%% ---------------- CONSTANTS ----------------
g  = 9.80665;     % gravity, m/s^2
Vs = 8077.2;      % satellite speed, m/s
a0 = 343;         % sea-level speed of sound, m/s

%% ---------------- VELOCITY DEFINITIONS ----------------
% Hypersonic regime
V0_hyp = 7622.9;      % initial velocity, m/s
Vf_hyp = 5 * a0;      % final velocity = Mach 5

% Supersonic regime
V0_sup = 5 * a0;      % initial velocity = Mach 5
Vf_sup = 1 * a0;      % final velocity = Mach 1

% Subsonic regime
V0_sub = 1 * a0;      % initial velocity = Mach 1
Vf_sub = 0;           % final velocity = 0

%% ---------------- GLIDE RANGE CALCULATIONS ----------------
R_hyp = glideRange(Vs, g, L_D_hyp, V0_hyp, Vf_hyp);
R_sup = glideRange(Vs, g, L_D_sup, V0_sup, Vf_sup);
R_sub = glideRange(Vs, g, L_D_sub, V0_sub, Vf_sub);

R_total = R_hyp + R_sup + R_sub;

%% ---------------- DISPLAY RESULTS ----------------
fprintf('Hypersonic Glide Range = %.2f km\n', R_hyp/1000);
fprintf('Supersonic Glide Range = %.2f km\n', R_sup/1000);
fprintf('Subsonic Glide Range   = %.2f km\n', R_sub/1000);
fprintf('Total Glide Range      = %.2f km\n', R_total/1000);

%% ---------------- FUNCTION ----------------
function R = glideRange(Vs, g, L_D, V0, Vf)
    % Computes glide range using:
    % Rglide = -(Vs^2/(2g))*(L/D)*ln[(1 - V0^2/Vs^2)/(1 - Vf^2/Vs^2)]

    term1 = 1 - (V0^2 / Vs^2);
    term2 = 1 - (Vf^2 / Vs^2);

    if term1 <= 0 || term2 <= 0
        error('Log argument became non-physical. Check velocity inputs.');
    end

    R = -(Vs^2 / (2*g)) * L_D * log(term1 / term2);
end