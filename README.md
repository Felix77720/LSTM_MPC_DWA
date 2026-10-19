# LSTM-prediction-enhanced MPC–DWA for UAV dynamic-obstacle avoidance

This repository contains the MATLAB/CasADi implementation and the current Version 13 conference submission. The final paper package is under [`paper/Conference_4Page_Submission/versions/13_final_submission/`](paper/Conference_4Page_Submission/versions/13_final_submission/); its README links the four-page PDF, editable LaTeX, bilingual manuscript, supplementary methods, figures, reproducibility packages, and final audit.

## Experiment records

The experiment archive is organized under the [experiment archive index](experiments/README.md); run-level results are kept locally and excluded from GitHub. For compatibility with historical MATLAB scripts, this workstation also retains a local `results/` junction to the archive. The records are not pooled across protocols, and no new scientific simulations were run during final organization.

- Stage 1 development/calibration: 4,320 episodes across six weight candidates, five integrated arms, 48 scenes, and three matched seeds. The selected trust vector is `[0.15,0.15,0.15,0.55]`; the equal-arm macro-average safe-arrival rate of 0.8042 is development evidence, not a held-out estimate.
- Seven-method exploratory comparison: 2,100 valid episodes (100 simulated scenes × three matched seeds × seven methods). Standalone MPC-CV achieved the highest observed safe-arrival rate (92.0%); shared LSTM achieved 73.7%. These results do not establish overall superiority.
- Frozen shared-LSTM versus DWA-only contrast: 500 scenes, 3,000 matched attempts, and a 6.7 percentage-point improvement (95% scene-cluster CI 4.2–9.2) for shared prediction. This is a subset of the five-controller benchmark, not a separate sample.
- All results are simulation-only. No real-flight validation is claimed. The 100-scene bank overlaps the first 100 scenes of a retired holdout design and is reported as exploratory, not independent confirmation.

For the detailed data inventory and protocol separation, see [`experiments/README.md`](experiments/README.md) and the Version 13 audit. Historical run drivers remain beside the simulator locally to preserve recorded paths and hashes. GitHub carries the current paper sources and selected reproduction scripts; multi-gigabyte raw runs and one-off development drivers are not uploaded.

## Reproduction

The paper package includes the current submission artifacts and bounded reproducibility archives. Re-running the optimizer-based simulations requires MATLAB R2025a (or compatible), Deep Learning Toolbox, and CasADi 3.8.0. CasADi is kept locally and is excluded from GitHub.
