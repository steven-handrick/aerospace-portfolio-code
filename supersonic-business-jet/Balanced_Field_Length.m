%% Balance Field Length Model
% Balanced field length model following Phillips, Mechanics of Flight
%
% Final outputs are:
% Stall Speed
% Liftoff Speed
% Takeoff Distance
% Balanced Field Length

clear; clc;

%% ---------------- INPUTS ----------------
g       = 9.80665;       % gravitational acceleration, m/s^2
rho     = 1.225;         % air density, kg/m^3, standard sea level
Vhw     = 0.0;           % headwind speed, m/s. Use 0 for no wind.

% Aircraft geometry and takeoff mass
mTO     = 26988.8;         % takeoff mass, kg
S       = 82.2972;         % wing reference area, m^2
b       = 10.0244;         % wingspan, m
h_w     = 1.5;           % wing height above runway during ground roll, m
AR      = b^2/S;         % aspect ratio
W       = mTO*g;         % takeoff weight, N

% Aerodynamics in takeoff configuration
CD0     = 0.007526;         % zero-lift drag coefficient, takeoff config.
CD0_L   = 0.0;           % linear drag polar term, takeoff config.
e       = 0.74;          % Oswald efficiency factor
CLmaxTO = 0.719236;           % max lift coefficient in takeoff config.
CLgr    = 0.123557;           % lift coefficient during acceleration run

% Ground operation assumptions
mu_roll  = 0.04;         % rolling friction coefficient during takeoff
mu_brake = 0.40;         % braking friction coefficient during rejected takeoff
t_rot    = 1.0;          % rotation time, s
t_rec    = 1.0;          % engine-failure recognition time, s
t_react  = 1.0;          % pilot reaction time before braking, s
h_obs    = 10.668;       % obstacle clearance height, m. 10.668 m = 35 ft

% Engine model
nEng = 2;                % total number of engines

% Define total all-engine thrust as a function of airspeed, in N.
% Constant thrust is a first estimate. 
T_static = 217732;        % all-engine static thrust, N
T_all = @(V) T_static + 0.*V;   % all-engine thrust model, N

%% ---------------- MAIN CALCULATION ----------------
% Stall, liftoff, and obstacle clearance speeds
Vstall = sqrt(2*W/(rho*S*CLmaxTO));
V_LO   = 1.10*Vstall;
V_OC   = 1.20*Vstall;

% Ground-effect drag coefficient for the acceleration run
CDgr = dragGroundEffect(CLgr, CD0, CD0_L, e, AR, h_w, b);

% All-engine takeoff ground roll
s_accel_AEO = groundDistance(0, V_LO, 1.0, mu_roll, CLgr, CDgr, ...
    mTO, W, S, rho, Vhw, T_all);
s_rot = max(V_LO - Vhw, 0)*t_rot;
s_ground_roll_AEO = s_accel_AEO + s_rot;

% All-engine climb distance to obstacle clearance altitude
[s_climb_AEO, gamma_OC_AEO] = climbTransitionDistance(1.0, V_LO, V_OC, ...
    mTO, W, S, rho, g, CD0, CD0_L, e, AR, h_w, b, h_obs, T_all);

% Takeoff distance with all engines operating
s_takeoff_AEO = s_ground_roll_AEO + s_climb_AEO;

% Balanced field length calculation with one engine inoperative
OEIscale = (nEng - 1)/nEng;
[s_BFL, Vef_crit, Vfr_crit, Vfrr_crit, abort_at_BFL, cont_at_BFL, data] = ...
    balancedFieldLength(V_LO, V_OC, OEIscale, mu_roll, mu_brake, CLgr, CDgr, ...
    mTO, W, S, rho, g, Vhw, T_all, t_rot, t_rec, t_react, CD0, CD0_L, e, AR, ...
    h_w, b, h_obs);

%% ---------------- OUTPUTS: METRIC AND ENGLISH ----------------
mps_to_fps = 3.280839895;
mps_to_kts = 1.943844492;
m_to_ft    = 3.280839895;
rad_to_deg = 180/pi;

fprintf('\nBalanced Field Length Results\n');
fprintf('-----------------------------------------------------------------------\n');
fprintf('Stall speed, Vstall                 = %8.2f m/s  | %8.2f ft/s | %6.2f kt\n', ...
    Vstall, Vstall*mps_to_fps, Vstall*mps_to_kts);
