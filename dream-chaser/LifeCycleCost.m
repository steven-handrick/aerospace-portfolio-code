%% Total Operations Cost Model (Dream Chaser / TransCost-Based)
% This script computes:
%   1. Development Cost (Cd)
%   2. Production Cost (Cf)
%   3. Direct Operations Cost (DOC)
%   4. Refurbishment and Spares Cost (R)
%   5. Indirect Operations Cost (IOC)
%   6. Total Operations Cost (C_ops)
%   7. Current Cost Per Flight Method
%   8. 10-Year Life-Cycle Cost (LCC)
%   9. LCC-Based Cost Per Flight
%   10. Specific Transportation Cost (SpTC)
%
% All base cost outputs are in Work-Years (WYr)

clear; clc;

%% -------------------- INPUTS --------------------
% Dream Chaser / mission data
Mdry_kg     = 8211.7337;      % Dream Chaser dry mass [kg]
Mss_kg      = 3500;           % Shooting Star dry mass [kg]
Mpload_kg   = 2000;           % Dream Chaser payload mass [kg] 
Msspload_kg = 3500;           % Shooting Star payload mass [kg]
Mp_Perox_kg = 506.67;         % onboard propellant mass of Hydrogen Peroxide [kg]
Mp_RP1_kg   = 73.01;          % onboard propellant mass of RP1 [kg] 
Mp_kg       = Mp_RP1_kg + Mp_Perox_kg;  % total propellant mass [kg]
Mrec_kg     = Mdry_kg + Mpload_kg;      % recovery mass [kg]
Meng_kg     = 3.727;          % mass of each engine [kg]

% Baseline launch rate used for single-case output
L           = 6;              % launches per year

N           = 1;              % effective number of stages
Neng_ss     = 6;              % number of engines on Shooting Star
Neng_DC     = 20;             % number of engines on Dream Chaser
Neng        = Neng_DC + Neng_ss;       % total number of engines

M0_kg       = Mdry_kg + Mss_kg + Mp_kg + Mpload_kg + Msspload_kg;
% Dream Chaser & Shooting Star gross launch mass [kg]

Nfpv        = 15;             % number of flights per vehicle lifetime
Ntf         = 60;             % baseline total number of flights for current CPF method

% Convert kg -> Mg where needed
M0_Mg = M0_kg / 1000;

%% -------------------- LIFE-CYCLE COST INPUTS --------------------
ProgramYears = 10;            % [years] total program duration
L_min = 1;                    % [launches/year] minimum launch rate
L_max = 100;                   % [launches/year] maximum launch rate

Revenue_per_flight_dollar = 257271018.29;
% [$ / flight]
% Placeholder revenue per Dream Chaser mission.
% Set this to a contract value later to calculate breakeven/profit.

Dollar = 434000;              % [$ / WYr] 2025 equivalent value

%% -------------------- VULCAN LAUNCH VEHICLE --------------------
% Gross lift-off mass of Vulcan used in launch purchase cost fit
M0_Vulcan_Mg = 340;         % [Mg]

%% -------------------- COST FACTORS --------------------
% fv = launch vehicle type correction factor
% 1.0 = cryogenic liquid-propellant launch vehicle
% 0.8 = storable liquid-propellant vehicle
% 0.3 = solid-propellant vehicle
% 0.7 = automated cargo vehicle / simplified operations
% 1.8 = crewed reusable system like Shuttle
fv = 0.7;

% fc = assembly / integration mode correction factor
% 1.0  = vertical integration and checkout at launch site
% 0.85 = vertical integration in separate facility
% 0.7  = horizontal integration and checkout
fc = 0.7;

% f0 = system engineering/integration factor
% N = number of stages
f0 = 1.04^N;

% f1 = development standard factor
% 1.3-1.4 = first gen system, new concept/technology
% 1.1-1.2 = new design with new technical/operational features
% 0.9-1.1 = standard project, similar to existing operational systems
% 0.6-0.8 = design modifications to existing systems
% 0.3-0.5 = variation of existing project
f1 = 1.1;

% f2 = technical quality factor
% different for each system

