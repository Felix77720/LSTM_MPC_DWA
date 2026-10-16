# Version 13 final submission package

Release state: updated, compiled and audited on 2026-10-16. This is a revision of the existing project manuscript, not a replacement study. Version 08 remains the audit baseline; historical results, source records, and original simulation data are preserved.

## Deliverables

- Four-page IEEE conference paper: canonical compiled PDF [`02_source/main.pdf`](02_source/main.pdf); editable source: [`02_source/main.tex`](02_source/main.tex) and [`02_source/references.bib`](02_source/references.bib). Older PDFs in `01_manuscript/` are retained interim artifacts and are not release copies.
- Complete bilingual reader: [`03_bilingual/paper.md`](03_bilingual/paper.md), synchronized with [`03_bilingual/source_map.json`](03_bilingual/source_map.json); the supplemental table guide is [`03_bilingual/supplementary_table_guide.md`](03_bilingual/supplementary_table_guide.md).
- Supplementary methods: [`03_supplementary/supplementary_methods.pdf`](03_supplementary/supplementary_methods.pdf) (18 pages in the current build) and editable [`supplementary_methods.tex`](03_supplementary/supplementary_methods.tex). Historical CV/Kalman and route evidence remain in the supplement.
- Seven-method route illustration and endpoint audit: [`02_source/figures/route_comparison_seven_method.pdf`](02_source/figures/route_comparison_seven_method.pdf) and [`qa/seven_method_route_endpoint_audit.json`](qa/seven_method_route_endpoint_audit.json).
- Historical four-controller route illustration source and endpoint audit: [`qa/confirmatory_route_figure_data/`](qa/confirmatory_route_figure_data/) and [`qa/historical_scene2_route_endpoint_audit.json`](qa/historical_scene2_route_endpoint_audit.json). These are saved-record exports for the S3 example, not a new simulation.
- Reproducibility archive: [`03_supplementary/reproducibility_package.zip`](03_supplementary/reproducibility_package.zip), with ZIP SHA-256 sidecar and package-internal `SHA256SUMS.txt`.
- Current delivery hash list: [`03_supplementary/final_delivery_SHA256.txt`](03_supplementary/final_delivery_SHA256.txt).
- Final audit: the complete report [`04_review/v13_final_submission_audit_20261015.md`](04_review/v13_final_submission_audit_20261015.md), continuation [`04_review/v13_final_submission_audit_20261016_addendum.md`](04_review/v13_final_submission_audit_20261016_addendum.md), and current forecast-sharing update [`04_review/v13_final_submission_audit_20261016_forecast_update.md`](04_review/v13_final_submission_audit_20261016_forecast_update.md).

## New exploratory evaluation

One limited evaluation completed 2,100 valid episodes: 100 simulated scenes × three matched seeds × seven controller arms (300 episodes per arm). It was exploratory under an internal scope amendment, not externally preregistered. Prescribed obstacle tracks and simulation-only evidence were used; no real-flight validation is claimed. No further simulation was run for this finalization.

| Controller | Safe goal arrival | Swept contacts |
|---|---:|---:|
| Standalone DWA-CV | 234/300 (78.0%) | 0/300 |
| Standalone MPC-CV | 276/300 (92.0%) | 15/300 |
| Coupled MPC–DWA-CV | 204/300 (68.0%) | 0/300 |
| MPC–DWA, LSTM to MPC only | 219/300 (73.0%) | 0/300 |
| MPC–DWA, LSTM to DWA only | 224/300 (74.7%) | 0/300 |
| MPC–DWA, shared LSTM | 221/300 (73.7%) | 0/300 |
| MPC–DWA, latest-position-hold reconstruction | 172/300 (57.3%) | 50/300 |

