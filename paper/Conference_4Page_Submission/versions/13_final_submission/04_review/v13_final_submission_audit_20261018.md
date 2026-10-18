# Final pre-submission audit — 2026-10-18

## Outcome

The main manuscript was edited in place and rebuilt as a four-page Letter-size IEEE conference paper. Figures 3 and 4 are each 0.485 text width and appear together at the top of page 4, immediately after the Results text that introduces the route example. Discussion, Conclusion and References follow the figures. All four pages were rendered and inspected at 1.6× scale; no blank page, cropped content, large unintended gap or displaced end-of-paper figure was found.

## Changes completed

- Reordered the abstract explicitly as problem, method, simulation results and conclusion using “First”, “Second”, “Then” and “Finally”.
- Rephrased defensive statements into evidence-first scope statements without changing any result or uncertainty interval.
- Clarified why one LSTM forecast is shared: MPC uses it to form the horizon route guide, DWA uses the same time-aligned positions to screen local rollouts, and the guide also affects trust-based DWA sampling.
- Clarified the execution boundary: the safe-set control box constrains MPC’s first input, whereas the screened DWA/emergency rollout is executed; the offline continuous swept-path audit classifies between-step contact.
- Kept the 4,320-episode development sweep, selected trust vector `[0.15,0.15,0.15,0.55]`, development macro-average 0.8042 and inherited historical vector `[0.35,0.30,0.15,0.20]` explicitly separated from held-out outcome claims.
- Moved the route-example introduction into Results and placed Figures 3 and 4 before Discussion. Removed the redundant full-width sentence above the figures.
- Redrew the seven-method route figure at native single-column width. The camera, line hierarchy, marker density and three-column legend were revised for legibility; every trajectory still uses all and only the saved states through its recorded terminal point.
- Updated the Figure 4 caption to decode safe-arrival, swept-contact and other-non-arrival endpoint markers.
- Synchronized the affected English/Chinese passages and the bilingual source map.

## Evidence and consistency checks

- Frozen comparison retained: shared LSTM 936/1,500 (62.4%) versus DWA-only LSTM 836/1,500 (55.7%); paired difference +6.7 percentage points, 95% scene-cluster CI 4.2–9.2.
- Separate seven-method evaluation retained: shared LSTM 221/300 (73.7%); standalone MPC-CV 276/300 (92.0%) with 15 swept contacts; shared-minus-DWA-only −1.0 point with simultaneous 95% CI −4.8 to 2.8.
- Frozen standalone rates retained: DWA+LSTM 82.4% and MPC+LSTM 95.2%. The manuscript states that these aggregate rates exceed the shared controller’s rate; no overall-superiority claim was introduced.
- Scene 72, seed 2 remains a descriptive matched example. Shared LSTM and DWA-CV are the two collision-free arrivals; MPC-CV enters goal tolerance with swept contact. The example is not used as aggregate evidence.
- No simulation was rerun and no result row, trajectory sample or endpoint was selected, removed or altered during this pass.
- Route endpoint generator checks: start coordinates, 0.1-s timestamp sequence, recorded state count, terminal coordinate, goal tolerance and saved outcome status all passed for seven methods.
- Nature-figure source preflight: 21 pass, 0 warning, 0 failure. Exported route PDF glyph floor: 5.5 pt. Rendered route collision audit: 0 failure, 0 warning. Single-plot alignment gate: not applicable/pass by design.
- LaTeX: two final `pdflatex` passes completed; output is 4 pages at 612 × 792 pt. No overfull box, undefined citation, undefined reference or compiler error remains. Remaining underfull warnings are limited to narrow-column line breaking in two Results paragraphs and bibliography entries.
- Bilingual `source_map.json` parses successfully. All four PDF pages contain text and were visually inspected.

## Remaining scope limits

- Evidence is simulation-only with prescribed obstacle tracks and point forecasts; no flight test is claimed.
- Controller rankings differ across the 1-s and 3-s protocols, which also differ in scene banks, trust weights and horizons. These protocols are reported separately and are not pooled.
- LSTM and CV use different configured input pipelines; a controlled input-matched sensitivity study is still needed for predictor-only attribution.
- The trust coefficients are supported by the 4,320-episode development sweep, not by an independent Stage-2 calibration.

## Deliverables and SHA-256

- `02_source/main.pdf` — `9ADD8D0AD5C4B1E21BE052DB8D4667F108C194322742F96439805BF0139A5C35`
- `02_source/main.tex` — `0B296715AB1D0C91EA4E563CBC8DF913950DE2F9C57FBB097742B10150C73DD1`
- `02_source/figures/route_comparison_seven_method_scene72_seed2_singlecol.pdf` — `3B00C1F4B327E366E2AE819F6ACAA47A3EA7385B1EBFADDE45FA27CD3498F82E`
- `03_bilingual/paper.md` — `FA96A476921F796ACF970C09F0D10136E854FD02B9DDB241DBECB747BC140B64`
- `03_bilingual/source_map.json` — `432326403385052D909FF1931CE7B58CAB77A6D48A171A2D64FB1235F60DD120`

Supporting route QA is in `qa/route_comparison_seven_method_scene72_seed2_singlecol.collision-audit.json`, `qa/route_comparison_seven_method_scene72_seed2_singlecol.alignment.json` and `qa/seven_method_route_endpoint_audit_scene72_seed2.json`.
