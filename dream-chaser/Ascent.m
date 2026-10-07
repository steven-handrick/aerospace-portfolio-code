function Ascent
% Numerically integrates gravity turn trajectory equations.
% Updated for Vulcan Centaur VC4L staging and upper-stage guided circularization.

clear; close all; clc

deg = pi/180;               % Convert degrees to radians
g0 = 9.80665;               % Sea-level acceleration of gravity (m/s)
Re = 6378e3;                % Radius of the earth (m)
mu = 3.986004418e14;        % Earth's gravitational parameter (m^3/s^2)
hscale = 7.5e3;             % Density scale height (m)
rho0 = 1.225;               % Sea level density of atmosphere (kg/m^3)

% ============================================================
% Vulcan Centaur VC4L Vehicle Data
% ============================================================

diam = 5.4;                 % Vehicle diameter (m)
A = pi/4*diam^2;            % Frontal area (m^2)
CD = 0.5;                   % Drag coefficient (assumed constant)

% Solid Rocket Boosters
nSRB = 4;                   % Number of solid rocket boosters
mSRB = 53400;               % Total mass of one SRB (kg)
mpropSRB = 48000;           % Propellant mass of one SRB (kg)
mdrySRB = mSRB - mpropSRB;  % Dry mass of one SRB (kg)
tburnSRB = 87.3;            % SRB burn time (s)
ThrustSRB = 2060634;        % Thrust of one SRB (N)
m_dotSRB = mpropSRB/tburnSRB; % Mass flow rate of one SRB (kg/s)

% Main Booster
nBE4 = 2;                   % Number of BE-4 engines
ThrustBE4 = 2446522;        % Thrust of one BE-4 engine (N)
tburnBooster = 286;         % Booster burn time from liftoff (s)
IspBE4 = 340;               % BE-4 specific impulse (s)
mdryBooster = 55602;        % Dry mass of main booster (kg)

ThrustBooster = nBE4*ThrustBE4;                      % Total booster thrust (N)
m_dotBooster = ThrustBooster/(IspBE4*g0);            % Booster mass flow rate (kg/s)
mpropBooster = m_dotBooster*tburnBooster;            % Booster propellant mass (kg)

% Centaur Upper Stage
mdryCentaur = 7100;         % Empty mass of Centaur (kg)
mpayload = 17792;           % Payload mass carried by Centaur (kg)
mpropCentaur = 46500;       % Centaur propellant mass (kg)
mCentaurTotal = mdryCentaur + mpayload + mpropCentaur;      % Total Centaur mass as booster payload (kg)

nRL10 = 2;                  % Number of RL10C engines
ThrustRL10 = 106757;        % Thrust of one RL10C engine (N)
IspUS = 461;                % RL10C specific impulse (s)

ThrustUpper = nRL10*ThrustRL10;                      % Total upper stage thrust (N)
m_dotUpper = ThrustUpper/(IspUS*g0);                 % Upper stage mass flow rate (kg/s)
tburnUpper = mpropCentaur/m_dotUpper;                % Maximum upper stage burn time (s)

% Mission Timing
tSRBsep = tburnSRB;                 % SRB burnout and separation time (s)
tBoosterCutoff = tburnBooster;      % Main booster cutoff time (s)
tUpperStart = tBoosterCutoff + 16;  % Centaur ignition, 16 s after booster cutoff (s)
tUpperBurnout = tUpperStart + tburnUpper; % Maximum upper stage burnout time (s)

% Lift-off Mass
m0 = mdryBooster + mpropBooster + mCentaurTotal + nSRB*mSRB;

% Target Orbit
hTarget = 250e3;                            % Target insertion altitude (m)
vCircularTarget = sqrt(mu/(Re + hTarget));  % Circular orbit speed at 250 km (m/s)

% ============================================================
% Initial Conditions and Guidance Settings
% ============================================================

hturn = 130;                % Height at which pitchover begins (m)

% Booster pitch program
% Tune gammaBoosterFinal to control the altitude at Centaur ignition.
gammaBoosterFinal = 5*deg;  % Desired booster flight path angle near cutoff
tPitchStart = 10;           % Time when pitch program begins (s)
tPitchEnd = tBoosterCutoff; % Time when pitch program ends (s)
tauPitch = 2;               % Booster pitch response time constant (s)

