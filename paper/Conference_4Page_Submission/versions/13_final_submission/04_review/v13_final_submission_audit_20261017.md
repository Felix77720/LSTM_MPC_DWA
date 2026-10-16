# Final layout and delivery audit — Version 13

Audit date: 2026-10-17. This is a layout-focused final pass on the existing V13 manuscript, not a new study or rewritten paper. Version 08 and all historical simulation records remain preserved.

## Main-text flow and figures

- The final main-text sequence is Figure 1 (problem-scene geometry, placed in Problem Formulation), Figure 2 (shared-forecast planning pseudocode, placed after the method description), Figure 3 (side-by-side outcome-rate comparisons for two separate protocols), and Figure 4 (seven-method matched trajectories from scene 72, seed 2).
- The outcome chart is in the main body and separates the frozen 500-scene/1-s-DWA benchmark from the exploratory 100-scene/3-s evaluation. Its caption states denominators, swept-contact counts and that bars are point estimates; the panels are not pooled into one ranking.
- The enlarged Figure 4 contains a 3-D view and XY, XZ and YZ projections. Each view is labelled a–d, and the caption identifies every view and all seven controllers. The render shows all seven traces/markers and their legend without clipping. Saved path coordinates were not changed, interpolated, smoothed, bent or extended; non-arrival routes stop at logged terminal states. The example is labelled descriptive and is not used as aggregate evidence.
- Historical CV/Kalman and earlier route comparisons remain in Supplementary Figures S3–S5 and the QA archive. The 2026-10-16 audits describe the earlier figure placement and are retained as dated provenance; this report supersedes them for the current main-paper layout.

## Equations and method description

The main text keeps five numbered display equations for the state/clearance model, causal LSTM forecast, MPC objective, trust allocation and DWA safety screen/command envelope. The MPC sequence is compactly written as `u_{1:30}` and explicitly defined as the next 30 commands. Definitions remain next to the equations and operational details (limits, scores, fallback logic and training setup) remain in the supplement. In prose the LSTM is described as producing the same time-aligned 3-s obstacle forecast for both MPC route-cost evaluation and DWA rollout screening; DWA's surviving control envelope constrains MPC's first command, while the screened DWA action is executed.

## Build, rendering and synchronization

- The connected LaTeX editor compile session was unavailable, so the open source was rebuilt in place with the existing MiKTeX installation, package auto-install disabled. The PDF reports exactly four US Letter pages. The bibliography was regenerated and references resolved; the log contains no overfull boxes or unresolved citation/reference warnings. Non-fatal underfull boxes and the IEEE `balance` timing notice remain.
- All four current main-paper pages were rendered from `02_source/main.pdf` and visually inspected. Page 1 contains Figure 1 and the opening of the method; page 3 contains Figure 2 and results text; page 4 contains Figures 3 and 4 with captions and visible bottom margin. Page 2 equations remain within the column; no clipping or formula line overflow was seen.
- The four-page bilingual source map validates 52 anchors. `sync_bilingual_source_map.py --dry-run` reports zero differences after updating the compact MPC notation. Equation page metadata now matches the render (Eq. 1 on page 1; Eqs. 2–5 on page 2).
- All four source-map synchronization regression tests pass. The bounded archive contains 198 entries (16.36 MiB); the full reproducibility archive contains 265 entries (90.80 MiB, below the 95-MiB guard). Both ZIPs passed a full entry read test, their SHA-256 sidecars match, and all 158 entries in the independent delivery manifest were recomputed successfully. The superseded compact ZIP backup and temporary rendered page images were removed after verification; no source data or simulation records were removed.
- The supplement remains the previously verified 21-page PDF; this layout pass changed no supplementary text or figure pages. The previous visual audit checked its updated algorithm, historical/selected route panels and final comparison table.

## Evidence boundary and remaining limitations

No simulation was rerun and no outcome records were edited. The frozen benchmark remains 936/1,500 (62.4%) for shared LSTM versus 836/1,500 (55.7%) for DWA-only LSTM, +6.7 percentage points (95% scene-cluster CI 4.2–9.2). In the separate exploratory evaluation, shared LSTM reached 221/300 (73.7%), the DWA-only LSTM contrast was inconclusive, and standalone MPC-CV had the highest rate (276/300; 92.0%). These results support a protocol-specific forecast-sharing gain, not overall superiority over independent DWA/MPC or global optimality. Figure 4 is one matched example; it does not replace those statistics. Evidence is simulation-only, prescribed obstacle paths are used, and the planned additional independent holdout and real-flight validation remain absent.

## Canonical files

- Four-page PDF: `02_source/main.pdf`
- Editable source and bibliography: `02_source/main.tex`, `02_source/references.bib`
- Main-text figure assets: `02_source/figures/algorithm_main_pseudocode.*`, `02_source/figures/seven_method_outcomes_main.*`, `02_source/figures/route_comparison_seven_method_scene72_seed2.*`
- Full bilingual reader and map: `03_bilingual/paper.md`, `03_bilingual/source_map.json`
- Supplement: `03_supplementary/supplementary_methods.pdf`, `03_supplementary/supplementary_methods.tex`
- Reproducibility archives and checksums: `03_supplementary/reproducibility_package.zip`, `03_supplementary/reproducibility_package_v13.zip`, `03_supplementary/final_delivery_SHA256.txt`
