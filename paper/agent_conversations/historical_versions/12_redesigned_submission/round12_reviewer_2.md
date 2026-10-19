# Round 12 pre-submission review

## Review setup

- **Input scope** The frozen four-page manuscript PDF and LaTeX source, the 11-page supplementary methods PDF, frozen experiment protocols, scene manifest, outcome summaries, and included figures.
- **Assessment boundary** Simulation-only UAV path planning in prescribed obstacle tracks. No physical-flight results or held-out maneuver-family evaluation are included. I assessed only the frozen Round 12 packet.
- **Shared manuscript claim summary** Within one integrated MPC–DWA planner, the authors compare giving the same 3-s LSTM obstacle forecast to both MPC and DWA against giving it to DWA while MPC holds obstacles at their latest observed positions. Across 500 matched scenes and three seeds per scene, the shared-forecast condition has a reported 6.7 percentage-point increase in collision-audited goal success.
- **Visible evidence base** The manuscript defines a 0.1-s planning cycle, a 3-s MPC route horizon, a 1-s DWA action rollout, and the forecast and safety checks. Supplementary Methods S1–S4 provide controller, model, scene-generation and analysis details. The packet includes primary run and scene summaries and the historical baseline figures and records.
- **Missing materials affecting confidence** The supplementary README and Supplementary Methods S8 refer to an accompanying `reproducibility_package.zip` and checksum, but neither appears in the frozen packet. I therefore cannot inspect the MATLAB source or trained model artifact or verify that archive’s availability to a submission reader. The primary experiment’s observation-noise and delay condition is also not specified in the methods or frozen protocol.

## Reviewer 2

- **Emphasis** Originality and scientific importance, with assessment of all five criteria.
- **Overall assessment** The manuscript asks a clear, bounded question about sharing one learned obstacle forecast across two planning horizons. The 500-scene matched comparison supports the reported average benefit in the tested simulation distribution, and the paper is careful not to treat the earlier multi-method experiment as the new confirmatory result. The design and planner interactions are substantially clearer than in a typical compressed four-page methods paper. The case for originality and broader significance remains modest, and the primary sensing condition needs to be stated for the result to be reproducible.
- **Who would be interested in the results, and why** UAV navigation, robotics and control researchers working with learned motion forecasts and receding-horizon planners would be interested in whether feeding a longer-horizon forecast to MPC adds value after a local DWA screen already uses that forecast. Researchers in machine learning for control may also care about the interface-level ablation. The current evidence is less likely to engage readers outside these areas because it is a simulation result on one generated distribution with overlapping training and evaluation maneuver families.
- **Major strengths**
  - The main question is isolated as a forecast-input change within the same integrated planner. The paper explicitly says it does not compare against standalone MPC or standalone DWA.
  - The text and Fig. 2 explain the complementary roles of MPC and DWA. The 3-s route horizon, 1-s action rollout, 0.1-s replanning interval, clearance thresholds, flight corridor and braking gate are specified across the main text and Supplementary Methods.
  - The primary experiment retains all 500 scenes, uses three matched seeds per scene, and resamples complete scene clusters. The main result and supplement report the run counts, paired interval, failures and scene-level outcome distribution.
  - Historical CV, Kalman and multi-method evidence remains visibly separate in the main text and Fig. 4, and in Supplementary Fig. S2 and Table S7. The paper notes that the older experiment used a different DWA rollout and does not pool those data with the primary result.
  - The manuscript bounds its claims to the tested simulation and identifies the missing flight and unseen-family validation.

### Major Concerns

#### R2-M1

- **Severity** Major
- **Blocking** No
- **Axis** Originality, scientific importance and interdisciplinary readership. Internal technical axis novelty-significance.
- **Claim pointer** The paper presents a forecast-sharing choice within an LSTM–MPC–DWA planner as its new contribution and argues that supplying the longer forecast to MPC adds goal-arrival benefit.
- **Evidence pointer** Main manuscript PDF, p. 1, Introduction paragraphs 2–3; p. 4, Discussion and Conclusion. Supplementary Methods, p. 8, section S6.2 and Table S7; p. 10, Supplementary Fig. S2.
- **Concern** The Introduction identifies adjacent prior approaches, including DWA with higher-level guidance, learned forecasts supplied to MPC, and an LSTM–DWA system, but it does not make the precise distinction from those cited approaches sufficiently explicit. The new result is a useful, carefully matched ablation of one forecast interface within a fixed planner. Its advance is therefore narrower than the title and general method framing may initially suggest, and the manuscript does not yet establish why this incremental controller-level result has importance beyond UAV planning.
- **Why it matters** The technical result may be credible while its originality and scientific importance remain difficult for readers to judge. A sharper distinction from the cited work is needed to assess whether the finding changes understanding of forecast use in multistage planning or documents a context-specific implementation choice.
- **Resolution test** Add a concise comparison of the cited planner interfaces, identifying which stage receives which forecast and what the present matched experiment adds. Keep the historical six-setting results separate and preserve the explicit statement that neither experiment is a standalone MPC or DWA benchmark. State the contribution and its scope in terms of the tested interface effect, and explain the specific insight that makes this result meaningful beyond the immediate application.

