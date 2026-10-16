# Version 13 final-submission audit addendum

Audit date: 2026-10-16. This addendum records the final continuation after the author confirmed that no additional scientific experiments should be run. It supplements, and does not replace, `v13_final_submission_audit_20261015.md`.

## Final text and interpretation update

The Discussion now states that the tested LSTM pipeline receives simulator-recorded obstacle position, velocity and heading, whereas the CV pipeline derives velocity from positions. The controller comparison therefore reflects the configured input streams, not predictor architecture alone. This qualification is consistent with the methods paragraph and the implementation. The English text, Chinese translation and source-map entries were synchronized; the updater validated all 45 anchors, and all four synchronization tests passed.

The paper retains the complete seven-arm exploratory comparison. Shared LSTM reached 221/300 collision-free goals (73.7%); the paired advantage over the latest-position-hold reconstruction was 16.3 percentage points (simultaneous 95% CI 5.1–27.6). Standalone MPC-CV reached 276/300 (92.0%) and standalone DWA-CV 234/300 (78.0%). Thus, the data support the stated reconstruction contrast, not overall superiority of shared LSTM. No simulation result is represented as real-flight validation.

## Code, data and provenance checks

- The 2,100 exploratory records comprise 100 scenes × 3 matched seeds × 7 arms, with 300 records per arm and unique planned keys. Their reported counts agree with the raw outcomes and summary table. The 4,320 Stage-1 development records and episode-hash rows remain complete.
- Stage 2 remains incomplete: 2,263 of 5,760 planned checkpoints exist. They were not scored or used for parameter selection. The 500-scene holdout was not run and is retired; the 100-scene exploratory bank is its deterministic first-100 prefix and is not treated as independent confirmation. No new scientific experiment was run in this continuation.
- Code inspection of `simulate_dynamic.m` (history construction around lines 377–407) found that prediction history is truncated at `observed_step`. `predict_obstacle_traj.m` computes CV from the latest two positions, while its LSTM branch passes the history through `features_from_traj.m`, which encodes position, velocity and heading. No future trajectory rows were found in the predictor input path. The clean-simulation arms nevertheless receive different information streams, as stated above; this limits predictor-only interpretation.
- The local MPC–DWA source PDF was rechecked. It supports the title, author order, journal and online-first date; its front page states that volume, issue and pagination were not yet finalized, and it lists no DOI. The existing reference audit appropriately leaves those fields unfilled. Source-PDF SHA-256: `C59D8299367333B5D7D39D58C333536FFB98685BD3064ABB1CB2AC0556D1FBFB`.

## Build and visual QA

The canonical source `02_source/main.tex` compiled in place with the existing MiKTeX installation. The paper is 4 pages on Letter; the supplement is 19 pages. All four newly rendered main-paper pages were visually inspected at 145 dpi. All 19 freshly rendered supplement pages were checked at page scale after rebuild. No clipping, overlap, missing figure/caption, blank page or formula collision was found; supplement page 17 is a sparse text continuation, not a blank page. The Figure-1 problem schematic remains separate from the seven-method trajectory figure. The supplement source was unchanged. Main log review found no overfull boxes or unresolved citations; nonfatal underfull and column-balance warnings remain.

The updated Discussion changes interpretation only; it does not alter any equation, experimental count, figure data or result. The rebuilt main PDF SHA-256 is recorded in `03_supplementary/final_delivery_SHA256.txt` and the reproducibility archive's internal hash inventory.

## Remaining limits and release state

The 100-scene study is exploratory, Stage 2 is incomplete, the confirmatory holdout was not run, and no real flight was performed. Prescribed tracks and simulator-recorded LSTM features also limit transfer to sensor-only deployment. These are explicit scope limits, not grounds for substituting or omitting outcomes. Version 08 and historical results remain preserved; no source experiment data were deleted.

