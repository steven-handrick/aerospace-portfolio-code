# Dream Chaser: Mission and Cost Models

UTA senior design (first of two), Squirrel Works (12 engineers), Spring 2026. The team reconstructed Sierra Space's Dream Chaser cargo spaceplane from public data. My disciplines were trajectory & performance and cost & market.

## Ascent.m

Staged gravity-turn ascent simulation of the Vulcan Centaur VC4L (four solid boosters, core stage, Centaur upper stage) using published thrust, mass and burn times, integrated with `ode45`. Upper-stage guidance holds the target altitude while the stage builds horizontal speed.

- **Result:** 250.6 km altitude, 7.755 km/s (circular velocity), 0.03° flight-path angle, using 839.4 s of 984.6 s of Centaur burn time.
- **Simplifications:** constant thrust per stage, non-rotating Earth, exponential atmosphere. Earth's rotation would help, so the margin is conservative.

## MissionWeightRatio.m

`[WR, ff, out] = MissionWeightRatio(h)` turns the on-orbit maneuvers into ΔV and a weight ratio with the rocket equation: a Hohmann transfer from an `h` km circular orbit up to the 400 km ISS orbit, then a deorbit burn to a −1.5° entry flight-path angle at 120 km.

- **Example:** `MissionWeightRatio(250)` for the 250 km insertion orbit.
- **Verification:** predicted weight ratios for the Space Shuttle, Cargo Dragon and HL-20 were 8.8%, 4.8% and 2.1% below actual. The model computes ideal ΔV, and real vehicles carry reserve, attitude-control and rendezvous propellant, so a consistent low bias is expected.

## GlideRange.m

Estimates lifting-body glide range across the hypersonic, supersonic and subsonic regimes from the L/D in each. Set the three L/D values in the INPUTS block.

- **Verification:** 5.4% error on the Space Shuttle and 5.7% on the HL-20.

## LifeCycleCost.m

TransCost-based operations and life-cycle cost model for Dream Chaser and its Shooting Star module: direct and indirect operations cost, refurbishment and spares, 10-year life-cycle cost, cost per flight, cost per kg, and profit versus launch cadence.

- **Verification:** within 8.4% of published cost per flight and cost per kg for Cygnus and Cargo Dragon.
- **Finding:** the baseline predicts a $15.7B loss over 10 years. Tracing it showed the clean-sheet development-cost relationship ignores Dream Chaser's HL-20 and SpaceDev heritage, which overstates development cost.
