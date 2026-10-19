# Reviewer B report

## Review setup

**Input scope**
The frozen five-page manuscript PDF, five-page Supplementary Methods PDF, LaTeX source and bibliography, and the ten frozen evidence CSVs, together with `review_scope.md` and `sha256_manifest.json`. Every listed file matched the manifest byte count and SHA-256 hash. The PDFs are treated as the authoritative layout.

**Assessment boundary**
This is a simulation-only review of the stated UAV dynamics, exogenous spherical-obstacle trajectories, sensing conditions, and maneuver families. The packet contains no flight-test evidence. No inference is made about hardware safety, unseen maneuver families, or behavior outside this simulation suite.

**Shared manuscript claim summary**
The paper proposes a causal LSTM obstacle forecast shared by a receding-horizon MPC route optimizer and trust-adaptive DWA screening. Its main comparison reports a 0.080 m increase in piecewise-linear minimum clearance for shared LSTM versus LSTM supplied to DWA only, with 36/36 versus 35/36 random-scene successes and a success-rate interval that includes no difference.

**Visible evidence base**
The paper and supplement specify the discrete UAV model, controller equations and weights, sampling and screening rules, LSTM architecture and split, solver settings, scene counts, bootstrap unit, and the interpolation audit. Evidence includes run-level clearance summaries, paired scene differences, sensing-pressure results, fallback replay, and configuration. These materials support a bounded assessment of the reported simulation comparison.

**Missing materials affecting confidence**
The frozen packet does not include controller or scene-generation implementation, trained model weights, or time-series UAV and obstacle trajectories. The available CSVs contain run or scene summaries rather than the underlying coordinates needed to rerun the closest-approach audit. I cannot assess from this packet whether these artifacts are available elsewhere.

**Emphasis**
Technical soundness, mathematical and algorithmic consistency, implementation traceability, and reproducibility, while assessing all five source-grounded criteria.

## Overall assessment

The reported within-suite clearance result is internally consistent. The run summary gives mean random-scene piecewise-linear clearances of 1.107 m for Shared LSTM and 1.028 m for DWA-only LSTM. The paired CSV gives a 0.0799 m scene-cluster mean difference with a 95% interval from 0.0070 to 0.1662 m; eight of twelve scene means are positive, and leave-one-scene-out means remain positive. The success difference is 2.78 percentage points, with an interval from zero to 8.33 points. The evidence therefore supports a modest geometric improvement in the tested suite, not a success-rate advantage or an operational safety margin.

The evaluation is unusually explicit about its simulated boundary, matched controller settings, scene-cluster resampling, and piecewise-linear interpolation assumption. Two technical issues still limit the strength of the engineering case. The fallback can alter and execute a command after it has failed the stated rollout gates, and the reviewed materials do not permit independent reproduction of the main audit. Neither issue disproves the reported aggregate under the supplied simulator, so neither is blocking for the narrowly stated result.

## Who would be interested in the results, and why

Researchers in UAV navigation, motion planning, and predictive control may be interested in the controlled comparison of forecast exposure across MPC and DWA layers. The reported increase in clearance, together with the uncertain success-rate difference and the single-scene horizon ablation, is useful as a focused simulation result. The packet does not establish broad scientific importance beyond this engineering community.

## Major strengths

- The paper distinguishes its integrated planner from its established components and does not claim superiority over separately published planners.
- The forecast-source comparison keeps the common controller, scenes, and sampling seeds matched. Random-scene uncertainty is resampled by scene, retaining the three matched runs within each cluster.
- The manuscript reports both sampled-state and piecewise-linear clearance, defines the interpolation calculation in the supplement, and states that it is not a higher-fidelity physical-motion model.
- Relevant limitations are disclosed, including overlapping training and evaluation maneuver families, exogenous obstacle motion, an unisolated trust-adaptive sampling effect, unknown host CPU, and the lack of flight testing.

