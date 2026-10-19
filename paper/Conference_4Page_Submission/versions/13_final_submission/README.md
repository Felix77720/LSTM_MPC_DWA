# Version 13 final submission package

Release state: updated, compiled and audited on 2026-10-19. This is a revision of the existing project manuscript, not a replacement study. Version 08 remains the audit baseline; historical results, source records, and original simulation data are preserved. Figure 1 presents the scene geometry in Problem Formulation. Figure 2 explains the five-stage shared-forecast update beside the method text. Figure 3 opens the Results section's visual evidence with the five integrated 3-s arms. Figure 4 then overlays the five matching scene-72/seed-2 routes at their recorded endpoints; the inset enlarges their early XY motion. The supplementary material retains all seven methods, the prior scene-404 example, and the historical CV/Kalman study. Route plots are descriptive examples; aggregate claims use the complete evaluation records. No new simulation was run for this finalization.

Version 08 is retained as the audit baseline. Technical audits, frozen experiment protocols, data-provenance checks, and reference verification remain in `04_review/`. See the [paper deliverables index](../../../../DOCUMENT_INDEX.md) for the final package map.

## Deliverables

- Four-page IEEE conference paper: canonical compiled PDF [`02_source/main.pdf`](02_source/main.pdf); editable source: [`02_source/main.tex`](02_source/main.tex) and [`02_source/references.bib`](02_source/references.bib).
- Complete bilingual reader: [`03_bilingual/paper.md`](03_bilingual/paper.md), synchronized with [`03_bilingual/source_map.json`](03_bilingual/source_map.json); the supplemental table guide is [`03_bilingual/supplementary_table_guide.md`](03_bilingual/supplementary_table_guide.md).
- Supplementary methods: [`03_supplementary/supplementary_methods.pdf`](03_supplementary/supplementary_methods.pdf) (21 pages in the current build) and editable [`supplementary_methods.tex`](03_supplementary/supplementary_methods.tex). Algorithm S1 is placed immediately after S1.4; historical CV/Kalman and route evidence remain in the supplement.
- Main-text figures: [`02_source/figures/algorithm_main_pseudocode.pdf`](02_source/figures/algorithm_main_pseudocode.pdf), [`02_source/figures/integrated_3s_outcomes_main.pdf`](02_source/figures/integrated_3s_outcomes_main.pdf), and the single-column five-integrated-method overlay [`02_source/figures/route_comparison_integrated_five_method_scene72_seed2_singlecol.pdf`](02_source/figures/route_comparison_integrated_five_method_scene72_seed2_singlecol.pdf). The seven-method four-view version remains a supplementary figure. Editable route records and endpoint checks remain in `qa/route_example_scene72_seed2/`; historical scene-404 assets are preserved.
- Historical four-controller route illustration source and endpoint audit: [`qa/confirmatory_route_figure_data/`](qa/confirmatory_route_figure_data/) and [`qa/historical_scene2_route_endpoint_audit.json`](qa/historical_scene2_route_endpoint_audit.json). These are saved-record exports for the S3 example, not a new simulation.
- Reproducibility archives: [`03_supplementary/reproducibility_package.zip`](03_supplementary/reproducibility_package.zip) (full) and [`03_supplementary/reproducibility_package_v13.zip`](03_supplementary/reproducibility_package_v13.zip) (compact), each with a ZIP SHA-256 sidecar; the full package has an internal `SHA256SUMS.txt`. The compact archive is delivered separately rather than duplicated inside the full ZIP.
- Current delivery hash list: [`03_supplementary/final_delivery_SHA256.txt`](03_supplementary/final_delivery_SHA256.txt).
- Final audit: [`04_review/v13_final_submission_audit_20261019.md`](04_review/v13_final_submission_audit_20261019.md) records current figure placement, equation/page checks, rendering, package and remaining limitations. Earlier dated audits and the [`route-figure selection amendment`](04_review/v13_route_illustration_amendment_20261016.md) remain as provenance.
- Both reproducibility packages include the paper index and scientific supporting files; their SHA-256 sidecars are regenerated with each package build.

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