Across the six scene-cluster paired contrasts, shared LSTM minus comparator (percentage points; simultaneous 95% max-|t| CI) was: DWA-CV −4.3 [−16.8, 8.1]; MPC-CV −18.3 [−29.6, −7.0]; coupled MPC–DWA-CV +5.7 [−3.4, 14.7]; LSTM-to-MPC only +0.7 [−9.0, 10.3]; LSTM-to-DWA only −1.0 [−4.8, 2.8]; position-hold reconstruction +16.3 [5.1, 27.6]. Only the position-hold contrast excluded zero in favor of shared LSTM. The decision gate specified in the internal amendment was not met: standalone MPC had the highest observed rate, and the intervals did not favor shared LSTM across all six comparators. The position-hold arm is a project-local reconstruction, not an exact reproduction of the cited paper.

One additional orphaned attempt (scene 58, seed 2) had an invalid checkpoint sidecar. It is preserved and listed in the output hash inventory, but it is not a planned episode and is excluded from the 2,100 valid episodes. Raw outcomes, invocation/failure logs, analysis outputs and hashes are retained in the results archive; the archive does not duplicate individual episode MAT checkpoints.

## Historical evidence and limitations

The frozen shared-versus-DWA-only contrast (500 scenes, 3,000 attempts) is a subset of the 7,500-episode five-controller benchmark, not an additional sample. It is reported in the main paper; full five-controller outcomes remain in the supplement. The separate 100-scene, 2,100-episode exploratory comparison, 4,320 Stage-1 development/calibration episodes, 864-episode earlier comparison, standalone-controller variants, CV/Kalman studies, and scene-404, seed-2 illustration remain distinctly identified. The 500-scene and 100-scene banks are not pooled. Stage 1 evaluated six trust-weight vectors across five integrated arms, 48 scenes and three matched seeds; it selected $[0.15,0.15,0.15,0.55]$ with a descriptive equal-arm macro-average safe-arrival rate of 0.8042. The five branch-specific development rates are given in Supplementary Methods and are not held-out estimates. Stage 2 planned 5,760 fresh episodes; 2,263 checkpoint files were preserved after an incomplete run (2,255 before a partial resume added eight). They were not analyzed or used to select parameters. On 2026-10-16, the author chose to run no further scientific experiments; this paper therefore uses the completed 4,320 development episodes, the 2,100 exploratory episodes, and the prespecified 500-scene contrast already contained in the five-controller benchmark. Scene 404, seed 2 remains one matched example, not an aggregate claim.

The planned v13 500-scene, seven-method holdout protocol was never run and is retired. This is distinct from the completed 500-scene, two-arm forecast-sharing contrast above. A seed-provenance audit confirmed that the completed 100-scene exploratory bank is the deterministic first-100 prefix of the retired holdout bank because both used suite seed `20261017` and scene-index-based random streams. The 100-scene results remain exploratory and are not reused as independent confirmation. Any future confirmation requires a fresh frozen seed and deduplication against the exploratory bank.

The manuscript reports a protocol-specific benefit: in the frozen 1-s DWA contrast, shared LSTM achieved 62.4% safe arrival versus 55.7% for DWA-only LSTM (+6.7 percentage points; 95% scene-cluster CI, 4.2–9.2). In the separate 3-s exploratory study, shared LSTM reached 73.7%, its contrast with DWA-only LSTM was inconclusive, and standalone MPC-CV had the highest rate (92.0%). These findings do not establish overall superiority or global optimality. LSTM and CV also use different input information streams; prescribed tracks and point forecasts were simulated, with no real-flight validation.

## Build and verification

The current main paper compiled to exactly four pages and the supplement to 18 pages. All four current main-paper pages and the updated supplement page 9 were freshly rendered and inspected; page 18 was also checked as the current final page. The abstract and 500-scene result were verified in extracted PDF text after correcting LaTeX percent escaping; all six references fit on page 4. The 500-scene contrast was statically reconciled against the corresponding 3,000 rows in the 7,500-run audit, with no outcome mismatches; it is not counted twice. The bilingual source map validates all 45 anchors and four synchronization regression tests pass. Bibliography fields were checked against publisher/conference/institutional sources; fields absent from the supplied online-first Chang article (volume, issue, pages, DOI) remain unfilled rather than guessed. See the dated audit files for checks and remaining limitations.
