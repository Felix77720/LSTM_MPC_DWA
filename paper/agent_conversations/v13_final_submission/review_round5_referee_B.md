## Review setup

- **Input scope:** I reviewed the frozen packet’s `main_revised.pdf`, `main.tex`, `references.bib`, three figure PDFs, and files in `supplementary`.
- **Assessment boundary:** All entries matched the adjacent SHA-256 manifest. I used only the frozen packet. I assessed prior-work positioning from the manuscript’s descriptions and bibliography, without consulting external papers or other review materials.
- **Evidence base:** The evaluation comprises four fixed scenes and 12 random scenes, with three matched seeds per scene. The random-scene forecast-layer comparison uses a 12-scene cluster bootstrap.
- **Missing materials affecting confidence:** The supplementary README describes a separate reproducibility archive containing code and model weights, but that archive is not part of the frozen packet.

## Reviewer 2

### Overall assessment

The manuscript describes a coherent simulation study of an LSTM forecast shared between MPC and DWA, with a DWA-approved control envelope passed to MPC. The claimed originality lies in this integrated planning design, rather than in the LSTM predictor or timing results. The clearest evidence is a within-suite increase in minimum clearance when the forecast is shared with MPC and DWA instead of supplied only to DWA. The scene-cluster interval is positive, while the success-rate interval includes no difference.

The work’s originality and significance remain underestablished. The introduction names relevant forecast-enabled DWA and UAV MPC studies but does not show how the proposed coupling differs from the closest systems. The experiments vary forecast source and layer exposure inside a common MPC–DWA controller; they do not measure the separate contribution of the accepted-control feedback or trust-adaptive sampling. The results support a limited simulation finding, not broad evidence of planner superiority or practical safety benefit.

### Who would be interested in the results, and why

Researchers in UAV navigation, motion planning, and predictive control may be interested in sharing obstacle forecasts between a horizon optimizer and a local action filter. The present evidence is most relevant to that robotics community. Broader autonomous-systems readers would need evidence that the approach transfers beyond the tested simulator, exogenous spherical obstacles, and motion families represented in predictor training.

### Major strengths

- The manuscript identifies the proposed integration clearly: one forecast informs MPC and DWA, and the accepted DWA controls constrain MPC’s first input.
- The forecast-layer comparison is matched by scene and seed. The report distinguishes the 12 independent random scenes from the 36 runs and gives a scene-cluster interval for the paired clearance result.
- The authors state key limits, including overlap between training and evaluation maneuver families, exogenous obstacle paths, unmeasured trust-adaptive sampling, and the piecewise-linear assumption in the between-state collision audit.

### Major Concerns

#### R2-M1 [novelty-significance]

**Severity:** Major  
**Blocking:** No  
**Axis:** Originality  
**Claim pointer:** The central advance is integrating a shared LSTM forecast across MPC and DWA, with DWA-accepted control bounds fed back to MPC.

**Evidence pointer:** Introduction, second paragraph, and Method, “MPC–DWA Guidance, Candidate Screening and Feedback”; Supplementary Methods S1.1; Fig. 2. The relevant cited-work positioning is References [3]–[7]. Evaluation Design and Fig. 3(d) describe the layer and horizon comparisons.

**Concern:** The manuscript describes relevant prior work on predictive collision avoidance for DWA, adaptive DWA, UAV MPC with obstacle forecasts, and intent-driven MPC. It does not directly compare those approaches with the proposed coupling or establish whether any already combine forecast sharing with DWA-to-MPC control feedback. The experiments also do not isolate the value of the accepted-control envelope or trust-adaptive sampling. They test forecast-source and forecast-layer variants within the same MPC–DWA controller. Thus, the forecast-sharing result is identifiable, but the originality and contribution of the integrated path-planning method remain unclear.

**Why it matters:** The manuscript’s principal originality claim rests on the integrated planner. Without a feature-level distinction from the closest cited methods, the reader cannot tell whether the contribution is a new coupling, an implementation of familiar components, or a narrower forecast-sharing comparison.

