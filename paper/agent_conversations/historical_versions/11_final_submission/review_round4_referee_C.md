# Review setup

- **Input scope** The five-page revised manuscript PDF, five-page Supplementary Methods PDF, corresponding LaTeX source and bibliography, and the supplied configuration, summary, bootstrap, sensing, fallback, and trajectory-audit CSVs in the frozen round 4 packet. The SHA-256 values matched `sha256_manifest.json`.
- **Assessment boundary** The claims are assessed for the simulated dynamics, sensing conditions, exogenous obstacle paths, and maneuver families described in the packet. The packet contains no flight-test evidence. I reviewed the PDFs as the authoritative layout and checked the source and CSVs for method and numerical anchors. No earlier review, ledger, or other reviewer material was consulted.
- **Shared manuscript claim summary** The paper proposes sharing a causal LSTM obstacle forecast between receding-horizon MPC and trust-adaptive DWA, with accepted DWA control bounds constraining the next MPC input. It reports higher minimum clearance for shared forecasting than for supplying the LSTM forecast to DWA alone, within the tested simulation suite.
- **Visible evidence base** Four fixed scenes and 12 independently generated random scenes, with three matched sampling seeds per scene; 228 runs in the forecast comparison; a three-seed ablation in one repeated-encounter scene; paired scene-cluster bootstrap summaries; leave-one-scene-out clearance estimates; a piecewise-linear trajectory audit; and a small S4 sensing-pressure suite.
- **Missing materials affecting confidence** Executable simulator and training code, trained network weights, and the underlying generated obstacle trajectories are not in the packet, so the results cannot be independently rerun from these files alone. The per-run audit and summary CSVs permit scrutiny of many reported outcomes. The host CPU model is also absent, as the manuscript states.
- **Review emphasis** Simulation evidence, statistical analysis, scene and seed coverage, figures, and claim boundaries, while assessing all five source-grounded reviewer axes.

# Reviewer 3

## Overall assessment

The revision presents a detailed and notably bounded simulation study. The main forecast-sharing comparison is matched, the independent unit for random-scene uncertainty is treated as the scene rather than each of the 36 runs, and the manuscript distinguishes a clearance result from an uncertain goal-success difference. The figures and supplement make several limitations visible, including that the main clearance result is suite-specific, the forecast families overlap between training and evaluation, and the fallback can pass below its nominal rejection threshold.

The reported 0.080 m clearance difference is supported for this simulated suite, but it is not an operational safety threshold or evidence of broader deployment performance. The scene-level effects range from -0.057 to 0.397 m, although the leave-one-scene-out means remain positive at 0.051 to 0.092 m. Thus the estimated direction is stable to dropping one scene, while the magnitude varies substantially across the 12 scenes. The supplied runtime CSV also contains extreme per-step timing values that are not reconciled with the much smaller timing reported for the single-scene ablation. The integration's novelty relative to the cited UAV MPC and dynamic-window work needs sharper explanation. I identify no blocking issue to the paper's narrow empirical claim, but the current evidence does not establish real-time or physical-UAV operation, generalization to unseen maneuver families, or a broad scientific advance.

## Who would be interested in the results, and why

Researchers in UAV autonomy, robot motion planning, and model predictive control would be interested in the forecasting interface and its matched within-controller comparison. Researchers in machine learning for control may also value the distinction between new trajectory instances and genuinely unseen motion families. The present results are mainly of interest to those communities because they use a single simulated vehicle model and exogenous obstacle trajectories, with no physical validation or comparison against external planner implementations.

## Major strengths

- The task, dynamics, scene assumptions, success definition, controller settings, forecast horizon, and candidate-screening gates are described in the main paper and Supplementary Methods.
- The forecast-source comparison holds the MPC-DWA controller fixed. The paper explicitly states that this is not a head-to-head comparison of standalone MPC and DWA, which makes the intended inference clearer.
- Random-scene uncertainty is estimated by paired resampling over 12 scenes while retaining each scene's three matched runs. The paper reports the 0.080 m clearance estimate, its 95% interval, the success-rate interval, the count of positive scene-level effects, and leave-one-scene-out estimates.
- All attempted runs contribute to the collision and success audit. The piecewise-linear clearance check is described as an interpolation assumption rather than a higher-fidelity model of physical motion.
- The visual evidence is clear and generally well captioned. Figure 1 is identified as illustrative only; Figure 2 distinguishes descriptive run-level standard deviations from the scene-cluster interval; and Figure 3 depicts the ungated best-effort fallback.
- The manuscript does not claim hardware validation, generalization to unseen maneuver families, a success-rate advantage, or real-time operation on another platform.

