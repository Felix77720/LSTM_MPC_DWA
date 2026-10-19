# Experiment archive

All local run outputs are kept here, separate from the manuscript workspace. The canonical archive is `experiments/results/`; it is excluded from GitHub because it contains multi-gigabyte MATLAB checkpoints and run-level records. The submitted package contains selected frozen summaries, protocol records, and SHA-256 inventories needed to interpret the paper.

## Cohorts

| Folder | Contents | Status in Version 13 |
|---|---|---|
| `confirmatory_revision/` | 48-scene forecast checks and the 500-scene shared-LSTM vs DWA-only matched contrast | 500-scene paired contrast reported; the 48-scene earlier check remains historical |
| `v12a_pooled_weight_development_inclusive_dev48_20261012/` | 4,320 Stage-1 development/calibration episodes and manifests | Used to select the trust weights; development-only |
| `v12a_pooled_weight_development_dev48_20261011*` | Earlier partial/recovery checkpoints from Stage 1 | Preserved as provenance; not treated as separate samples |
| `v13_seven_method_100scene_exploratory_20261015/` | Seven methods × 100 simulated scenes × three matched seeds, plus route-example records | 2,100 valid episodes; exploratory |
| `standalone_controller_revision/` | Matched standalone DWA/MPC reruns and earlier variants | Supporting comparison evidence |
| `original_baseline_revision/` | Reproduction of the original MPC–DWA baseline | Historical baseline comparison |
| `v13_trust_scale_calibration_inclusive_dev48_20261014_recovery/` | Partial recovery checkpoints for an incomplete Stage-2 plan | Not analyzed or used for selecting parameters |
| remaining dated folders | Ablations, sensing/runtime analyses, historical figures and summaries | Retained only where they preserve distinct prior evidence |

No run-level output is deleted merely because it is old. The folder inventory preserves run-specific records and incomplete-run evidence; data sets with different seeds, scenarios, controller arms, or protocol status are not considered duplicates. The compact paper tables and audit files are in the Version 13 supplementary package.

## Drivers and paths

MATLAB experiment drivers (`run_*.m`, `analyze_*.m`, and `recompute_*.m`) remain at the repository root next to the simulator and model code. Their `mfilename`-based root resolution and recorded source hashes are part of the historical run provenance. The root-level `results/` path is a local Windows junction to `experiments/results/` so existing scripts continue to work without editing frozen runner code. This junction is workstation-only; a clean clone can create its own ignored `results/` output directory.

The `_local_archive/` tree retains older source-model and auxiliary data used by legacy analyses. It is not a release directory and is excluded from GitHub.

## Historical materials

`experiments/archive/` contains the prior Zenodo staging package, older summary-table versions, and small provenance materials extracted from superseded release bundles. Run-level MATLAB outputs remain only in `experiments/results/`; historical bundle inventories do not replace those raw records. The root `results/` junction is workstation-only compatibility plumbing.
