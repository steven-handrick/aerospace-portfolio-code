function [WR, ff, out] = MissionWeightRatio(h)
% MissionWeightRatio
% Inputs:
%   h  = initial circular orbit altitude above Earth [km]
%
% Outputs:
%   WR    = weight ratio W0/Wf from rocket equation using total delta-V
%   out   = struct with intermediate results (velocities, delta-Vs, etc.)
%
% Notes:
% - Uses a Hohmann transfer from initial circular orbit (h) to 400 km circular.
% - Deorbit burn occurs at 400 km (treated as apogee after burn).
% - Deorbit ellipse is chosen so that at r = Re+120 km the flight-path angle is gamma = -1.5 deg.

    %% Constants
    mu   = 398600.4418;   % [km^3/s^2] Earth gravitational parameter
    Re   = 6378.137;      % [km] Earth mean equatorial radius
    g0   = 9.80665;       % [m/s^2] gravitational acceleration
    Isp  = 283;           % [s] assumed Isp for weight ratio

    %% Radii
    r1   = Re + h;        % [km] initial circular orbit radius
    r2   = Re + 400;      % [km] target circular orbit radius (400 km)
    rEI  = Re + 120;      % [km] entry interface radius (120 km altitude)

    %% Circular orbit velocities
    v1   = sqrt(mu/r1);   % [km/s] initial circular speed
    v2   = sqrt(mu/r2);   % [km/s] 400 km circular speed

    %% Hohmann transfer from r1 -> r2
    aT  = 0.5*(r1 + r2);  % [km] transfer orbit semi-major axis

    vT1 = sqrt(mu*(2/r1 - 1/aT));  % [km/s] transfer speed at r1
    vT2 = sqrt(mu*(2/r2 - 1/aT));  % [km/s] transfer speed at r2

    dV_H_1 = abs(vT1 - v1);      % [km/s] burn to enter transfer
    dV_H_2 = abs(v2 - vT2);      % [km/s] burn to circularize at 400 km
    dV_H   = dV_H_1 + dV_H_2;    % [km/s] total delta V for Hohmann transfer

    %% Deorbit burn from 400 km circular to ellipse hitting 120 km at gamma = -1.5 deg
    % Assumption: burn is at 400 km and that point becomes APOGEE of the ellipse.
    % Let rA = apogee radius = r2.
    rA = r2;

    gamma_deg = -1.5;              % magnitude
    gamma_rad = deg2rad(gamma_deg);
    t = tan(gamma_rad);            % only t^2 appears in sizing equation

    % Solve for eccentricity e (0<e<1)
    % with rA = a(1+e) and p = a(1-e^2) = rA(1-e),
    % k = p/rEI = rA(1-e)/rEI,
    % and e^2 = k^2*t^2 + (k-1)^2
    f = @(e) e.^2 - ( ( (rA*(1-e)/rEI).^2 )*(t^2) + (rA*(1-e)/rEI - 1).^2 );

    % Root find on (0,1)
    e_lo = 1e-8; 
    e_hi = 0.999999;
    f_lo = f(e_lo);
    f_hi = f(e_hi);

    if sign(f_lo) == sign(f_hi)
        e0 = 0.2;
        e  = fminsearch(@(x) (f(max(min(x,0.999999),1e-8))).^2, e0);
        e  = max(min(e,0.999999),1e-8);
    else
        e = fzero(f, [e_lo, e_hi]);
    end

    % Semi-major axis from apogee condition
    aD = rA/(1+e);                  % [km]
    % Speed at apogee of the ellipse (where burn occurs)
    vA = sqrt(mu*(2/rA - 1/aD));    % [km/s]
    vEI = sqrt(mu*(2/rEI - 1/aD));    % [km/s]
    dV_D = abs(v2 - vA);   % [km/s] retro burn magnitude at 400 km

    %% Total delta-V
    dV_total_kms = dV_H + dV_D;  % [km/s]
    dV_total_ms  = dV_total_kms * 1000;  % [m/s]

    %% Weight ratio (rocket equation)
    WR = exp(dV_total_ms/(Isp*g0));         % Weight Ratio
    ff = (WR - 1) / WR;                     % Fuel Fraction
    %% Pack outputs
    out = struct();
    out.mu              = mu;               %[km^3/s^2]
    out.Re              = Re;               %[km]
    out.Isp             = Isp;              %[s]

    out.r1              = r1;               %[km]
    out.r400            = r2;               %[km]
    out.rEI             = rEI;              %[km]

    out.v1              = v1;               %[km/s]
    out.v400            = v2;               %[km/s]

    out.dV_H1           = dV_H_1;           %[km/s]
    out.dV_H2           = dV_H_2;           %[km/s]
    out.dV_H            = dV_H;             %[km/s]

    out.D_e             = e;                %[dimensionless]
    out.D_a             = aD;               %[km]
    out.v_apogee        = vA;               %[km/s]
    out.v_reentry       = vEI               %[km/s]
    out.dV_deorbit      = dV_D;             %[km/s]

    out.dV_total_kms    = dV_total_kms;     %[km/s]
    out.dV_total_ms     = dV_total_ms;      %[m/s]
    out.WeightRatio     = WR; 
    out.FuelFraction    = ff;
end