% f3 = team experience factor
% 1.3-1.4 = new team, no relevant direct company experience
% 1.1-1.2 = partially new project activities for team
% 1.0     = company/industry team with some related experience
% 0.8-0.9 = team has developed similar projects
% 0.7-0.8 = team has superior experience with this type of project
f3 = 1.0;

% f4 = learning factor
% typical range: 0.70 to 0.85
f4 = 0.80;

% f5 = refurbishment fraction
% 0.013 = space shuttle without engines
% 0.023 = space shuttle with engines
f5 = 0.013;

% f6 = delayed schedule fraction
% 1-1.6 = value based on how delayed the development is
f6 = 1;

% f7 = subcontractor fraction
% n = number of parallel major contractors
% 5 = shuttle operations
n = 1;
f7 = n^0.2;

% f8 = country productivity factor
% 1.0 = United States reference
% 1.49 = Russia productivity
f8 = 1.0;

% f9 = subcontractors factor
% typical range: 1.0 to 1.83
f9 = 1.1;

% f10 = cost reduction by past experience
% typical range: 0.75 to 0.85
f10 = 0.85;

% f11 = commercial cost reduction factor
% typical range: 0.45 to 0.55 if commercial
f11 = 0.50;

% =========================================================
%% DEVELOPMENT COST
% =========================================================

%% -------------------- ENGINE DEVELOPMENT --------------------
% HE = propulsion/engine development [WYr]
% HEs = solid rocket motors
% HEs = 16.8 * Meng_kg^0.54 * f1 * f3 * f8;
% HEl = liquid rocket engines with turbopumps
% HEl = 277 * Meng_kg^0.48 * f1 * f2 * f3 * f8;
% f2 = 0.026 * (log(Nq))^2;
% Nq = number of qualification firings: 500 is average
% HEp = pressure-fed engines

HEp = 167 * Meng_kg^0.35 * f1 * f3;
HE = HEp;

%% -------------------- VEHICLE SYSTEM DEVELOPMENT --------------------
% HV = vehicle development [WYr] based on mass of system without engines

% HVe = expendable ballistic stages
% f2 = kref / keff 
% kref is from graph in textbook pg 57-58
% keff = (Mdry - Meng) / Mpropellant

kref = 0.125;

f2_HVe = kref / ((Mss_kg - Meng_kg * Neng_ss) / (Mp_Perox_kg + Mp_RP1_kg));

HVe = 98.5 * Mss_kg^0.555 * f1 * f2_HVe * f3 * f8 * f10 * f11;

% HVw = winged orbital vehicles
% f2 = kref / keff
% 5 = Dream Chaser reference value used for f2 estimate

f2_HVw = (5 / (Mdry_kg / (Mp_kg + Mpload_kg)))^2;

HVw = 1420 * (Mdry_kg - Meng_kg * Neng_DC)^0.35 * f1 * f2_HVw * f3 * f8 * f10 * f11;

HV = HVe + HVw;

%% -------------------- TOTAL DEVELOPMENT COST --------------------
Cd = f0 * (HE + HV) * f6 * f7 * f8;

% =========================================================
%% PRODUCTION COST
% =========================================================

%% -------------------- FIRST-UNIT ENGINE COST --------------------
% FEls = pressure-fed engines

FEls = 1.9 * Meng_kg^0.535 * f4 * f8 * f10 * f11;

% first-unit engine cost
FE = FEls * Neng;

%% -------------------- FIRST-UNIT VEHICLE SYSTEMS COST --------------------
% FVs = storable propellant ballistic vehicles/stages
FVs = 1.265 * (Mss_kg - Meng_kg * Neng_ss)^0.59 * f4 * f8 * f10 * f11;

% FVw = winged orbital vehicles
FVw = 5.8314 * (Mdry_kg - Meng_kg * Neng_DC)^0.6058 * f4 * f8 * f10 * f11;

% first-unit vehicle cost
FV = FVs + FVw;

%% -------------------- TOTAL PRODUCTION COST --------------------
Cf = f0^N * (FE + FV) * f9;

% =========================================================
%% OPERATION COST
% =========================================================

