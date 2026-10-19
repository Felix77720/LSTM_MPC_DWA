# Reviewer A report

## Review setup

- **Input scope**
  The frozen five-page manuscript PDF, five-page Supplementary Methods PDF, manuscript LaTeX source and bibliography, supplied evidence CSVs, `review_scope.md`, and `sha256_manifest.json`. Every listed frozen file matched its manifest byte count and SHA-256 value.

- **Assessment boundary**
  This is a simulation-only assessment of three-dimensional UAV path planning among exogenous moving spherical obstacles. The visible closed-loop suite contains four fixed scenes and 12 random scenes with three matched seeds per scene. A three-seed structural ablation uses one repeated-encounter scene. The packet has no flight-test evidence and does not test generalization to unseen motion families.

- **Shared manuscript claim summary**
  A causal LSTM predicts three seconds of obstacle motion from one second of observations. The same forecast informs a 30-step MPC route and trust-adaptive DWA rollout screening. The accepted DWA candidates' control bounds constrain the next MPC first input. In the random-scene suite, sharing the forecast with both layers rather than DWA alone is associated with a 0.080 m increase in piecewise-linear minimum clearance. The success difference is 2.8 percentage points, with an interval including zero.

- **Visible evidence base**
  Main PDF pages 1 to 5, Supplementary Methods pages 1 to 5, including main Figs. 1 to 3 and Eqs. 1 to 7, Supplementary sections S1 to S4, and the manifest-listed CSV summaries and run-level audits. Relevant quantitative anchors include `evidence/paired_clearance_bootstrap.csv`, `evidence/layer_ablation_bootstrap.csv`, `evidence/scene_clearance_sensitivity.csv`, `evidence/trajectory_clearance_summary.csv`, and `evidence/shared_lstm_fallback_audit.csv`.

- **Missing materials affecting confidence**
  The supplied bibliography and Introduction provide a bounded account of prior work, but not a detailed comparison of the closest methods. No physical flight or unseen-motion-family validation is supplied, as the manuscript itself states. The code implementation is not part of this packet, so implementation-level reproduction is outside this assessment.

## Reviewer A

### Overall assessment

This is a transparent, carefully bounded simulation study. Its strongest result is the matched forecast-sharing comparison, which supports a modest clearance improvement within the tested scene suite. The paper appropriately distinguishes that result from a success-rate advantage and from a continuous-time or physical safety guarantee.

The central advance is described as an interface between established prediction, MPC, and DWA components. The paper does not yet explain precisely how that interface advances the closest cited work, and it does not isolate the trust-adaptive sampling component's contribution. This makes the originality difficult to judge. The evidence also establishes a field-local simulation result more readily than outstanding or far-reaching scientific importance.

### Who would be interested in the results, and why

Researchers in UAV motion planning, dynamic-obstacle avoidance, MPC, DWA, and learned trajectory forecasting would be interested. The paper gives a concrete implementation in which a shared obstacle forecast informs both route optimization and reachable-action screening, then measures the forecast-sharing effect under matched scenes and seeds. Readers building related simulation planners may also value the explicit fallback behavior, timing boundary, and piecewise-linear clearance audit.

Interest beyond these areas is less clear. The studied obstacles are exogenous, the closed-loop evaluation uses new instances from motion families represented in training, and no hardware results are provided. The measured clearance gain has no stated operational threshold, while the success-rate interval includes no difference.

### Major strengths

- The Introduction explicitly states that prediction, MPC, and DWA are established components and avoids claiming superiority over separately published planners (main PDF p. 1, Introduction).
- The forecast time alignment and the exchange between DWA's accepted-control bounds and MPC's next first input are specified in enough detail to identify the proposed integration (main PDF pp. 2 to 3, Method, Eqs. 3 to 7; Supplementary Methods pp. 1 to 3, S1).
- Forecast conditions are compared under matched controller settings, scenes, and seeds. The paper correctly distinguishes this design from standalone DWA and MPC benchmarks (main PDF p. 3, Evaluation Design; Supplementary Methods p. 4, S4).
- The result is reported with scene-cluster uncertainty. The manuscript also reports the scene-level direction of effects and makes clear that the success-rate interval includes no difference (main PDF p. 4, Results; `evidence/layer_ablation_bootstrap.csv`; `evidence/scene_clearance_sensitivity.csv`).
- The authors disclose important boundaries, including overlap between training and evaluation maneuver families, the ungated fallback, the interpolation assumption, and the missing hardware and cross-platform timing evidence (main PDF pp. 2 to 5; Supplementary Methods pp. 3 to 4).

