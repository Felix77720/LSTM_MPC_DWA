# Referee report B

## Review setup

- **Input scope** Complete five-page main manuscript and four-page supplementary methods in the frozen round 3 packet.
- **Assessment boundary** Assessment is limited to those two PDFs and the supplied packet description. The paper is simulation-only. No hardware or evidence beyond the packet is inferred.
- **Shared manuscript claim summary** The paper proposes a 3D UAV planner that shares causal LSTM obstacle forecasts between a receding-horizon MPC and trust-adaptive DWA. Across four fixed and twelve random scenes, it reports 12/12 and 36/36 goal successes for the shared-forecast planner. In the random-scene layer ablation, adding LSTM forecasts to MPC increases mean clearance by 0.080 m, while the success-rate interval includes no difference.
- **Visible evidence base** Main paper sections I through VII, equations (1) through (7), Figures 1 through 3, and the supplementary controller, training, simulation-setting and comparison details in S1 through S4.
- **Missing materials affecting confidence** The supplied packet does not include source code, generated obstacle trajectories, per-run results or model weights. Supplementary S4 refers to `scene_clearance_sensitivity.csv`, but that file is not part of the frozen packet. The scene-generation procedure and parameter distributions are not specified sufficiently here to regenerate the reported suite independently.

## Reviewer B

### Overall assessment

The paper gives a concrete and mostly well-specified simulation study of a forecast-sharing LSTM-MPC-DWA controller. Its matched layer ablation is relevant to the integration claim, and the reported clearance effect is carefully distinguished from the uncertain success-rate contrast. However, the evaluation establishes only clearance at sampled post-action states. The fallback branch can execute a modified command outside the DWA acceptance gates, and the supplied materials do not permit independent reconstruction of the scene-level comparison. These points materially limit the safety interpretation and reproducibility of the central result.

### Who would be interested in the results, and why

Researchers in UAV planning, mobile robotics, model predictive control, dynamic-window planning and learned motion forecasting would be interested in how a shared forecast and a DWA-derived control envelope affect clearance in a receding-horizon planner. The integration question could interest a wider autonomy audience, but the present evidence is confined to exogenous obstacle simulations and the tested motion families.

### Major strengths

- The paper defines the vehicle dynamics, workspace, obstacle geometry, clearance, success criterion and planning horizon explicitly.
- Forecast settings are compared under matched scenes, seeds and controller settings. The authors clearly state that these are forecast and layer comparisons, not standalone MPC or DWA benchmarks.
- The uncertainty analysis retains the three matched runs within each of twelve random scenes. The paper reports the success-rate contrast as uncertain rather than claiming an advantage from 36/36 versus 35/36.
- The supplement gives substantial implementation detail, including the MPC objective, DWA gates and scores, fallback sequence, network architecture, training split, optimizer settings and principal simulation parameters.
- The paper states important limits directly, including family overlap between training and evaluation, sampled collision checks, fallback clearances below the nominal rejection threshold, and the absence of hardware evidence.

### Major Concerns

#### RB-M1 [experimental-design]

**Severity** Major  
**Blocking** No  
**Claim pointer** The closed-loop results support successful collision avoidance and increased true minimum clearance for the proposed planner in the tested scenes.  
**Evidence pointer** Main paper, §II and Eq. (2), p. 2; §IV, p. 3; §§V and VI and Fig. 2, p. 4. Supplementary Methods, S2, p. 3.  
**Concern** Clearance is evaluated only at post-action states spaced 0.1 s apart, and a run is successful when no sampled state has negative clearance. The manuscript explicitly says that no swept-volume or between-sample collision check is used. These values are valid minima over the sampled true-state positions, but they do not establish the minimum clearance of the intervening UAV and obstacle trajectories. An intersection between updates could therefore be missed and counted as a successful run.  
**Why it matters** Collision avoidance is the task being evaluated. If between-sample intersections occur, both success counts and clearance comparisons could overstate path safety, even though the sampled-state calculations themselves are correctly defined. The present results support sampled-state clearance only.  
**Resolution test** Evaluate relative UAV-obstacle motion continuously between control updates, or use sufficiently fine swept-volume checks, then recompute collisions, success and minimum clearance for all trials. If the evaluation remains sample-based, label the metric consistently as sampled-state minimum clearance and keep the conclusion within that scope.

#### RB-M2 [experimental-design]