%% -------------------- PROP COST INPUT --------------------
% Propellant cost values (cp) (2009 USD/kg) from TransCost reference table:
%   LH2   (Liquid Hydrogen)               = 7.16  $/kg
%   LOX   (Liquid Oxygen)                 = 0.21  $/kg
%   RP-1  (Kerosene)                      = 3.2   $/kg
%   Isopropyl Alcohol                     = 2.31  $/kg
%   N2O4 (Nitrogen Tetroxide, MON-1)      = 88    $/kg
%   N2H4 (Hydrazine)                      = 340   $/kg
%   MMH  (Monomethylhydrazine)            = 340   $/kg
%   UDMH (Unsymmetrical Dimethylhydrazine)= 340   $/kg
%   Aerozine-50                           = 340   $/kg
%   H2O2 (Hydrogen Peroxide, 85%)         = 5.5   $/kg
%   Helium Gas                            = 18    $/kg
%   Nitrogen Gas                          = 0.11  $/kg
%   Hydrogen Gas                          = 10.6  $/kg

cp_Perox = 5.5;
cp_RP1 = 3.2;
WYr_2009_dollars = 286600;  % 1 WYr = $286,600 (2009)

%% -------------------- COMPLEXITY COST INPUT --------------------
% Complexity factor - add all Q values for a vehicle
% Typical Q values:
% 0.15 = small solid rocket motor stage
% 0.4  = expendable liquid-propellant stage / large booster
% 1.0  = recoverable / fly-back system
% 2.0  = unmanned reusable orbital system
% 3.0  = crewed orbital system
% 2.0  = expendable lunar transfer vehicle

Qsum = 2.0;  

% ---- Define mission type ----
crewed = false;             % set to true for crewed mission

% ---- Only needed if crewed ----
Tm = 10;                    % mission duration [days] 
Na = 4;                     % number of crew 

% =========================================================
%% BASELINE OPERATIONS COST AT SELECTED L
% =========================================================

%% Ground Operations Cost
% Cc = 8 * M0^0.67 * L^(-0.9) * N^0.7 * fv * fc * f4 * f8 * f11
% M0 in Mg

Cc = 8 * (M0_Mg^0.67) * (L^(-0.9)) * (N^0.7) * fv * fc * f4 * f8 * f11;

%% Material / Propellant Cost
% Cp = [sum (Mp * cp)] / 286600

Cp = (Mp_Perox_kg * cp_Perox + Mp_RP1_kg * cp_RP1) / WYr_2009_dollars;

%% Flight and Mission Operations Cost
% Base mission operations cost

Cm = 20 * Qsum * (L^(-0.65)) * f4 * f8;

% Crewed mission additional cost
% Cma = 75 * Tm^0.5 * Na^0.5 * L^(-0.8) * f4 * f8 * f11

if crewed
    Cma = 75 * (Tm^0.5) * (Na^0.5) * (L^(-0.8)) * f4 * f8 * f11;
    Cm_total = Cm + Cma;
else
    Cma = 0;
    Cm_total = Cm;
end

%% Transport and Recovery Cost
% Ct = (1.5/L) * (7*L^0.7 + M^0.83) * f8 * f11
% M = recovery mass in kg

%Ct = (1.5 / L) * (7 * L^0.7 + Mrec_kg^0.83) * f8 * f11;

%% Fees / Purchased Ride Launch Cost
% Vulcan Launch: Fees = 26.55 * M0_Vulcan^0.484
% M0_Vulcan in Mg, output in WYr for Vulcan Launch
% Falcon 9 Launch: Fee = 300
% Atlas Launch (HL-20): Fee = 587
% Space Shuttle: Fee = 0
% Soyuz Launch: Fee = 250

Fees = 430.9;

%% Total Direct Operations Cost
DOC = Cc + Cp + Cm_total + Fees;

%% Refurbishment and Spares Cost
% R = f5 * TFU

R = f5 * (FVw + FEls * Neng_DC);

%% Indirect Operations Cost
% IOC = 65 * L^(-0.38) for non-vertical organizations
% IOC = 42.2 * L^(-0.38) for semi-vertical organizations
% IOC = 32.5 * L^(-0.39) for vertical organizations