### Major Concerns

#### R-A-M1 [originality]

**Severity**  
Major

**Blocking**  
No

**Axis**  
Originality and positioning

**Claim pointer**  
The contribution is an integrated planner in which one causal LSTM forecast informs both MPC and DWA, accepted DWA control bounds constrain MPC's next first input, and a trust score reallocates DWA sampling (main PDF p. 1, Introduction; pp. 2 to 3, Method).

**Evidence pointer**  
Main PDF p. 1, Introduction and references [3] to [7]. Main PDF pp. 2 to 3, Method, Eqs. 3 to 7. Supplementary Methods pp. 1 to 3, S1. Main PDF pp. 3 to 4, Evaluation Design and Results. The cited bibliography identifies predictive collision avoidance for DWA, adaptive DWA, and UAV MPC with forecast or intent inputs, but the paper's comparison remains categorical (`source/references.bib`).

**Concern**  
The Introduction identifies broad strands of related work, then calls the contribution an interface between established components. It does not distinguish the proposed shared-forecast use and accepted-control feedback from the closest cited methods in enough technical detail for a reader to judge what is original. It is also unclear which element carries the novelty claim, since forecast sharing is tested, whereas the independent contribution of trust-adaptive sampling is expressly not isolated. From the supplied material, the proposed integration is plausible, but its specific advance over the cited planning approaches is not established.

**Why it matters**  
Originality is central to the paper's case. Without a precise account of the difference from the closest prior methods, readers cannot tell whether the result is a novel planning interface, a useful combination of known elements, or mainly an empirical forecast-sharing result.

**Resolution test**  
Add a concise comparison with the closest cited DWA and UAV-MPC approaches that identifies their forecast inputs, planning layers, and control interfaces, then state which element is new here. Separate the demonstrated forecast-sharing result from the unisolated trust-adaptive sampling contribution. If the distinction remains integration rather than a new component, describe and position the advance at that scope.

#### R-A-M2 [scientific-importance]

**Severity**  
Major

**Blocking**  
No

**Axis**  
Scientific importance and interdisciplinary readership

**Claim pointer**  
The matched simulations support the integrated planner as a meaningful contribution to three-dimensional dynamic-obstacle planning, with forecast sharing improving clearance (main PDF pp. 4 to 5, Results, Discussion, and Conclusion).

**Evidence pointer**  
Main PDF p. 4, Results and Fig. 2; pp. 4 to 5, Discussion and Conclusion. The shared-forecast versus DWA-only comparison has a 0.080 m mean clearance difference, a 95% scene-cluster interval of about 0.007 to 0.167 m, and positive scene-level differences in 8 of 12 scenes (`evidence/layer_ablation_bootstrap.csv`; `evidence/scene_clearance_sensitivity.csv`). The success difference is 2.8 percentage points with a 95% interval from 0 to 8.3 points (`evidence/paired_clearance_bootstrap.csv`). The horizon and forecast-layer ablation is confined to one scene and three seeds (main PDF p. 4, Results; Supplementary Methods p. 4, S4).

**Concern**  
The evidence supports a geometric clearance difference in this suite, but does not yet establish its operational importance or broad transfer. The success comparison does not establish a success-rate improvement, four of 12 scene means are non-positive, and the one-scene ablation does not show that the component trade-offs hold across environments. The manuscript acknowledges these limits, so the issue is the strength and reach of the scientific-importance case rather than an inconsistency in the reported result.

**Why it matters**  
The most immediate readership is the UAV planning and control community. The current evidence is too bounded to show that the result has immediate, far-reaching implications for readers beyond that community. A 0.080 m increase may be useful, but the manuscript supplies no operational clearance threshold by which to interpret it.

