# Reviewer 3

## Review setup

- **Input scope** The frozen four-page English manuscript and LaTeX source, figures 1 to 4, supplied simulation protocols and outcome summaries, and the bilingual reader with its source map.
- **Assessment boundary** Simulation-only evidence for one integrated MPC-DWA planner, comparing two forecast interfaces across 500 matched scenes and three seeds per scene. Obstacles follow prescribed paths and do not react to the UAV. No physical-flight test, held-out motion-family test, or standalone MPC or DWA benchmark is supplied.
- **Shared manuscript claim summary** DWA receives the same LSTM forecast in both conditions. The comparison changes MPC from the latest observed obstacle positions to the same 3-s forecast. Across the tested simulation distribution, the shared-forecast condition has a 6.7 percentage-point higher goal-arrival rate, with a 95% scene-cluster bootstrap interval from +4.2 to +9.2.
- **Visible evidence base** Main manuscript pages 1 to 4, figures 1 to 4, LaTeX and bibliography, confirmatory protocol, scenario specification and manifest, run audit, method summaries, paired scene outcomes and bootstrap summaries, historical comparison summaries, and the English-Chinese paper.
- **Missing materials affecting confidence** The supplied material does not establish performance beyond the simulated distribution. The Supplementary README describes a MATLAB source and model archive, but that archive is not present in this frozen packet, so independent reconstruction of the complete controller is not assessable here. The run audit and scene-level records do permit scrutiny of the reported outcome contrast. Novelty relative to literature beyond the cited framing is also not assessable from this packet alone.

## Reviewer 3

- **Emphasis** Interdisciplinary readership and readability for nonspecialists.
- **Overall assessment** The paper poses a clear, bounded question about where a shared obstacle forecast enters a multistage planner. Its matched comparison and outcome accounting support the stated average benefit within the tested simulation. The manuscript also openly limits the result to prescribed obstacle paths and the trained motion families. The four-page presentation is dense, but the introduction and planner diagram give readers without UAV-planning experience a workable account of why long-horizon route planning and short-horizon action screening are both used. The finding is useful to robotics and autonomous-systems researchers, although its broader scientific importance remains limited by the simulation scope and the modest, domain-specific design advance.
- **Who would be interested in the results, and why** Researchers in robot motion planning, UAV autonomy, model predictive control, and learned trajectory prediction may use the result when deciding whether a forecast should inform both a route optimizer and a local action screen. Readers interested in dependable autonomy may also value the explicit distinction between goal success, collision, and infeasible stops. The current evidence is unlikely to support broader claims about deployment or flight safety.
- **Major strengths** The introduction explains in ordinary terms that DWA screens actions the vehicle can execute soon, whereas MPC plans farther ahead and depends on obstacle forecasts. Figure 2 summarizes the observe-predict-plan-screen-execute cycle in a concise top-to-bottom diagram. Figure 3 presents both the per-condition goal-arrival rates and a scene-level outcome summary. Its caption and the Results text state the paired difference and scene-cluster interval, while the discussion makes clear that most scenes tie and the average gain is concentrated in a subset. Figures 2 and 3 are legible at the manuscript's one-column printed scale. The earlier CV, Kalman, MPC-only LSTM, DWA-only LSTM, and shared-LSTM comparisons remain available in the supplement, while figure 4 is explicitly identified as a historical example. The reviewed English and Chinese text consistently reports the comparison, counts, uncertainty, and simulation limits.
- **Major Concerns** None identified from the supplied material. There are no Blocking Yes concerns.
- **Minor Comments**

  **Concern ID** R3-m1 [figures-and-tables]  
  **Severity** Minor  
  **Blocking** No  
  **Affected element** Figure 3 uncertainty display  
  **Evidence pointer** p.3, Fig. 3(a-b) and its caption; Results, p.3; supplementary file `confirmatory_cluster_bootstrap.csv`  
  **Issue** Panel (a) places intervals around each condition's success rate, while the central inferential quantity is the paired scene-cluster difference. The caption and Results text report the paired difference and its interval, so the result is available, but the graphic does not visually distinguish the per-condition intervals from the paired interval. A reader may compare the two sets of whiskers as if their overlap were the test of the matched contrast.  
  **Required correction** Label the whiskers explicitly as per-condition scene-cluster intervals and show the paired difference with its interval as a separate graphic annotation, or otherwise make the distinction visible in the figure.  
  **Resolution test** A reader can identify which intervals describe each condition's rate and which interval describes the paired contrast directly from the figure and caption.

  **Concern ID** R3-m2 [reproducibility]  
  **Severity** Minor  
  **Blocking** No  
  **Affected element** Reproducibility package described in the supplement  
  **Evidence pointer** Supplementary README, “Tables, diagnostics and reproduction details”; frozen packet file set  
  **Issue** The README says that a ZIP containing MATLAB source, the trained model, runs, analysis scripts, figure data, and checksums is supplied with the revision, but that ZIP is absent from the supplied packet. The included run audit, scene manifest, and bootstrap output support outcome-level review, but they do not permit reconstruction of the full simulation from this packet.  
  **Required correction** Include the described archive with the review materials or revise the README to state where the archive can be retrieved.  
  **Resolution test** The named archive is available with a matching checksum, or the README provides a working retrieval location for the same materials.

