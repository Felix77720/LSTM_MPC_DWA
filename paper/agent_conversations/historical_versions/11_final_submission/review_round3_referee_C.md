# Round 3 referee report, Reviewer C

## Review setup

- **Input scope** Complete five-page main manuscript and four-page supplementary methods in the frozen packet.
- **Assessment boundary** Simulation evidence, including the reported scenes, method, figures, equations, references and limitations. No hardware performance or results beyond the supplied PDFs are inferred.
- **Manuscript claim summary** The paper proposes a 3D UAV planner that shares causal LSTM obstacle forecasts between MPC and trust-adaptive DWA. It reports matched simulation outcomes in four fixed scenes and twelve random scenes, with higher mean sampled minimum clearance when both layers use LSTM than when only DWA does. The success-rate contrast is uncertain.
- **Visible evidence base** `main_revised.pdf` and `supplementary_methods.pdf`, as identified in the packet.
- **Missing materials affecting confidence** Supplementary Methods p. 4 refers to `scene_clearance_sensitivity.csv` for per-scene paired means and leave-one-out estimates, but that file is not included in the frozen packet. The manuscript also states that hardware flight and unseen motion-family testing were not done.

## Reviewer C

- **Overall assessment** The paper presents a well-specified simulation study with matched forecast comparisons and appropriately distinguishes its clearance result from the uncertain success-rate result. The strongest evidence is a modest increase in sampled minimum clearance within the tested scene suite. The main limitation is that the outcome calculation does not check collision between 0.1-s samples, including when the planner uses its fallback. The evidence also remains narrow at the scene level and does not establish operational safety or performance beyond this simulator.
- **Who would be interested in the results, and why** Researchers in UAV navigation, motion planning and robot control would be interested in the interface between forecast-based MPC and local action screening. Autonomy and safety researchers may also care about the fallback behavior and how forecast uncertainty affects clearance, but the present simulation does not establish deployment readiness.
- **Major strengths** The forecast-source comparisons use matched scenes and DWA seeds, and uncertainty is clustered by scene rather than treating the three runs within each scene as independent environments. Every attempted run is included in the clearance summary. The paper reports the success-rate interval as including no difference, identifies the fallback's sub-threshold clearances, and limits generalization to the tested simulator and motion families. The supplement provides substantial controller and training detail.

### Major Concerns

#### R3-M1 [experimental-design]

**Severity** Major  
**Blocking** No  
**Axis** Technical soundness and claim moderation  
**Claim pointer** The reported success counts and minimum-clearance outcomes characterize successful trajectory planning among moving obstacles.  
**Evidence pointer** Main paper p. 3, Section IV, where clearance and collision are evaluated at post-action 0.1-s samples and no swept-volume or between-sample check is used; main paper p. 3, Section III, fallback description; main paper p. 4, Section V.A, fallback results; Supplementary Methods pp. 2-3, Sections S1.2 and S1.4.  
**Concern** The stated success definition requires no collision sample, so it does not rule out a collision between consecutive samples. This matters in particular because the fallback bypasses the 0.25-m candidate rejection gate, and the paper reports fallback-action clearances of 0.155-0.224 m. The reported 36/36 random-scene successes are valid under the stated sampled criterion, but they do not establish collision-free continuous trajectories; the same sampling limitation can affect the reported run-level minimum clearance.  
**Why it matters** Collision avoidance is central to the planning task. A reader cannot interpret the success counts or clearance values as continuous-path safety outcomes without a check between integration samples.  
**Resolution test** Recompute collision and minimum-clearance outcomes with swept-volume checks over each 0.1-s interval, using the simulated UAV and obstacle motion, and report how the success counts and paired clearance contrast change. If only the sampled-state result is intended, label it consistently as such wherever success and clearance are interpreted.

#### R3-M2 [statistical-rigor]