**Resolution test**  
Either keep the contribution explicitly framed as a field-local simulation result, or establish broader importance with representative independent scene families and a decision-relevant operating criterion, followed by validation beyond the current exogenous-obstacle simulator if broader deployment implications are intended. Do not present the present clearance result as a demonstrated operational-safety or success-rate gain.

### Minor Comments

#### R-A-m1 [writing-clarity]

**Severity**  
Minor

**Affected element**  
Supplementary evidence cross-references

**Evidence pointer**  
Main PDF p. 4, Results, which refers to “Supplementary Table S2.” Supplementary Methods p. 4, S4, refers to Table S2 and Fig. S1, whereas page 5 labels the displayed items “Table 1” and “Figure 1.”

**Issue**  
The labels in the main text and the supplementary PDF do not agree, making it harder to locate the paired-scene values and interval figure.

**Required correction**  
Use one consistent table and figure numbering scheme in the main-text references, the S4 prose, and the page 5 captions.

#### R-A-m2 [writing-clarity]

**Severity**  
Minor

**Affected element**  
Introduction, closing two paragraphs

**Evidence pointer**  
Main PDF p. 1, Introduction. The paragraph beginning “Building on finite-horizon MPC” and the following paragraph beginning “Here, we develop” both summarize shared LSTM forecasts, the MPC-DWA coupling, and the evaluation.

**Issue**  
The repeated summary uses valuable space without explaining in plain language why passing the accepted DWA control bounds to the next MPC input changes the planning behavior. This slightly reduces the orientation available to interdisciplinary readers before the dense equations.

**Required correction**  
Condense the repeated contribution statement and use the freed space for one intuitive sentence explaining the practical role of that feedback between the short-term action screen and the longer-horizon route.

### Technical failings that need to be addressed before the case is established

No blocking technical failing is identified for the paper's stated, simulation-bounded clearance result. The result should remain separated from a success-rate advantage or operational safety claim. R-A-M1 and R-A-M2 are major but non-blocking concerns about the novelty distinction and the reach of the importance claim.

### Assessment against Nature-style criteria

- **Originality**
  The shared-forecast planner is a plausible integration advance, but the paper does not adequately distinguish its interface from the closest cited methods. Priority or novelty beyond the supplied positioning cannot be assessed.

- **Scientific importance**
  The clearance result is statistically compatible with an improvement within the tested suite, while the success-rate interval includes no difference. The suite does not establish outstanding importance beyond UAV planning and control.

- **Interdisciplinary readership**
  UAV planning, MPC, DWA, and learned prediction researchers are the clearest audience. Broader interest is possible, but the paper does not yet show a general principle or an operational consequence that would make the result immediately important outside these areas.

- **Technical soundness**
  The matched comparisons, scene-cluster analysis, and clearance audit support the bounded simulation claims. The inter-sample check is exact only for the stated piecewise-linear interpolation, not for the physical path. The forecast-sharing effect is measured, whereas the independent effect of trust-adaptive sampling is not. These limitations are stated and do not invalidate the narrow result.

- **Readability for nonspecialists**
  The abstract and Introduction explain the planning problem and the basic role of forecasting. The method is dense on pages 2 to 3, with many symbols and compressed algorithmic steps. A plain-language explanation of the DWA-to-MPC feedback would make the main design easier to follow across disciplines.

### Recommendation posture

Promising as a bounded simulation contribution for the UAV planning and control community, but the originality distinction and the case for broad scientific importance remain underdeveloped. A clearer comparison with the closest cited methods and a claim calibrated to the demonstrated scope are needed before the wider case is established.

## Risk and unsupported claims

- The packet does not establish superiority to separately published planners. The manuscript correctly says its forecast-source comparisons are not such benchmarks.
- The success difference between shared-forecast and DWA-only conditions is uncertain. The reported interval includes no difference.
- The paper does not isolate the independent contribution of trust-adaptive sampling. The Evaluation Design and Discussion state that no fixed-budget comparison was run.
- The no-collision statement applies to 228 stored trials under piecewise-linear interpolation of recorded UAV and obstacle centers. It is not evidence of continuous-time physical safety.
- Hardware performance, unseen motion-family generalization, and real-time operation on other platforms are not established.
- The evidence supports a clearance difference in the supplied simulation suite. No operational clearance threshold is given to establish the practical importance of 0.080 m.

