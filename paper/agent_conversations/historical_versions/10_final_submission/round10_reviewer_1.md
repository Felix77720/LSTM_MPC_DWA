# Independent reviewer 1

## Review setup

- **Input scope** The frozen four-page manuscript PDF and LaTeX source, bibliography, supplementary methods PDF, confirmatory protocol, method-summary CSV and scene-cluster-bootstrap CSV.
- **Assessment boundary** One independent review of the listed packet only. I did not read other review reports or treat the historical experiment as part of the 500-scene confirmatory study. The venue is unspecified, so I use Nature-style criteria as a review lens rather than assuming a Nature submission.
- **Shared manuscript claim summary** In a simulated UAV planner, giving the same 3-s LSTM obstacle forecast to MPC as well as to DWA increased collision-audited goal success versus giving that forecast to DWA while MPC held obstacle positions static. The comparison covers 500 matched scenes and 1,500 runs per condition.
- **Visible evidence base** Manuscript pp. 1–4, especially the Introduction, Sections III–VI, Figs. 1–4; the frozen confirmatory protocol; the two supplied CSVs; and Supplementary Methods, especially S4 and S6–S8, Table S7 and Fig. S2.
- **Missing materials affecting confidence** Supplementary Methods S8 describes an accompanying reproducibility archive with code and run-level records, but that archive was not in the review packet. I therefore could not independently trace the aggregate results to the per-run records or execute the analysis.

## Overall assessment

The confirmatory experiment addresses a precise, useful engineering question. Its matched comparison and scene-cluster analysis support the stated average benefit within the tested simulation. The main reservation is the scope of the advance. The evidence establishes a forecast-interface ablation, while the claimed contribution sits close to prior predictive DWA and forecast-informed MPC work. The paper is also explicit about important limits, including no standalone MPC or DWA comparison, no unseen-family test and no flight validation.

## Audience and strengths

Researchers in UAV navigation, motion planning and model-based control may care about whether a longer-horizon planner benefits from a forecast already used by a local action screen. Researchers combining trajectory prediction with control may find the ablation useful. The result has less evident reach beyond those communities because it concerns one simulated planner and a particular distribution of prescribed obstacle motions.

- The research question and contrast are clearly stated. DWA receives the same forecast in both arms, and the tested change is whether MPC receives it too.
- The protocol defines matched scenes and sampler seeds, retains failed runs, uses whole-scene bootstrap resampling and sets a positive lower confidence bound as the evidence criterion.
- The manuscript reports the primary outcome and relevant trade-offs, including clearance, collisions, infeasible stops, solver failures and path length. It also distinguishes the new comparison from the historical results.
- The claims are bounded to the tested simulation. The paper does not present the result as evidence of physical-flight safety or superiority to standalone MPC or DWA.

## Major concern

### R1-M1 [novelty-significance]

- **Severity** Major
- **Blocking** No
- **Claim pointer** The paper presents sharing a learned obstacle forecast across MPC and DWA as a contribution addressing a gap in dynamic-obstacle planning.
- **Evidence pointer** Manuscript p. 1, Introduction and references [3]–[12]; p. 3, Fig. 4 and Discussion; Supplementary Methods pp. 7–9, S6, Table S7 and Fig. S2; confirmatory protocol, “Research question and primary contrast.”
- **Concern** The tested question is specific and the manuscript does distinguish its arms, but the advance remains a narrow integration ablation. The Introduction cites predictive and adaptive DWA, UAV MPC with motion forecasts or intent prediction, forecast-informed MPC, and an LSTM–DWA UUV study, then gives limited detail on how the present forecast-sharing question differs from those approaches. The historical six-setting study is useful context: shared LSTM exceeded CV there, while its difference from DWA-only LSTM was inconclusive. That study used a different DWA rollout horizon, and the new 500-scene experiment compares only the two forecast interfaces. The new result therefore supports the value of supplying this forecast to MPC in this planner and simulation; it does not establish a general algorithmic advance or a current-protocol advantage over CV, Kalman, standalone MPC or standalone DWA.
- **Why it matters** The result appears technically supported, but its originality and scientific importance are field-local and incremental on the evidence provided. The historical CV/Kalman comparisons cannot be read as head-to-head evidence for the new setup.
- **Resolution test** Sharpen the Introduction and Discussion to distinguish the present question from the cited predictive-DWA and forecast-informed-MPC work, and state the contribution as a confirmatory forecast-interface ablation. Preserve the distinction between the historical 3-s DWA rollout and the new 1-s rollout. If broader comparative superiority is intended, it would require matched baselines under the confirmatory protocol.

## Minor comment

### R1-m1 [reproducibility]

- **Severity** Minor
- **Affected element** Reproducibility of the confirmatory simulation
- **Evidence pointer** Supplementary Methods p. 10, S8; supplied method-summary and bootstrap CSVs.
- **Issue** S8 says the source and run-level records are in an accompanying archive and that the archive is not in a public repository. The review packet contains aggregate tables but not those records or executable code, so I could not independently check the simulation outputs.
- **Required correction** Ensure the described archive is accessible with the submission or through a persistent release, and identify its version or hashes so it can be matched to the frozen protocol.

## Technical failings

None that block the central numerical claim on its stated simulation scope. R1-M1 concerns the strength and positioning of the contribution, not the validity of the reported paired comparison.

## Assessment against Nature-style criteria

- **Originality** The forecast-sharing question is clearly defined, but the distinction from prior predictive DWA and forecast-informed MPC work needs a more direct account. The supported contribution is specific to this planner interface.
- **Scientific importance** The 6.7-percentage-point average difference is supported by a positive scene-cluster interval. Its importance is primarily for the tested planner and generated scene distribution; the result does not establish broad algorithmic or deployment significance.
- **Interdisciplinary readership** Control and robotics readers, and researchers integrating prediction with planning, are the clearest audience. The findings have limited demonstrated interest beyond those areas.
- **Technical soundness** The matched design, frozen analysis rule, cluster resampling and reporting of failed runs support the stated simulation inference. Generalization remains untested across motion families, obstacle tracks are prescribed, and no flight evidence is provided; the authors appropriately limit their claims.
- **Readability for nonspecialists** The abstract and Introduction convey the planning problem and the difference between the short DWA action screen and longer MPC route. The figures help explain the setup and result. The methods remain dense with control terminology and equations, but the basic question and conclusion are understandable.

## Recommendation posture

The work is a credible, bounded engineering study. I would regard it as promising for a specialist engineering conference, subject to clearer positioning against related predictive planning work and access to the stated reproducibility archive. The supplied evidence does not establish a broad-interest claim.

## Risk and unsupported claims

- The current evidence does not establish superiority over CV or Kalman forecasts in the new 500-scene protocol, or over standalone MPC or DWA.
- The results do not establish generalization to unseen motion families, physical-flight performance or safety.
- The manuscript presents these as limitations; the review does not infer them from missing experiments.
