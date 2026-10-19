# Round 12 post-review synthesis

## Scope

This synthesis combines three independent, mutually blind reviews of the frozen packet documented in `qa/round12_review_packet/FREEZE_MANIFEST.sha256`. The reviewer reports remain unchanged in `round12_reviewer_1.md` through `round12_reviewer_3.md`. This document records the cross-review findings and the author actions; it is not a replacement reviewer report.

## Overall assessment

The three reviewers agree that the paper addresses a clear, bounded path-planning question: within one integrated MPC--DWA planner, does supplying MPC with the LSTM obstacle forecast improve goal arrival after DWA already receives that forecast? The matched 500-scene comparison supports a +6.7 percentage-point average difference (95% scene-cluster bootstrap CI, +4.2 to +9.2) in the tested simulation distribution. No reviewer identified a blocking technical concern. The contribution is focused and incremental, and evidence does not establish performance on unseen motion families, physical flight, or superiority over standalone MPC or DWA.

## Findings raised across reviews

1. **Reproduction materials.** All three reviewers noted that the archive named by the supplementary materials was absent from the frozen review packet. The underlying run-level and scene-level records support an arithmetic audit but not a full independent rerun. The revision must include the local archive and checksum with the submitted materials, and must not describe it as a public deposit.
2. **Primary observation condition.** Reviewer 2 found that the primary sensor condition was not explicit. The implementation uses current-time simulator observations with zero added noise and zero delay; noisy or delayed histories belong to training augmentation or the separate sensing diagnostic.
3. **Observation-window convention.** Reviewer 1 noted that ten samples at 0.1-s spacing span 0.9 s from first to last. The prose and supplementary table should state this exactly without changing the experiment.
4. **Novelty framing.** Reviewer 2 requested a sharper distinction from prior DWA, learned-forecast MPC, uncertainty-aware MPC and LSTM--DWA work. The paper should define its contribution as the integrated forecast interface and matched input ablation, without claiming a general new planning principle.
5. **Figure 3 interval roles and labels.** Reviewers 2 and 3 requested clearer condition labels and a visible distinction between per-condition intervals and the paired contrast interval. The figure should show the paired estimate separately from the rate whiskers.

## Author resolution and remaining boundary

The revised manuscript and supplementary materials now state the 0.9-s sample span, document the clean current-time primary observations, and give the archive's local location and checksum sidecar. Figure 3 presents condition-specific rates and intervals in panel (a), scene-level outcome counts in panel (b), and a separate paired-gain interval callout. The Introduction maps the cited neighboring approaches to the specific forecast-sharing question. These are documentation and presentation changes; they do not alter the frozen protocol or any simulation outcome.

The archive remains a local companion file without a DOI. It must accompany any external submission if the authors want referees to rerun the code and inspect the trained predictor. Claims remain restricted to the tested simulation distribution; standalone planner comparisons, held-out maneuver-family generalization, and physical-flight performance remain untested.