## Major Concerns

### R3-M1 [novelty-significance]

**Severity** Major  
**Blocking** No  
**Claim pointer** The contribution is the shared LSTM forecast and the interface in which DWA accepted-control bounds constrain MPC's next first input, together with trust-adaptive sampling.  
**Evidence pointer** Main PDF, p. 1, Introduction and references [3]-[7]; p. 3, Evaluation Design; p. 4, Results and Discussion.  
**Concern** The Introduction lists prior work on moving-obstacle prediction for DWA, adaptive DWA weights, and forecast- or intent-guided UAV MPC, then describes the present work as an interface between established components. It does not explain in enough detail how the combined forecast-sharing and feedback design differs from the closest cited approaches. In addition, trust-adaptive sample allocation is presented as part of the method, but the paper says its independent effect is not isolated because no fixed-budget DWA comparison was run. The evaluation isolates forecast source and layer exposure within this planner, but the manuscript explicitly does not benchmark standalone or published planners. Thus, the empirical case for a within-controller effect is stronger than the case for an original advance of broader significance.  
**Why it matters** The distinction affects whether readers view the paper as a new planning method or a useful integration and evaluation of established methods. That is central to the originality and scientific-importance assessment, even though it does not invalidate the reported simulator results.  
**Resolution test** Add a concise comparison with the closest cited methods that identifies which interface or control mechanism is new and what capability it adds. If trust-adaptive allocation is a principal novelty claim, compare it with a fixed-budget policy; otherwise describe its independent contribution as untested. If the distinction is primarily the integration, keep the contribution and significance claims explicitly at that level rather than implying a broader planner advance.

### R3-M2 [experimental-design]

**Severity** Major  
**Blocking** No  
**Claim pointer** The planner is evaluated as a receding-horizon method with 0.1 s control steps, and the ablation is used to assess a computation-clearance trade-off.  
**Evidence pointer** Main PDF, p. 3, Eq. (5) and Evaluation Design; p. 4, Forecast-Sharing Ablation; p. 5, Discussion. Supplementary Methods, S3, p. 4. `evidence/matched_dwaonly_random12.csv`, rows `Seed=1, ScenarioIndex=1` and `Seed=1, ScenarioIndex=2`.  
**Concern** The supplied DWA-only-forecast random-scene CSV records `MeanStepTime_ms` of 9,527.05 ms for R01 seed 1 and 83,919.85 ms for R02 seed 1. The latter row reports `MeanDwaTime_ms` of 83,878.96 ms. Under the manuscript's stated units and timing convention, these are per-run mean step times of approximately 9.5 seconds and 83.9 seconds. They differ by orders of magnitude from the 42.23 to 78.65 ms per-step values reported for the three-seed, single-scene horizon ablation. The paper notes that the CPU model was not recorded and disclaims cross-platform real-time operation, but it does not reconcile these two extreme random-scene values or explain how representative the ablation timing is.  
**Why it matters** Runtime is part of the stated computation-clearance trade-off, and the simulated controller advances at 0.1 s intervals. If the CSV values are correct, the planner's computational behavior is highly scenario-dependent and the ablation timing alone is not an adequate characterization. If the values reflect a logging or unit issue, the reported timing evidence is not interpretable until corrected.
**Resolution test** Verify the timing units and the two rows against the archived logs. Report the per-run timing distribution and the worst-case values for the matched suite, or correct the CSV if it is erroneous. Clarify whether the timings measure simulated workload or wall-clock execution, and keep any real-time wording aligned with the resulting evidence.

## Minor Comments

### R3-m1 [figures-and-tables]