IOC = 65 * (L^(-0.38));

%% Total Operations Cost
% C_ops = DOC + R + IOC

C_ops = DOC + R + IOC;

% =========================================================
%% CURRENT COST PER FLIGHT METHOD
% =========================================================

% This is the original method used in the code.
% It amortizes development over Ntf and production over Nfpv.

CPF_Current = Cd / Ntf + Cf / Nfpv + C_ops;
CPF_Current_Dollar = CPF_Current * Dollar;

%% Specific Transportation Cost Using Current CPF

SpTC_Current = CPF_Current / (Mpload_kg + Msspload_kg);       % WYr/kg
SpTC_Current_Dollar = SpTC_Current * Dollar;                 % $/kg

% =========================================================
%% LIFE-CYCLE COST STUDY
% =========================================================

% Launch rate sweep
L_vec = L_min:L_max;

% Allocate arrays
Ntf_vec                    = zeros(size(L_vec));   % total flights over program
Nveh_vec                   = zeros(size(L_vec));   % number of vehicles needed

Cc_vec                     = zeros(size(L_vec));
Cp_vec                     = zeros(size(L_vec));
Cm_vec                     = zeros(size(L_vec));
Ct_vec                     = zeros(size(L_vec));
Fees_vec                   = zeros(size(L_vec));
DOC_vec                    = zeros(size(L_vec));
R_vec                      = zeros(size(L_vec));
IOC_vec                    = zeros(size(L_vec));
C_ops_vec                  = zeros(size(L_vec));

C_prod_total_vec           = zeros(size(L_vec));   % total production cost [WYr]
C_ops_total_vec            = zeros(size(L_vec));   % total operations cost [WYr]

LCC_vec                    = zeros(size(L_vec));   % total life-cycle cost [WYr]
LCC_Dollar_vec             = zeros(size(L_vec));   % total life-cycle cost [$]

CPF_Current_Sweep_vec      = zeros(size(L_vec));   % current CPF method [WYr/flight]
CPF_Current_Sweep_Dollar_vec = zeros(size(L_vec)); % current CPF method [$/flight]

CPF_LCC_vec                = zeros(size(L_vec));   % LCC-based CPF [WYr/flight]
CPF_LCC_Dollar_vec         = zeros(size(L_vec));   % LCC-based CPF [$/flight]

CPF_Difference_vec         = zeros(size(L_vec));   % LCC CPF - current CPF [WYr/flight]
CPF_Difference_Dollar_vec  = zeros(size(L_vec));   % LCC CPF - current CPF [$/flight]

SpTC_LCC_vec               = zeros(size(L_vec));   % LCC-based SpTC [WYr/kg]
SpTC_LCC_Dollar_vec        = zeros(size(L_vec));   % LCC-based SpTC [$/kg]

Revenue_vec                = zeros(size(L_vec));   % total revenue [$]
Profit_vec                 = zeros(size(L_vec));   % total profit [$]

