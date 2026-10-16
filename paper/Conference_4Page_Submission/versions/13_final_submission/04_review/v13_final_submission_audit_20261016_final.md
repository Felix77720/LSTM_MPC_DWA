# Final pre-submission audit — Version 13

Audit date: 2026-10-16. This closes the final route-figure and release-package checks. It revises the existing manuscript and preserves Version 08, prior drafts, historical results, raw simulation records and the prospectively fixed scene-1/seed-1 route example.

## Claims and evidence boundary

- The frozen 1-s forecast-sharing comparison contains 500 scenes × three matched DWA seeds (1,500 attempts per arm). Shared LSTM achieved 62.4% safe arrival versus 55.7% when LSTM was supplied only to DWA, a paired difference of 6.7 percentage points (95% scene-cluster CI 4.2–9.2). These 3,000 episodes are part of the existing 7,500-run benchmark.
- In the separate 3-s, 100-scene exploratory comparison, shared LSTM achieved 73.7%, standalone DWA-CV 78.0%, and standalone MPC-CV 92.0%. The shared-versus-DWA-only contrast was inconclusive. The manuscript therefore does not claim overall superiority over independent DWA or MPC.
- The completed 4,320 Stage-1 episodes remain development/calibration evidence. The separate 2,100-run seven-arm dataset remains exploratory. No new simulation was run for this finalization; incomplete Stage-2 records are unscored and excluded. Results are simulation-only, not flight validation.

## Route figure and selection

The seven-method overlay uses scene 79, sampling seed 2, the only one of 300 matched scene–seed sets in the existing exploratory records where shared LSTM reached safely and all six other methods failed to reach the goal. This is a post hoc, outcome-selected illustration, not population evidence or an aggregate superiority test. In this case one baseline had swept contact and five stopped without contact. The visual-selection trade-off is real: the more varied scene 34, seed 2 has six of seven methods reaching safely, so it does not meet the requested exclusive-arrival preference. The selected case therefore has short, nearly straight early-stop traces; we kept those recorded paths rather than bending, extending or hiding them.

All seven curves use every saved XYZ state through its recorded terminal point. No path was bent, smoothed, interpolated, resampled, shifted or extended. Some comparators stopped early, leaving short, nearly straight traces; no alternative case satisfies the unique-arrival selection rule. Readability was improved with heavier strokes, larger markers at actual saved states, a neutral start marker and unfilled panes. The trajectory data and outcome values were unchanged. The original fixed scene-1/seed-1 routes remain archived.

The plotting-source preflight reports 21 PASS, 0 WARN and 0 FAIL. The route PDF has a 7 pt minimum glyph size and the rendered collision audit reports 0 FAIL and 0 WARN. Full-PDF glyph audits pass with a 6.2 pt minimum in the main paper and 5.2 pt in the supplement; no text glyph falls below 5 pt. The endpoint audit verifies each start, terminal point, timestamp sequence, goal status and trajectory hash against the saved CSV/status records.

## Compilation, layout and synchronization

The open LaTeX editor had no connected compile session. The in-project, no-auto-install build script compiled the existing editable source in place. The current main paper is four US Letter pages; Supplementary Methods is 18 US Letter pages. No overfull boxes or unresolved citations/references were found; nonfatal underfull/column-balance notices remain in the logs.

Fresh renders of all four main pages and updated Supplementary pages 2, 4, 5 and 16–18 were inspected. These include the revised MPC/DWA equations, selected trust weights, historical route figure, post hoc route note and final outcome tables; the other supplement pages were unchanged and had been reviewed in the preceding full-page audit. No clipping, overlap, missing figure/caption, blank page or formula collision was observed. Rendered evidence is retained in `qa/render_final_route_20261016/`.

The bilingual reader and source map remain aligned at 45 anchors; all four source-map regression tests pass and the dry run reports zero pending changes. Translation notes were brought into line with the current seven-method main figure, six cited references and preserved historical examples. Historical CV/Kalman comparisons and the earlier scene-404 example remain separate and preserved. The reference audit leaves unavailable DOI, volume, issue and pagination fields for the online-first Chang et al. article unfilled rather than guessing.

## Final release checks

The reproducibility package includes the route-selection audit, all seven route CSVs, the endpoint and collision audits, the figure generator, the manuscript sources, the full bilingual reader, supplementary files and the existing reproducibility records. The ZIP contains 201 entries; all 200 non-index files match the embedded SHA-256 index, CRC validation passes, the archive sidecar matches the ZIP, and all 96 entries in the independent delivery manifest verify. No historical simulation result or source data was deleted.

Remaining limits are the exploratory 100-scene scope, incomplete/unscored Stage 2, the absence of the planned additional holdout, prescribed obstacle tracks and the absence of real-flight validation. The route example is illustrative only and is not a replacement for the aggregate comparisons.

## Canonical delivery paths

- Main PDF and editable source: `02_source/main.pdf`, `02_source/main.tex`, `02_source/references.bib`.
- Complete Chinese–English reader: `03_bilingual/paper.md` and `03_bilingual/source_map.json`.
- Supplementary PDF/source and reproducibility bundle: `03_supplementary/supplementary_methods.pdf`, `03_supplementary/supplementary_methods.tex`, `03_supplementary/reproducibility_package.zip`.
- Figure and records: `02_source/figures/route_comparison_seven_method.*`, `qa/route_example_scene79_seed2/`.
- Release hashes: `03_supplementary/reproducibility_package.zip.sha256` and `03_supplementary/final_delivery_SHA256.txt`.