**Severity** Minor  
**Affected element** The reference to Supplementary Table S2 for paired scene values and leave-one-scene-out estimates.  
**Evidence pointer** Main PDF, p. 4, Results, paragraph following the paired layer contrast; Supplementary Methods, pp. 4-5; `evidence/scene_clearance_sensitivity.csv`.  
**Issue** The manuscript points readers to Supplementary Table S2, but the supplied Supplementary Methods PDF contains a different Table 1 and Figure 1, not Table S2. The CSV does contain the scene-level values and leave-one-out estimates, so the numbers are available but the table reference is not verifiable in the supplied supplement.  
**Required correction** Include Supplementary Table S2 in the supplement or replace the reference with the correct supplied file and table identifier.

### R3-m2 [statistical-rigor]

**Severity** Minor  
**Affected element** The 95% paired scene-cluster bootstrap intervals.  
**Evidence pointer** Main PDF, p. 3, Evaluation Design; p. 4, Results; `evidence/layer_ablation_bootstrap.csv` and `evidence/paired_clearance_bootstrap.csv`.  
**Issue** The resampling unit and number of replicates are reported, but the interval construction method is not stated in the visible manuscript or CSV headers. With 12 scene clusters and a lower clearance interval bound close to zero, that detail would help readers reproduce the estimate.  
**Required correction** Specify how the 95% interval is calculated from the paired cluster-bootstrap replicates and use the same description for the clearance and success contrasts.

### R3-m3 [experimental-design]

**Severity** Minor  
**Affected element** The S4 sensing-pressure result.  
**Evidence pointer** Main PDF, p. 5, Discussion; `evidence/sensing_summary.csv`, rows for LSTM under `clean`, `noise005`, `delay1`, and `noise005_delay1`.  
**Issue** The Discussion reports the clean and joint-noise-plus-delay LSTM results, 2/3 and 1/3 successes, while the supplied summary also gives noise-only and delay-only results, each 2/3. The sample size is clearly small and the text does not claim robustness, but the partial display obscures the structure of the sensitivity check.  
**Required correction** Report all four conditions in a compact sentence or table, label the check exploratory, and retain the three-run denominator.

## Technical failings that need to be addressed before the case is established

No blocking failing identified. R3-M1 and R3-M2 are major but nonblocking. The first limits the originality and significance case. The second requires reconciliation of the supplied timing evidence before the computation-clearance trade-off can be interpreted.

## Assessment against Nature-style criteria

- **Originality** The architecture combines a shared forecast with MPC-DWA feedback, but the distinction from the cited dynamic-window and UAV MPC approaches is not yet demonstrated in sufficient detail.
- **Scientific importance** The clearance increase is quantitatively supported within this suite, while the 2.8 percentage-point success difference includes no difference. No operational clearance margin is specified, and no physical deployment result is available. The broader importance therefore remains uncertain.
- **Interdisciplinary readership** The strongest readership is in robotics, autonomous systems, and control. Interest beyond these fields is possible but not established by the current simulator-only evidence.
- **Technical soundness** The matched comparisons, scene-cluster bootstrap, per-run outcome summaries, and interpolation audit are appropriate strengths. Scene-level heterogeneity and the timing discrepancy limit interpretation. The ungated fallback and exogenous obstacle trajectories are candidly described, so the results should remain framed as empirical findings under those assumptions rather than safety guarantees.
- **Readability for nonspecialists** The Introduction gives a usable problem overview and Figure 3 helps explain the planner. The paper remains notation-dense and relies on specialist terms such as trust allocation, forecast exposure, and dynamic-window control. A nonspecialist can follow the main finding but may not understand why the integration matters without a sharper comparison to prior approaches.

## Recommendation posture

Promising as a focused simulation study for UAV planning and control readers. A stronger broad-interest case depends on clarifying the technical novelty, reconciling the runtime record, and preserving the manuscript's current limits on generalization, safety, and deployment. This is a reviewer assessment, not an editorial decision.

## Claims not established by the supplied evidence

The packet does not establish hardware flight performance, real-time feasibility on a target platform, generalization to unseen obstacle-motion families, reactive obstacle behavior, a formal collision-safety guarantee, or an independent performance benefit from trust-adaptive sampling. The 0.080 m clearance result is for the specified random-scene suite and is not tied to an operational safety threshold.

**Status** Frozen after independent review.

