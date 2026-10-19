# Final blind review B — statistics, data consistency, and evidence boundaries

**Decision: MINOR**  
**Blocking issues: none.**  
**Scope:** Independent check limited to `qa/final_review_packet` and its `FREEZE_MANIFEST.sha256`. No other review reports were consulted.

## Freeze integrity

All eight entries in `FREEZE_MANIFEST.sha256` were checked individually with SHA-256. Every listed file matched its expected digest: `command_template_compliance.md`, `five_method_paired_bootstrap.csv`, `five_method_summary.csv`, `five_method_terminal_outcomes.csv`, `main_revised.pdf`, `README.md`, `reference_verification.md`, and `supplementary_methods.pdf`.

## Statistical and data checks

- The five methods each have 1,500 runs. Arrival counts and percentages agree: 33 (2.2%), 1,146 (76.4%), 1,428 (95.2%), 836 (55.733…%, reported as 55.7%), and 936 (62.4%). Swept-collision counts and rates also agree: 624 (41.6%), 0, 36 (2.4%), 2 (0.133…%), and 0. `BetweenStateCollisionRuns` is zero for all five methods.
- The mutually exclusive terminal rows close exactly to 1,500 for every method: 33+624+143+0+700; 1,146+0+354+0+0; 1,428+36+0+9+27; 836+2+453+0+209; and 936+0+366+0+198. The manuscript and supplement correctly distinguish overlapping event flags from exclusive terminal accounting; the two shared-arm solve failures are described as later ending in the infeasible-stop category and are counted once.
- The primary shared-minus-DWA-only result is consistent across the manuscript, supplement, and CSV: +6.6667 percentage points, 95% scene-cluster CI +4.2 to +9.2, from 20,000 resamples. The shared-minus-reconstructed-baseline contrast is +60.2 points, CI +56.2 to +64.2. The supplement specifies resampling the 500 complete scenes while retaining all three matched seeds and both methods, so the seed runs are not treated as independent clusters. Standalone contrasts are identified as secondary and unadjusted.
- The manuscript’s ranking and claim limits are accurate: shared LSTM is the best tested coupled MPC–DWA variant, while standalone MPC has the highest overall arrival rate (95.2%); standalone DWA also exceeds shared integration (76.4%). The text does not present the integrated method as a universal optimum.
- Scene 404, seed 2 is explicitly called a selected illustrative route in the main caption and supplement. Aggregate claims are tied to the 500-scene, 1,500-run-per-method analysis, not that example.
- The reported evaluation evidence is identified as simulation-only. The supplement describes exogenous prescribed obstacle tracks, clean current-time primary observations, and the simulated vehicle model; the conclusion and discussion retain flight hardware and reactive motion as future validation needs. I found no wording that presents a real flight trial as completed.
- The trust-weight provenance is properly bounded in the supplement: the source MPC–DWA paper supplies a four-part framework but no numerical coefficients; `[0.35, 0.30, 0.15, 0.20]` and the alignment substitution are described as fixed engineering choices, not source-paper values. The weights are stated to be fixed across runs, not learned, outcome-fitted, or sensitivity-tuned; the trust score is not called a probability or calibrated uncertainty.

## Minor clarifications

1. The timing contrast point estimates need an explicit estimand label. `five_method_paired_bootstrap.csv` labels its point field `MeanDifference` for `MedianPlanningStep_ms`; for example, shared minus latest-position is +14.682 ms, whereas subtracting the displayed method-level medians (95.704−79.470 ms) gives +16.234 ms. Shared minus DWA-only is +0.010 ms in the contrast CSV, while the displayed medians (95.704 and 95.909 ms) differ by −0.205 ms. These can differ if the contrast is an average of scene-level paired summaries rather than a difference of pooled medians, but that statistic is not defined in the packet. State the aggregation used and label the point estimate accordingly. Timing is secondary/descriptive, so this does not block the primary conclusion.
2. Figure 4(a) labels its per-controller bars as 95% scene-cluster intervals, but the frozen packet includes paired contrast intervals only; it does not include the absolute interval values or per-scene outcomes needed to independently reproduce those bars. The stated clustering approach is consistent with the supplement, and no contradictory interval value was found. Include the absolute interval table in a review/reproducibility packet if independent reproduction of the figure is required.

## Blocking issues

none

## Post-minor verification

**Decision: PASS**  
**Blocking issues: none.**

- All 9 files listed in `qa/final_review_packet_postminor/FREEZE_MANIFEST.sha256` passed individual SHA-256 verification.
- `five_method_absolute_bootstrap.csv` supplies a 95% absolute scene-cluster interval for each of the five plotted arrival rates, with 20,000 replicates per method. Its point percentages and method order agree with Figure 4(a); the supplement’s S4.3 specifies the 500-scene cluster resampling with all three matched seeds retained. The figure’s error bars are therefore supported by the frozen numeric artifact.
- Supplementary Methods S4.3 now defines `MedianPlanningStep_ms`: each scene contributes the median of its three run-level mean step times, and the contrast point estimate is the mean paired difference across 500 scenes. It explicitly distinguishes this estimand from the descriptive method-level median across all 1,500 run-level mean step times shown in Table S6. This resolves the prior ambiguity between the paired contrast CSV and pooled method medians.

The two minor items raised in the initial review are resolved in the post-minor packet.