Across the six scene-cluster paired contrasts, shared LSTM minus comparator (percentage points; simultaneous 95% max-|t| CI) was: DWA-CV −4.3 [−16.8, 8.1]; MPC-CV −18.3 [−29.6, −7.0]; coupled MPC–DWA-CV +5.7 [−3.4, 14.7]; LSTM-to-MPC only +0.7 [−9.0, 10.3]; LSTM-to-DWA only −1.0 [−4.8, 2.8]; position-hold reconstruction +16.3 [5.1, 27.6]. Only the position-hold contrast excluded zero in favor of shared LSTM. The decision gate specified in the internal amendment was not met: standalone MPC had the highest observed rate, and the intervals did not favor shared LSTM across all six comparators. The position-hold arm is a project-local approximation for architectural context.

One additional orphaned attempt (scene 58, seed 2) had an invalid checkpoint sidecar. It is preserved and listed in the output hash inventory, but it is not a planned episode and is excluded from the 2,100 valid episodes. Raw outcomes, invocation/failure logs, analysis outputs and hashes are retained in the results archive; the archive does not duplicate individual episode MAT checkpoints.

## Historical evidence and limitations

The frozen shared-versus-DWA-only contrast (500 scenes, 3,000 attempts) is a subset of the 7,500-episode historical five-controller benchmark, not an additional sample; it remains in the supplement. The separate 100-scene, 2,100-episode exploratory comparison, 4,320 Stage-1 development/calibration episodes, 864-episode earlier comparison, standalone-controller variants, CV/Kalman studies, and scene-404, seed-2 illustration remain distinctly identified. The 500-scene and 100-scene banks are not pooled. Stage 1 evaluated six trust-weight vectors across five integrated arms, 48 scenes and three matched seeds; it selected $[0.15,0.15,0.15,0.55]$ with a descriptive equal-arm macro-average safe-arrival rate of 0.8042. The five branch-specific development rates are given in Supplementary Methods and are not held-out estimates. Stage 2 planned 5,760 fresh episodes; 2,263 checkpoint files were preserved after an incomplete run. They were not analyzed or used to select parameters. The final paper therefore uses the completed 4,320 development episodes and the 2,100 exploratory episodes, while retaining earlier evidence separately.

The planned v13 500-scene, seven-method holdout protocol was never run and is retired. This is distinct from the completed 500-scene, two-arm forecast-sharing contrast above. A seed-provenance audit confirmed that the completed 100-scene exploratory bank is the deterministic first-100 prefix of the retired holdout bank because both used suite seed `20261017` and scene-index-based random streams. The 100-scene results remain exploratory and are not reused as independent confirmation. Any future confirmation requires a fresh frozen seed and deduplication against the exploratory bank.

The current 3-s main analysis shows shared LSTM at 73.7%, 16.3 percentage points above latest-position hold (simultaneous 95% CI, 5.1–27.6). Its differences from coupled CV and either one-layer LSTM injection remain uncertain. Cross-architecture standalone results and the historical 1-s studies are retained in the supplement and do not establish overall superiority or global optimality. Prescribed tracks and point forecasts were simulated, with no real-flight validation. The full reproducibility package includes the frozen LSTM model and its verified SHA-256 digest; the compact package is a smaller audit-oriented subset.

## Build and verification

The current main paper compiles to exactly four pages. Figure 1 is adjacent to the scene model on page 1; Figure 2 sits with the method section; Figure 3 opens the visual evidence in Results; and Figure 4 follows the matched route-example sentence. Figures 3 and 4 are separate single-column floats. Figure 4 uses the five integrated recorded paths and logged endpoints; the seven-method four-view version remains in the supplement. All four main pages and updated supplement pages were rendered and visually checked. The supplement remains 21 pages. The bilingual source map validates 51 anchors and its synchronization test reports zero differences; the dated final audit and publication assessment record evidence boundaries and remaining limitations.