**Severity** Major  
**Blocking** No  
**Claim pointer** The DWA screening and resulting safe control envelope support the planner's obstacle-avoidance behavior.  
**Evidence pointer** Main paper, §III.B and Eq. (6), p. 3; §V and Fig. 2, p. 4; Fig. 3, p. 5. Supplementary Methods, S1.2 through S1.4, pp. 2 to 3.  
**Concern** When no candidate passes, the fallback selects a maximum-clearance sample, then changes its speed, pitch-rate and yaw-rate commands. If no corridor-valid sample exists, selection is made from all samples. The described sequence executes this modified command without reporting a new rollout through the clearance and corridor gates. Thus the candidate's predicted clearance does not by itself verify the command that is actually executed. In four of 36 random-scene runs, fallback actions had sampled true clearances of 0.155 to 0.224 m, below the 0.25 m rejection threshold. No negative sampled clearance was observed in those runs, but the PDF does not report how often fallback had no corridor-valid candidate or whether the modified command violated the corridor.  
**Why it matters** The screening gate does not govern every executed action. The reported fallback cases show that the actual planner can leave the nominal clearance margin, and its behavior when the safe set is empty is central to interpreting safety and robustness.  
**Resolution test** Clarify whether the modified fallback command is rolled out and rechecked before execution. Report fallback causes, corridor compliance, sampled and continuous clearances, and collision outcomes for every fallback action. Evaluate cases with no retained candidate and no corridor-valid candidate. If the branch remains best-effort, describe it as such and limit the safety interpretation accordingly.

#### RB-M3 [reproducibility]

**Severity** Major  
**Blocking** No  
**Claim pointer** The shared forecast raises mean random-scene clearance by 0.080 m, with a reported 95% scene-cluster interval of 0.006 to 0.167 m.  
**Evidence pointer** Main paper, §IV, p. 3 and §V.B, p. 4. Supplementary Methods, S2 and S4, pp. 3 to 4.  
**Concern** The supplement specifies the scenario seed and says that `scene_clearance_sensitivity.csv` contains per-scene paired means and leave-one-out estimates, but the CSV is not included in the supplied packet. The fixed and random obstacle tracks, scene-generator parameter distributions and per-run outcomes are also absent. Although the controller and LSTM training settings are described in detail, the packet is not sufficient to recreate the twelve-scene paired comparison or verify its scene-level sensitivity calculations.  
**Why it matters** The 0.080 m clearance effect is the principal evidence that adding LSTM forecasts to MPC improves the shared planner. Without the underlying paired scene results and enough information to regenerate the suite, independent scrutiny of this result is limited.  
**Resolution test** Provide the referenced sensitivity CSV, per-run outputs and obstacle trajectories, together with the fixed-scene definitions and random-scene generation procedure, including parameter distributions and random-number implementation. Alternatively, make an archived reproducibility package available and identify it in the manuscript.

### Minor Comments

#### RB-m1 [novelty-significance]

**Severity** Minor  
**Affected element** Introduction's description of the contribution  
**Evidence pointer** Main paper, §I, p. 1, particularly the discussion of predictive DWA and forecast-informed MPC in refs. [3] through [7].  
**Issue** The Introduction identifies the proposed coupling of LSTM, MPC and trust-adaptive DWA, but does not state precisely which methodological capability distinguishes it from the cited predictive DWA and forecast-informed MPC approaches. The system-level increment is plausible from the supplied account, but its novelty is not sharply delimited.  
**Required correction** Add a concise comparison that states the specific new coupling or feedback mechanism and the capability demonstrated by the matched layer ablation, using only distinctions the authors can substantiate.

### Technical failings that need to be addressed before the case is established

No concern is classified as Blocking Yes. RB-M1 and RB-M2 limit the safety interpretation; RB-M3 limits independent reproduction of the principal layer comparison.

### Assessment against Nature-style criteria

- **Originality** The shared forecast and DWA-derived constraint on MPC's first input form a plausible systems-level contribution. The Introduction cites relevant predictive DWA and forecast-informed MPC work, but does not clearly distinguish the new element from those strands.
- **Scientific importance** The observed clearance increase is modest and comes from twelve random scenes. The success-rate contrast is uncertain, the motion families overlap training, and there is no hardware validation. The evidence supports a useful specialist result, but does not establish outstanding broad scientific importance.
- **Interdisciplinary readership** The work is relevant to robotics, control and machine learning. The general problem of safely incorporating learned forecasts into autonomous control has wider interest, although the current evidence is narrow and simulator-bound.
- **Technical soundness** The controller, training setup and matched comparisons are described with unusual detail for a short paper. The sampled collision definition, unscreened modified fallback and missing run-level materials leave important gaps in safety interpretation and reproducibility.
- **Readability for nonspecialists** The abstract explains the problem, method and cautious success claim clearly. Figures 1 and 3 help orient readers. The main method still relies on dense notation and MPC/DWA terminology, so a reader outside robotics may not follow the command sequence or the relationship between the safe set and fallback without the supplement.

### Recommendation posture

The study is promising for a specialist UAV-planning audience, with a useful matched test of forecast sharing. Substantial revision is needed to bound the collision-avoidance claim, characterize the fallback path and make the main comparison independently reproducible. A broad-interest case is not established by the supplied evidence.

### Risks and claims not established by the supplied material

- Continuous collision-free motion is not established by the sampled post-action checks.
- The success-rate difference between shared LSTM and DWA-only LSTM does not establish a success advantage. The manuscript appropriately reports that its interval includes no difference.
- Generalization to unseen maneuver families, reactive obstacles, hardware flight and deployment performance is not established. The manuscript acknowledges these boundaries.
- The scene-level clearance analysis cannot be independently audited from the packet because the cited sensitivity CSV and underlying run materials are not included.


