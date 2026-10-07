# Supersonic Business Jet: Takeoff and Cost Models

UTA senior design (second of two), Dragon Works (12 engineers), 2026. The team designed supersonic derivatives of the Cessna Citation X at Mach 1.6 and Mach 2.0. My disciplines were trajectory & performance and cost & market.

## Balanced_Field_Length.m

Computes the balanced field length to 14 CFR 25.109–25.113, following Phillips, *Mechanics of Flight*. It sweeps the engine-failure speed, computes accelerate-go (continue to 35 ft on the remaining engines) and accelerate-stop distances, and finds where the two curves cross. That crossing gives V1 and the balanced field length.

- **Inputs:** takeoff mass, wing area and span, takeoff CLmax, thrust, runway friction and air density (edit the INPUTS block at the top).
- **Outputs:** stall speed, liftoff speed, ground roll, V1 and balanced field length, plus the accelerate-go / accelerate-stop plot.
- **Verification:** within 8% of published takeoff lengths for the Citation X (+6.6%), Challenger 350 (−2.6%), Citation Latitude (−7.2%) and Falcon 2000LXS (+3.2%).
- **Result:** 3,916 ft for the Mach 1.6 and 4,466 ft for the Mach 2.0, against the team's 5,500 ft limit. The saved inputs reproduce the Mach 2.0 case.

Run: open the file in MATLAB and press Run.

## Roskam_SBJ_Cost_Model_2025.m

A function that applies Roskam's *Airplane Design Part VIII* development (RDTE), production and operating cost methods to one aircraft, in 2025 USD. It ran inside the team's convergence code so every converged design had a cost.

- **Outputs:** RDTE cost, production cost, airplane price, profit, cost per flight hour and block hour, and break-even quantity.
- **Result:** about $2.4B development cost for the Mach 1.6 and $4.6B for the Mach 2.0.

Example:

```matlab
[RDTE, prod, prodPerAC, AEP, profit, profitPerAC, perFlightHr, perBlockHr, breakeven] = ...
    Roskam_SBJ_Cost_Model_2025(WAMPR, MTOW, WOEW, Vmax, 'swept', TTO_total_lbf, cruiseAlt_ft, Wbl_fuel);
```

Inputs are in Roskam units (lb, kt, ft); see the header comments for each one.
