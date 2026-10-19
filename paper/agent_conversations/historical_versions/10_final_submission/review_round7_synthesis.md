# Round 7 review synthesis — final 500-scene revision

> Internal author-side synthesis after the confirmatory rerun. It combines evidence, technical and presentation checks; it is not a set of new independent blinded referee reports.

## Decision

**Weak accept / minor revision for a simulation-focused conference paper.** The central matched comparison now supports an added goal-arrival benefit from sharing the LSTM forecast with MPC after DWA already receives it. The claim is specific to the tested integrated planner and simulation distribution.

## Evidence chain

| Claim | Evidence | Review judgement |
|---|---|---|
| Shared LSTM improves goal arrival over DWA-only LSTM | 936/1,500 (62.4%) vs 836/1,500 (55.7%); paired difference +6.67 percentage points; 95% scene-cluster CI +4.20 to +9.20 | Supported by the prespecified primary criterion |
| Shared setting improves minimum clearance | Paired difference +0.058 m; 95% CI +0.027 to +0.090 m | Supportive secondary result; interval is unadjusted |
| Method is safer on real aircraft or generalizes to unseen motion | No flight trial; obstacle tracks are exogenous; evaluation motion types overlap training | Not established; manuscript correctly limits scope |
| Method outperforms standalone DWA or standalone MPC | Neither is a condition in the 500-scene confirmatory comparison | Not established; manuscript explicitly avoids this claim |

## Technical review

- **Strength:** DWA sees the same forecast in both arms; the only planned interface change is whether MPC uses the LSTM forecast or holds obstacles at observed positions. This isolates the claimed contribution.
- **Strength:** Scene-cluster resampling respects the three matched seeds per scene. All 3,000 runs, including two shared-arm solver failures, remain in the audit and success denominator.
- **Remaining boundary:** Forecasts have no calibrated uncertainty; piecewise-linear collision auditing is an approximation; the simulation does not model obstacle response to the UAV.
- **Reporting action:** Keep the clearance finding secondary and unadjusted. Do not describe this study as a standalone DWA/MPC benchmark or a real-flight safety result.

## Presentation review and completed corrections

- The abstract follows problem/difficulty → method → simulation result → conclusion and states the primary effect and interval.
- The scene schematic remains untouched and visually separate from the measured 3D route comparison.
- The route legend was removed from the crowded lower axis region; route colors and start/goal markers are stated in the caption. The result plot directly shows both goal-arrival rates and the positive paired difference against zero.
- The top-to-bottom algorithm flowchart was simplified, rerendered and checked for node overflow and text collision.
- The main PDF compiles to four pages; the supplementary PDF compiles to ten pages. The bilingual reader has four equation anchors and four figure mappings; its math/source-map validator reports no findings.
- A stale 3 s DWA rollout description in the supplement was corrected to the confirmed 1 s (10-step) action horizon. The separate sensing stress test is labelled as diagnostic and not part of the primary 500-scene comparison.

## Final recommendation

The paper is coherent and evidence-aligned for a simulation-only methods contribution. Keep the current narrow claim and retain explicit limitations. A broader robotics-journal claim would require standalone baselines and validation across unseen dynamics or physical flight.

## Round 7 preservation and final-figure addendum — 6 October 2026

The final layout explicitly retains the earlier CV/Kalman and planner-interface evidence. Supplementary Fig. S1 preserves the initial four-method pilot and its original result figure; its random-scene shared-LSTM versus CV estimate was +8.3 percentage points (95% CI 0.0 to 25.0), which remains inconclusive at the lower limit. Supplementary Fig. S2 preserves the separate 48-scene six-setting study: shared LSTM versus CV was +15.28 points (95% scene-cluster CI +6.25 to +25.69), while shared LSTM versus DWA-only LSTM was +2.08 points (95% CI -1.39 to +6.94), not conclusive. Those historical results use a different DWA rollout and are not pooled with the 500-scene primary test.

The main route figure remains the earlier four-method 3D comparison, separate from the problem-scene schematic. The primary summary chart now directly shows rates, counts and the paired interval. Both main and supplementary PDFs were re-rendered after the final edits. The revised route, primary-result and historical-baseline figures have at least 6 pt text and pass collision/clipping audits. The main manuscript remains four pages and the supplement is ten pages.