## Major Concerns

### B-M1 [claim-moderation]

**Severity** Major  
**Blocking** No  
**Claim pointer** The planner screens executable DWA actions against clearance, corridor, and braking conditions, and the main result is interpreted as improved trajectory clearance.  
**Evidence pointer** Main manuscript, Method, “MPC–DWA Guidance, Candidate Screening and Feedback,” page 3, Eq. (6) and fallback description; Results, page 4, fallback paragraph; Fig. 3 and caption, page 5. Supplementary Methods, S1.4, page 3. `evidence/shared_lstm_fallback_audit.csv` and `evidence/trajectory_clearance_audit.csv`.  
**Concern** When no candidate passes, the controller selects a sample, modifies its speed and angular commands, and executes the modified command without rolling it out again or checking the clearance, corridor, or braking gates. This is a property of the implemented controller, not just an untested edge case. The audit records fallback in four of 36 shared-LSTM random trials for 33 actions, with minimum point-sampled clearances from 0.155 m to 0.224 m, all below the stated 0.25 m candidate-rejection threshold. These actions had no recorded collisions and all four runs reached the goal, so the data do not show a collision; they do show that passing the candidate gate is not a condition on every executed action.  
**Why it matters** The clearance gate cannot be read as a safety property of the complete planner. The positive aggregate result remains valid for the tested runs, but the fallback branch weakens any broader interpretation of this controller as a screened or safety-bounded planner.  
**Resolution test** Re-run the shared-LSTM random suite with a fallback that is itself rolled out and checked against the same gates, or provide an alternative validated action such as a stop or hold. Report fallback frequency, minimum executed clearance, and success and collision outcomes for the revised behavior. If no gate-passing fallback is available, keep the method explicitly best-effort and avoid describing the rejection threshold as a guarantee for executed actions.

### B-M2 [reproducibility]

**Severity** Major  
**Blocking** No  
**Claim pointer** Matched simulation results and the 228-run piecewise-linear reanalysis support the claimed clearance and success outcomes.  
**Evidence pointer** Main manuscript, Evaluation Design and Results, pages 3 and 4. Supplementary Methods, S2 through S4, pages 3 and 4. `evidence/trajectory_clearance_audit.csv`, `evidence/trajectory_clearance_summary.csv`, `evidence/scene_clearance_sensitivity.csv`, and `evidence/paired_clearance_bootstrap.csv`. The frozen manifest lists `source/main.tex` and `source/references.bib`, but no simulation implementation or trajectory files.  
**Concern** The supplement provides substantial parameter and algorithm detail, but the packet does not contain the executable controller, the scene-generation implementation, the trained LSTM artifact, or the per-time UAV and obstacle positions. The per-run clearance audit records minima and outcomes, not trajectories. Consequently, an independent reader cannot rerun the 228 trials, verify the exact closest-approach calculation from the raw paths, or check the scene and seed pairing underlying the paired contrast from the supplied materials.  
**Why it matters** The central evidence is a custom simulator comparison and an interpolation audit. Summary CSVs permit arithmetic checks but do not independently establish that the controller and audit were implemented as described.  
**Resolution test** Archive the executable implementation and trained model, document the exact scene-generation procedure, and provide per-time UAV and obstacle center coordinates for the audited trials with the seed and method mapping. These materials would allow an independent replay of the paired analysis and clearance calculation.

## Minor Comments

### B-m1 [experimental-design]

**Severity** Minor  
**Affected element** Scope of the fixed-scene forecast comparison  
**Evidence pointer** Main manuscript, Evaluation Design, page 3, five forecast settings and “12 and 36 trials per setting”; Results, page 4, fixed-scene counts; `evidence/trajectory_clearance_summary.csv` and `evidence/trajectory_clearance_audit.csv`.  
**Issue** The Evaluation Design wording can be read as saying all five settings were evaluated in both suites. The fixed-scene summary and run-level audit contain four settings only, while DWA-only LSTM appears in the S4 route example and in the random-scene aggregate. The 228 total audited trials are consistent with four settings in the fixed suite and five in the random suite.  
**Required correction** State explicitly that DWA-only LSTM is excluded from the fixed-scene aggregate, or provide its fixed-scene run rows if those trials were performed. Reconcile the “per setting” wording with the reported counts.

