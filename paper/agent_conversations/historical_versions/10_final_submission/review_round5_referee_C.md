# Reviewer 3

## Review setup

- **Input scope:** I reviewed the frozen packet at `review_round5_packet\frozen`, including the manuscript PDF and TeX source, bibliography, three figure PDFs, supplementary PDF and TeX source, README, and CSV files. All 22 manifest entries matched their recorded SHA-256 hashes.
- **Assessment boundary:** This assessment is based only on those frozen files. The packet describes separate source code and model weights, which were not included; I did not independently reproduce the simulations or validate the cited literature.
- **Shared manuscript claim summary:** A causal LSTM forecast is supplied to both MPC and DWA, with DWA’s accepted-control bounds constraining the first input of a fresh MPC solve. Matched simulations report higher piecewise-linear minimum clearance for shared forecasting than for LSTM supplied only to DWA; the success-rate difference remains uncertain.
- **Visible evidence base:** Main PDF and source, bibliography, three main figures, supplementary methods and figures, configuration and summary tables, and run-level audit CSVs.
- **Missing materials affecting confidence:** Controller source code, trained model weights, and the MATLAB run bundles are not in this packet, as the supplementary README states.

## Overall assessment

The paper makes a bounded systems contribution: it combines established prediction, MPC, and DWA components through a particular forecast-sharing and control-feedback cycle. Its distinction from prior work is stated in the Introduction, though the originality lies in this integration rather than in a new predictor or optimizer. The reported clearance result is presented with an appropriate scene-cluster interval, and the paper clearly states that the success-rate interval includes no difference.

The audience is primarily UAV robotics, control, and motion-prediction researchers. The problem setup and result story are easy to follow, and the figures correspond well to the text. The main accessibility cost is the dense controller description, where the central sequence of operations is spread across equations, long prose, a flowchart, and supplementary steps.

## Who would be interested in the results, and why

Researchers in UAV navigation, model predictive control, and dynamic-obstacle avoidance may find the forecast-sharing comparison useful. Readers working on learned motion prediction may also be interested in how one forecast is consumed by both route optimization and local action screening. Broader interest is limited by the simulated, exogenous obstacle trajectories, overlap between training and evaluation maneuver families, and absence of physical flight tests, all of which the paper acknowledges.

## Major strengths

- The Introduction states the proposed coupling clearly: one forecast informs both planning layers, and DWA-accepted controls constrain MPC’s next first input.
- Figure 1 addresses both requested visual tasks. Panel (a) gives a UAV-to-goal scene schematic; panel (b) presents the route comparison with labeled \(x\), \(y\), and \(z\) axes in metres.
- Figure 2 gives a compact view of the planning cycle and makes the fallback branch visible. The caption and Methods also state that the fallback is not rechecked against the candidate gates.
- The Evaluation Design separates fixed and random scene suites, describes the matched seeds, and explains the scene-cluster bootstrap. The supplementary tables and CSVs provide paired scene values and run-level clearance audits.
- The discussion and conclusion bound the claims to the tested simulator and maneuver families. They also distinguish the clearance result from the uncertain success-rate difference and disclose that trust-adaptive sampling was not independently evaluated.

## Major Concerns

### R3-M1

- **Severity:** Major
- **Blocking:** No
- **Axis:** Readability and interdisciplinary readership
- **Claim pointer:** Method, “MPC–DWA Guidance, Candidate Screening and Feedback,” especially Eqs. (5)–(7), and the claim that the accepted DWA control bounds constrain only the first input of a fresh MPC solve.
- **Evidence pointer:** Main PDF pp. 2–3, Figure 2; Supplementary Methods §S1.4, p. 2.
- **Concern:** The central algorithm is described through a long sequence of prose and equations in the main paper. Figure 2 is a useful flowchart, but it leaves details such as the safe-set-to-MPC feedback step at a high level. The more explicit eight-step procedure is in Supplementary Methods §S1.4. As a result, readers must assemble the exact cycle from several locations to distinguish the paper’s coupling from a generic MPC–DWA pipeline.
- **Why it matters:** This coupling is the main methodological contribution. Its role and order of operations should be apparent before readers work through the controller’s parameter and score definitions.
- **Resolution test:** Place a short algorithm or pseudocode block beside the explanation in Method §“MPC–DWA Guidance, Candidate Screening and Feedback.” State the forecast, MPC, DWA screening, safe-set feedback, action execution, and fallback steps in order. Keep detailed component definitions and parameter settings in the supplementary methods.

## Minor Comments

### R3-m1

- **Severity:** Minor
- **Axis:** Figure readability
- **Affected element:** Figure 3(d), main PDF p. 4
- **Evidence pointer:** The horizon-30 points and the “Shared,” “Ref. off,” “DWA only,” and “MPC only” labels cluster at the right edge of panel (d).
- **Issue:** At the paper’s single-column scale, it takes effort to match each point group to its condition.
- **Required correction:** Add a compact key or use direct labels with clearer spacing. Keep the three-seed points visually distinct from the mean and standard-deviation summary described in the caption.

### R3-m2

- **Severity:** Minor
- **Axis:** Interdisciplinary accessibility
- **Affected element:** Method, “MPC–DWA Guidance, Candidate Screening and Feedback,” Eq. (5), and Figure 2
- **Evidence pointer:** Trust \(\tau\) is defined as a weighted combination of safety, goal progress, route tracking, and smoothness.
- **Issue:** “Trust” can suggest calibrated confidence, while the manuscript defines a controller score from hand-specified components.
- **Required correction:** Briefly state that \(\tau\) is a heuristic controller score, not a probability or calibrated uncertainty estimate.

### R3-m3

- **Severity:** Minor
- **Axis:** Supplementary source completeness
- **Affected element:** Supplementary Methods §S4, Figure S1
- **Evidence pointer:** The frozen supplementary PDF includes Figure S1 on p. 6. The frozen `supplementary_methods.tex` references `figures/scene_clearance_sensitivity.pdf`, but that asset is absent from the frozen supplementary directory and manifest.
- **Issue:** The supplementary PDF is readable, but the included TeX source cannot reproduce that figure from the frozen packet as supplied.
- **Required correction:** Include the referenced figure asset, or document and provide the generation step that produces it from `scene_clearance_sensitivity.csv`.

## Technical failings that need to be addressed before the case is established

None apparent for the paper’s bounded within-simulator clearance claim. External validity remains limited by exogenous simulated obstacles, overlapping training and evaluation maneuver families, and the absence of physical flight tests. The paper also states that the independent contribution of trust-adaptive sampling has not been measured.

## Assessment against the requested criteria

- **Originality:** The integration and feedback arrangement is a distinct systems-level contribution. The manuscript differentiates it from forecast use in a local evaluator or a horizon optimizer, but does not establish that the individual LSTM, MPC, or DWA components are novel.
- **Scientific importance:** The clearance improvement is relevant to the tested planning setting. Its practical importance remains uncertain beyond that simulator, especially given the modest number of random scenes and the untested physical-flight setting.
- **Interdisciplinary interest:** The question connects learned obstacle forecasting with control and UAV navigation. The abstract, section flow, and figures provide a good entry point, though the controller details are demanding for readers outside robotics and control.
- **Technical soundness:** The comparison design and uncertainty treatment are explained, and clearance is audited both at sampled states and under the stated piecewise-linear interpolation. The paper appropriately limits what these checks say about physical motion.
- **Readability:** The problem-to-method-to-evaluation flow is coherent. Figure 1’s scene schematic and 3D route comparison meet their stated roles, and Figure 2 helps orient readers. The principal improvement is a concise algorithm block beside the controller explanation.