% Upper-stage guidance
% The upper stage keeps a positive climb angle until 250 km, then pitches
% toward 0 deg for circular orbit insertion.
gammaUpperClimb = 5*deg;    % Positive upper-stage climb angle before 250 km
gammaUpperFinal = 0*deg;    % Final circular orbit flight path angle
tauUpperPitch = 15;         % Upper-stage pitch response time constant (s)
gammaTol = 0.25*deg;        % Flight path angle tolerance for final orbit

v0 = 0;                     % Initial velocity (m/s)
gamma0 = 89.85*deg;         % Initial flight path angle (rad)
x0 = 0;                     % Initial downrange distance (m)
h0 = 0;                     % Initial altitude (m)
vD0 = 0;                    % Initial velocity loss due to drag (m/s)
vG0 = 0;                    % Initial velocity loss due to gravity (m/s)

f0 = [v0; gamma0; x0; h0; vD0; vG0];

% ============================================================
% Numerical Integration
% ============================================================

% Booster and coast integration:
% Gravity-turn/pitch-program model from liftoff to Centaur ignition.
tspanBooster = [0 tUpperStart];
[tBooster,fBooster] = ode45(@ratesBooster,tspanBooster,f0);

% Initial state for Centaur burn:
% The upper stage starts from the actual booster/coast state.
% Do not force the altitude or flight path angle because that creates
% artificial jumps in the trajectory.
f0Upper = fBooster(end,:)';

% Centaur integration:
% The burn stops when circular orbit conditions are reached, or when
% propellant is depleted.
optionsUpper = odeset('Events',@eventsUpper);
tspanUpper = [tUpperStart tUpperBurnout];

[tUpper,fUpper,te,ye,ie] = ode45(@ratesUpper,tspanUpper,f0Upper,optionsUpper);

% Combine booster and upper-stage solutions
t = [tBooster; tUpper(2:end)];
f = [fBooster; fUpper(2:end,:)];

% ============================================================
% Extract Solution
% ============================================================

v = f(:,1)*1e-3;        % Velocity (km/s)
gamma = f(:,2)/deg;     % Flight path angle (degrees)
x = f(:,3)*1e-3;        % Downrange distance (km)
h = f(:,4)*1e-3;        % Altitude (km)
vD = -f(:,5)*1e-3;      % Velocity loss due to drag (km/s)
vG = -f(:,6)*1e-3;      % Velocity loss due to gravity (km/s)

% Dynamic pressure and Mach number
q = zeros(length(t),1);
M = zeros(length(t),1);
a = zeros(length(t),1);

for i = 1:length(t)

    Rho = rho0 * exp(-h(i)*1000/hscale);    % Air density (kg/m^3)
    q(i) = 0.5*Rho*(v(i)*1000)^2;           % Dynamic pressure (Pa)

    if h(i)*1000 <= 85000
        [~, a(i), ~, ~] = atmosisa(h(i)*1000);
        M(i) = 1000*v(i)/a(i);
    else
        a(i) = NaN;
        M(i) = NaN;
    end

end

% Max dynamic pressure
[maxQ,imax] = max(q);
tQ = t(imax);
vQ = v(imax);
hQ = h(imax);

if h(imax)*1000 <= 85000
    [~, aQ, ~, ~] = atmosisa(h(imax)*1000);
    MQ = 1000*vQ/aQ;
else
    MQ = NaN;
end

output