fprintf('Liftoff speed, V_LO                 = %8.2f m/s  | %8.2f ft/s | %6.2f kt\n', ...
    V_LO, V_LO*mps_to_fps, V_LO*mps_to_kts);
fprintf('Obstacle clearance speed, V_OC      = %8.2f m/s  | %8.2f ft/s | %6.2f kt\n', ...
    V_OC, V_OC*mps_to_fps, V_OC*mps_to_kts);

fprintf('\nAll-engine takeoff:\n');
fprintf('  Acceleration distance             = %8.1f m    | %8.1f ft\n', ...
    s_accel_AEO, s_accel_AEO*m_to_ft);
fprintf('  Rotation distance                 = %8.1f m    | %8.1f ft\n', ...
    s_rot, s_rot*m_to_ft);
fprintf('  Ground roll                       = %8.1f m    | %8.1f ft\n', ...
    s_ground_roll_AEO, s_ground_roll_AEO*m_to_ft);
fprintf('  Climb angle at obstacle clearance = %8.3f deg\n', gamma_OC_AEO*rad_to_deg);
fprintf('  Climb distance to %.1f m obstacle = %8.1f m    | %8.1f ft\n', ...
    h_obs, s_climb_AEO, s_climb_AEO*m_to_ft);
fprintf('  Takeoff distance                  = %8.1f m    | %8.1f ft\n', ...
    s_takeoff_AEO, s_takeoff_AEO*m_to_ft);

fprintf('\nBalanced field length:\n');
fprintf('  Critical engine failure speed     = %8.2f m/s  | %8.2f ft/s | %6.2f kt\n', ...
    Vef_crit, Vef_crit*mps_to_fps, Vef_crit*mps_to_kts);
fprintf('  Critical recognition speed        = %8.2f m/s  | %8.2f ft/s | %6.2f kt\n', ...
    Vfr_crit, Vfr_crit*mps_to_fps, Vfr_crit*mps_to_kts);
fprintf('  Speed when braking starts         = %8.2f m/s  | %8.2f ft/s | %6.2f kt\n', ...
    Vfrr_crit, Vfrr_crit*mps_to_fps, Vfrr_crit*mps_to_kts);
fprintf('  Balanced field length             = %8.1f m    | %8.1f ft\n', ...
    s_BFL, s_BFL*m_to_ft);
fprintf('  Abort distance at balance         = %8.1f m    | %8.1f ft\n', ...
    abort_at_BFL, abort_at_BFL*m_to_ft);
fprintf('  Continue distance at balance      = %8.1f m    | %8.1f ft\n', ...
    cont_at_BFL, cont_at_BFL*m_to_ft);
fprintf('-----------------------------------------------------------------------\n\n');

% Balance Field Length Plot in Feet
figure('Color','white');
plot(data.Vef*m_to_ft, data.abortDistance*m_to_ft, 'LineWidth', 1.5); hold on;
plot(data.Vef*m_to_ft, data.continueDistance*m_to_ft, 'LineWidth', 1.5);
xline(Vef_crit*m_to_ft, '--'); yline(s_BFL*m_to_ft, '--');
grid on;
xlabel('Engine failure speed, V_{ef} (ft/s)');
ylabel('Field Length (ft)');
legend('Abort takeoff', 'Continue takeoff OEI', 'Critical V_{ef}', 'BFL', ...
    'Location', 'best');
title('Balanced Field Length Determination');

% Balanced Field Length in Meters
figure('Color','white');
plot(data.Vef, data.abortDistance, 'LineWidth', 1.5); hold on;
plot(data.Vef, data.continueDistance, 'LineWidth', 1.5);
xline(Vef_crit, '--'); yline(s_BFL, '--');
grid on;
xlabel('Engine failure speed, V_{ef} (m/s)');
ylabel('Field length (m)');
legend('Abort takeoff', 'Continue takeoff OEI', 'Critical V_{ef}', 'BFL', ...
    'Location', 'best');
title('Balanced Field Length Determination');

%% ---------------- FUNCTIONS ----------------
function CD = dragGroundEffect(CL, CD0, CD0_L, e, AR, h, b)
    % Drag coefficient in ground effect.
    % Induced drag multiplier approaches 0 near the ground and 1 far away.
    GE = (16*h/b)^2/(1 + (16*h/b)^2);
    CD = CD0 + CD0_L*CL + GE*CL^2/(pi*e*AR);
end

