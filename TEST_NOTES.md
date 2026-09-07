# Test notes

Actual MATLAB R2025a checks performed by the main agent:

- `test_regression_dynamic` passed, including synthetic straight-line zero-event and three-wave three-event cases.
- `test_predict_trajectory_constant` passed 10 random cases; maximum difference from the reference `UAV_model` loop was `7.11e-15`.
- Three-step obstacle-free simulation regression passed (`steps == 3`, trajectory rows `== 4`).
- The first development quick run is retained as-is; it did not establish three independent detour events. No claim of three-peak repeat-scenario success is made here.

Offline fixed-window post-processing reads the existing CSV and writes grouped means/counts; it does not invoke prediction again.

## Repeated-encounter tuning boundary (2026-09-04)

- `s=[4,15,21]`, `t_cross=[3,14,24]`, alternating crossing sides, radius 1.0 m: measured `success=1`, `collisions=0`, `detourEvents=1`, event indices `[18,202]`, peak absolute lateral offset 1.825 m, minimum true clearance 0.987 m, 29 fallback steps. The second encounter prolongs the first response and the third produces only about 0.16 m lateral offset.
- A temporary DWA endpoint pull toward the original line was tested and reverted: it still gave one event but increased peak absolute lateral offset to 5.859 m with 30 fallback steps. The ablation artifacts are retained under `results/probe/*route_score_ablation*` and must not be used as final evidence.
- A milder radius 0.9 m trial produced no detour event (peak absolute lateral offset 0.25 m). Therefore the three-independent-event acceptance criterion was not met by parameter-only tuning; do not claim it as achieved without a new same-protocol run.
- Final bounded-fallback probe after the emergency-control patch completed with `success=1`, `collisions=0`, `detourEvents=0`, `minClearance=0.230 m`, `solveFailures=1`, and `fallbackSteps=1`; its trajectory and figure are in `results/probe/`. This confirms the safety/termination boundary but is not evidence of repeated visible detours.
