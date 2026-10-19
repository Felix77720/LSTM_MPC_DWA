# Review setup

- **Input scope** Complete five-page manuscript and four-page supplementary methods PDF in the frozen round 3 packet.
- **Assessment boundary** Review of the supplied simulation study only. No hardware, reactive-obstacle, or unseen-motion-family evidence is inferred. No external literature search was performed.
- **Shared manuscript claim summary** The paper presents a 3D UAV planner that shares causal LSTM obstacle forecasts between receding-horizon MPC and trust-adaptive DWA, and reports matched simulation outcomes across four fixed and twelve random scenes.
- **Visible evidence base** Main-text method, equations, figures, results, discussion, conclusion and references, together with implementation, training, safety-screening and simulation details in the supplied supplement.
- **Missing materials affecting confidence** The packet contains no physical flight tests, tests on unseen maneuver families, or head-to-head implementation of the cited predictive DWA and UAV MPC approaches. The authors state the first two limits; comparative performance against those prior methods therefore cannot be assessed.

# Reviewer 1

**Emphasis** Originality and positioning relative to cited predictive DWA/MPC work, with attention to scientific importance and audience. All five assessment axes are considered below.

## Overall assessment

This is a clearly specified simulation study of a 3D UAV planner that aligns a 3 s LSTM obstacle forecast with MPC and DWA. The matched experiments support a bounded result. Sharing the forecast with both layers raises mean true minimum clearance by 0.080 m relative to supplying it only to DWA, with a scene-cluster 95% CI from 0.006 to 0.167 m. The corresponding success counts are 36/36 and 35/36, while the reported success-rate interval includes no difference. The paper is appropriately cautious about that contrast.

The main weakness is that the manuscript does not establish what is original in this combination relative to its own cited predictive DWA, adaptive DWA, UAV MPC, forecast-assisted MPC and intent-prediction work. Its tests compare configurations of one common MPC-DWA controller, so they establish within-planner effects rather than comparative performance against those approaches. In addition, the adaptive sampling rule is described but not isolated experimentally. These gaps leave the contribution and its broader importance under-established, even though the implementation and simulation evidence are presented in useful detail.

## Who would be interested in the results, and why

Researchers in UAV autonomy, robot motion planning and model-predictive control would be interested in the forecast-sharing architecture and its measured clearance trade-off. Researchers in predictive control more broadly may find the control-layer coupling useful if its distinction from earlier predictive DWA and forecast-assisted MPC is made explicit. The supplied results do not yet show a conclusion with clear reach beyond these communities.

## Major strengths

- The paper specifies the simulated UAV dynamics, obstacle representation, controller objectives and parameter settings, with further implementation details in the supplement.
- The principal forecast comparisons hold the controller and scene conditions fixed, use matched sampling seeds, and resample at the scene level rather than treating repeated runs within a scene as independent scenes.
- The results distinguish clearance from goal success and report uncertainty for both. The text also identifies the fallback branch, sampled collision checks and limits on generalization instead of presenting the simulation as hardware validation.
- Figure 3 and the supplementary cycle description make the relationship between prediction, MPC, DWA screening and execution legible to a specialist reader.

## Major Concerns

### R1-M1 [novelty-significance]

**Severity** Major  
**Blocking** Yes  
**Axis** originality and scientific importance  
**Claim pointer** The causal LSTM forecast shared by MPC and trust-adaptive DWA is presented as the contribution of a new 3D trajectory planner, with improved clearance in the tested simulations.  
**Evidence pointer** Main text p. 1, Abstract and Section I, including cited work [3], [4], [5], [6] and [7]; pp. 3 and 4, Section IV and Section V, especially the comparison scope and Fig. 2; references on pp. 4 and 5; Supplementary Methods p. 4, Section S4.  
**Concern** The introduction cites predictive collision avoidance for DWA [3], adaptive DWA [4], nonlinear MPC for UAVs with dynamic obstacles [5], MPC with motion forecasts [6], and intent-prediction-driven MPC [7]. It does not state precisely which technical capability remains absent from those approaches or what the present combination adds beyond them. The experiments compare forecast sources and forecast-layer variants within the same MPC-DWA controller. The supplement explicitly says these are not standalone DWA or MPC benchmarks. Thus the results support a within-planner clearance difference, but do not establish a distinct advance or comparative advantage over the closely related work identified by the manuscript itself.

The specific combination may be original, but the paper does not yet make that case verifiable. This is central to the claimed contribution and to judging whether the result is more than a useful field-local integration.

**Why it matters** Without a precise distinction from the cited predictive DWA/MPC work, the manuscript does not establish the originality or importance of its central contribution. The reported simulations cannot resolve that positioning gap by themselves.

**Resolution test** State a concise, claim-by-claim distinction from references [3], [4], [5], [6] and [7], covering forecast model, forecast use in each control layer, the adaptive sampling rule and the safety-screening role. Where comparative performance is claimed, add a fair matched comparison to representative cited approaches; otherwise keep the claims explicitly limited to the tested integration and its within-controller effects.

### R1-M2 [experimental-design]