for i = 1:length(L_vec)

    % Current launch rate
    L_loop = L_vec(i);

    % Total flights over the program life
    Ntf_loop = ProgramYears * L_loop;

    % Number of reusable Dream Chaser vehicles required
    % ceil rounds up no matter how small the decimal is.
    Nveh_loop = ceil(Ntf_loop / Nfpv);

    % -----------------------------------------------------
    % Recalculate operations cost terms that depend on L
    % -----------------------------------------------------

    % Ground Operations Cost
    Cc_loop = 8 * (M0_Mg^0.67) * (L_loop^(-0.9)) * ...
        (N^0.7) * fv * fc * f4 * f8 * f11;

    % Material / Propellant Cost
    Cp_loop = (Mp_Perox_kg * cp_Perox + Mp_RP1_kg * cp_RP1) / WYr_2009_dollars;

    % Flight and Mission Operations Cost
    Cm_loop = 20 * Qsum * (L_loop^(-0.65)) * f4 * f8;

    if crewed
        Cma_loop = 75 * (Tm^0.5) * (Na^0.5) * ...
            (L_loop^(-0.8)) * f4 * f8 * f11;
        Cm_total_loop = Cm_loop + Cma_loop;
    else
        Cm_total_loop = Cm_loop;
    end

    % Transport and Recovery Cost
    %Ct_loop = (1.5 / L_loop) * (7 * L_loop^0.7 + Mrec_kg^0.83) * f8 * f11;

    % Fees / Purchased Ride Launch Cost
    Fees_loop = 26.55 * (M0_Vulcan_Mg^0.484);

    % Total Direct Operations Cost
    DOC_loop = Cc_loop + Cp_loop + Cm_total_loop + Fees_loop;

    % Refurbishment and Spares Cost
    R_loop = f5 * (FVw + FEls * Neng_DC);

    % Indirect Operations Cost
    IOC_loop = 65 * (L_loop^(-0.38));

    % Total Operations Cost per flight
    C_ops_loop = DOC_loop + R_loop + IOC_loop;

    % -----------------------------------------------------
    % Current CPF Method
    % -----------------------------------------------------
    % This matches the original equation structure:
    % CPF = Cd/Ntf + Cf/Nfpv + C_ops
    %
    % In this sweep, Ntf changes with launch rate so the old method
    % can be compared fairly against the new LCC-based method.

    CPF_Current_Sweep = Cd / Ntf_loop + Cf / Nfpv + C_ops_loop;

    % -----------------------------------------------------
    % Life-Cycle Cost Method
    % -----------------------------------------------------

    C_prod_total_loop = Cf * Nveh_loop;
    C_ops_total_loop  = C_ops_loop * Ntf_loop;

    LCC_loop = Cd + C_prod_total_loop + C_ops_total_loop;

    % Average cost per flight from total LCC
    CPF_LCC_loop = LCC_loop / Ntf_loop;

    % The LCC-based CPF can also be written as:
    % CPF_LCC = Cd/Ntf + (Cf*Nveh)/Ntf + C_ops

    % -----------------------------------------------------
    % Dollar Conversion
    % -----------------------------------------------------

    LCC_Dollar_loop = LCC_loop * Dollar;

    CPF_Current_Sweep_Dollar = CPF_Current_Sweep * Dollar;
    CPF_LCC_Dollar_loop = CPF_LCC_loop * Dollar;

    CPF_Difference = CPF_LCC_loop - CPF_Current_Sweep;
    CPF_Difference_Dollar = CPF_Difference * Dollar;

    % -----------------------------------------------------
    % Specific Transportation Cost
    % -----------------------------------------------------

    SpTC_LCC_loop = CPF_LCC_loop / (Mpload_kg + Msspload_kg);
    SpTC_LCC_Dollar_loop = SpTC_LCC_loop * Dollar;

    % -----------------------------------------------------
    % Revenue and Profit
    % -----------------------------------------------------

    Revenue_total_loop = Revenue_per_flight_dollar * Ntf_loop;
    Profit_total_loop = Revenue_total_loop - LCC_Dollar_loop;

    % -----------------------------------------------------
    % Store Results
    % -----------------------------------------------------

    Ntf_vec(i) = Ntf_loop;
    Nveh_vec(i) = Nveh_loop;

    Cc_vec(i) = Cc_loop;
    Cp_vec(i) = Cp_loop;
    Cm_vec(i) = Cm_total_loop;
    %Ct_vec(i) = Ct_loop;
    Fees_vec(i) = Fees_loop;
    DOC_vec(i) = DOC_loop;
    R_vec(i) = R_loop;
    IOC_vec(i) = IOC_loop;
    C_ops_vec(i) = C_ops_loop;

    C_prod_total_vec(i) = C_prod_total_loop;
    C_ops_total_vec(i) = C_ops_total_loop;

    LCC_vec(i) = LCC_loop;
    LCC_Dollar_vec(i) = LCC_Dollar_loop;

    CPF_Current_Sweep_vec(i) = CPF_Current_Sweep;
    CPF_Current_Sweep_Dollar_vec(i) = CPF_Current_Sweep_Dollar;

    CPF_LCC_vec(i) = CPF_LCC_loop;
    CPF_LCC_Dollar_vec(i) = CPF_LCC_Dollar_loop;

    CPF_Difference_vec(i) = CPF_Difference;
    CPF_Difference_Dollar_vec(i) = CPF_Difference_Dollar;

    SpTC_LCC_vec(i) = SpTC_LCC_loop;
    SpTC_LCC_Dollar_vec(i) = SpTC_LCC_Dollar_loop;

    Revenue_vec(i) = Revenue_total_loop;
    Profit_vec(i) = Profit_total_loop;

