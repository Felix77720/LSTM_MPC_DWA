# Round 10 post-review synthesis

## Review setup and boundary

Three reviewers independently assessed the same frozen four-page manuscript, source, bibliography, supplement, confirmatory protocol and primary summary tables. Their reports are preserved separately in `round10_reviewer_1.md`, `round10_reviewer_2.md` and `round10_reviewer_3.md`. No reviewer read another review before completing their own. The reviewers did not inspect or execute the full simulator archive, so their assessment of implementation-level reproducibility is limited to the supplied packet.

## Shared assessment

All three reviewers considered the matched comparison interpretable: DWA receives the same LSTM forecast in both arms, and the confirmatory change is whether MPC also receives that forecast. They accepted the scene-cluster analysis and the bounded conclusion that the shared-forecast condition had higher average goal arrival in this simulation. None identified a blocking technical flaw or a material overclaim about flight safety or generalization.

The clearest readership is UAV robotics, motion planning and control. Reviewers described the contribution as a focused planner-integration or forecast-interface result, rather than a broad new planning principle. The paper should therefore retain that scope in its abstract, discussion and conclusion.

## Concerns and author actions

### Reproduction and scene distribution

Reviewers 1 and 2 explicitly raised access to the code/run archive; Reviewer 2 also noted that the review packet lacked enough detail to characterize the sampled obstacle distribution. The supplement now gives the generator seed and sampling ranges, identifies the seven equally sampled motion families, and points to the exact 500-scene manifest. The manifest and a reader-facing scene-generation specification are included in the revision package with the generator and run records. This resolves the missing description in the manuscript materials. The archive is still a local submission artifact rather than a persistent public repository, so external availability must be arranged by the authors at submission.

### Novelty positioning

Reviewer 1 requested a more direct distinction from predictive DWA and forecast-informed MPC work. The Introduction now frames the contribution as a narrower matched ablation: after DWA already receives the learned forecast, does supplying that same forecast to the longer-horizon MPC add value? This avoids treating the historical baseline study as evidence for the confirmatory protocol or claiming a general planner advance.

### Figure labels and historical routes

Reviewer 3 found that “DWA only” versus “DWA + MPC” could be mistaken for a comparison between planner classes. The primary chart now names the DWA-only LSTM and shared-LSTM forecast conditions, identifies the MPC input as the varied factor, and states that DWA receives the same forecast in both. The top-to-bottom method diagram also labels the forecast input in each arm. Reviewer 3 suggested replacing the historical route panel with a current-test route or removing it. The author’s prior specification requires retaining the earlier four-method 3D comparison; its caption and surrounding text therefore identify it as one fixed, separate historical example and direct readers to the new experiment’s aggregate chart for the primary evidence.

### Runtime wording

Reviewer 2 noted that mean and median alone do not establish how often a step exceeds the nominal control interval. The manuscript now calls the reported time a descriptive mean and continues to state that it does not establish real-time performance. No upper-tail timing claim is made.

## Recommendation posture

This review supports a specialist engineering-conference submission after the specified framing, figure and reproducibility clarifications. It does not support a prediction of acceptance or a broad-interest Nature-level claim. The central evidence remains limited to the prescribed, simulated obstacle distribution and the two forecast-input conditions. It does not establish superiority over standalone MPC or DWA, performance on unseen motion families, or physical-flight safety.

## Remaining author checks before submission

- Place the rebuilt reproducibility archive and scene manifest where reviewers can access them; the current package is local.
- Verify the target conference’s page limit, anonymous-review rules and supplementary-file policy.
- Keep the four-page main text and the separately identified historical comparisons intact when preparing the submission bundle.