**Resolution test:** Add a concise comparison with the closest cited methods that identifies which planning layer receives predictions, how local action screening interacts with MPC, and which command is executed. Isolate the accepted-control feedback in a matched ablation, or narrow the contribution claim to the forecast-sharing effect that the current comparisons test. Do not present the LSTM forecast or runtime measurements as evidence of algorithmic novelty.

#### R2-M2 [claim-moderation]

**Severity:** Major  
**Blocking:** No  
**Axis:** Scientific importance and claim moderation  
**Claim pointer:** The conclusion presents LSTM–MPC–DWA as an integrated trajectory-planning method and reports that sharing forecasts increases minimum clearance.

**Evidence pointer:** Evaluation Design; Results, “Route Outcomes and Forecast Accuracy” and “Forecast-Sharing Ablation”; Discussion and Conclusion; Fig. 3; Supplementary Methods S2 and S4, including Table S2.

**Concern:** The 0.080 m shared-forecast clearance increase is supported within this suite: its scene-cluster 95% interval is 0.007–0.166 m, and eight of 12 scene means are positive. The success-rate difference is 2.8 percentage points, with a 95% interval of 0–8.3 that includes no difference. The study has 12 independent random scenes, four fixed scenes, and a repeated-encounter ablation in one scene. Evaluation maneuvers overlap the training families, obstacles are exogenous, and no physical-flight or unseen-family result is provided. These results do not establish improved goal success, generalization, or an operational safety benefit for the integrated method.

**Why it matters:** The within-suite clearance result is useful field-specific evidence, but it does not yet establish broad scientific importance or the practical value of the integrated planner beyond the tested configuration.

**Resolution test:** Keep the contribution framed as a simulation result for the tested suite, and distinguish the positive clearance estimate from the uncertain success-rate difference. If the manuscript argues for broader importance or general planner benefit, add independently generated scenes from unseen maneuver families and a direct comparison against relevant complete-planner baselines.

### Minor Comments

#### R2-m1 [figures-and-tables]

**Severity:** Minor  
**Affected element:** Fig. 3(b), “Minimum clearance”  
**Evidence pointer:** Fig. 3(b) and its caption; Supplementary Table S2.

**Issue:** The caption correctly identifies the bars as descriptive run-level standard deviations rather than scene-cluster uncertainty. The panel does not itself show the number of independent scenes or the paired forecast-layer estimate, which is the main inferential result.

**Required correction:** Add the independent scene count and the paired clearance estimate with its cluster interval in the caption or adjacent text, so readers do not interpret the run-level bars as the uncertainty for the paired effect.

### Technical failings that need to be addressed before the case is established

No blocking technical failing is identified from the frozen packet. R2-M1 and R2-M2 are nonblocking concerns about originality and the scope of the significance claim.

### Assessment against the requested criteria

- **Originality:** The integration of a shared forecast and DWA-to-MPC feedback is the plausible contribution. Its distinction from the cited prior methods is not yet established.
- **Scientific importance:** The positive clearance estimate is a meaningful result within the tested random-scene suite. The goal-success comparison is uncertain, and the current study does not establish broad or operational significance.
- **Interdisciplinary interest:** The work is most directly relevant to UAV robotics and predictive control. Interest beyond those fields remains prospective.
- **Technical soundness:** The main comparison is matched, and the uncertainty analysis treats scenes as the resampling unit. The empirical scope is limited by the small number of scenes, overlapping maneuver families, and lack of a direct ablation of the feedback component.
- **Readability for nonspecialists:** The manuscript explains the planning cycle and reports the limits clearly, but its compressed treatment of related work and dense controller terminology make the contribution harder to assess for readers outside UAV control.

**Assessment posture:** The packet supports a narrow, simulation-specific forecast-sharing result. A stronger originality and significance case requires clearer comparison with prior methods and claims calibrated to the tested evidence.