function a = accelGround(V, thrustScale, mu, CL, CD, mTO, W, S, rho, T_all)
    % Ground acceleration from Newton's second law.
    % All variables are metric:
    %   V     = m/s
    %   mTO   = kg
    %   W     = N
    %   S     = m^2
    %   rho   = kg/m^3
    %   T_all = N
    %   a     = m/s^2
    V = max(V, 0);
    q = 0.5*rho.*V.^2;
    L = q*S*CL;
    D = q*S*CD;
    T = thrustScale*T_all(V);

    % Normal force on wheels is W - L.
    Ffric = mu*max(W - L, 0);

    % Net force along the runway.
    Fnet = T - D - Ffric;

    % Acceleration.
    a = Fnet./mTO;
end

function s = groundDistance(V1, V2, thrustScale, mu, CL, CD, mTO, W, S, rho, Vhw, T_all)
    % Distance required to accelerate or decelerate from V1 to V2.
    % Numerical form:
    %   ds/dV = V_ground / a
    % where V_ground = V - Vhw.
    %
    % For braking, acceleration is negative and V2 < V1, so the integral
    % still returns a positive distance after abs().

    integrand = @(V) (V - Vhw)./accelGround(V, thrustScale, mu, CL, CD, mTO, W, S, rho, T_all);
    s = integral(integrand, V1, V2, 'ArrayValued', true, 'RelTol', 1e-8, 'AbsTol', 1e-8);
    s = abs(s);
end

function [V2, s] = constAccelStep(V1, dt, thrustScale, mu, CL, CD, mTO, W, S, rho, Vhw, T_all)
    % Short recognition/reaction interval, treated with constant net force.
    a = accelGround(V1, thrustScale, mu, CL, CD, mTO, W, S, rho, T_all);
    Vg1 = max(V1 - Vhw, 0);
    s = Vg1*dt + 0.5*a*dt^2;
    V2 = V1 + a*dt;
end

function [sc, gammaOC] = climbTransitionDistance(thrustScale, V_LO, V_OC, mTO, W, S, rho, g, ...
    CD0, CD0_L, e, AR, h_w, b, h_obs, T_all)
    % Transition climb distance from liftoff to obstacle clearance altitude.
    % Uses an average effective net force between liftoff and obstacle clearance.

    % Liftoff point
    qLO = 0.5*rho*V_LO^2;
    CL_LO = W/(qLO*S);
    CD_LO = dragGroundEffect(CL_LO, CD0, CD0_L, e, AR, h_w, b);
    D_LO = qLO*S*CD_LO;
    T_LO = thrustScale*T_all(V_LO);

    % Obstacle clearance point.
    % Iterate because gamma changes the lift required and therefore drag.
    gammaOC = 0;
    for k = 1:50
        qOC = 0.5*rho*V_OC^2;
        CL_OC = W*cos(gammaOC)/(qOC*S);
        CD_OC = dragGroundEffect(CL_OC, CD0, CD0_L, e, AR, h_w + h_obs, b);
        D_OC = qOC*S*CD_OC;
        T_OC = thrustScale*T_all(V_OC);
        arg = (T_OC - D_OC)/W;
        arg = max(min(arg, 0.99), -0.99);
        gammaNew = asin(arg);
        if abs(gammaNew - gammaOC) < 1e-10
            gammaOC = gammaNew;
            break;
        end
        gammaOC = gammaNew;
    end

    % Effective accelerating/climbing force.
    Fc_bar = ((T_LO - D_LO) + (T_OC - D_OC)/cos(gammaOC))/2;

    if Fc_bar <= 0
        warning('Effective net force during climb is not positive. Climb distance set to NaN.');
        sc = NaN;
        return;
    end

    % Energy-style distance estimate: height gain plus kinetic energy change.
    sc = W/Fc_bar*(h_obs + (V_OC^2 - V_LO^2)/(2*g));
end

