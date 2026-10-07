function [RDTECost, productionCost, productionCostperAircraft, AEP, totalProfit, ProfitperAircraft, ...
          USD_per_flight_hr, USD_per_block_hr, breakevenAircraft] = ...
    Roskam_SBJ_Cost_Model_2025(WAMPR, MTOW, WOEW, Vmax, wingType, ...
        TTO_total_lbf, cruiseAltitude_ft, Wbl_fuel)
%ROSKAM_SBJ_COST_MODEL_2025_V4 Roskam Part VIII cost model for the Dragon Works SSBJ.
%
% INPUTS (Roskam units)
%   WAMPR    - Aeronautical Manufacturers Planning Report weight, lb
%   MTOW     - Maximum takeoff weight, lb
%   WOEW     - Operating empty weight, including engines, lb
%   Vmax          - Maximum/design cruise speed used by Roskam, kt
%   wingType       - 'swept' or 'ogive'
%   TTO_total_lbf   - Total installed takeoff thrust from all engines, lbf
%   cruiseAltitude_ft- Design cruise altitude for the mission, ft
%   Wbl_fuel         - Block fuel consumed for the mission, lb
%
% OUTPUTS (2025 USD)
%   RDTECost          - Total research, development, test, and evaluation cost
%   productionCost    - Total manufacturing-program cost, including financing
%                       but excluding manufacturer profit and RDTE recovery
%   AEP               - Airplane estimated price, USD/aircraft
%   totalProfit       - Total manufacturer production profit over Nm aircraft
%   ProfitperAircraft  - Manufacturer production profit per aircraft
%   USD_per_flight_hr - Total operating cost allocated per airborne flight hour
%   USD_per_block_hr  - Total operating cost per block hour
%   breakevenAircraft  - Minimum whole aircraft sales required for cumulative
%                        revenue to cover RDTE plus average production cost

    narginchk(8, 8);
    validateattributes(WAMPR, {'numeric'}, {'real','finite','scalar','positive'}, mfilename, 'WAMPR', 1);
    validateattributes(MTOW,  {'numeric'}, {'real','finite','scalar','positive'}, mfilename, 'MTOW',  2);
    validateattributes(WOEW,  {'numeric'}, {'real','finite','scalar','positive'}, mfilename, 'WOEW',  3);
    validateattributes(Vmax, {'numeric'}, {'real','finite','scalar','positive'}, mfilename, 'Vmax', 4);
    wingType = validatestring(wingType, {'swept','ogive'}, mfilename, 'wingType', 5);
    validateattributes(TTO_total_lbf, {'numeric'}, ...
        {'real','finite','scalar','positive'}, mfilename, 'TTO_total_lbf', 6);
    validateattributes(cruiseAltitude_ft, {'numeric'}, ...
        {'real','finite','scalar','>=',10000,'<=',60000}, ...
        mfilename, 'cruiseAltitude_ft', 7);
    validateattributes(Wbl_fuel, {'numeric'}, ...
        {'real','finite','scalar','positive'}, mfilename, 'Wbl_fuel', 8);

    if WOEW >= MTOW
        error('RoskamSBJ:InvalidWeight', 'WOEW must be less than MTOW.');
    end

    if Wbl_fuel >= (MTOW - WOEW)
        warning('RoskamSBJ:HighBlockFuel', ...
            ['Wbl_fuel is greater than or equal to MTOW-WOEW. ', ...
             'Check that block fuel is mission fuel burned, not total fuel capacity.']);
    end

    %% ================================================================
    %  FIXED AIRCRAFT AND PROGRAM ASSUMPTIONS
    %  ================================================================
    p.Npax     = 12;
    p.Neng     = 2;
    p.Nprop    = 0;

    % RDTE and production quantities
    p.Nrdte    = 6;       % Six flying test aircraft plus two static articles
    p.Nst      = 2;
    p.Nm       = 175;
    p.Nr       = 0.33;    % RDTE production rate, aircraft/month
    p.Nm_rate  = 3;       % Full-rate production, aircraft/month
    p.Nacq     = p.Nm;
    p.Nyr      = 20;

    p.Nprogram = p.Nrdte + p.Nm;
    p.Nfly_rdte = p.Nrdte - p.Nst;

    %% ================================================================
    %  2025 COST ESCALATION BASIS
    %  ================================================================
    % Roskam CEF values are anchored to CEF_1970 = 1.0. The 1992 Roskam
    % value is extended to 2025 using the NASA NNSI 1992-to-2025 ratio.
    p.CEF_Roskam_1989   = 3.02;
    p.CEF_Roskam_1990   = 3.05;
    p.CEF_Roskam_1992   = 3.10;
    p.NNSI_1992_to_2025 = 2.4307385532853107;
    p.CEF                = p.CEF_Roskam_1992 * p.NNSI_1992_to_2025;
    p.CEF_1990_to_2025   = p.CEF / p.CEF_Roskam_1990;

    %% ================================================================
    %  LABOR RATES AND ROSKAM JUDGMENT FACTORS
    %  ================================================================
    % Fully burdened aerospace labor rates, 2025 USD/manhour
    p.Re_r = 155;
    p.Rm_r = 90;
    p.Rt_r = 110;
    p.Re_m = p.Re_r;
    p.Rm_m = p.Rm_r;
    p.Rt_m = p.Rt_r;

    switch wingType
        case 'swept'
            p.Fdiff = 1.5;
            % Calibrated to business-jet direct-climb data near FL400-FL430.
            p.avgClimbRate_fpm = 1750;
            p.Uann_bl   = 620;
        case 'ogive'
            p.Fdiff = 1.75;
            % Higher cruise altitude includes slower upper-climb performance.
            p.avgClimbRate_fpm = 1500;
            p.Uann_bl   = 560;

    end

    p.Fcad   = 0.8;    % Experienced CAD organization
    p.Fmat   = 2.0;    % Carbon-composite airframe
    p.Fobs   = 1.0;    % Non-stealth commercial aircraft
    p.Ftsf   = 0.0;    % No separately estimated new test facility
    p.Fpro_r = 0.0;    % No RDTE profit
    p.Ffin_r = 0.15;
    p.Ffin_m = 0.15;
    p.Fpro_m = 0.20;   % Markup on total manufacturing cost

    %% ================================================================
    %  VENDOR ITEMS AND INTERIOR
    %  ================================================================
    p.Fint_1990 = 3000;  % Roskam business-jet interior, 1990 USD/passenger

    % Modified non-afterburning F100-PW-229 derivative, 2025 USD/engine
    p.Ce_r = 8.7e6;
    p.Ce_m = 8.7e6;
    p.Cp_r = 0;
    p.Cp_m = 0;

    % Citation X+/G5000-class integrated avionics, 2025 USD/aircraft
    p.Cav_r = 622000;
    p.Cav_m = 622000;

    p.EP  = p.Ce_m;   % Engine price used by Ch. 5
    p.PP  = p.Cp_m;
    p.ASP = p.Cav_m;  % Avionics price used by Ch. 5

    %% ================================================================
    %  PRODUCTION FLIGHT-TEST ASSUMPTIONS
    %  ================================================================
    p.Tpft  = 10;     % Flight-test hours before delivery
    p.Fftoh = 4.0;    % Production flight-test overhead factor
    % Cops_hr_prodtest is deliberately not an input. It is iterated to the
    % total operating cost per block hour calculated by Chapter 5.

    %% ================================================================
    %  OPERATING-COST ASSUMPTIONS NOT YET SUPPLIED BY VEHICLE CODE
    %  ================================================================
    p.Rbl       = 3130;          % Teterboro-to-London-Luton block distance, nm
    p.routeFlag = 'international';
    p.Vcl       = 420;           % Average horizontal climb speed, kt
    p.Vde       = 360;           % Average horizontal descent speed, kt
    p.Vman      = 250;           % Maneuvering speed, kt

    % Preliminary altitude-based climb/descent estimates. These should be
    % replaced by trajectory-model times once those are available.
    p.cruiseAltitude_ft = cruiseAltitude_ft;
    p.avgDescentRate_fpm = 2000;
    p.Tcl = p.cruiseAltitude_ft/(p.avgClimbRate_fpm*60);
    p.Tde = p.cruiseAltitude_ft/(p.avgDescentRate_fpm*60);

    % Cockpit crew: [captain, first officer, flight engineer]
    p.crew.n   = [1, 1, 0];
    p.crew.K   = [0.40, 0.40, 0.40];
    p.crew.SAL = [225000, 165000, 0];
    p.crew.AH  = [p.Uann_bl, p.Uann_bl, 750];
    p.crew.TEF = [27, 27, 0];

    % Fuel and oil. Block fuel is supplied by the vehicle/mission analysis so
    % the swept- and ogive-wing designs can use different mission fuel burns.
    p.Wbl_fuel        = Wbl_fuel;  % Block fuel consumed, lb
    p.FP              = 6.00;   % Jet-A price, 2025 USD/US gal
    p.FD              = 6.74;   % Jet-A density, lb/US gal
    p.useOilAlternate = true;
    p.Wbl_oil         = 0;
    p.OLP             = 20;
    p.OD              = 7.74;

    % Hull insurance
    p.fins_hull = 0.015;

    %% ================================================================
    %  MAINTENANCE ASSUMPTIONS AND ENGINE DATA
    %  ================================================================
    p.Weng = 3036.008;       % Weight of one modified engine, lb
    p.TTO_total_lbf = TTO_total_lbf; % Total installed takeoff thrust, lbf
    p.Hem  = 4000;          % Effective hours between engine overhauls

    if WOEW <= p.Neng*p.Weng
        error('RoskamSBJ:InvalidEmptyWeight', ...
              'WOEW must exceed the total installed engine weight.');
    end

    % Base labor rates chosen so the Roskam labor burden gives an effective
    % 2025 business-aviation service-center rate near 166 USD/manhour.
    p.Rap      = 83;
    p.Reng     = 83;
    p.famb_lab = 1.00;
    p.famb_mat = 0.35;
    p.ESPPF    = 1.50;

    %% ================================================================
    %  DEPRECIATION AND OTHER OPERATING FACTORS
    %  ================================================================
    p.F_dap    = 0.70; p.DPap     = 10;
    p.F_deng   = 0.70; p.DPeng    = 7;
    p.F_dprp   = 0.85; p.DPprp    = 7;
    p.F_dav    = 1.00; p.DPav     = 5;
    p.F_dapsp  = 0.85; p.DPapsp   = 10;
    p.F_dengsp = 0.85; p.DPengsp  = 7;
    p.Fapsp    = 0.10;
    p.Fengsp   = 0.10;

    % Historical Roskam operating relationships retained pending later audit
    p.Caplf    = 0.002 * MTOW * p.CEF / p.CEF_Roskam_1989;
    p.Capnf    = 0;
    p.frt      = 0.001 + 1.0e-8*MTOW;
    p.ffin_DOC = 0.07;
    p.fioc     = 0.0;  % Corporate/personal aircraft assumption

    %% ================================================================
    %  CHAPTER 3: RDTE COST
    %  ================================================================
    % Eqs. 3.2-3.3: airframe engineering and design
    MHR_aed_r = 0.0396 * WAMPR^0.791 * Vmax^1.526 * ...
                p.Nrdte^0.183 * p.Fdiff * p.Fcad;
    Caed_r = MHR_aed_r * p.Re_r;

    % Eq. 3.7: development support and testing
    Cdst_r = 0.008325 * WAMPR^0.873 * Vmax^1.890 * ...
             p.Nrdte^0.346 * p.CEF * p.Fdiff;

    % Eq. 3.9: engines and avionics for flying RDTE aircraft
    Ce_a_r = (p.Ce_r*p.Neng + p.Cp_r*p.Nprop + p.Cav_r) * p.Nfly_rdte;

    % Eqs. 3.10-3.11: manufacturing labor for test aircraft
    MHR_man_r = 28.984 * WAMPR^0.740 * Vmax^0.543 * ...
                p.Nrdte^0.524 * p.Fdiff;
    Cman_r = MHR_man_r * p.Rm_r;

    % Eq. 3.12: materials for test aircraft
    Cmat_r = 37.632 * p.Fmat * WAMPR^0.689 * Vmax^0.624 * ...
             p.Nrdte^0.792 * p.CEF;

    % Eqs. 3.13-3.14: RDTE tooling
    MHR_tool_r = 4.0127 * WAMPR^0.764 * Vmax^0.899 * ...
                 p.Nrdte^0.178 * p.Nr^0.066 * p.Fdiff;
    Ctool_r = MHR_tool_r * p.Rt_r;

    % Eq. 3.15: quality control
    Cqc_r = 0.13 * Cman_r;

    % Eq. 3.8: flight-test airplanes
    Cfta_r = Ce_a_r + Cman_r + Cmat_r + Ctool_r + Cqc_r;

    % Eq. 3.16: flight-test operations
    Cfto_r = 0.001244 * WAMPR^1.160 * Vmax^1.371 * ...
             p.Nfly_rdte^1.281 * p.CEF * p.Fdiff * p.Fobs;

    % Eqs. 3.17-3.19: solve fractions of total RDTE algebraically
    frac_rdte = p.Ftsf + p.Fpro_r + p.Ffin_r;
    if frac_rdte >= 1
        error('RoskamSBJ:InvalidRDTEFractions', ...
              'Ftsf + Fpro_r + Ffin_r must be less than one.');
    end

    Crdte_known = Caed_r + Cdst_r + Cfta_r + Cfto_r;
    RDTECost = Crdte_known / (1 - frac_rdte);

    %% ================================================================
    %  CHAPTER 4 TERMS INDEPENDENT OF PRODUCTION FLIGHT-TEST COST
    %  ================================================================
    % Eqs. 4.5-4.6: production engineering and design
    MHR_aed_program = 0.0396 * WAMPR^0.791 * Vmax^1.526 * ...
                      p.Nprogram^0.183 * p.Fdiff * p.Fcad;
    Caed_m = MHR_aed_program * p.Re_m - Caed_r;

    % Eq. 4.8: production engines and avionics
    Ce_a_m = (p.Ce_m*p.Neng + p.Cp_m*p.Nprop + p.Cav_m) * p.Nm;

    % Eq. 4.9: production interiors, correctly escalated from 1990
    Cint_m = p.Fint_1990 * p.Npax * p.Nm * p.CEF_1990_to_2025;

    % Eqs. 4.10-4.11: production manufacturing labor
    MHR_man_program = 28.984 * WAMPR^0.740 * Vmax^0.543 * ...
                      p.Nprogram^0.524 * p.Fdiff;
    Cman_m = MHR_man_program * p.Rm_m - Cman_r;

    % Eqs. 4.12-4.13: production materials
    Cmat_program = 37.632 * p.Fmat * WAMPR^0.689 * Vmax^0.624 * ...
                   p.Nprogram^0.792 * p.CEF;
    Cmat_m = Cmat_program - Cmat_r;

    % Eqs. 4.14-4.15: production tooling
    MHR_tool_program = 4.0127 * WAMPR^0.764 * Vmax^0.899 * ...
                       p.Nprogram^0.178 * p.Nm_rate^0.066 * p.Fdiff;
    Ctool_m = MHR_tool_program * p.Rt_m - Ctool_r;

    % Eq. 4.16: production quality control
    Cqc_m = 0.13 * Cman_m;

    % Eq. 4.7: production-airplane cost excluding production flight testing
    Capc_m = Ce_a_m + Cint_m + Cman_m + Cmat_m + Ctool_m + Cqc_m;
    Cmanuf_before_prodtest = Caed_m + Capc_m;

    %% ================================================================
    %  COUPLED CHAPTER 4 / CHAPTER 5 SOLUTION
    %  ================================================================
    % Production flight-test cost uses the Chapter 5 operating cost per block
    % hour. AEP also affects insurance, depreciation, and maintenance materials.
    % A fixed-point iteration resolves this small circular dependency.
    maxIterations = 100;
    tolerance = 1.0e-8;
    relaxation = 0.5;
    Cops_hr_prodtest = 0;

    for iteration = 1:maxIterations
        Cfto_m = p.Nm * Cops_hr_prodtest * p.Tpft * p.Fftoh;

        productionCost = (Cmanuf_before_prodtest + Cfto_m) / (1 - p.Ffin_m);
        totalProfit = p.Fpro_m * productionCost;
        CACA = productionCost + totalProfit;
        AEP = (CACA + RDTECost) / p.Nm;

        [newFlightHrCost, newBlockHrCost] = ...
            calculateOperatingCosts(AEP, MTOW, WOEW, Vmax, p);

        scale = max(1, abs(newBlockHrCost));
        if abs(newBlockHrCost - Cops_hr_prodtest) <= tolerance*scale
            Cops_hr_prodtest = newBlockHrCost;
            break;
        end

        Cops_hr_prodtest = relaxation*newBlockHrCost + ...
                           (1-relaxation)*Cops_hr_prodtest;
    end

    if iteration == maxIterations
        warning('RoskamSBJ:NoConvergence', ...
                'Production/operating-cost iteration reached the maximum iteration count.');
    end

    % Final internally consistent calculation using the converged operating cost
    Cfto_m = p.Nm * Cops_hr_prodtest * p.Tpft * p.Fftoh;
    productionCost = (Cmanuf_before_prodtest + Cfto_m) / (1 - p.Ffin_m);
    productionCostperAircraft = productionCost / p.Nm;
    totalProfit = p.Fpro_m * productionCost;
    ProfitperAircraft = totalProfit / p.Nm;
    CACA = productionCost + totalProfit;
    AEP = (CACA + RDTECost) / p.Nm;

    %% ================================================================
    %  PROGRAM BREAK-EVEN QUANTITY
    %  ================================================================
    % Break-even occurs when cumulative sales revenue covers RDTE and the
    % average production cost of the aircraft sold:
    %
    %   N*AEP >= RDTECost + N*productionCostperAircraft
    %
    % This uses the program-average production cost calculated for p.Nm
    % aircraft. The ceiling function returns the first whole aircraft sale
    % that reaches or exceeds break-even.
    contributionMarginPerAircraft = AEP - productionCostperAircraft;

    if contributionMarginPerAircraft <= 0
        breakevenAircraft = Inf;
        warning('RoskamSBJ:NoBreakeven', ...
                ['AEP does not exceed the average production cost per aircraft. ', ...
                 'The program cannot break even under the current assumptions.']);
    else
        breakevenAircraft = ceil(RDTECost / contributionMarginPerAircraft);
    end

    [USD_per_flight_hr, USD_per_block_hr] = ...
        calculateOperatingCosts(AEP, MTOW, WOEW, Vmax, p);
