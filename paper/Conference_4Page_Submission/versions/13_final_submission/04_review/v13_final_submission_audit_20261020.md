# Version 13 final submission audit — 2026-10-20

## Decision

The current Version 13 manuscript is a four-page, simulation-only conference submission with editable LaTeX, a synchronized Chinese--English reader, a 21-page supplement and reproducibility archives. This round revised the existing paper in place. It did not rerun or alter the scientific simulations, and it preserves Version 08, historical studies and raw records as provenance.

## Changes completed in this round

- The Introduction now identifies forecast disagreement between route planning and local action screening as the design problem. It explains why the existing MPC and DWA roles are retained instead of replacing either planner.
- Planning Method now derives the architecture from the observed failure mechanism and states three choices: predict once for both layers, keep MPC responsible for early long-horizon detours, and keep DWA responsible for the next reachable action. It also explains the two-way exchange of the MPC guide and screened DWA control ranges.
- Figure 2 was redrawn as a five-module update loop with the explicit information hierarchy “one future, two time scales, screened execution.” The diagram separates long-horizon MPC, immediate DWA screening, the normal/emergency gate, feedback and execution.
- Figure 4 was redrawn from the unchanged scene-72/seed-2 saved coordinates. The main view includes all five integrated paths. A comparator-only XY inset magnifies the terminal region of coupled CV, LSTM-to-MPC, LSTM-to-DWA and position hold so their overlapping trajectories and endpoints remain readable. No coordinate was offset, smoothed, interpolated or extended.
- The Figure 2 and Figure 4 captions and the bilingual reader were synchronized. The redundant main-text outcome table was removed because the same five values and contact counts are already reported in the result paragraph and Figure 3; full tabular results remain in Supplementary Tables S11--S12.

## Scientific and numerical checks

The result values were not changed. The main analysis still reports 1,500 integrated episodes from the 2,100-episode exploratory bank. Shared LSTM reached safely in 221/300 runs (73.7%); position hold reached 172/300 (57.3%), coupled CV 204/300 (68.0%), LSTM-to-MPC 219/300 (73.0%), and LSTM-to-DWA 224/300 (74.7%). The displayed shared-minus-comparator intervals remain +16.3 percentage points [5.1, 27.6] for position hold, +5.7 [−3.4, 14.7] for coupled CV, +0.7 [−9.0, 10.3] for LSTM-to-MPC, and −1.0 [−4.8, 2.8] for LSTM-to-DWA.

Claims remain bounded by those intervals. The paper states an improvement over latest-position hold, not global superiority over coupled CV, the one-layer LSTM variants or standalone controllers. Scene 72, seed 2 remains explicitly post hoc and illustrative. The 4,320 development episodes are still identified as coefficient-selection runs, not held-out evaluation.

The route generator revalidated each source CSV against the logged method, state count and terminal coordinate before export. Per-coordinate terminal differences are within the six-decimal serialization tolerance used by the endpoint audit. The shared route has 507 saved states; coupled CV, LSTM-to-MPC, LSTM-to-DWA and position hold have 84, 88, 67 and 85 states, respectively. All paths stop at their saved terminal point.

## Figure and layout QA

- `algorithm_main_pseudocode.pdf`: strict rendered-collision audit passed with 0 failures and 0 warnings; minimum PDF text size is 6.35 pt.
- `route_comparison_integrated_five_method_scene72_seed2_singlecol.pdf`: strict rendered-collision audit passed with 0 failures and 0 warnings; minimum PDF text size is 5.0 pt.
- Both figures passed the generator's alignment gate. SVG, PDF, PNG and LZW-compressed TIFF exports were regenerated from the Python source.
- The main paper compiles to 4 pages; the supplement compiles to 21 pages. Final logs contain no Overfull, Undefined, Fatal or LaTeX Error entry.
- All four main pages were raster-rendered and inspected at 140 dpi. Figure 1 remains in Problem Formulation, Figure 2 remains with Planning Method, Figure 3 precedes the numerical Results discussion, and Figure 4 is placed with the matched route example. No cropped formula, clipped label, displaced float or large unintended blank page remains.
- Supplementary page 6 was rerendered to confirm that Algorithm S1 remains intact after the package rebuild.

## Bilingual and package checks

`03_bilingual/paper.md` contains the revised rationale, method description and figure captions in both languages. The source-map synchronizer validated 51 anchors and updated 12 content fields. Its four unit tests pass.

The compact and full reproducibility packages are rebuilt from the current paper, figures, source records and QA artifacts. SHA-256 sidecars and the delivery hash list are regenerated after compilation. No raw simulation result, historical study or Version 08 baseline was deleted.

## Remaining limitations

The evidence remains simulation-only. Obstacles follow prescribed tracks and the LSTM provides point forecasts. Prediction uncertainty, unseen motion families and real-flight performance have not been tested. The current intervals do not establish that shared LSTM is better than coupled CV or either one-layer LSTM injection arm, and the standalone arms retain higher observed arrival rates. These limits remain in the abstract, Results, Discussion, Conclusion, bilingual reader and supplement.

## Canonical delivery paths

- Paper PDF: `02_source/main.pdf`
- Editable source: `02_source/main.tex`, `02_source/references.bib`
- Bilingual reader: `03_bilingual/paper.md`, `03_bilingual/source_map.json`
- Supplement: `03_supplementary/supplementary_methods.pdf`, `03_supplementary/supplementary_methods.tex`
- Figures: `02_source/figures/algorithm_main_pseudocode.*`, `02_source/figures/route_comparison_integrated_five_method_scene72_seed2_singlecol.*`
- Compact reproducibility archive: `03_supplementary/reproducibility_package_v13.zip`
- Full reproducibility archive: `03_supplementary/reproducibility_package.zip`
- Delivery hashes: `03_supplementary/final_delivery_SHA256.txt` and ZIP `.sha256` sidecars