function [BFL, VefCrit, VfrCrit, VfrrCrit, abortCrit, contCrit, data] = balancedFieldLength( ...
    V_LO, V_OC, OEIscale, mu_roll, mu_brake, CLgr, CDgr, mTO, W, S, rho, g, Vhw, T_all, ...
    t_rot, t_rec, t_react, CD0, CD0_L, e, AR, h_w, b, h_obs)

    % Climb distance with one engine inoperative is independent of Vef.
    [s_climb_OEI, ~] = climbTransitionDistance(OEIscale, V_LO, V_OC, mTO, W, S, rho, g, ...
        CD0, CD0_L, e, AR, h_w, b, h_obs, T_all);

    N = 400;
    VefGrid = linspace(0, V_LO, N);
    abortDist = nan(size(VefGrid));
    contDist  = nan(size(VefGrid));
    VfrGrid   = nan(size(VefGrid));
    VfrrGrid  = nan(size(VefGrid));

    for i = 1:N
        Vef = VefGrid(i);

        % Distance before failure: all engines operating.
        s_to_failure = groundDistance(0, Vef, 1.0, mu_roll, CLgr, CDgr, ...
            mTO, W, S, rho, Vhw, T_all);

        % Continue takeoff: one engine inoperative acceleration to liftoff,
        % then rotation and OEI climb to obstacle clearance.
        s_after_failure = groundDistance(Vef, V_LO, OEIscale, mu_roll, CLgr, CDgr, ...
            mTO, W, S, rho, Vhw, T_all);
        contDist(i) = s_to_failure + s_after_failure + max(V_LO - Vhw, 0)*t_rot + s_climb_OEI;

        % Abort takeoff:
        % 1) recognition interval with one engine inoperative
        % 2) reaction interval with one engine inoperative
        % 3) braking to a full stop with thrust set to zero
        [Vfr, s_rec]    = constAccelStep(Vef, t_rec, OEIscale, mu_roll, CLgr, CDgr, ...
            mTO, W, S, rho, Vhw, T_all);
        [Vfrr, s_react] = constAccelStep(Vfr, t_react, OEIscale, mu_roll, CLgr, CDgr, ...
            mTO, W, S, rho, Vhw, T_all);
        s_brake = groundDistance(Vfrr, 0, 0.0, mu_brake, CLgr, CDgr, ...
            mTO, W, S, rho, Vhw, T_all);

        abortDist(i) = s_to_failure + s_rec + s_react + s_brake;
        VfrGrid(i) = Vfr;
        VfrrGrid(i) = Vfrr;
    end

    % Balanced field occurs where abort and continue distances are equal.
    diffDist = abortDist - contDist;
    idx = find(diffDist(1:end-1).*diffDist(2:end) <= 0, 1, 'first');

    if isempty(idx)
        warning('No balanced field intersection found between 0 and V_LO. Using closest point.');
        [~, idxMin] = min(abs(diffDist));
        VefCrit = VefGrid(idxMin);
        [abortCrit, contCrit, VfrCrit, VfrrCrit] = distancesAtVef(VefCrit);
        BFL = max(abortCrit, contCrit);
    else
        V1 = VefGrid(idx);   V2 = VefGrid(idx+1);
        d1 = diffDist(idx);  d2 = diffDist(idx+1);
        VefCrit = V1 - d1*(V2 - V1)/(d2 - d1);

        [abortCrit, contCrit, VfrCrit, VfrrCrit] = distancesAtVef(VefCrit);
        BFL = 0.5*(abortCrit + contCrit);
    end

    data.Vef = VefGrid;
    data.Vfr = VfrGrid;
    data.Vfrr = VfrrGrid;
    data.abortDistance = abortDist;
    data.continueDistance = contDist;

    function [abortLength, continueLength, Vfr, Vfrr] = distancesAtVef(Vef)
        s_to_failure = groundDistance(0, Vef, 1.0, mu_roll, CLgr, CDgr, ...
            mTO, W, S, rho, Vhw, T_all);

        s_after_failure = groundDistance(Vef, V_LO, OEIscale, mu_roll, CLgr, CDgr, ...
            mTO, W, S, rho, Vhw, T_all);
        continueLength = s_to_failure + s_after_failure + max(V_LO - Vhw, 0)*t_rot + s_climb_OEI;

        [Vfr, s_rec] = constAccelStep(Vef, t_rec, OEIscale, mu_roll, CLgr, CDgr, ...
            mTO, W, S, rho, Vhw, T_all);
        [Vfrr, s_react] = constAccelStep(Vfr, t_react, OEIscale, mu_roll, CLgr, CDgr, ...
            mTO, W, S, rho, Vhw, T_all);
        s_brake = groundDistance(Vfrr, 0, 0.0, mu_brake, CLgr, CDgr, ...
            mTO, W, S, rho, Vhw, T_all);

        abortLength = s_to_failure + s_rec + s_react + s_brake;
    end
end