- **Technical failings that need to be addressed before the case is established** None identified from the supplied material. The missing archive limits independent reproduction but does not by itself undermine the reported contrast because run-level and scene-level outcome records are supplied.
- **Assessment against Nature-style criteria**
  - **Originality** The manuscript identifies a specific planner-interface question and distinguishes its matched ablation from prior forecasting and DWA-MPC combinations cited in the introduction. The contribution appears original at this narrow interface level, but is incremental rather than a broad conceptual advance. Priority against the full literature cannot be established from the supplied packet alone.
  - **Scientific importance** The 500-scene comparison supports an average improvement in this simulated planner. The high proportion of scene-level ties and the lack of physical validation keep the importance field-local and prevent an inference about operational UAV performance.
  - **Interdisciplinary readership** Robotics, control, autonomous systems, and machine-learning readers who work on trajectory prediction are the clearest audience. The general problem of planning under uncertain moving obstacles may interest adjacent communities, but the paper does not yet show consequences beyond this simulation setting.
  - **Technical soundness** The matched forecast-interface contrast, complete denominator, scene-cluster resampling, and separate treatment of secondary outcomes make the central simulation result interpretable. The manuscript correctly states that obstacle paths are prescribed, the LSTM is a point predictor without calibrated uncertainty, motion families overlap between training and evaluation, and standalone planner comparisons are absent. These restrictions are reflected in the claims rather than hidden.
  - **Readability for nonspecialists** The abstract and introduction define the roles of MPC and DWA in accessible terms, and Figure 2 provides a useful process overview. Equations and implementation detail make the methods dense, but the four-page structure remains followable for a reader who uses the diagram and the clear primary comparison in Figure 3. The bilingual sections reviewed match the English account on the experimental contrast, numerical results, and evidence limits.
- **Recommendation posture** The central simulation finding is supported and appropriately bounded. The paper would be clearer with the figure-uncertainty distinction made explicit and the cited reproduction archive supplied or accurately located. Its significance is strongest for the path-planning community, with broader interest remaining prospective.

## Risk / unsupported claims

- No physical-flight safety, unseen-motion-family generalization, or standalone MPC or DWA superiority is established. The manuscript explicitly states these limits.
- The reported success-rate difference and confidence interval are supported by the supplied confirmatory summaries and scene-cluster analysis records. They support an average effect over the generated simulation distribution, not success in a new individual scene.
- The proposed explanation that earlier route adjustment helps avoid future encounters is presented as an interpretation consistent with the route examples, not as a demonstrated mechanism.
- The paper's priority claim is only assessable against the literature cited in the packet. No broader literature search was part of this packet-based review.