end


function [USD_per_flight_hr, USD_per_block_hr] = ...
    calculateOperatingCosts(AEP, MTOW, WOEW, Vmax, p)
%CALCULATEOPERATINGCOSTS Roskam Chapter 5 commercial operating cost.

    %% Block-time calculation, Eqs. 5.7 and 5.9-5.13
    Vcr = Vmax;
    Tgm  = 0.51e-6*MTOW + 0.125;
    Rcl  = p.Vcl*p.Tcl;
    Rde  = p.Vde*p.Tde;
    Tman = 0.25e-6*MTOW + 0.0625;
    Rman = p.Vman*Tman;

    switch p.routeFlag
        case 'domestic'
            routeFactor = 1.06;
        case 'international'
            routeFactor = 1.01;
        otherwise
            error('RoskamSBJ:InvalidRoute', 'Unknown routeFlag.');
    end

    Tcr = (routeFactor*p.Rbl - Rcl - Rde + Rman)/Vcr;
    if Tcr <= 0
        error('RoskamSBJ:InvalidCruiseTime', ...
              'Calculated cruise time is nonpositive. Check MTOW, Vmax, and mission assumptions.');
    end

    Tbl  = Tgm + p.Tcl + Tcr + p.Tde;
    Tflt = p.Tcl + Tcr + p.Tde;
    Vbl  = p.Rbl/Tbl;
    Vflt = p.Rbl/Tflt;
    Rbl_ann = Vbl*p.Uann_bl;

    %% Crew cost per nautical mile, Eq. 5.21
    Ccrew = 0;
    for j = 1:numel(p.crew.n)
        Ccrew = Ccrew + p.crew.n(j) * ...
            (((1+p.crew.K(j))/Vbl)*(p.crew.SAL(j)/p.crew.AH(j)) + ...
             p.crew.TEF(j)/Vbl);
    end

    %% Fuel and oil cost per nautical mile, Eqs. 5.25 and 5.30
    if p.useOilAlternate
        Cpol = 1.05*(p.Wbl_fuel/p.Rbl)*(p.FP/p.FD);
    else
        Cpol = (p.Wbl_fuel/p.Rbl)*(p.FP/p.FD) + ...
               (p.Wbl_oil/p.Rbl)*(p.OLP/p.OD);
    end

    %% Hull insurance, Eq. 5.31
    AMP = AEP;
    Cins_ann = p.fins_hull*AMP;
    Cins = Cins_ann/Rbl_ann;

    %% Maintenance manhours, Figs. 5.5-5.6
    WA = WOEW - p.Neng*p.Weng;
    MHRap_bl = 3.0 + 0.067*(WA/1000);

    TTO_eng_lbf = p.TTO_total_lbf/p.Neng;
    MHReng_bl = (0.4956 + 0.0532*(TTO_eng_lbf/1000)) * ...
                (1100/p.Hem) + 0.10;

    %% Maintenance materials, Figs. 5.8-5.9 and Eq. 5.39
    ATF = 1.0;  % Turbine airplane above 10,000 lb
    AFP = max(AEP - p.Neng*p.EP, 0);

    Cmat_ap_blhr = 30*(p.CEF/p.CEF_Roskam_1989)*ATF + ...
                    0.79e-5*AFP;

    KHem = 0.202*(p.Hem/1000) + 0.763;
    Cmat_eng_blhr = ((5.43e-5*p.EP)*p.ESPPF - 0.47)/KHem;

    %% Direct maintenance cost per nautical mile, Eqs. 5.34-5.39
    Clab_ap  = 1.03*MHRap_bl*p.Rap/Vbl;
    Clab_eng = 1.03*1.3*p.Neng*MHReng_bl*p.Reng/Vbl;
    Cmat_ap  = 1.03*Cmat_ap_blhr/Vbl;
    Cmat_eng = 1.03*1.3*p.Neng*Cmat_eng_blhr/Vbl;

    Camb = 1.03 * (...
        p.famb_lab*(MHRap_bl*p.Rap + p.Neng*MHReng_bl*p.Reng) + ...
        p.famb_mat*(Cmat_ap_blhr + p.Neng*Cmat_eng_blhr)) / Vbl;

    DOC_maint = Clab_ap + Clab_eng + Cmat_ap + Cmat_eng + Camb;

    %% Direct operating cost of flying, Eq. 5.20
    DOC_flt = Ccrew + Cpol + Cins;

    %% Depreciation, Eqs. 5.40-5.46
    airframePrice = max(AEP - p.Neng*p.EP - p.Nprop*p.PP - p.ASP, 0);
    airplaneSparesBasis = max(AEP - p.Neng*p.EP, 0);

    Cdap = p.F_dap*airframePrice / ...
           (p.DPap*p.Uann_bl*Vbl);
    Cdeng = p.F_deng*(p.Neng*p.EP) / ...
            (p.DPeng*p.Uann_bl*Vbl);
    Cdprp = p.F_dprp*(p.Nprop*p.PP) / ...
            (p.DPprp*p.Uann_bl*Vbl);
    Cdav = p.F_dav*p.ASP / ...
           (p.DPav*p.Uann_bl*Vbl);
    Cdapsp = p.F_dapsp*p.Fapsp*airplaneSparesBasis / ...
             (p.DPapsp*p.Uann_bl*Vbl);
    Cdengsp = p.F_dengsp*p.Fengsp*p.Neng*p.EP*p.ESPPF / ...
              (p.DPengsp*p.Uann_bl*Vbl);

    DOC_depr = Cdap + Cdeng + Cdprp + Cdav + Cdapsp + Cdengsp;

    %% Landing fees, navigation fees, registry taxes, and financing
    Clf = p.Caplf/p.Rbl;
    Cnf = p.Capnf/p.Rbl;

    recursiveFraction = p.frt + p.ffin_DOC;
    if recursiveFraction >= 1
        error('RoskamSBJ:InvalidDOCFractions', ...
              'Registry-tax and DOC-financing fractions must sum to less than one.');
    end

    DOC_fixed = DOC_flt + DOC_maint + DOC_depr + Clf + Cnf;
    DOC = DOC_fixed/(1-recursiveFraction);

    %% Indirect and total operating cost
    IOC = p.fioc*DOC;
    TOC_per_nm = DOC + IOC;

    USD_per_block_hr  = TOC_per_nm*Vbl;
    USD_per_flight_hr = TOC_per_nm*Vflt;
end
