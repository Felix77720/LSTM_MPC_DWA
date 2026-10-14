# v13 final submission package

This release contains a four-page simulation study, its editable LaTeX source, a complete English–Chinese side-by-side reader, supplementary methods, retained historical comparisons, and an evidence archive. It does not include new simulation runs. The 08 reviewer revision and original experiment records remain unchanged.

## Deliverables

- Main paper: [`02_source/main.pdf`](02_source/main.pdf), four IEEE double-column pages; editable source: [`02_source/main.tex`](02_source/main.tex).
- Supplement: [`03_supplementary/supplementary_methods.pdf`](03_supplementary/supplementary_methods.pdf), 17 pages; editable source and data index: [`03_supplementary/supplementary_methods.tex`](03_supplementary/supplementary_methods.tex) and [`03_supplementary/README.md`](03_supplementary/README.md).
- Full main-text bilingual reader: [`03_bilingual/paper.md`](03_bilingual/paper.md), with synchronized map, figure assets and translation notes.
- Reproducibility evidence archive: [`03_supplementary/reproducibility_package_v13.zip`](03_supplementary/reproducibility_package_v13.zip); its SHA-256 is recorded in the adjacent `.sha256` file. The per-file release manifest is [`03_supplementary/final_submission_SHA256_20261014.txt`](03_supplementary/final_submission_SHA256_20261014.txt).
- Final audit: [`04_review/v13_final_submission_audit_20261014.md`](04_review/v13_final_submission_audit_20261014.md).

## Evidence reported

The main results are from the completed historical five-controller comparison: 500 scenes × three matched seeds × five methods = 7,500 runs, with a 1-s DWA screening horizon and a 30-step MPC horizon. Sharing LSTM between MPC and DWA produced 936/1,500 collision-free arrivals (62.4%), compared with 836/1,500 (55.7%) for the integrated DWA-only forecast arm; the paired gain was 6.7 percentage points (95% scene-cluster CI 4.2–9.2). The shared method had higher arrival than the project-local latest-position-hold reconstruction (2.2%), but lower arrival than standalone DWA+LSTM (82.4%) and standalone MPC+LSTM (95.2%). Thus, the manuscript describes it as the best tested coupled MPC–DWA variant; it does not claim overall superiority. Scene 404, seed 2 is one matched illustration only.

The 4,320 Stage-1 development episodes (6 candidate vectors × 5 integrated branches × 48 scenes × 3 matched seeds) are reported separately as calibration evidence. Recovery validated all 4,320 existing records and created zero new simulations. The selected trust vector was `[0.15, 0.15, 0.15, 0.55]`; its equal-arm macro-average development collision-free-arrival score was 0.8042. Branch rates and run-level evidence are included in Supplementary Methods and `03_supplementary/stage1_development/`. Because these runs selected the vector, the score is descriptive, not held-out validation. The selected vector was not applied to the 7,500-run historical benchmark. The earlier 864-episode experiment and two standalone-DWA implementations (76.4% and 82.4%) remain separately identified rather than pooled.

Stage-2 calibration and the planned seven-method held-out controller study are not reported in this paper. The available evidence is simulation-only, uses prescribed obstacle tracks and point forecasts without uncertainty estimates, and does not establish real-flight performance or global optimality.

## Reproducibility and provenance

The ZIP contains the main and supplementary source/PDFs, final vector figures, bilingual reader, selected historical run-level records and bootstrap tables, the 4,320-row Stage-1 recovered outcome table, Stage-1 selection/recovery manifests and per-episode SHA-256 index, the recovery audit, and the relevant analysis and recovery scripts. The 4,320 original MAT checkpoints (about 1.25 GB) remain in the project results directory and are not duplicated in the ZIP; the package includes their individual hashes and the recovery audit. No Stage-2 payloads are included. Reproduction requires MATLAB R2025a, Deep Learning Toolbox and CasADi 3.8.0 on Windows 64-bit, as recorded in the supplement.

The supplied MPC–DWA article does not provide dynamic-obstacle prediction code, run-level data or executable settings. Its comparator is therefore identified as a project-local latest-position-hold reconstruction, not an exact reproduction of the cited paper.

Ten bibliography records were field-checked against publisher, conference, institutional or author-maintained sources. Five are cited in the main paper. Fields absent from the supplied online-first Chang paper, including volume/issue/pages/DOI, are not guessed; the remaining field-level notes are in [`04_review/reference_verification_20261014.md`](04_review/reference_verification_20261014.md).

The manuscript PDFs were rebuilt from the open source files and visually checked page by page. The main paper is exactly four pages; the supplement is 17 pages. See the final audit for scope, render checks, minor compiler warnings and remaining limitations.
