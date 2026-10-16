# LSTM-Prediction-Enhanced MPC-DWA UAV Dynamic Obstacle Avoidance

This repository contains MATLAB + CasADi code for LSTM-enhanced dynamic-obstacle avoidance. The current formal paper package is Version 13 at [`paper/Conference_4Page_Submission/versions/13_final_submission/`](paper/Conference_4Page_Submission/versions/13_final_submission/). Its four-page paper, 19-page supplementary methods, bilingual reader, reproducibility ZIP and final audit/addendum are listed in that package's README.

## Current Version 13 evidence

The package reports three distinct evidence sets; they are not pooled:

- Stage 1 development/calibration is complete: 4,320 episodes across six trust-weight candidates, five integrated arms, 48 scenes and three matched seeds. The selected vector is `[0.15,0.15,0.15,0.55]`, with descriptive equal-arm macro-average safe-arrival rate 0.8042. This is development-set selection evidence, not a held-out estimate.
- Stage 2 planned 5,760 fresh episodes. It has 2,263 checkpoint files, remains incomplete, and was not analyzed or used for parameter selection. No Stage 2 parameter-selection result is claimed.
- The seven-method exploratory evaluation completed 2,100 valid episodes (100 simulated scenes × three matched seeds × seven arms). Safe-arrival rates were DWA-CV 78.0%, MPC-CV 92.0%, coupled MPC-DWA-CV 68.0%, LSTM-to-MPC-only 73.0%, LSTM-to-DWA-only 74.7%, shared LSTM 73.7%, and latest-position-hold reconstruction 57.3%.

Only the shared-LSTM versus position-hold contrast has a simultaneous 95% scene-cluster confidence interval supporting an improvement: +16.3 percentage points [5.1, 27.6]. The evidence does not establish overall superiority; standalone MPC-CV had the highest observed rate. The 500-scene confirmation protocol was never run and is retired. Its first 100 scenes overlap exactly with the exploratory bank, so those results are not independent confirmation. All results are simulations; no real-flight validation was performed.

## Historical experiments

Earlier four-method and 7,500-run experiments remain historical records, separate from Version 13 and not pooled with its 100-scene evaluation. The historical three-seed comparison reported 12/12 LSTM successes versus 10/12 static, 9/12 CV and 9/12 Kalman; the separate 12-scene suite contained 144 runs and reported 36/36 LSTM successes. These earlier results are descriptive historical evidence, not the current paper's seven-method result or a claim of universal performance. Original records and data have been preserved.

## Reproducibility and dependencies

Version 13 deliverables include `02_source/main.pdf` and editable LaTeX, `03_supplementary/supplementary_methods.pdf`, `03_bilingual/paper.md`, `03_supplementary/reproducibility_package.zip`, and the full audit plus `04_review/v13_final_submission_audit_20261016_addendum.md`. The final discussion identifies that the LSTM and CV arms use different input information streams; results are not presented as an overall method ranking. Original checkpoint trees and large historical MAT bundles remain at their existing paths; the reproducibility package records hashes for omitted artifacts. Reproduction of optimizer-based simulations requires MATLAB R2025a (or compatible), Deep Learning Toolbox, and CasADi 3.8.0 installed under `MPC_DWA_Fusion/third_party/`.

The older `run_experiments`, `run_multiseed`, `run_sensing_robustness`, `run_random_multiseed`, and ablation workflows describe previous study protocols. They should not be read as the Version 13 seven-method protocol. Consult the versioned package README and audit for the authoritative current scope and artifacts.
