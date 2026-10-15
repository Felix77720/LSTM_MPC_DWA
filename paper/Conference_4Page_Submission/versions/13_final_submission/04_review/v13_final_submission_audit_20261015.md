# Final submission audit — Version 13

Audit date: 2026-10-15. Scope: the revised manuscript descended from Version 08, its LaTeX source, bilingual reader, supplementary methods, figures, reproducibility package and the limited seven-method evaluation. Version 08 and original simulation records remain preserved.

## Disposition

The main paper is compiled to four pages and the supplementary PDF to 19 pages. The manuscript now reports the 100-scene exploratory comparison while keeping the historical 500-scene, 4,320-episode Stage-1 development, earlier 864-episode study, CV/Kalman diagnostics and scene-404 example separate. The evidence does not support an overall-superiority claim for shared LSTM; the abstract, results, discussion, conclusion, bilingual reader and audit records state that limit.

## Experimental evidence and integrity

The limited run contains 2,100 valid planned episodes: 100 new simulated scenes × three matched seeds × seven controller arms (300 episodes per arm). The seven arms are standalone DWA-CV; standalone MPC-CV; coupled MPC–DWA-CV; coupled MPC–DWA with LSTM to MPC only; coupled MPC–DWA with LSTM to DWA only; shared-LSTM coupled MPC–DWA; and a project-local latest-position-hold MPC–DWA reconstruction. The run was exploratory under an internal scope amendment, not externally preregistered. The frozen simulation code was not rerun for this finalization.

Checkpoint/sidecar and scenario/run-manifest checks validated the 2,100 unique planned keys and complete 100 × 3 × 7 coverage. One extra orphaned attempt for scene 58, seed 2 had an invalid sidecar; it remains preserved and hash-listed but is not a planned key and was excluded. Raw outcomes, invocation/failure logs, trajectories, run signature, analysis outputs and their hash manifest remain under `results/v13_seven_method_100scene_exploratory_20261015/`. A separate compatibility copy addressed snapshot pre-validation only; the frozen runner and analyzer and numerical calculations were not changed.

| Controller | Collision-free goal arrivals | Swept contacts |
|---|---:|---:|
| Standalone DWA-CV | 234/300 (78.0%) | 0/300 |
| Standalone MPC-CV | 276/300 (92.0%) | 15/300 |
| Coupled MPC–DWA-CV | 204/300 (68.0%) | 0/300 |
| LSTM to MPC only | 219/300 (73.0%) | 0/300 |
| LSTM to DWA only | 224/300 (74.7%) | 0/300 |
| Shared LSTM to MPC and DWA | 221/300 (73.7%) | 0/300 |
| Latest-position-hold reconstruction | 172/300 (57.3%) | 50/300 |

The primary endpoint is arrival within goal tolerance without continuous swept-path contact. Seeds were averaged within scene; 20,000 scene-cluster paired bootstrap resamples and centered max-|t| simultaneous 95% intervals covered six shared-minus-comparator contrasts (percentage points): DWA-CV −4.3 [−16.8, 8.1]; MPC-CV −18.3 [−29.6, −7.0]; coupled CV +5.7 [−3.4, 14.7]; LSTM-to-MPC only +0.7 [−9.0, 10.3]; LSTM-to-DWA only −1.0 [−4.8, 2.8]; position-hold +16.3 [5.1, 27.6]. Only the position-hold interval excludes zero in favor of shared LSTM. Standalone MPC has the highest observed arrival rate and its interval favors that baseline; standalone DWA is numerically higher than shared LSTM, with an interval that includes zero. The specified gate (highest observed rate plus all six paired intervals favoring shared LSTM) failed. No method is described as globally optimal.

## Manuscript, figures and equations

- The abstract follows the requested problem → method → simulation result → conclusion sequence. The problem formulation has no experimental-number clutter and Figure 1 directly illustrates the modeled three-dimensional workspace, start, goal and moving obstacles.
- The method explains LSTM inputs/forecast, MPC route optimization, DWA reachable-action screening and the feedback between them. In the shared arm one time-aligned causal LSTM forecast enters both MPC and DWA; passing DWA candidates constrain MPC's first input, and the updated MPC route informs DWA ranking. The one-layer ablations and constant-velocity baselines are distinguished.
- Core equations are collected in the methods section and their variables, units, bounds and roles are defined in adjacent prose. The physical command box, safety gates, trust-score formula, sampling budget and fixed DWA score term are tied to the implemented settings. The trust-weight vector was selected from the separate 4,320-episode Stage-1 development set; its score is descriptive selection evidence, not held-out validation.
- The seven-method 3-D route figure is one preselected scene-1/seed-1 illustration. All seven logged paths use one shared axis and stop at their recorded endpoints; no path was extended or smoothed. The caption says the example is not aggregate evidence. Figure 1 remains independent of the trajectory comparison. Historical CV/Kalman and scene-404 images remain in the supplement.
- Main Table 1 retains all seven methods, safe-arrival rates and swept-contact counts; full paired intervals are in Supplementary Table S12. The bilingual table and source map were synchronized to the final main caption and table numbering.

