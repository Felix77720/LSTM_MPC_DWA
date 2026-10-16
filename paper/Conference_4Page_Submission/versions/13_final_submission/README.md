# Version 13 final submission package

Release state: compiled and audited on 2026-10-16. This is a revision of the existing project manuscript, not a replacement study. Version 08 remains the audit baseline; historical results, source records, and original simulation data are preserved.

## Deliverables

- Four-page IEEE conference paper: [`02_source/main.pdf`](02_source/main.pdf); editable source: [`02_source/main.tex`](02_source/main.tex) and [`02_source/references.bib`](02_source/references.bib).
- Complete bilingual reader: [`03_bilingual/paper.md`](03_bilingual/paper.md), synchronized with [`03_bilingual/source_map.json`](03_bilingual/source_map.json); the supplemental table guide is [`03_bilingual/supplementary_table_guide.md`](03_bilingual/supplementary_table_guide.md).
- Supplementary methods: [`03_supplementary/supplementary_methods.pdf`](03_supplementary/supplementary_methods.pdf) (19 pages) and editable [`supplementary_methods.tex`](03_supplementary/supplementary_methods.tex). Historical CV/Kalman and route evidence remain in the supplement.
- Seven-method route illustration and endpoint audit: [`02_source/figures/route_comparison_seven_method.pdf`](02_source/figures/route_comparison_seven_method.pdf) and [`qa/seven_method_route_endpoint_audit.json`](qa/seven_method_route_endpoint_audit.json).
- Historical four-controller route illustration source and endpoint audit: [`qa/confirmatory_route_figure_data/`](qa/confirmatory_route_figure_data/) and [`qa/historical_scene2_route_endpoint_audit.json`](qa/historical_scene2_route_endpoint_audit.json). These are saved-record exports for the S3 example, not a new simulation.
- Reproducibility archive: [`03_supplementary/reproducibility_package.zip`](03_supplementary/reproducibility_package.zip), with ZIP SHA-256 sidecar and package-internal `SHA256SUMS.txt`.
- Current delivery hash list: [`03_supplementary/final_delivery_SHA256.txt`](03_supplementary/final_delivery_SHA256.txt).
- Final audit: [`04_review/v13_final_submission_audit_20261015.md`](04_review/v13_final_submission_audit_20261015.md).

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

The 7,500-episode historical five-controller study, 4,320 Stage-1 development/calibration episodes, 864-episode earlier comparison, standalone-controller variants, CV/Kalman studies, and scene-404, seed-2 illustration remain separately identified. They are not pooled with the 100-scene evaluation. Stage 1 evaluated six trust-weight vectors across five integrated arms, 48 scenes and three matched seeds; it selected $[0.15,0.15,0.15,0.55]$ with a descriptive equal-arm macro-average safe-arrival rate of 0.8042. The five branch-specific development rates are given in Supplementary Methods and are not held-out estimates. Stage 2 planned 5,760 fresh episodes; 2,263 checkpoint files were preserved after an incomplete run (2,255 before a partial resume added eight). They were not analyzed or used to select parameters. On 2026-10-16, the author chose to run no further scientific experiments; this paper uses the completed 4,320-episode development and 2,100-episode exploratory comparison as its current quantitative study and keeps historical evidence separate. The historical scene-404 result is one matched example, not an aggregate claim.

The original v13 500-scene holdout protocol was never run and is retired. A seed-provenance audit confirmed that the completed 100-scene exploratory bank is its deterministic first-100 prefix because both used suite seed `20261017` and scene-index-based random streams. The 100-scene results remain exploratory and are reported once; they are not reused as independent confirmation. Any future confirmation requires a fresh frozen seed and deduplication against the exploratory bank.

The manuscript’s conclusion is therefore limited: shared LSTM improved safe arrival over the latest-position-hold reconstruction, but it did not outperform standalone MPC and does not establish overall superiority or global optimality. The simulator uses prescribed obstacle motion and point forecasts; real-world flight performance remains untested.

## Build and verification

The main paper compiled to exactly four pages and the supplement to 19 pages. All four main-paper pages and all supplementary pages were rendered and visually inspected; page 15's historical route caption distinguishes DWA sampling seed 1, describes the recorded endpoints, and marks the figure as one example rather than aggregate evidence. The final supplementary page contains the paired-contrast table. Bibliography fields were checked against publisher/conference/institutional sources; fields absent from the supplied online-first Chang article (volume, issue, pages, DOI) remain unfilled rather than guessed. See the dated audit report for rendering checks, data-integrity notes, citation-field status, and remaining limitations.
