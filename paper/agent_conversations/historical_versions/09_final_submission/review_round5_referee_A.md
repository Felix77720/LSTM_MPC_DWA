# Reviewer 1

## Review setup

- **Input scope** The frozen packet’s `main_revised.pdf`, `main.tex`, `references.bib`, three main-text figure PDFs, and all files in `supplementary`. All files listed in the adjacent SHA-256 manifest matched.
- **Assessment boundary** Simulation results in the supplied packet. I did not assess physical flight or behavior on unseen obstacle-motion families.
- **Shared manuscript claim summary** A causal LSTM forecast is shared by MPC and DWA in a UAV planner. In a matched 12-scene simulation suite, this setting has higher mean piecewise-linear minimum clearance than supplying the LSTM forecast to DWA alone, while the success-rate difference remains uncertain.
- **Visible evidence base** Main-text figures and methods, supplementary methods, scene-level sensitivity and bootstrap summaries, run-level clearance and timing summaries, sensing-condition summaries, and the DWA-only random-scene run data.
- **Missing materials affecting confidence** The packet does not include the controller source, trained weights, scene trajectories, or full per-run time series. The supplementary README says these remain in a separate project archive. This limits independent reproduction of the reported audit and model outputs.

## Overall assessment

The manuscript presents a clearly bounded simulation study. Its strongest quantitative result is the matched shared-LSTM versus DWA-only clearance contrast: approximately 0.080 m, with a scene-cluster interval that narrowly excludes zero. The reported success-rate difference is only one run out of 36, and its interval includes no difference. The authors generally keep their claims within these limits and disclose that trust-adaptive sampling is not separately evaluated, the obstacle families overlap training, and physical flight remains untested.

The main technical concern is that the fallback can execute a command that did not pass the stated clearance and corridor gates. The current data show positive but sub-threshold clearances for the shared-LSTM fallback actions audited in random scenes; they do not establish a safety guarantee. Reproducibility is also incomplete in this packet: several central outputs cannot be reconstructed from the supplied summaries alone.

Robotics and control researchers working on UAV navigation among moving obstacles would be the most interested audience. The integration of forecast use across MPC and DWA is relevant, but the contribution appears incremental and its demonstrated importance is limited to the tested simulator and scene suite.

## Who would be interested in the results, and why

UAV navigation, robotics, and model-predictive control researchers may find the forecast-sharing design and its matched comparison useful. Researchers in motion prediction may be interested in how forecast quality interacts with downstream planning. The evidence supports a small clearance improvement in this suite, not a demonstrated increase in success rate or general safety.

## Major strengths

- The LSTM is causal, and the manuscript specifies its input history, forecast horizon, training split, and time alignment with both planning layers.
- The random-scene comparison is matched by scene and seed, and its bootstrap resamples scenes rather than treating repeated seeds as independent environments.
- The manuscript distinguishes sampled-state success from the piecewise-linear clearance audit and describes the interpolation assumption.
- The authors disclose the fallback behavior, the single-scene scope of the structural ablation, overlapping training and evaluation maneuver families, and the absence of physical-flight tests.

## Major Concerns

### R1-M1

- **Severity** Major
- **Blocking** No
- **Axis** Technical soundness
- **Claim pointer** Method, “MPC–DWA Guidance, Candidate Screening and Feedback,” following Eq. (6); Fig. 2; Results, “Route Outcomes and Forecast Accuracy”; Supplementary Methods S1.2 and S1.4.
- **Evidence pointer** When no candidate passes the stated gates, the fallback selects a maximum-clearance sample, modifies its speed, pitch, and yaw commands, then executes the modified command without a new rollout or gate check. The four shared-LSTM random-scene runs using fallback total 33 actions, with reported minimum sampled clearance between 0.155 and 0.224 m, below the 0.25 m candidate-rejection threshold.
- **Concern** The screening gates do not apply to every executed action. The fallback is explicitly best-effort, so the planner’s candidate filter cannot be interpreted as a safety constraint on the full control loop. The reported successful fallback runs are useful empirical evidence for those trials, but do not establish safe behavior when the fallback is invoked in other conditions.
- **Why it matters** The method’s collision-avoidance interpretation depends on whether executed actions remain screened. A branch that bypasses those checks is an important failure mode, particularly under forecast or sensing errors.
- **Resolution test** Either re-roll out and gate the modified fallback command, with a defined response when no command passes, then report the resulting simulation outcomes; or retain the branch but describe the full planner as having no hard safety guarantee and report fallback frequency, sampled and interpolated clearance, and collision outcomes by setting and sensing condition.

