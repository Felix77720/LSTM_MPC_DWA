# Final pre-submission audit — Version 13

Audit date: 2026-10-16. This closes the final route-figure and release-package checks. It revises the existing manuscript and preserves Version 08, prior drafts, historical results, raw simulation records and the prospectively fixed scene-1/seed-1 route example.

## Claims and evidence boundary

- The frozen 1-s forecast-sharing comparison contains 500 scenes × three matched DWA seeds (1,500 attempts per arm). Shared LSTM achieved 62.4% safe arrival versus 55.7% when LSTM was supplied only to DWA, a paired difference of 6.7 percentage points (95% scene-cluster CI 4.2–9.2). These 3,000 episodes are part of the existing 7,500-run benchmark.
- In the separate 3-s, 100-scene exploratory comparison, shared LSTM achieved 73.7%, standalone DWA-CV 78.0%, and standalone MPC-CV 92.0%. The shared-versus-DWA-only contrast was inconclusive. The manuscript therefore does not claim overall superiority over independent DWA or MPC.
- The completed 4,320 Stage-1 episodes remain development/calibration evidence. The separate 2,100-run seven-arm dataset remains exploratory. No new simulation was run for this finalization; incomplete Stage-2 records are unscored and excluded. Results are simulation-only, not flight validation.

## Route figure and selection

Main-text Figure 2 now uses scene 404, seed 2 from the existing five-controller benchmark. This is one of three matched keys in that dataset where only shared LSTM arrived safely (scene 288/seeds 2 and 3; scene 404/seed 2). Their median across-method path excesses (polyline length minus start-to-terminal chord) were 0.1201, 0.1457 and 0.2647 m; counts of paths exceeding 0.25 m were 1/5, 2/5 and 3/5. Scene 404 therefore had the clearest recorded curvature among those exclusive-arrival candidates. One comparator stopped after 2 s; the other four ran approximately 22–26 s. This selected matched case is descriptive, not a population comparison.

Supplementary Figure S5 presents all seven methods using scene 72, seed 2 from the distinct exploratory evaluation. All six comparator runs span at least 5 s; shared LSTM and standalone DWA arrived safely in this example. Scene 79/seed 2, the sole exclusive-arrival case in the seven-method set, remains in QA records but is not plotted because several comparator paths are short and nearly straight. Captions identify selection and outcomes; neither figure substitutes for aggregate results.

All five main-figure and seven S5 curves use saved XYZ states through their logged terminal points. No path was bent, smoothed, interpolated, resampled, shifted, selectively cut or extended. Display improvements use method-specific color, line style and saved-state marker shape; the main plot also reserves a right-side gutter so the z-axis title is not clipped. Coordinates and outcomes are unchanged. The original fixed scene-1/seed-1 routes remain archived.

The main-figure generator checks scene 404/seed 2, all five expected methods, logged terminal steps and terminal coordinates against the route-status table, plus obstacle-track coverage. The seven-method scene-72 endpoint audit verifies source states and route hashes. The figure-source validator reports 21 PASS, 0 WARN and 0 FAIL for both generators. The main route PDF has a 5.2 pt minimum text size and the seven-method route PDF has a 7.0 pt minimum; rendered collision audits report 0 WARN and 0 FAIL for both. Final-size inspection confirms the main z-axis title is inside the page and route markers remain distinguishable.

## Compilation, layout and synchronization

The open LaTeX editor had no connected compile API, so the existing in-project, no-auto-install build script compiled the editable source in place. The current main paper is four US Letter pages; Supplementary Methods is 19 US Letter pages after adding the retained unique-success example as Supplementary Figure S5. No overfull boxes or unresolved citations/references were found; nonfatal underfull/column-balance notices remain in the logs.

Fresh renders of all four main pages and updated Supplementary page 17 were generated from the final PDFs. Main pages 1–4 were each inspected; Supplement page 17 was checked for route visibility, caption and page clipping. The main paper remains four US Letter pages and the supplement 19 pages; page 19 remains populated. Text extraction shows nonempty content on all pages, and logs contain no overfull boxes or unresolved references. Temporary PNG page renders were used for visual QA and are not included in the release package; the canonical PDFs remain the deliverables.

The bilingual reader and source map are aligned at 47 anchors; all four source-map regression tests pass and the dry run reports zero pending changes. Translation notes distinguish the scene-404 five-controller main example from the scene-72 seven-method S5, while retaining the historical CV/Kalman and full-width scene-404 comparison. The reference audit leaves unavailable DOI, volume, issue and pagination fields for the online-first Chang et al. article unfilled rather than guessing.

## Final release checks

The refreshed reproducibility package includes the scene-404 main figure in four formats, the scene-72 seven-method S5 in four formats, the selected route records, the two scene-288 exclusive-arrival candidate exports used for the curvature screen, collision audits, the generator, editable sources, bilingual reader, supplement and preserved result records. The builder verified the ZIP inventory, CRC, embedded file hashes and external sidecar; the archive contains 246 entries and is below its 95-MiB GitHub size guard. The final ZIP digest is recorded in `03_supplementary/reproducibility_package.zip.sha256`; the independent delivery SHA-256 list was regenerated. No historical simulation result or source data was deleted.

Remaining limits are the exploratory 100-scene scope, incomplete/unscored Stage 2, the absence of the planned additional holdout, prescribed obstacle tracks and the absence of real-flight validation. The route example is illustrative only and is not a replacement for the aggregate comparisons.

## Canonical delivery paths

- Main PDF and editable source: `02_source/main.pdf`, `02_source/main.tex`, `02_source/references.bib`.
- Complete Chinese–English reader: `03_bilingual/paper.md` and `03_bilingual/source_map.json`.
- Supplementary PDF/source and reproducibility bundle: `03_supplementary/supplementary_methods.pdf`, `03_supplementary/supplementary_methods.tex`, `03_supplementary/reproducibility_package.zip`.
- Figure and records: main Figure 2 `02_source/figures/route_comparison_five_method_scene404_seed2.*`; seven-method Supplementary Figure S5 `02_source/figures/route_comparison_seven_method_scene72_seed2.*`; main route states in `qa/five_method_route_data/`; scene-79 and fixed scene-1 records remain archived.
- Release hashes: `03_supplementary/reproducibility_package.zip.sha256` and `03_supplementary/final_delivery_SHA256.txt`.