### B-m2 [writing-clarity]

**Severity** Minor  
**Affected element** Meaning of the 0.1 s control cycle  
**Evidence pointer** Fig. 3 title area and caption, page 5; Supplementary Methods, S3, page 4; `evidence/sensing_summary.csv`.  
**Issue** The figure labels the method as a “0.1-s control cycle,” while the clean LSTM sensing condition reports a mean step time of 166 ms and a 95th-percentile step time of 204 ms. The Discussion correctly says these timings do not establish real-time operation on another platform, but the figure wording may be read as a wall-clock 10 Hz capability.  
**Required correction** Clarify that 0.1 s is the simulated state-update interval and that the reported wall-clock loop time can exceed that interval. Keep the existing limitation on real-time operation.

## Technical failings that need to be addressed before the case is established

No blocking concern prevents the narrow claim of a within-suite clearance increase. B-M1 and B-M2 are material nonblocking concerns for a stronger engineering and reproducibility case. In particular, the candidate rejection threshold does not cover fallback actions after modification.

## Assessment against Nature-style criteria

- **Originality** The contribution is legibly framed as a planner integration and forecast-sharing interface. The paper acknowledges that LSTM, MPC, and DWA are established and does not claim head-to-head superiority over cited planners. The supplied evidence establishes the integrated implementation and a controlled forecast-layer comparison, while novelty beyond this integration is not demonstrated.
- **Scientific importance** The result is technically relevant but narrow. The positive clearance difference is modest, the success-rate interval includes no difference, and the horizon ablation uses one repeated-encounter scene. Outstanding or far-reaching importance is not established by this simulation suite.
- **Interdisciplinary readership** The clearest readership is UAV robotics, planning, and control. The main conclusion has limited demonstrated reach beyond those fields.
- **Technical soundness** The paired setup, scene-level bootstrap, and interpolation audit are appropriate for the bounded simulation claim. The fallback semantics and unavailable replay artifacts limit confidence in a broader safety or reproducibility case. The authors appropriately disclose that interpolation is not a physical-motion guarantee.
- **Readability for nonspecialists** The abstract and introduction explain the planning problem and the division of roles between forecasting, MPC, and DWA. The method section is equation-dense and assumes control terminology, but the paper does provide a schematic and states the contribution in accessible terms. A nonspecialist can follow the main result, though not readily reconstruct the algorithm from the short main text alone.

## Recommendation posture

A focused and technically useful simulation study for the UAV planning community, with a credible but modest within-suite clearance result. Revision should address the unchecked fallback as an executed-control issue and provide artifacts that permit independent reproduction of the main comparison. The evidence does not establish hardware safety, real-time deployment, unseen-family generalization, or broad interdisciplinary significance.

## Risk / unsupported claims

- Novelty is supported as an integration and interface contribution, not as a demonstrated advance over the cited end-to-end planners.
- Broad scientific importance is not established. The strongest effect is a small within-suite clearance difference, while the success-rate contrast remains uncertain.
- The controller has an explicit fallback path that bypasses its stated candidate gates. No flight test or reactive-obstacle test is included.
- The “no between-state collision” statement is supported only for piecewise-linear interpolation of stored states and exogenous obstacle centers, as the paper itself specifies.
- Independent reproduction of the run and interpolation audit is not assessable from the frozen packet because it lacks implementation code and per-time trajectories.
- Readability is assessable from the complete manuscript. Its abstract and introduction are accessible, while the mathematical method remains specialist-oriented.


