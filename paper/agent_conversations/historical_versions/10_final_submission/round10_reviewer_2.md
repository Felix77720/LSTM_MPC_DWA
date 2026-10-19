## Review setup

**Input scope**  
The specified manuscript PDF and LaTeX source, bibliography, supplementary methods PDF, frozen confirmatory protocol, and two primary result CSVs.

**Assessment boundary**  
This is a review of the four-page engineering conference paper using Nature-style criteria as a lens. I did not inspect the companion code and run archive mentioned in the supplement, or any other files.

**Shared manuscript claim summary**  
In a simulated UAV planner, giving MPC the same 3-second LSTM obstacle forecast already used by DWA increased collision-audited goal success by 6.7 percentage points across 500 matched scenes, compared with holding obstacles at their latest observed positions in MPC. The claim is limited to this simulation.

**Visible evidence base**  
The manuscript, frozen protocol, supplementary methods and results, confirmatory summary table, and scene-cluster bootstrap table.

**Missing materials affecting confidence**  
The supplement describes a local archive containing the scenario generator, controller source, model weights and run-level data. That archive is outside the supplied packet, so I could not verify it. The supplied files also do not specify the generated scene distribution in enough detail to assess which obstacle configurations the average represents.

## Reviewer 2

**Overall assessment**  
The matched comparison and scene-cluster analysis support the stated average success benefit under the tested simulation protocol. The manuscript is appropriately cautious about physical flight, unseen motion families, and comparisons with standalone MPC or DWA. Independent assessment of the scene distribution and reproduction of the result remain limited by the materials supplied.

**Who would be interested in the results, and why**  
Researchers in UAV navigation, robotics, and control may find the result useful because it tests whether a longer-horizon planner benefits from receiving a forecast already used by a local action screen. The question is relevant beyond UAVs in principle, but the evidence here is confined to one simulated planner and prescribed obstacle motion.

**Major strengths**

- The two conditions are well matched. DWA receives the same LSTM forecast in both; the intended contrast is whether MPC also receives it.
- The protocol retains all scenes and failures, matches three sampler seeds per scene, and resamples complete scene clusters for the primary interval.
- The primary endpoint and evidence criterion are specified. Secondary outcomes are identified as descriptive with unadjusted intervals.
- The discussion reports that gains were not typical of most individual scenes and limits the interpretation to the generated distribution.

### Major Concerns

**R2-M1 [reproducibility]**

**Severity** Major  
**Blocking** No  
**Claim pointer** Sharing the forecast improves average goal success across the 500-scene test distribution.  
**Evidence pointer** Manuscript pp. 2–3, Sections II and IV; frozen protocol, “Scenarios and sample size”; Supplementary Methods §S3, Table S2, p. 5, and §S8, p. 10.  
**Concern** The protocol names `generate_random_eval_scenarios(cfg, 500, 20261015)`, but the supplied files do not define the scene-generation configuration. They describe the workspace and vehicle settings, but not key features of the sampled scenes such as obstacle counts, radii, speeds, starting positions, or the mix and frequency of motion types. The supplement says a separate local archive contains the generator and run-level files, but it was not included in this review packet. The reported difference can therefore be assessed as an aggregate for the tested simulation, while the test distribution and its difficulty cannot be independently scrutinized here.  
**Why it matters** The scope of the primary estimate depends on which scenes the generator produces. Without those details, readers cannot judge what the average represents or reproduce the confirmatory run from the supplied materials.  
**Resolution test** Provide the generator configuration and distributions, including per-scene motion composition, and make the referenced code, model, and run-level archive available with the submission materials or a persistent repository.

### Minor Comments

**R2-m1 [engineering review]**

**Severity** Minor  
**Affected element** Runtime characterization  
**Evidence pointer** Manuscript p. 4, Discussion; Supplementary Methods §S3, Table S4, p. 6.  
**Issue** The reported mean step time is about 100 ms, close to the 0.1-second planning interval, but only the mean and median are given. Those summaries do not show how often individual steps exceed the nominal interval. The paper appropriately says this does not establish real-time performance.  
**Required correction** If retaining the timing comparison, add an upper-tail summary or the fraction of steps exceeding 100 ms, or state that the reported values are descriptive averages only.

**Technical failings that need to be addressed before the case is established**  
No blocking failure identified. R2-M1 is the main issue for independent verification and interpretation of the tested distribution.

**Assessment against Nature-style criteria**

- **Originality** The contribution is a clearly framed forecast-sharing ablation, rather than a claim of a new general-purpose planner. Its distinction from related predictive MPC and DWA work is credible at this narrow scope, though the advance appears incremental.
- **Scientific importance** The finding may inform engineering choices in this planner class. The evidence does not establish broad scientific importance.
- **Interdisciplinary readership** The direct audience is primarily robotics and control researchers. Broader interest is possible, but not demonstrated by this simulation alone.
- **Technical soundness** The matched design, retained failures, primary endpoint, and scene-cluster interval support the stated average comparison. The missing scene-generation specification limits reproducibility and interpretation. Prescribed nonreactive obstacles, overlapping training and evaluation motion families, and absent physical-flight validation are acknowledged boundaries, not evidence for wider claims.
- **Readability for nonspecialists** The abstract and figures communicate the core comparison, but the compressed four-page text, equations, and field-specific terminology will make the methods difficult for nonspecialists to follow.

**Recommendation posture**  
The central simulated comparison is supported as stated. Supportive for an engineering conference paper if the scene-generation specification and referenced reproducibility materials are made reviewable. The current evidence does not support conclusions about physical-flight safety or generalization beyond the tested motion families.