## Compilation, layout and references

`scripts/compile_final.ps1` completed using the installed MiKTeX packages; no dependencies were downloaded. The main PDF is exactly four pages and the supplement is 19 pages. After the final figure/caption revision, all four main pages and supplementary pages 3–4 and 16–19 were rendered and visually inspected. The S1.2 display equation was reflowed into aligned rows without changing its mathematics; the resulting supplement log has no overfull boxes, and the main log has no overfull boxes or unresolved citations. Two nonfatal underfull table-row warnings remain in the supplement; visual review found no clipping or overlap. The final supplementary page contains the paired-contrast table, not an empty page.

The final route-figure source audit passes with 21 checks, and the rendered collision audit reports zero failures and zero warnings. Its visible labels remain at least 6.38 pt after inclusion in the main PDF; the routes use only saved XYZ states and terminate at their recorded endpoints. The scene schematic remains separate in Problem Formulation. The final figure/caption wording is synchronized in the English source and Chinese–English reader/source map. The final PDF layout was checked after compilation; no experiment was rerun for this formatting-only correction.

The release allowlist excludes the retained Revision-11-era `audit_revision_delivery.py`, whose assertions target a five-method, 15-page package and do not validate v13. It remains unchanged in the project history; the current v13 results are instead evidenced by this report, the figure/endpoint audit records, and the package builder's own integrity checks.

All ten source-bibliography records were reviewed field by field; nine have their listed bibliographic fields corroborated, while the supplied online-first Chang article remains partially specified. Six records are cited in the main text. Conference volume/issue fields are marked not applicable; the IEEE record for Dobrevski and Skočaj does not state an issue number, which remains unfilled. For the supplied Chang article, title, author order, journal and 26 March 2026 online-first date were verified; volume, issue, pages and DOI could not be confirmed and remain unfilled. The complete per-field evidence and unresolved fields are in `04_review/reference_verification_v13.md`.

## Remaining limits and delivered files

The current comparison is exploratory, uses prescribed obstacle tracks and point forecasts, and has no real-flight data. The position-hold arm is a project-local reconstruction rather than an exact reproduction because the supplied baseline paper does not provide an executable dynamic-obstacle predictor. Stage-2 trust-scale calibration remains incomplete and is not used for this evaluation. The claim is therefore limited to the observed contrast against the position-hold reconstruction; standalone MPC-CV performed better.

To avoid duplicating large files in the GitHub release, the ZIP contains the full v13 scenario bank, run-level outcomes, saved trajectories and logs, but not the redundant combined `experiment_bundle.mat`, five large historical 500-scene MAT bundles, or the platform-specific CasADi binary tree. Those original files remain unchanged at their existing project paths; `OMITTED_ARTIFACTS_SHA256.csv` and `CASADI_3.8.0_SHA256.csv` record their source identities. The prior compact reproducibility archive is retained inside the current package. Re-running optimizer-based simulations therefore requires a compatible local CasADi 3.8.0 installation.

- Main PDF and editable source: `02_source/main.pdf`, `02_source/main.tex`, `02_source/references.bib`.
- Complete bilingual reader and map: `03_bilingual/paper.md`, `03_bilingual/source_map.json`; table guide: `03_bilingual/supplementary_table_guide.md`.
- Supplement PDF/source: `03_supplementary/supplementary_methods.pdf`, `03_supplementary/supplementary_methods.tex`.
- Reproducibility archive and hashes: `03_supplementary/reproducibility_package.zip`, `03_supplementary/reproducibility_package.zip.sha256`, `03_supplementary/final_delivery_SHA256.txt`.
- Experiment protocol, raw results and analysis: `04_review/seven_method_100scene_exploratory_amendment_20261015.md` and `results/v13_seven_method_100scene_exploratory_20261015/`.

`04_review/final_submission_audit.md` is retained as an earlier revision's audit record; this Version 13 audit and `04_review/reference_verification_v13.md` are the current final audit documents.

Historical raw data and the Version 08 audit baseline were not deleted or overwritten.
