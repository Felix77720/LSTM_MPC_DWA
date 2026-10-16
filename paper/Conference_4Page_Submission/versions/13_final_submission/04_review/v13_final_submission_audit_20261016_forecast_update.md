# Final submission audit update: forecast-sharing contrast

Audit date: 2026-10-16
Scope: continued revision of Version 13; no new scientific experiment or parameter search was run.

## Evidence surfaced in the main text

The manuscript now reports the frozen, protocol-defined shared-LSTM versus DWA-only-LSTM contrast in the main text. It uses 500 scenes and three matched DWA sampling seeds per scene (1,500 attempts per arm). DWA received the same LSTM forecast in both arms; only the shared arm also supplied that forecast to MPC. MPC held each obstacle at its latest observed position in the DWA-only arm. DWA screened a 1-s rollout, MPC planned over 3 s, and both arms used the inherited trust-weight vector.

Shared LSTM achieved 936/1,500 collision-free arrivals (62.4%), versus 836/1,500 (55.7%). The paired difference was +6.7 percentage points, with a 95% whole-scene bootstrap interval of +4.2 to +9.2. The analysis resampled 500 complete scene clusters, retaining the three matched seeds, for 20,000 replicates. The protocol was frozen internally before execution but was not publicly preregistered.

The 3,000 two-arm records are a subset of the 7,500-run five-controller benchmark, not another cohort. A key-level reconciliation matched all 3,000 records against the corresponding controller rows in `five_method_run_audit.csv`; success, collision, infeasible-stop and step-count outcomes had zero mismatches. The associated files are:

- `03_supplementary/confirmatory_method_summary.csv`
- `03_supplementary/confirmatory_cluster_bootstrap.csv`
- `03_supplementary/confirmatory_raw.csv`
- `04_review/shared_vs_dwaonly_confirmatory_protocol.md`
- `results/final_five_method_fair_revision/five_method_fair_20261010_232757/five_method_run_audit.csv`

The main paper keeps the separate 100-scene, seven-method exploratory evaluation visible. Under its 3-s MPC/DWA setup and development-selected trust weights, shared LSTM reached 221/300 (73.7%), the DWA-only-LSTM arm reached 224/300 (74.7%), and standalone MPC-CV reached 276/300 (92.0%). The simultaneous interval for the shared-versus-DWA-only contrast included zero. This evaluation uses a different scene bank; the protocols are not pooled. Scene banks, trust weights and screening horizons differ, so the cross-protocol difference cannot identify a horizon effect.

## Manuscript and package changes

- Revised the abstract in the requested problem → method → results → conclusion sequence. It now reports the 500-scene matched effect and the separate 100-scene boundary.
- Added the forecast-allocation contrast to the Results and aligned the Discussion and Conclusion with the protocol-specific evidence. The 1-s forecast-sharing contrast and the separate 3-s controller ranking are reported side by side.
- Added one SI sentence identifying the 3,000 shared/DWA-only episodes as part of the 7,500-run benchmark.
- Updated the complete Chinese-English reader and synchronized `source_map.json`; all 45 anchors validate and the source-map dry run reports zero remaining changes.
- Updated README and revision status; no raw experiment record, historical result, image, or original manuscript was deleted or altered.

## Build and layout check

The open editor had no connected document session, so its `compile_latex_document` command was unavailable. The existing in-project `scripts/compile_final.ps1` compiled the same editable source and supplement successfully using the installed MiKTeX toolchain; no package was downloaded. Current outputs are a four-page Letter main paper and an 18-page Letter supplement. The main log has no unresolved citations/references or overfull-box warnings; nonfatal underfull and balance warnings remain.

Fresh Poppler renders of all four main pages were inspected. The updated SI page 9 and current final page 18 were also inspected. The abstract and the full 500-scene comparison were checked in the rendered pages and extracted PDF text; literal percent signs display correctly after LaTeX escaping. Equations, Figure 1, the seven-method Figure 2, Table 1, the SI outcome table, captions and page-4 references showed no clipping or overlap. The problem-scene schematic remains separate from the trajectory comparison. Main figure data and historical CV/Kalman figures were unchanged.