end

% =========================================================
%% BREAKEVEN ANALYSIS
% =========================================================

BreakevenIndex = find(Profit_vec >= 0, 1, 'first');

if isempty(BreakevenIndex)
    BreakevenLaunchRate = NaN;
    BreakevenFlights = NaN;
else
    BreakevenLaunchRate = L_vec(BreakevenIndex);
    BreakevenFlights = Ntf_vec(BreakevenIndex);
end

% =========================================================
%% LIFE-CYCLE COST RESULTS TABLE
% =========================================================

LCC_Table = table( ...
    L_vec', ...
    Ntf_vec', ...
    Nveh_vec', ...
    LCC_vec', ...
    LCC_Dollar_vec', ...
    CPF_Current_Sweep_vec', ...
    CPF_Current_Sweep_Dollar_vec', ...
    CPF_LCC_vec', ...
    CPF_LCC_Dollar_vec', ...
    CPF_Difference_vec', ...
    CPF_Difference_Dollar_vec', ...
    SpTC_LCC_vec', ...
    SpTC_LCC_Dollar_vec', ...
    Revenue_vec', ...
    Profit_vec', ...
    'VariableNames', { ...
    'LaunchesPerYear', ...
    'TotalFlights', ...
    'VehiclesRequired', ...
    'LCC_WYr', ...
    'LCC_Dollars', ...
    'CPF_Current_WYr', ...
    'CPF_Current_Dollars', ...
    'CPF_LCC_WYr', ...
    'CPF_LCC_Dollars', ...
    'CPF_Difference_WYr', ...
    'CPF_Difference_Dollars', ...
    'SpTC_LCC_WYr_per_kg', ...
    'SpTC_LCC_Dollars_per_kg', ...
    'Revenue_Dollars', ...
    'Profit_Dollars'} );

% =========================================================
%% OUTPUTS
% =========================================================

fprintf('--------------------------------------------------\n');
fprintf('DEVELOPMENT COST BREAKDOWN\n');
fprintf('--------------------------------------------------\n');
fprintf('HE   Engine Development Cost       = %10.4f WYr\n', HE);
fprintf('HV   Vehicle Development Cost      = %10.4f WYr\n', HV);
fprintf('--------------------------------------------------\n');
fprintf('Cd   Total Development Cost        = %10.4f WYr\n', Cd);

fprintf('--------------------------------------------------\n');
fprintf('PRODUCTION COST BREAKDOWN\n');
fprintf('--------------------------------------------------\n');
fprintf('FE   Engine Production Cost        = %10.4f WYr\n', FE);
fprintf('FV   Vehicle Production Cost       = %10.4f WYr\n', FV);
fprintf('--------------------------------------------------\n');
fprintf('Cf   Total Production Cost         = %10.4f WYr\n', Cf);

fprintf('--------------------------------------------------\n');
fprintf('BASELINE OPERATIONS COST BREAKDOWN\n');
fprintf('Baseline Launch Rate               = %10.4f launches/year\n', L);
fprintf('--------------------------------------------------\n');
fprintf('Cc   Ground Operations Cost        = %10.4f WYr\n', Cc);
fprintf('Cp   Propellant Cost               = %10.4f WYr\n', Cp);
fprintf('Cm   Flight & Mission Ops Cost     = %10.4f WYr\n', Cm_total);
%fprintf('Ct   Transport & Recovery Cost     = %10.4f WYr\n', Ct);
fprintf('Fees Launch Cost                   = %10.4f WYr\n', Fees);
fprintf('--------------------------------------------------\n');
fprintf('DOC  Direct Operations Cost        = %10.4f WYr\n', DOC);
fprintf('R    Refurbishment & Spares Cost   = %10.4f WYr\n', R);
fprintf('IOC  Indirect Operations Cost      = %10.4f WYr\n', IOC);
fprintf('--------------------------------------------------\n');
fprintf('Cops Total Operations Cost         = %10.4f WYr\n', C_ops);

