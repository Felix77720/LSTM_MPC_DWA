# Frozen protocol: original MPC--DWA architecture baseline

**Frozen before the new baseline arm is executed:** 2026-10-09  
**Direct source:** Chang Xucheng, Wang Jingyu, Dang Shuailong, Pei Yulei and Zhu Feng, “Research on UAV Path Planning Algorithm Based on MPC-DWA Strategy,” *Electronics Optics & Control*, online first, 26 March 2026, <https://link.cnki.net/urlid/41.1227.TN.20260325.1153.006>.  
**Local source SHA-256:** `c59d8299367333b5d7d39d58c333536ffb98685bd3064abb1cb2ac0556d1fbfb`

## Research question

On the same 500 dynamic-obstacle scenes and three matched sampling seeds already used by the shared-LSTM experiment, does adding one causal LSTM forecast to both planning horizons improve the reproduced bidirectionally coupled MPC--DWA architecture relative to its original no-learned-forecast form?

## Architectural baseline

The source paper defines a hierarchical bidirectional coupling: DWA maps its reachable-control region into MPC constraints; MPC supplies a receding-horizon reference trajectory to DWA; a four-component trust score controls intelligent sampling; and trust-dependent weights score route agreement, speed and obstacle avoidance. The project-local `MPC_DWA_Fusion` tree reproduces that architecture. The added baseline arm invokes `simulate_dynamic(...,'static',...)`, which holds each obstacle at its latest observed position in both MPC and DWA. It therefore retains the coupling, trust, sampling, dynamic weighting, safety screens, solver and vehicle model but removes every learned or extrapolative obstacle forecast.

This is an architectural reproduction, not a numerical replication of the source paper's Tables 1--2. The source paper does not report run counts, confidence intervals, random seeds, complete numeric settings, source code or run-level data, so its printed percentages cannot be pooled with this experiment.

## Frozen comparison

- **Baseline arm:** original bidirectionally coupled MPC--DWA, current-position hold in both layers (`static`).
- **Proposed arm:** the already frozen integrated shared-LSTM arm (`lstm`).
- **Scenes and seeds:** the exact 500 scene objects and sampling seeds 1--3 stored in `shared_vs_dwaonly_h1s_mpc3s_500scenes_20261005_164515/experiment_bundle.mat`.
- **Unchanged controls:** vehicle dynamics, workspace, obstacle tracks, MPC and DWA horizons, trust coefficients, sampling and scoring parameters, safety gates, stopping rules and solver configuration.
- **Permitted difference:** obstacle-forecast provider only: current-position hold versus the same causal LSTM sequence supplied to both MPC and DWA.
- **No tuning:** no coefficient, threshold, horizon, seed, scene or stopping-rule change is permitted after inspecting baseline outcomes.

## Outcomes and analysis

The primary outcome is collision-free goal arrival along the continuous piecewise-linear UAV path relative to the time-aligned obstacle tracks. The single planned primary contrast is shared LSTM minus original MPC--DWA in percentage points. Its 95% interval uses 20,000 paired bootstrap resamples of the 500 complete scenes, retaining all three seeds in every selected scene cluster.

Secondary descriptive contrasts are swept-collision rate, mean per-run minimum swept-path clearance, path length and median planning-step time. Their intervals are unadjusted and cannot replace the primary outcome. The original paper's reported 95% obstacle-avoidance rate is not an analysis target because its denominator and scene distribution are unavailable.

## Interpretation rule

The manuscript may say that shared forecasting improves the reproduced original MPC--DWA architecture only if the estimated collision-free-arrival difference is positive and its paired 95% interval excludes zero. Regardless of that result, comparisons with standalone DWA and standalone MPC remain separate architecture-level results and cannot be rewritten.

