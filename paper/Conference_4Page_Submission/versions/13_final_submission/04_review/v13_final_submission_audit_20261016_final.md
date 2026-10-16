# Final pre-submission audit — Version 13

Audit date: 2026-10-16. This closes the final route-figure and release-package checks. It revises the existing manuscript and preserves Version 08, prior drafts, historical results, raw simulation records and the prospectively fixed scene-1/seed-1 route example.

## Claims and evidence boundary

- The frozen 1-s forecast-sharing comparison contains 500 scenes × three matched DWA seeds (1,500 attempts per arm). Shared LSTM achieved 62.4% safe arrival versus 55.7% when LSTM was supplied only to DWA, a paired difference of 6.7 percentage points (95% scene-cluster CI 4.2–9.2). These 3,000 episodes are part of the existing 7,500-run benchmark.
- In the separate 3-s, 100-scene exploratory comparison, shared LSTM achieved 73.7%, standalone DWA-CV 78.0%, and standalone MPC-CV 92.0%. The shared-versus-DWA-only contrast was inconclusive. The manuscript therefore does not claim overall superiority over independent DWA or MPC.
- The completed 4,320 Stage-1 episodes remain development/calibration evidence. The separate 2,100-run seven-arm dataset remains exploratory. No new simulation was run for this finalization; incomplete Stage-2 records are unscored and excluded. Results are simulation-only, not flight validation.

## Route figure and selection

Main-text Figure 2 now uses scene 72, sampling seed 2. It was selected post hoc from existing records under a visibility-balanced rule: shared LSTM reaches safely, exactly one comparator also reaches safely, and all six comparator trajectories span at least 5 s. The two safe arrivals are shared LSTM and standalone DWA; standalone MPC reached the goal tolerance after swept contact, position-hold MPC–DWA had swept contact before arrival, and the other three integrated methods stopped without contact. This single case is descriptive, not a population comparison. To preserve the user's preferred exclusive-arrival example without sacrificing path legibility in the main panel, Supplementary Figure S5 retains scene 79, seed 2, the only matched set where shared LSTM arrived safely and the other six did not reach the goal.

All seven Figure 2 curves use the saved XYZ states through their actual logged terminal point. No path was bent, smoothed, interpolated, resampled, shifted or extended. Display improvements use thicker lines, method-specific colors, line styles and marker shapes placed only on saved states, a neutral start marker and unfilled panes; the route coordinates and outcomes are unchanged. Scene 79/S5 uses the same marker coding. The original fixed scene-1/seed-1 routes remain archived.

The endpoint audits verify each start, terminal point, timestamp sequence, goal status and trajectory hash against the saved CSV/status records. The scene-72 and scene-79 figures are both explicitly labelled as examples, with population claims grounded in the complete evaluation. The figure-source validator reports 21 PASS, 0 WARN and 0 FAIL. Both figure PDFs have a 7.0 pt text-size minimum; rendered collision audits for both report 0 WARN and 0 FAIL. Both endpoint audits confirm all seven routes use only saved positions and stop at the logged terminal states.

## Compilation, layout and synchronization

The open LaTeX editor had no connected compile API, so the existing in-project, no-auto-install build script compiled the editable source in place. The current main paper is four US Letter pages; Supplementary Methods is 19 US Letter pages after adding the retained unique-success example as Supplementary Figure S5. No overfull boxes or unresolved citations/references were found; nonfatal underfull/column-balance notices remain in the logs.

Fresh renders of all four main pages and all 19 supplement pages were generated. All main pages were inspected at page scale; updated Supplementary pages 17–19 were inspected at page scale, and the full supplement contact sheet was reviewed for page flow. After the final route-marker and caption refinement, main page 4 and Supplementary page 17 were rendered again and inspected against the synchronized scene-72 and scene-79 assets. The revised equations, main route caption, scene-79 Supplementary Figure S5 and the ending outcome tables have no clipping, overlap, formula collision or missing content. Supplement page 19 is a partial but populated final page, not a blank page. Rendered evidence is retained in `qa/render_route_visibility_20261016/` and `qa/render_route_final_20261016/`.

The bilingual reader and source map are aligned at 47 anchors; all four source-map regression tests pass and the dry run reports zero pending changes. The source-map validator now recognizes the numbered supplementary-figure heading and checks its linked image/caption. Translation notes were updated to distinguish scene 72 (main Figure 2) from scene 79 (Supplementary Figure S5), while retaining the historical CV/Kalman and scene-404 comparisons. The reference audit leaves unavailable DOI, volume, issue and pagination fields for the online-first Chang et al. article unfilled rather than guessing.

## Final release checks

The reproducibility package includes both route-selection audits and all fourteen saved route CSVs, separate endpoint and rendered-collision audits for scenes 72 and 79, the figure generator, manuscript sources, complete bilingual reader, supplementary files and existing reproducibility records. Each method now has a unique route-point marker shape, in addition to color and line style; all markers lie on saved samples. The final builder validates the exact ZIP inventory and CRC, every non-index file against the embedded SHA-256 index, the archive sidecar and the independent delivery manifest. The current verification counts and hashes are captured in the generated manifests. No historical simulation result or source data was deleted.

Remaining limits are the exploratory 100-scene scope, incomplete/unscored Stage 2, the absence of the planned additional holdout, prescribed obstacle tracks and the absence of real-flight validation. The route example is illustrative only and is not a replacement for the aggregate comparisons.

## Canonical delivery paths

- Main PDF and editable source: `02_source/main.pdf`, `02_source/main.tex`, `02_source/references.bib`.
- Complete Chinese–English reader: `03_bilingual/paper.md` and `03_bilingual/source_map.json`.
- Supplementary PDF/source and reproducibility bundle: `03_supplementary/supplementary_methods.pdf`, `03_supplementary/supplementary_methods.tex`, `03_supplementary/reproducibility_package.zip`.
- Figure and records: main Figure 2 `02_source/figures/route_comparison_seven_method_scene72_seed2.*`, Supplementary Figure S5 `02_source/figures/route_comparison_seven_method.*`, and route records under `qa/route_example_scene72_seed2/` and `qa/route_example_scene79_seed2/`.
- Release hashes: `03_supplementary/reproducibility_package.zip.sha256` and `03_supplementary/final_delivery_SHA256.txt`.