% ============================================================
% Nested booster rates function
% ============================================================
function dydt = ratesBooster(t,y)
    % Calculates the time rates dy/dt for the booster phase.

    dydt = zeros(6,1);

    v = y(1);                               % Velocity (m/s)
    gamma = y(2);                           % Flight path angle (rad)
    h = y(4);                               % Altitude (m)

    % ------------------------------------------------------------
    % Booster phase logic
    % ------------------------------------------------------------

    if t < tSRBsep

        % Phase 1:
        % Main booster and 4 SRBs are burning.
        m = m0 - (m_dotBooster + nSRB*m_dotSRB)*t;
        T = ThrustBooster + nSRB*ThrustSRB;

    elseif t < tBoosterCutoff

        % Phase 2:
        % SRBs have burned out and separated.
        % Main booster continues burning.
        mSRBsep = m0 ...
            - (m_dotBooster + nSRB*m_dotSRB)*tSRBsep ...
            - nSRB*mdrySRB;

        m = mSRBsep - m_dotBooster*(t - tSRBsep);
        T = ThrustBooster;

    else

        % Coast phase:
        % Main booster has burned out and separated.
        % Centaur has not ignited yet.
        m = mCentaurTotal;
        T = 0;

    end

    g = g0/(1 + h/Re)^2;                    % Gravity variation with altitude
    rho = rho0*exp(-h/hscale);              % Atmospheric density
    D = 0.5*rho*v^2*A*CD;                   % Drag force

    % ------------------------------------------------------------
    % Booster guidance equations of motion
    % ------------------------------------------------------------

    if h <= hturn

        % Vertical rise before pitchover.
        gamma_dot = 0;
        v_dot = T/m - D/m - g;
        x_dot = 0;
        h_dot = v;
        vG_dot = -g;

    else

        % Commanded pitch schedule from nearly vertical to nearly horizontal.
        if t <= tPitchStart

            gammaCmd = gamma0;

        elseif t < tPitchEnd

            pitchFrac = (t - tPitchStart)/(tPitchEnd - tPitchStart);

            % Smooth cosine schedule from gamma0 to gammaBoosterFinal.
            gammaCmd = gammaBoosterFinal ...
                + 0.5*(gamma0 - gammaBoosterFinal)*(1 + cos(pi*pitchFrac));

        else

            gammaCmd = gammaBoosterFinal;

        end

        % Drive actual flight path angle toward commanded value.
        gamma_dot = (gammaCmd - gamma)/tauPitch;

        % Acceleration along the vehicle velocity direction.
        v_dot = T/m - D/m - g*sin(gamma);

        x_dot = Re/(Re + h)*v*cos(gamma);
        h_dot = v*sin(gamma);
        vG_dot = -g*sin(gamma);

    end

    vD_dot = -D/m;

    dydt(1) = v_dot;
    dydt(2) = gamma_dot;
    dydt(3) = x_dot;
    dydt(4) = h_dot;
    dydt(5) = vD_dot;
    dydt(6) = vG_dot;

end

% ============================================================
% Nested upper-stage rates function
% ============================================================
function dydt = ratesUpper(t,y)
    % Calculates the time rates dy/dt for the Centaur upper-stage burn.
    % The upper stage first climbs toward 250 km with a positive flight
    % path angle, then pitches toward 0 deg for circularization.

    dydt = zeros(6,1);

    v = y(1);                               % Velocity (m/s)
    gamma = y(2);                           % Flight path angle (rad)
    h = y(4);                               % Altitude (m)

    if t < tUpperBurnout

        % Centaur is burning.
        m = mCentaurTotal - m_dotUpper*(t - tUpperStart);
        T = ThrustUpper;

    else

        % Centaur propellant depleted.
        m = mdryCentaur + mpayload;
        T = 0;

    end

    g = g0/(1 + h/Re)^2;                    % Gravity variation with altitude
    rho = rho0*exp(-h/hscale);              % Atmospheric density
    D = 0.5*rho*v^2*A*CD;                   % Drag force, nearly zero above atmosphere

    % ------------------------------------------------------------
    % Upper-stage guidance
    % ------------------------------------------------------------

    if h < hTarget

        % Before reaching 250 km, keep a small positive climb angle.
        gammaCmd = gammaUpperClimb;

    else

        % Once 250 km is reached, pitch toward horizontal flight.
        gammaCmd = gammaUpperFinal;

    end

    % Smoothly drive actual flight path angle toward commanded value.
    gamma_dot = (gammaCmd - gamma)/tauUpperPitch;

    % ------------------------------------------------------------
    % Upper-stage equations of motion
    % ------------------------------------------------------------

    v_dot = T/m - D/m - g*sin(gamma);

    x_dot = Re/(Re + h)*v*cos(gamma);
    h_dot = v*sin(gamma);

    vD_dot = -D/m;
    vG_dot = -g*sin(gamma);

    dydt(1) = v_dot;
    dydt(2) = gamma_dot;
    dydt(3) = x_dot;
    dydt(4) = h_dot;
    dydt(5) = vD_dot;
    dydt(6) = vG_dot;

end

