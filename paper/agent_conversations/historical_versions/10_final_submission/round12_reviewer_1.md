# Review setup

- **Input scope** The frozen round 12 packet, including the four-page English manuscript PDF and TeX source, bibliography, figures, frozen protocol, supplementary methods, scene manifest, run audit, cluster-level outcomes, and historical summaries.
- **Assessment boundary** This is a simulation-only UAV path-planning study with prescribed, nonreactive obstacle tracks. The packet does not provide physical-flight validation, held-out motion-family planning tests, or standalone MPC and DWA comparisons. My reproducibility assessment is limited to files in this frozen packet.
- **Shared manuscript claim summary** Supplying MPC with the same 3-s LSTM obstacle forecast already used by DWA improves collision-audited goal arrival relative to giving that forecast only to DWA, within the tested integrated planner and generated scene distribution.
- **Visible evidence base** The main manuscript, especially its Abstract, Introduction, Problem Formulation, Planning Method, Simulation and Results, and Discussion; Figure 2 and Figure 3; the frozen confirmatory protocol; the 500-scene manifest; the 3,000-run audit; scene-cluster summaries; and the supplementary controller and experiment descriptions.
- **Missing materials affecting confidence** Supplementary Methods §S8 describes a reproducibility archive containing the planner source and trained LSTM weights, but that archive is not listed in the frozen packet manifest. The packet supports checking the run counts and reported scene-level outcome pattern, but not independently rerunning the controller and predictor.

# Reviewer 1

- **Overall assessment** The manuscript addresses a clearly defined UAV path-planning problem among moving obstacles and makes a focused comparison between two forecast interfaces in one integrated MPC-DWA planner. The primary outcome, matched scene design, cluster-level uncertainty calculation, failure reporting, and simulation limits are described with unusual care for a short paper. The central average benefit is supported for the stated generated distribution, while the prose avoids presenting it as a general safety or flight result. The principal gap is that the implementation and trained model needed to reproduce the simulation are referenced but absent from the supplied packet.
- **Who would be interested in the results, and why** Researchers in aerial robotics, predictive control, and learning-based motion planning may find the result useful because it tests whether a longer-horizon planner benefits from receiving a forecast already used by a local action screen. Its broader interdisciplinary interest is limited by the narrow controller-interface question and synthetic simulation setting.
- **Major strengths**
  - The title, Abstract, and Introduction make the central task and comparison clear. DWA receives the same LSTM forecast in both arms; only the forecast supplied to MPC differs.
  - The 500 scenes, three matched seeds per scene, retained failures, prespecified success criterion, and scene-cluster bootstrap are described consistently. The run audit reproduces the reported 936/1,500 versus 836/1,500 successes and the scene pattern of 72 better, 404 tied, and 24 worse clusters.
  - The Discussion distinguishes infeasible stops, swept collisions, solver failures, path length, and clearance, and says that the secondary intervals are unadjusted. It also states that the route example is illustrative and that the average result is not an advantage in most scene clusters.
  - The manuscript explicitly bounds its inference to the tested simulation, notes the overlap between training and evaluation motion families, and disclaims physical-flight and standalone-controller conclusions. Earlier CV, Kalman, and multi-method evidence is identified as historical and kept separate from the 500-scene primary estimate.

- **Major Concerns**

  - **Concern ID** R1-M1
  - **Severity** Major
  - **Blocking** No
  - **Axis** Reproducibility
  - **Claim pointer** The supplementary material describes an accompanying archive that contains the MATLAB planner, trained LSTM weights, run files, and scripts needed to reproduce the confirmatory simulation.
  - **Evidence pointer** supplementary/supplementary_methods.pdf, §S8, p. 8; supplementary/README.md; FREEZE_MANIFEST.sha256. The manifest includes the protocol, scene manifest, run audit, and outcome summaries, but not the referenced archive. The README describes that archive as a local companion without a public deposit or DOI.
  - **Concern** The supplied records permit verification of the outcome counts and re-aggregation of the paired scene results, but do not allow an independent reader to execute the planner or inspect the exact predictor artifact and implementation. This matters because the result depends on custom sampling, predicted-clearance gates, fallback actions, and solver behavior. The packet therefore supports an audit of the reported arithmetic more strongly than an independent reproduction of the simulated experiment.
  - **Why it matters** Without the implementation and trained weights, readers cannot verify that the reported runs follow the described algorithm or recreate the primary comparison. That limits confidence in the reproducibility of the central algorithmic result, although the reported run-level outcomes remain available for analysis.
  - **Resolution test** Include the referenced archive and checksum among the actual submission materials, or provide a versioned accessible repository with the planner, predictor weights, scene generator, analysis scripts, environment details, and a command that reproduces the 500-scene result. If these items cannot accompany the submission, revise the availability language so it accurately distinguishes the supplied run records from the materials needed to rerun the simulations.

- **Minor Comments**

  - **Concern ID** R1-m1
  - **Severity** Minor
  - **Axis** Experimental design
  - **Affected element** LSTM observation-window duration
  - **Evidence pointer** source/main.tex, §Planning Method, “Shared LSTM Forecast,” Eq. 2; supplementary/supplementary_methods.pdf, §S2, p. 4 and Table S1.
  - **Issue** The input is indexed as ten observations from t-9 through t, while the controller time step is 0.1 s and the text describes this as a 1-s history. Ten samples separated by 0.1 s span nine intervals, or 0.9 s, unless the implementation uses a different timestamp convention.
  - **Required correction** State the exact observation timestamps or interval convention and make the equation, main-text description, and supplementary table agree.

- **Technical failings that need to be addressed before the case is established** R1-M1 is a material reproducibility gap, but the supplied run records and prespecified analysis allow the reported outcome contrast to be checked without rerunning the simulation.
- **Assessment against Nature-style criteria** **Originality** The contribution is incremental but clear, namely a controlled forecast-input ablation within a coupled planner rather than a new general planning algorithm. **Scientific importance** The effect is relevant to a focused robotics audience, but its value is bounded by a fixed synthetic task distribution, nonreactive obstacle paths, and the absence of physical testing. **Interdisciplinary readership** The question may interest control, robotics, and applied machine-learning researchers; the broad cross-disciplinary case is modest. **Technical soundness** The matched comparison and scene-cluster inference fit the stated question, and the primary counts agree with the run audit. No evidence supports extrapolation to unseen motion families or hardware. **Readability for nonspecialists** The Abstract, Introduction, and planning-cycle figure explain the task and the 1-s versus 3-s horizons in accessible terms. The four-page Methods remain equation-dense, but the principal comparison and simulation claim are understandable without treating the LSTM, MPC, or DWA as interchangeable methods.
- **Recommendation posture** I would support further consideration as a focused conference contribution after the reproducibility materials are made accessible and the observation-window convention is clarified. The conclusion should remain limited to average goal-arrival performance in the tested simulation distribution.

# Risk / unsupported claims

- The paper does not make a supported claim of physical-flight safety or generalization to unseen motion families; it explicitly identifies these as untested. Its interpretation that sharing the forecast helps the route planner is presented as consistent with the evidence, not demonstrated as a mechanism. The material risk is reproducibility of the custom simulation from the supplied files.