fprintf('--------------------------------------------------\n');
fprintf('CURRENT COST PER FLIGHT METHOD\n');
fprintf('--------------------------------------------------\n');
fprintf('Baseline Total Flights             = %10.4f flights\n', Ntf);
fprintf('Vehicle Lifetime                   = %10.4f flights/vehicle\n', Nfpv);
fprintf('CPF Current Method                 = %10.4f WYr\n', CPF_Current);
fprintf('CPF Current Method                 = %10.2f $\n', CPF_Current_Dollar);

fprintf('--------------------------------------------------\n');
fprintf('SPECIFIC TRANSPORTATION COST, CURRENT METHOD\n');
fprintf('--------------------------------------------------\n');
fprintf('SpTC Current Method                = %10.4f WYr/kg\n', SpTC_Current);
fprintf('SpTC Current Method                = %10.2f $/kg\n', SpTC_Current_Dollar);

fprintf('--------------------------------------------------\n');
fprintf('10-YEAR LIFE-CYCLE COST STUDY\n');
fprintf('--------------------------------------------------\n');
fprintf('Program Duration                   = %10.4f years\n', ProgramYears);
fprintf('Launch Rate Range                  = %10.0f to %0.0f launches/year\n', L_min, L_max);
fprintf('Revenue Per Flight                 = %10.2f $\n', Revenue_per_flight_dollar);

if isnan(BreakevenLaunchRate)
    fprintf('No breakeven occurs between %d and %d launches/year.\n', L_min, L_max);
else
    fprintf('Breakeven Launch Rate              = %10.0f launches/year\n', BreakevenLaunchRate);
    fprintf('Breakeven Total Flights            = %10.0f flights over %d years\n', BreakevenFlights, ProgramYears);
end

fprintf('--------------------------------------------------\n');
fprintf('LIFE-CYCLE COST TABLE\n');
fprintf('--------------------------------------------------\n');

disp(LCC_Table);

% =========================================================
%% LIFE-CYCLE COST PLOTS
% =========================================================

figure;
plot(L_vec, LCC_Dollar_vec, 'LineStyle', 'none', 'Marker', '.');
xlabel('Launches per Year');
ylabel('10-Year Life-Cycle Cost [$]');
title('10-Year Life-Cycle Cost vs. Launch Rate');
grid on;

figure;
plot(L_vec, CPF_Current_Sweep_Dollar_vec, 'LineStyle', 'none', 'Marker', '.');
hold on;
plot(L_vec, CPF_LCC_Dollar_vec, 'LineStyle', 'none', 'Marker', '.');
xlabel('Launches per Year');
ylabel('Cost per Flight [$ / flight]');
title('Current CPF Method vs. LCC-Based CPF Method');
legend('Current CPF Method', 'LCC-Based CPF Method', 'Location', 'best');
grid on;

figure;
plot(L_vec, CPF_Difference_Dollar_vec, 'LineStyle', 'none', 'Marker', '.');
xlabel('Launches per Year');
ylabel('CPF Difference [$ / flight]');
title('CPF Difference: LCC-Based CPF - Current CPF');
grid on;

figure;
plot(L_vec, SpTC_LCC_Dollar_vec, 'LineStyle', 'none', 'Marker', '.');
xlabel('Launches per Year');
ylabel('Specific Transportation Cost [$ / kg]');
title('LCC-Based Specific Transportation Cost vs. Launch Rate');
grid on;

figure;
plot(L_vec, Profit_vec, 'Color','k', 'LineStyle', 'none', 'Marker', '.');
xlabel('Launches per Year');
ylabel('10-Year Profit [$]');
title('10-Year Profit vs. Launch Rate');
grid on;