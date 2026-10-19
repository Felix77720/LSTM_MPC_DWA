## Review setup

- **Input scope** Frozen four-page manuscript and LaTeX source, supplementary methods and results, confirmatory protocol, method summary CSV, and scene-cluster bootstrap CSV.
- **Assessment boundary** Independent review of the round 10 packet. No other reviewer reports were consulted. The paper is assessed as an engineering conference submission, with Nature-style criteria used only as a review lens.
- **Shared claim summary** In a simulated UAV planner, both conditions give DWA the same LSTM forecast for its 1-second action screen. The tested change is whether MPC also receives that forecast over its 3-second route. Across 500 matched scenes, the shared-forecast condition has a reported 6.7 percentage-point higher goal-success rate.
- **Visible evidence base** Manuscript pp. 1–4, Figs. 1–4, Supplementary Methods, frozen protocol, confirmatory method summary, and bootstrap contrasts.
- **Missing materials affecting confidence** Supplementary Methods S8 refers to a companion archive with code, model weights, and per-run records. That archive is outside this review packet, so I could not independently reproduce the analysis or audit the simulator implementation.

## Reviewer 3

- **Overall assessment** The paper gives a clear, bounded account of a focused engineering question. Its abstract and main text explain the LSTM, MPC, and DWA roles and distinguish the shared-forecast condition from the DWA-only LSTM condition. The four-page story is readable, though the primary comparison and route figures could communicate the experimental contrast more directly.
- **Who would be interested in the results, and why** Robotics, UAV autonomy, and control researchers may be interested in whether a longer-horizon planner benefits from a learned forecast already available to a short-horizon action screen. The result is relevant to predictor integration in multi-stage planners.
- **Major strengths**
  - The abstract and Introduction state the planning problem and the specific forecast-sharing question without implying that the experiment compares against standalone MPC or DWA.
  - The methods and Fig. 2 distinguish the LSTM’s obstacle-position forecast, MPC’s 3-second route, and DWA’s 1-second reachable-action screen. The text also makes clear that the two conditions differ only in MPC’s forecast input.
  - The confirmatory result includes all 500 scenes and unsuccessful runs, reports a scene-cluster interval, and keeps the earlier experiments separate.
  - Discussion and conclusion bound the findings to this simulation. They acknowledge the prescribed obstacle paths, shared maneuver families, point forecasts, and absence of physical-flight evidence.

### Major Concerns

None identified from the supplied material.

### Minor Comments

**R3-m1 [figures-and-tables]**

- **Severity** Minor
- **Affected element** Fig. 2 and Fig. 3a, pp. 3
- **Evidence pointer** Fig. 2 depicts the shared-forecast configuration. Fig. 3a labels the rows “DWA only” and “DWA + MPC.” The protocol and Section IV state that both arms use the integrated MPC–DWA planner, and that DWA receives the LSTM forecast in both.
- **Issue** The figure labels can make the contrast look like a planner comparison, although the experiment changes only MPC’s obstacle forecast. Fig. 2 also does not visually show the comparator’s static-position input to MPC.
- **Required correction** Label the Fig. 3a rows as the DWA-only LSTM and shared LSTM forecast conditions, or otherwise state directly in the plot that MPC’s input is the varied factor. Add a small alternate-input cue to Fig. 2 if space permits.

**R3-m2 [figures-and-tables]**

- **Severity** Minor
- **Affected element** Fig. 4, p. 3
- **Evidence pointer** Fig. 4 caption identifies a predetermined example from the earlier six-setting evaluation. Section IV and Supplementary Methods S6 state that this study used a different DWA rollout and is separate from the 500-scene test. The current-test route example is in Supplementary Fig. S3.
- **Issue** The small, low-contrast route panels use space in the four-page paper for an example from a different evaluation. Although the caption labels it historical and the text cautions that it is illustrative, the figure is not closely connected to the paper’s primary result.
- **Required correction** Consider using the matched route example from the current test, or omit the route figure if it cannot be made legible at the available size. Keep the earlier evaluation clearly identified as separate if retained.

- **Technical failings that need to be addressed before the case is established** None identified from the aggregate evidence supplied. The companion archive is mentioned but was not in the review boundary, so reproducibility of the implementation and bootstrap is not independently assessable here.

- **Assessment against Nature-style criteria**
  - **Originality** The forecast-sharing question is specific and distinct from a standalone planner comparison. The contribution appears to be an integration and ablation result rather than a new forecasting or control formulation.
  - **Scientific importance** The confirmatory simulation supports an average improvement under the tested setup. The evidence establishes a focused engineering result, not broad scientific importance.
  - **Interdisciplinary readership** The most direct readership is in robotics and control. Broader interest is possible for researchers integrating prediction into layered controllers, but the manuscript does not establish far-reaching implications.
  - **Technical soundness** The matched contrast, frozen protocol, cluster bootstrap, and bounded claims support the reported simulation result. The source code, model weights, and per-run archive were not available in this packet for independent reproduction.
  - **Readability for nonspecialists** The abstract explains the core roles and contrast in a useful sequence, and the section transitions are clear. The equations and trust-index details are dense, but the accompanying text and Fig. 2 make the control cycle understandable. The main opportunity is clearer labeling of the comparison figures.

- **Recommendation posture** A coherent, narrowly scoped engineering conference contribution. Minor figure revisions would make the central comparison easier to follow. The packet does not establish broad interdisciplinary impact, physical-flight performance, or generalization to unseen motion families.

- **Risk / unsupported claims** No material overclaim is apparent in the central conclusion. Physical-flight safety and unseen-motion generalization are explicitly left untested. Reproduction of the simulator results remains unverified from the supplied review packet.