#### R2-M2

- **Severity** Major
- **Blocking** No
- **Axis** Technical soundness and reproducibility. Internal technical axis reproducibility.
- **Claim pointer** The primary 500-scene comparison estimates the benefit of supplying the LSTM forecast to MPC when DWA already receives that forecast.
- **Evidence pointer** Main manuscript PDF, p. 2, subsection “Shared LSTM Forecast”; Supplementary Methods, p. 4, section S2 and Table S1; p. 6, section S4; supplementary/confirmatory_experiment_protocol.md; supplementary/supplementary_methods.pdf, p. 7, section S5.
- **Concern** The manuscript describes training histories that include clean inputs, one-step-delayed inputs and position noise, but does not state which observation stream is used in the primary 500-scene runs. The protocol specifies the planner arms and horizons but not whether their input histories are clean, delayed, noisy or a defined mixture. The separate sensing-pressure check in S5 changes observation conditions in one repeated-encounter scene and does not resolve the primary experiment’s condition.
- **Why it matters** Obstacle-state quality directly affects the 3-s forecast supplied to MPC and therefore the result being interpreted. Without the primary observation condition, readers cannot reproduce the exact comparison or tell what sensor assumptions the reported 6.7-point difference represents.
- **Resolution test** State the exact primary observation model for position, velocity and heading over the 1-s history, including whether noise or delay is applied and how it is parameterized. If the primary runs use clean state observations, say so explicitly. Distinguish this condition from the training augmentation and the separate S5 diagnostic.

### Minor Comments

#### R2-m1 [writing-clarity]

- **Severity** Minor
- **Axis** Readability for nonspecialists.
- **Affected element** The compact label “DWA-only LSTM” in the abstract, method description and Fig. 3.
- **Evidence pointer** Main manuscript PDF, pp. 1–3, abstract, subsection “Shared LSTM Forecast” and Fig. 3 caption.
- **Issue** The surrounding text explains that this is still the integrated MPC–DWA planner and that only DWA receives the LSTM forecast. A first-time reader could nevertheless read “DWA-only” as a standalone DWA comparison.
- **Required correction** Use a compact label such as “LSTM-to-DWA only” with “MPC uses latest positions” alongside it in the abstract or result figure. Keep the wording explicit that both conditions use the integrated planner.

- **Technical failings that need to be addressed before the case is established** No Blocking-Yes concern is identified. R2-M2 is a major reproducibility issue that should be resolved for the primary comparison to be reproducible. R2-M1 concerns the strength and scope of the novelty and significance case.

- **Assessment against Nature-style criteria**
  - **Originality** The forecast-sharing interface is a plausible and precisely testable contribution. Its distinction from the adjacent approaches cited in the Introduction needs a more direct explanation.
  - **Scientific importance / significance** The observed average improvement is supported for the tested simulation distribution. The manuscript has not shown that the benefit is robust to different sensing conditions, unseen motion families or physical dynamics, and it appropriately avoids claiming those results. The broader importance is therefore not yet established.
  - **Interdisciplinary readership interest** The finding should interest UAV planning, robotics and control readers. The current result has limited demonstrated reach beyond those communities.
  - **Technical soundness / technical failings** The matched design, all-run denominator, scene-cluster bootstrap and declared secondary outcomes are strengths. The planner horizons, major constraints and fallback logic are well explained across the paper and supplement. The primary observation condition is missing, and the code and model archive named by the supplement is not available in this frozen packet.
  - **Readability for nonspecialists** The Introduction explains the high-level difference between short-horizon action screening and longer-horizon route planning, and Fig. 2 makes the cycle accessible. Equations and the trust-index scoring remain specialized, but the supplement provides definitions and the main text warns that trust is not forecast confidence. The label issue in R2-m1 is localized.
- **Recommendation posture** The narrow in-simulation result is supported by the reported matched comparison. Before a stronger Nature-style case can be made, the manuscript needs a clearer account of what is new relative to its cited approaches, and the primary observation condition should be documented. This is a reviewer assessment, not an editorial decision.

## Risk / unsupported claims

- Physical-flight performance and unseen-motion-family generalization are not established. The manuscript states both limits and does not claim those results.
- The packet supports the reported primary outcome and uncertainty summary, but does not permit an independent rerun. The ZIP archive and checksum listed in supplementary/README.md and Supplementary Methods S8 are absent from the frozen packet inventory.
- Originality is assessed only against the references and distinctions visible in the frozen packet. The packet does not establish a broader literature-level novelty claim.
- The historical CV, Kalman and multi-method results are visibly separate from the new 500-scene comparison. No standalone MPC or standalone DWA performance claim is supported or made.

