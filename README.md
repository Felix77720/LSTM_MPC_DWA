# LSTM-Prediction-Enhanced MPC-DWA UAV Dynamic Obstacle Avoidance

This repository contains the LSTM-enhanced extension of the reproduced
`MPC_DWA_Fusion` baseline (bidirectionally coupled MPC planning and DWA
execution in MATLAB + CasADi). It adds LSTM prediction of dynamic obstacle
trajectories and time-varying collision-constraint injection for the
experiments in an EI conference paper.

## Dependencies

- MATLAB R2025a or a compatible release
- CasADi 3.8.0 (install under `MPC_DWA_Fusion/third_party`; see the local
  directory README for the expected layout)
- Deep Learning Toolbox (installed)

## Design Choice

LSTM training and inference use the MATLAB Deep Learning Toolbox directly,
without a PyTorch-to-ONNX bridge. Reasons:

1. The baseline is entirely MATLAB + CasADi. Keeping the predictor in MATLAB
   avoids cross-language serialization overhead at every control step, which
   is relevant because per-step time is a reported metric.
2. `trainNetwork`, `lstmLayer`, `sequenceInputLayer`, and `regressionLayer`
   are available, while `importNetworkFromONNX` is not installed, PyTorch/ONNX
   are not installed, and network access is restricted.
3. The model is small (many-to-one LSTM: past 1 s to future 3 s positions),
   so MATLAB is sufficient and simplifies reproduction by reviewers.

## Running

In MATLAB, change the current folder to the cloned repository:

```matlab
cd('<path-to-cloned-LSTM_MPC_DWA>')
run_experiments
```

Outputs are written to `results/`: `metrics.csv`, per-scenario 3D trajectory
PNGs, prediction-comparison PNGs, and `lstm_predictor.mat`.

For the publication protocol, run `run_multiseed` after the model is trained.
It writes 48 matched closed-loop rows (4 scenarios x 3 seeds x 4 methods) to
`results/multiseed_comparison.csv` and the descriptive method summary to
`results/multiseed_summary.csv`. `run_robustness_experiments` adds the S4
5-cm-observation-noise plus one-step-delay stress test; each run now generates
one fixed noisy observation stream shared by MPC and DWA. The current Chinese
manuscript and archived result tables are kept outside this code-only
repository in the local archive/reproducibility package.

## Directory Structure

- `run_experiments.m`: main entry point (data generation -> training ->
  four-method comparison -> ablation -> visualization).
- `config_LSTM.m`: extended configuration.
- `generate_obstacle_trajectory.m` / `generate_training_data.m` /
  `generate_eval_scenarios.m`: independent dynamic obstacle trajectory
  generation (not coupled to the ego vehicle).
- `build_lstm_network.m` / `train_lstm_predictor.m` /
  `predict_obstacle_traj.m`: LSTM predictor and unified prediction interface.
- `MPC_UAV_dynamic.m`: MPC layer that turns predicted positions into
  time-varying soft collision constraints.
- `simulate_dynamic.m`: closed-loop simulation for one scenario and one
  method (MPC time-varying constraints; DWA obstacle scoring uses the minimum
  clearance over the prediction window).
- `computeTrust_dynamic.m`: trust computation for the time-varying obstacle
  version.
- `visualize_scenario.m` / `visualize_prediction.m`: trajectory and prediction
  visualization.

## Comparison and Metrics

Comparison groups:

1. `static`: treats each moving obstacle as its current static position
   (baseline behavior).
2. `cv`: constant-velocity extrapolation.
3. `kalman`: constant-velocity Kalman filter baseline.
4. `lstm`: proposed method.

Metrics: obstacle avoidance success rate, collision count, minimum safe
distance, path length, tracking error (RMSE from the start-goal line),
per-step computation time, and prediction ADE/FDE.

Ablation:

- Prediction on/off: `static` vs. `lstm`.
- Prediction horizon length: `cfg.dyn.injectHorizon` in {10, 20, 30}
  (look-ahead steps injected into MPC/DWA).

## Current evidence summary

The current publication protocol uses future-state time alignment, cached
CasADi MPC compilation, a positive safety-margin penalty, a 3-D route-recovery
soft cost and a 0.25-m DWA candidate-rejection threshold. In the 3-seed main
comparison (12 runs per method), success is static 10/12, CV 9/12, Kalman
9/12 and LSTM 12/12. Mean true minimum clearance is 0.688, 0.665, 0.528 and
0.967 m respectively. These are simulation results under clean observations,
not evidence of universal real-time or flight performance.

The fixed-window prediction evaluation contains 340 overlapping windows per
method. Static/CV/Kalman/LSTM ADE-FDE are 2.07/3.92, 0.51/1.23, 0.56/1.31
and 0.49/1.14 m. Overlapping windows are descriptive prediction measurements,
not independent replicates. The unified sensing suite is a single fixed S4
scene with six obstacles, four conditions, three seeds and four methods (48
rows) at `results/robustness_unified/sensing_20260906_160557`; LSTM succeeds
2/3, 2/3, 2/3 and 1/3 across clean, noise-only, delay-only and joint
conditions. The joint result is a boundary observation, not a universal
robustness claim.

The expanded random suite contains 12 fixed-seed scenes × 3 run seeds × 4
methods = 144 closed-loop trials. Success is static 26/36, CV 33/36, Kalman
33/36 and LSTM 36/36; full per-run failure and timing data are in the separate
reproducibility data package.

Run the multi-seed comparison with:

```matlab
cd('<path-to-cloned-LSTM_MPC_DWA>')
run_multiseed
```

Outputs: `results/multiseed_comparison.csv` and
`results/multiseed_summary.csv`.

## Obstacle Trajectories

### Repeated-encounter validation scene

`generate_repeat_scenario.m` creates three ego-independent sine-speed obstacles
at fixed along-track locations and crossing times (3.5/12/20 m and 6/22/38 s,
with alternating sides). The trajectory is generated before the closed-loop
simulation; its speed variation makes constant-velocity prediction a genuine
negative control. The pilot supplemental run also records the repeat-scene
route-weight, MPC-only/DWA-only injection, and H=10/20/30 horizon diagnostics.
`count_detour_events.m` reports only separated, sustained signed lateral
excursions (0.5 m, 5 samples, 10 below-threshold samples). A low clearance or
collision is never converted into a detour event.

Dynamic obstacles are generated by an independent kinematic model, including
straight lines, sharp turns, helix, hover-then-maneuver, zigzag, waypoint
following, and variable-speed maneuvers (constant acceleration and sinusoidal
speed). Some generators are nonlinear; this alone does not guarantee a learned
predictor outperforms constant-velocity extrapolation. Training data and evaluation scenarios use the same
generator; evaluation scenarios are fixed while training scenarios are random.

## Self-contained repository layout

The repository includes the `MPC_DWA_Fusion` baseline source tree so that the
relative dependency layout is preserved after cloning. The MATLAB entry points
resolve that baseline from the local folder first and retain compatibility with
the original sibling-folder layout. The platform-specific CasADi binaries are
not committed; install CasADi 3.8.0 under
`MPC_DWA_Fusion/third_party/casadi-3.8.0-windows64-matlab2018b/` as described
in that directory's README.

The entry points create a local `results/` directory for generated outputs. The
fixed trained model used by the archived runs is included in the separate data
package; it is not committed to the code repository. Run `retrain_lstm` first
in a fresh clone, then run the evaluation entry points. Manuscripts, previous
results and AI/debug working material are kept only in the ignored local
`_local_archive/` directory. Replace the `TODO` archive fields in the release
metadata after Zenodo publication.