### R1-M2

- **Severity** Major
- **Blocking** No
- **Axis** Technical soundness and reproducibility
- **Claim pointer** Evaluation Design and Results, including the 228-run interpolation audit and random-scene clearance contrast; Supplementary Methods S2, S4, and S5.
- **Evidence pointer** The supplementary README says the packet excludes source code, model weights, execution logs, and per-run MATLAB bundles; it says these remain in a project archive. The supplied `trajectory_clearance_audit.csv` contains run-level outcome summaries, not the trajectories needed to recompute the interpolation audit. Supplementary Methods S5 says the reproducibility archive is supplied as a companion file, but that archive is not in the frozen packet.
- **Concern** The packet supports checking some aggregate arithmetic, including the scene-level clearance effect, but it does not permit an independent rerun of the controller or reconstruction of the reported collision audit. The model hash in the DWA-only data cannot be checked against the model artifact because the weights are absent.
- **Why it matters** The central result depends on a specific trained model, controller implementation, and generated trajectories. Summaries alone cannot determine whether another implementation of the described method would produce the same outputs or audit results.
- **Resolution test** Supply the referenced anonymous archive or repository with the hashed model weights, controller and scene-generation source, full obstacle and UAV trajectories, and scripts for the clearance and timing summaries. Make the companion-file status consistent across the README and Supplementary Methods.

## Minor Comments

### R1-m1

- **Severity** Minor
- **Axis** Evidence traceability
- **Affected element** Fig. 3(c), online forecast error; Evaluation Design.
- **Evidence pointer** The packet includes `matched_dwaonly_random12.csv` for the DWA-only condition, which Fig. 3(c) excludes, and `sensing_summary.csv` for S4 sensing conditions. It does not include per-run online ADE/FDE values for the four plotted settings.
- **Issue** The plotted means and descriptive run-level standard deviations cannot be checked against numerical per-run data from this packet.
- **Required correction** Add a compact CSV of the per-run ADE/FDE values used for Fig. 3(c), with the aggregation definition.

### R1-m2

- **Severity** Minor
- **Axis** Reproducibility
- **Affected element** Supplementary Methods S4 and Fig. S1.
- **Evidence pointer** `supplementary_methods.tex` references `figures/scene_clearance_sensitivity.pdf`, which is absent from the frozen packet, although the compiled supplementary PDF contains Fig. S1.
- **Issue** The supplied supplementary source cannot reproduce its compiled figure from the files in the packet.
- **Required correction** Include the figure source asset in the supplement or provide the script and data that regenerate it.

### R1-m3

- **Severity** Minor
- **Axis** Readability and submission format
- **Affected element** `main_revised.pdf`, compiled page count.
- **Evidence pointer** The compiled main PDF has five pages, with the references continuing onto page 5.
- **Issue** The packet is in a folder named `Conference_4Page_Submission`, but the rendered paper is five pages.
- **Required correction** Confirm that the target venue permits this page count; if the four-page limit is strict, shorten the manuscript or references accordingly.

## Assessment against the requested criteria

- **Originality** The contribution is mainly an integration of known ingredients: causal LSTM forecasting, MPC, and DWA. Sharing a forecast across layers and feeding accepted-control bounds back to MPC is a useful design choice, but the packet does not establish broad algorithmic novelty beyond that integration.
- **Scientific importance** The clearance improvement is statistically positive within the supplied 12-scene suite, but modest in absolute size. The success-rate interval includes no difference. The study does not test unseen motion families or physical flight, and its conclusions are appropriately bounded to the simulator and maneuver families.
- **Interdisciplinary interest** The work may interest researchers spanning UAV robotics, control, and learned motion prediction. Its appeal outside these areas is likely limited.
- **Technical soundness** The matched random-scene design and scene-cluster analysis are reasonable for the stated comparison, and the key reported clearance estimates agree with the supplementary scene-level summaries. The unverified fallback branch weakens any safety-preserving interpretation. Missing implementation and trajectory artifacts also limit independent verification.
- **Readability** The paper is organized clearly and the figures communicate the pipeline and comparisons. The methods are equation-dense, but the supplement supplies useful definitions. The five-page compiled output should be checked against the intended venue format.

**Technical issues requiring attention before the evidential case is fully established** R1-M1 and R1-M2. Both are marked non-blocking because the reported simulation outcomes support the narrower empirical claims, while the fallback and missing materials limit safety interpretation and independent reproduction.

**Blocking concerns** None. This report does not make an editorial decision.