**Severity** Major  
**Blocking** No  
**Axis** Technical soundness and scientific importance  
**Claim pointer** Sharing the LSTM forecast with MPC increases mean true minimum clearance by 0.080 m in the random-scene comparison.  
**Evidence pointer** Main paper p. 3, Section IV, which specifies twelve random scenes with three matched runs per scene and a scene-cluster bootstrap; main paper p. 4, Section V.A, which reports a 95% CI of 0.006-0.167 m and positive scene-level means in 8 of 12 scenes; main paper p. 4, Section V.B, which reports a one-scene, three-seed structural ablation; Supplementary Methods p. 4, Section S4.  
**Concern** Clustering the bootstrap by scene is appropriate, but the independent environmental sample is twelve scenes. The reported interval has a lower bound close to zero, and the positive leave-one-scene-out averages do not show that the effect is consistent across the scene distribution, particularly when only 8 of 12 scene means are positive. The separate horizon and layer ablation uses one repeated-encounter scene. In addition, the supplement points readers to a per-scene CSV that is absent from the frozen packet, so the reported paired scene values cannot be inspected here. No mission-level clearance requirement is given to show what an 0.080-m increase means operationally.  
**Why it matters** These results support a directional clearance difference in this simulation suite, while the 36-versus-35 success comparison has an interval that includes no difference. They do not yet establish a robust or operationally meaningful planning advantage across a broad range of dynamic scenes.  
**Resolution test** Include the per-scene paired values and the referenced CSV, show scene-level outcomes alongside the aggregate interval, and expand the independently generated scene set if a broader robustness claim is intended. State the operational clearance criterion used to interpret practical benefit, or keep the 0.080-m result as a descriptive geometric difference within this suite.

### Minor Comments

#### R3-m1 [figures-and-tables]

**Severity** Minor  
**Axis** Statistical rigor and figure presentation  
**Affected element** Figure 2, panels (b)-(d), and its caption.  
**Evidence pointer** Main paper p. 4, Figure 2 caption, which identifies run-level standard deviations for panels (b) and (c), while panel (d) shows three-seed means.  
**Issue** The plotted run-level spread in panels (b) and (c) is distinct from the scene-cluster bootstrap interval used for the main paired clearance contrast. Panel (d) summarizes only three seeds without showing their individual values.  
**Required correction** Show paired scene-level values or the cluster-bootstrap interval for the main contrast, and plot the individual seed outcomes in panel (d). Keep the caption explicit that run-level standard deviations are descriptive, not the inferential interval for the paired effect.

#### R3-m2 [reproducibility]

**Severity** Minor  
**Axis** Technical soundness and readability  
**Affected element** The safe-candidate corridor gate in Equation (6).  
**Evidence pointer** Main paper p. 3, Section III and Equation (6); Supplementary Methods p. 2, Section S1.2.  
**Issue** The main text says candidates must stay inside the flight corridor, while the supplement specifies both the altitude bounds and a 3-m constraint relative to nominal altitude. This is an important part of the DWA acceptance gate but is not explicit in the main-text definition.  
**Required correction** State the complete corridor criterion in the main methods or cross-reference the supplement at Equation (6).

- **Technical failings that need to be addressed before the case is established** No Blocking-Yes concern for the narrowly stated sampled-simulation comparison. R3-M1 prevents interpreting the reported outcomes as continuous collision-free performance.
- **Assessment against Nature-style criteria**
  - **Originality** The contribution is a specific integration of LSTM forecasting, MPC and DWA feedback. The references include adjacent work on predictive DWA and forecast-based MPC, but the introduction does not clearly separate this integration from the closest prior combinations. The advance is plausible, although its distinctiveness is not fully established.
  - **Scientific importance** The clearance comparison may be useful to UAV planning, but the evidence is a small simulation suite and does not show a success-rate advantage or an operationally defined safety improvement. The broader importance remains unproven.
  - **Interdisciplinary readership** The immediate audience is robotics and control. The work could interest broader autonomy and safety readers if the outcome were validated against continuous collision checks and operational clearance requirements.
  - **Technical soundness** The matched comparisons, scene-cluster bootstrap and detailed supplement are strengths. The sampled collision definition limits the interpretation of success and clearance outcomes, while the scene-level evidence supports only a bounded conclusion.
  - **Readability for nonspecialists** The abstract clearly states the problem and principal result, and Figures 1 and 3 help orient readers. The dense control equations and trust-adaptation terminology make the method difficult for readers outside robotics without a short plain-language explanation of how the DWA safe set changes the MPC input.
- **Recommendation posture** The manuscript supports a bounded simulation result, namely a modest sampled-clearance increase in the tested suite. A stronger collision-avoidance or engineering-performance case depends on continuous collision accounting and clearer evidence for scene-level robustness and practical clearance value.

## Risk / unsupported claims

- Continuous collision-free success is not established by checks only at 0.1-s post-action samples.
- Generalization to unseen obstacle-motion families and hardware flight is explicitly untested.
- The practical safety meaning of an 0.080-m mean clearance increase is not assessable without a stated operational clearance requirement.
- Originality beyond the integration of established planning and forecasting components is not fully distinguished from adjacent cited work.
- Per-scene paired sensitivity values cannot be checked from the frozen packet because the referenced CSV is not supplied.