**Severity** Major  
**Blocking** No  
**Axis** technical soundness and claim support  
**Claim pointer** The trust signal adapts the DWA candidate budget and the MPC-guided versus exploratory sample split as a material part of the proposed planner.  
**Evidence pointer** Main text p. 3, Section III.B, Eqs. (5) through (7); p. 4, Sections IV and V.B and Fig. 2(d); Supplementary Methods pp. 2 and 3, Sections S1.2 through S1.4, and p. 4, Section S4.  
**Concern** The trust rule is specified, and its possible sample count varies from 315 to 600, but the evaluation does not compare it with a fixed-budget or non-adaptive sampling policy. The reported ablations vary forecast sharing, horizon and the reference-line term. They therefore do not show whether the adaptive allocation itself improves clearance, success or computation time, or whether the reported outcomes would be similar with a simpler fixed sampling budget.

**Why it matters** The combined planner has measured outcomes, but the contribution of one prominently described design element remains unknown. This limits the evidence for the method's internal rationale without negating the reported within-planner result.

**Resolution test** Add a matched fixed-budget or non-adaptive DWA comparison using the same scenes and sampling seeds, reporting clearance, success and step time; alternatively, present trust adaptation as an implementation choice whose independent benefit was not tested.

## Minor Comments

### R1-m1 [claim-moderation]

**Severity** Minor  
**Axis** claim moderation  
**Affected element** “Safe set” and “safe control envelope” wording in the abstract and Fig. 3.  
**Evidence pointer** Main text p. 1, Abstract; p. 3, Section III.B; p. 4, Section VI; p. 5, Fig. 3 and caption; Supplementary Methods p. 3, Sections S1.4 and S2.  
**Issue** The screening criterion is based on predicted rollouts sampled at 0.1 s intervals. The fallback bypasses the DWA acceptance gates and can produce minimum true clearances below the 0.25 m rejection threshold. The paper also states that no between-sample or swept-volume check is used. These qualifications are disclosed, but “safe” can imply a continuous-time or execution guarantee that the supplied checks do not establish.
**Required correction** Describe the result as a sampled predicted-clearance screen, state clearly that fallback is outside that screen, and reserve any continuous-time safety implication for evidence that tests between-sample collisions.

### R1-m2 [reproducibility]

**Severity** Minor  
**Axis** technical soundness and reproducibility  
**Affected element** Reported increase in computation time with prediction horizon.  
**Evidence pointer** Main text p. 4, Section V.B and Fig. 2(d); Supplementary Methods p. 4, Section S3.  
**Issue** Mean step time is reported as increasing from 42.23 to 78.65 ms, against a 0.1 s control cycle, but the supplied material does not identify the timing hardware or what components and repetitions are included in the measurement.
**Required correction** Report the processor or accelerator, timing scope and aggregation procedure so readers can interpret and reproduce the real-time comparison.

### R1-m3 [writing-clarity]

**Severity** Minor  
**Axis** readability for nonspecialists  
**Affected element** Abstract, first uses of MPC and DWA.  
**Evidence pointer** Main text p. 1, Abstract.  
**Issue** The abstract expands LSTM but uses MPC and DWA without defining them. Their full forms appear in the index terms and later introduction, which may not help readers who encounter the abstract alone.
**Required correction** Expand “model-predictive control” and “dynamic window approach” at first use in the abstract.

## Technical failings that need to be addressed before the case is established

R1-M1. The manuscript needs to establish the claimed contribution relative to the specific related work it cites.

## Assessment against Nature-style criteria

- **Originality** A potentially useful combination is presented, but its distinction from the cited predictive DWA and forecast-assisted UAV MPC work is not established in the manuscript.
- **Scientific importance** The study reports a measurable clearance improvement within its tested simulator. The success-rate contrast is uncertain, and the evidence does not yet establish outstanding importance beyond a bounded engineering proof of concept.
- **Interdisciplinary readership** UAV autonomy, motion-planning and control readers are the clearest audience. Broader interest in predictive autonomy is plausible, but the packet does not demonstrate implications beyond the tested planner and simulator.
- **Technical soundness** The formulation and simulation settings are substantially specified, and the matched within-controller comparisons support the reported clearance result. The lack of direct related-method comparisons and of an ablation for trust adaptation limits the stronger contribution claims. Sampled collision checking also does not establish continuous-time safety.
- **Readability for nonspecialists** The paper follows a clear methods-to-results structure, and Fig. 3 summarizes the control loop. The dense control notation and undefined MPC and DWA in the abstract make the paper harder to enter without robotics background.

## Recommendation posture

Promising, technically detailed simulation work for the UAV planning community. The central originality claim and broader importance remain under-established until the relationship to the cited predictive DWA/MPC work is made explicit. The reported benefits should be read as within-controller simulation findings, not evidence of superiority over those prior approaches or of deployed flight safety.

## Risk / unsupported claims

- The packet does not establish that the combined architecture is a distinct advance over the cited predictive DWA and UAV MPC/forecast methods.
- Comparative performance against those cited methods is not assessable because no head-to-head implementations are included.
- The independent contribution of the trust-adaptive sampling policy is not established by the supplied ablations.
- Continuous-time collision avoidance and hardware-flight performance are not established. The paper acknowledges sampled collision checking and the absence of hardware tests.
- Generalization to unseen maneuver families is not established; the authors state that evaluation families overlap those used for training.
