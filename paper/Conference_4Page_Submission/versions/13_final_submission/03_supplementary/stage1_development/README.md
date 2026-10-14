# Stage-1 trust-weight development artifacts

This folder preserves the completed development evidence used to choose the trust-weight vector. The design was six candidate vectors × five integrated branches × 48 development scenes × three matched seeds = 4,320 episodes. The recovery audit validated all existing records and created zero new simulations.

The selected vector was `[0.15, 0.15, 0.15, 0.55]`. Its equal-arm macro-average collision-free-arrival score was 0.8042. At that vector, the five branch rates were 0.8958 (shared LSTM), 0.7431 (CV-coupled MPC–DWA), 0.8194 (LSTM to MPC only), 0.8958 (LSTM to DWA only), and 0.6667 (latest-position hold). These are selection-set development statistics, not held-out or independent comparative estimates. The selected vector was not applied retrospectively to the separate 7,500-run historical benchmark.

`pooled_development_raw.csv` contains the recovered run-level outcome rows. `pooled_episode_sha256.csv` maps all 4,320 episode records to their preserved checkpoint hashes; `pooled_calibration_artifact_sha256.csv` records the original SHA-256 values for the selection artifacts. The manifests, selection bundle and recovery bundle are included alongside the CSVs.

The original MAT checkpoints remain unchanged under `results/v12a_pooled_weight_development_inclusive_dev48_20261012/episodes/` in the project workspace; the 4,320 individual checkpoint files are deliberately not duplicated in this release archive. Verify copied selection-artifact files against `pooled_calibration_artifact_sha256.csv` and the manifest sidecars. The independent recovery details are in [`v12a_stage1_recovery_audit_20261014.md`](../../04_review/v12a_stage1_recovery_audit_20261014.md).

This folder contains no Stage-2 parameter-selection results or seven-method held-out controller results. The earlier 864-episode six-setting benchmark remains a distinct historical dataset.