% ============================================================
% Nested upper-stage event function
% ============================================================
function [value,isterminal,direction] = eventsUpper(t,y)
    % Stops Centaur integration when the vehicle has reached:
    %   1. at least 250 km altitude,
    %   2. nearly zero flight path angle,
    %   3. circular velocity for the current altitude.

    v = y(1);        % Velocity (m/s)
    gamma = y(2);    % Flight path angle (rad)
    h = y(4);        % Altitude (m)

    vCircularCurrent = sqrt(mu/(Re + h));

    if h < hTarget || abs(gamma) > gammaTol

        % Do not allow cutoff before the vehicle is high enough and
        % the flight path angle is nearly horizontal.
        value = 1;

    else

        % Once altitude and flight path angle are acceptable, stop
        % when circular velocity is reached.
        value = v - vCircularCurrent;

    end

    isterminal = 1;
    direction = 1;

end

% ============================================================
% Nested output function
% ============================================================
function output

    [~,iMECO] = min(abs(t - tBoosterCutoff));
    [~,iCentaur] = min(abs(t - tUpperStart));

    vCircularFinal = sqrt(mu/(Re + h(end)*1000));

    fprintf('\n\n––––––––––––––––––––––––––––––––––––––––––––––––––\n')
    fprintf('\nVulcan Centaur VC4L Ascent Model')
    fprintf('\n––––––––––––––––––––––––––––––––––––––––––––––––––\n')

    fprintf('\n\nVehicle Inputs:')
    fprintf('\nVehicle diameter                  = %10.3f m', diam)
    fprintf('\nLift-off mass                     = %10.3f kg', m0)
    fprintf('\nMain booster propellant mass      = %10.3f kg', mpropBooster)
    fprintf('\nCentaur propellant mass           = %10.3f kg', mpropCentaur)

    fprintf('\n\nThrust Inputs:')
    fprintf('\nTotal SRB thrust                  = %10.3f N', nSRB*ThrustSRB)
    fprintf('\nTotal BE-4 thrust                 = %10.3f N', ThrustBooster)
    fprintf('\nTotal RL10C thrust                = %10.3f N', ThrustUpper)

    fprintf('\n\nMission Timing:')
    fprintf('\nSRB burnout/separation            = %10.3f s', tSRBsep)
    fprintf('\nBooster engine cutoff             = %10.3f s', tBoosterCutoff)
    fprintf('\nCentaur ignition                  = %10.3f s', tUpperStart)
    fprintf('\nMaximum Centaur burnout time      = %10.3f s', tUpperBurnout)
    fprintf('\nTarget altitude                   = %10.3f km', hTarget/1000)
    fprintf('\nTarget circular velocity          = %10.3f km/s', vCircularTarget/1000)

    fprintf('\n\nBooster Pitch Program:')
    fprintf('\nPitch start time                  = %10.3f s', tPitchStart)
    fprintf('\nPitch end time                    = %10.3f s', tPitchEnd)
    fprintf('\nTarget booster cutoff angle       = %10.3f deg', gammaBoosterFinal/deg)
    fprintf('\nPitch response time constant      = %10.3f s', tauPitch)

    fprintf('\n\nUpper-stage Guidance:')
    fprintf('\nUpper-stage climb angle           = %10.3f deg', gammaUpperClimb/deg)
    fprintf('\nUpper-stage final angle           = %10.3f deg', gammaUpperFinal/deg)
    fprintf('\nUpper-stage pitch time constant   = %10.3f s', tauUpperPitch)
    fprintf('\nFinal flight path angle tolerance = %10.3f deg', gammaTol/deg)

    fprintf('\n\nInitial Conditions:')
    fprintf('\nInitial flight path angle         = %10.3f deg', gamma0/deg)
    fprintf('\nPitchover altitude                = %10.3f m', hturn)

    fprintf('\n\nBooster Cutoff State:')
    fprintf('\nBooster cutoff altitude           = %10.3f km', h(iMECO))
    fprintf('\nBooster cutoff velocity           = %10.3f km/s', v(iMECO))
    fprintf('\nBooster cutoff flight path angle  = %10.3f deg', gamma(iMECO))

    fprintf('\n\nCentaur Ignition State:')
    fprintf('\nCentaur ignition altitude         = %10.3f km', h(iCentaur))
    fprintf('\nCentaur ignition velocity         = %10.3f km/s', v(iCentaur))
    fprintf('\nCentaur ignition flight path angle= %10.3f deg', gamma(iCentaur))

    fprintf('\n\nMaximum Dynamic Pressure:')
    fprintf('\nMaximum dynamic pressure          = %10.3f kPa', maxQ/1000)
    fprintf('\nTime at max Q                     = %10.3f s', tQ)
    fprintf('\nSpeed at max Q                    = %10.3f km/s', vQ)
    fprintf('\nAltitude at max Q                 = %10.3f km', hQ)
    fprintf('\nMach number at max Q              = %10.3f', MQ)

    fprintf('\n\nFinal State:')
    fprintf('\nTime                              = %10.3f s', t(end))
    fprintf('\nSecond-stage actual burn time     = %10.3f s', t(end) - tUpperStart)
    fprintf('\nSecond-stage max burn time        = %10.3f s', tburnUpper)
    fprintf('\nSpeed                             = %10.3f km/s', v(end))
    fprintf('\nCircular speed at final altitude  = %10.3f km/s', vCircularFinal/1000)
    fprintf('\nFlight path angle                 = %10.3f deg', gamma(end))
    fprintf('\nAltitude                          = %10.3f km', h(end))
    fprintf('\nTarget altitude                   = %10.3f km', hTarget/1000)
    fprintf('\nDownrange distance                = %10.3f km', x(end))
    fprintf('\nDrag loss                         = %10.3f km/s', vD(end))
    fprintf('\nGravity loss                      = %10.3f km/s', vG(end))

    if ~isempty(te)
        fprintf('\n\nTarget circular-orbit condition reached before Centaur propellant depletion.')
    else
        fprintf('\n\nCentaur propellant depleted before circular-orbit condition was reached.')
    end

    fprintf('\n\n––––––––––––––––––––––––––––––––––––––––––––––––––\n')

    % ------------------------------------------------------------
    % Plots
    % ------------------------------------------------------------

    figure('Name','Trajectory','Color','w')

    plot(x,h,'LineWidth',1.5)
    hold on
    yline(hTarget/1000,'--','250 km Target Altitude')
    xline(interp1(t,x,tSRBsep,'linear','extrap'),'--','SRB Sep')
    xline(interp1(t,x,tBoosterCutoff,'linear','extrap'),'--','Booster Cutoff')
    xline(interp1(t,x,tUpperStart,'linear','extrap'),'--','Centaur Ignition')
    title('Altitude vs Downrange Distance')
    xlabel('Downrange Distance (km)')
    ylabel('Altitude (km)')
    grid on

    figure('Name','Dynamic Pressure','Color','w')

    plot(h, q/1000,'LineWidth',1.5)
    title('Dynamic Pressure vs Altitude')
    xlabel('Altitude (km)')
    ylabel('Dynamic Pressure (kPa)')
    xticks(0:25:250)
    grid on

    figure('Name','Velocity vs Time')

    plot(t,v,'LineWidth',1.5)
    hold on
    yline(vCircularTarget/1000,'--','250 km Circular Velocity')
    xline(tSRBsep,'--','SRB Sep')
    xline(tBoosterCutoff,'--','Booster Cutoff')
    xline(tUpperStart,'--','Centaur Ignition')
    title('Velocity vs Time')
    xlabel('Time (s)')
    ylabel('Velocity (km/s)')
    grid on

    figure('Name','Flight Path Angle','Color','w')

    plot(t,gamma,'LineWidth',1.5)
    hold on
    yline(0,'--','Circular Orbit Flight Path Angle')
    xline(tSRBsep,'--','SRB Sep')
    xline(tBoosterCutoff,'--','Booster Cutoff')
    xline(tUpperStart,'--','Centaur Ignition')
    title('Flight Path Angle vs Time')
    xlabel('Time (s)')
    ylabel('Flight Path Angle (deg)')
    grid on

    figure('Name','Altitude vs Time','Color','w')

    plot(t,h,'LineWidth',1.5)
    hold on
    yline(hTarget/1000,'--','250 km Target Altitude')
    xline(tSRBsep,'--','SRB Sep')
    xline(tBoosterCutoff,'--','Booster Cutoff')
    xline(tUpperStart,'--','Centaur Ignition')
    title('Altitude vs Time')
    xlabel('Time (s)')
    ylabel('Altitude (km)')
    grid on

end

end