The LaTeX log's MiKTeX setup/update notice is environmental and did not block compilation. The source-map dry run validates all 45 anchors with zero changes, and all four synchronization tests pass. The refreshed allowlist archive contains 187 entries, including the 3,000 paired contrast records and full 7,500-run reconciliation data; the ZIP sidecar, all 186 embedded SHA-256 entries and all 79 external delivery hashes were independently checked with zero mismatches. The canonical main PDF is `02_source/main.pdf`; the older `01_manuscript/main_revised.pdf` remains an interim artifact and was neither overwritten nor packaged.

## Final verification after copyedit

The final copyedit updates abstract, Results and Conclusion phrasing in `main.tex`, the corresponding bilingual blocks and the last interpretation sentence in Supplementary Methods. It makes the evidence statement direct while preserving every outcome and interval. No experiment, parameter, figure data or historical record changed. The final build was run with the existing project script and installed MiKTeX; no dependency was downloaded. The generated logs and `pdfinfo` report a four-page Letter main paper and an 18-page Letter supplement, with no overfull boxes, unresolved references or LaTeX errors. All 4 main pages and all 18 supplement pages were freshly rendered. Pages 1, 3 and 4 of the main paper and page 18 of the supplement, which contain the copyedited text, were visually rechecked; the other pages are unchanged from the preceding complete visual inspection. The earlier addendum's 19-page supplement count records a prior build and is superseded by this 18-page source/PDF/log result.

The bilingual updater validated all 45 anchors and synchronized the English/Chinese abstract, Results and Conclusion entries in `source_map.json`; the four synchronization regression tests passed. The revised final sentences report the 6.7-point gain only for the frozen 1-s DWA protocol and identify standalone MPC-CV as highest in the separate 3-s exploratory evaluation. The six exploratory contrasts are described exactly: shared LSTM exceeded the position-hold reconstruction, standalone MPC-CV exceeded shared LSTM, and the remaining four intervals included zero.

## Remaining limitations

- Stage 2 remains incomplete at 2,263/5,760 saved checkpoints and is unscored. The planned 10,500-run seven-method holdout was not run, in accordance with the author's instruction to stop adding scientific experiments.
- The 100-scene evaluation remains exploratory and does not reproduce the 500-scene result under its 3-s protocol. The 500-scene protocol was not publicly preregistered.
- LSTM receives simulator-recorded obstacle velocity and heading, whereas CV estimates velocity from positions. Results compare configured input pipelines, not predictor architectures alone.
- All outcomes are simulations with prescribed obstacle motion and point forecasts. No real-flight validation or unseen-family generalization is established.
- The 100-scene exploratory evaluation ranked standalone MPC-CV highest for collision-free arrival (92.0%, versus 73.7% for shared LSTM); the frozen 1-s protocol favored shared LSTM over DWA-only input by 6.7 percentage points.
- The supplied Chang et al. article does not provide verifiable DOI, volume, issue or page range in the available source; the reference audit leaves these fields blank rather than guessing.

## Final files

- Canonical main PDF: `02_source/main.pdf` (the older `01_manuscript/main_revised.pdf` is retained as an interim artifact and is not part of this release).
- Editable main source and bibliography: `02_source/main.tex`, `02_source/references.bib`
- Supplement PDF and source: `03_supplementary/supplementary_methods.pdf`, `03_supplementary/supplementary_methods.tex`
- Bilingual reader and map: `03_bilingual/paper.md`, `03_bilingual/source_map.json`
- Figures: `02_source/figures/`
- Reproducibility archive and SHA-256 inventories: `03_supplementary/reproducibility_package.zip`, `03_supplementary/reproducibility_package.zip.sha256`, `03_supplementary/final_delivery_SHA256.txt`
- This audit update: `04_review/v13_final_submission_audit_20261016_forecast_update.md`
