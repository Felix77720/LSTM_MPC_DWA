# Version 13 final submission audit — 2026-10-19

## Decision

The active Version 13 manuscript is ready for submission as a four-page, simulation-only conference paper, subject to the venue's ordinary metadata and upload checks. This release revises the existing manuscript and preserves Version 08, raw simulation records, historical studies and incomplete Stage-2 checkpoints as provenance. No new scientific simulation was run during finalization.

## Manuscript and method

- The abstract now follows problem → method → simulation result → conclusion. It identifies dynamic-obstacle uncertainty, explains the shared 3-s LSTM forecast, reports the five integrated arms as 1,500 episodes within the 2,100-episode bank, and limits the claim to evidence supported by simultaneous intervals.
- Problem Formulation contains the scene, vehicle, moving spherical obstacles, observations, command and terminal conditions without embedding experiment-specific numeric settings. Figure 1 is placed with this model; recorded routes remain separate.
- Planning Method states the responsibility and execution order of all three modules. LSTM supplies one time-aligned 30-step forecast to both layers; MPC uses it for route-level clearance costs; DWA screens reachable rollouts against the same future. The prior MPC route changes DWA's guided/exploratory sample allocation, and the ranges of screened DWA controls constrain only MPC's next first command. The separately screened DWA or emergency action is the command executed.
- Equations (1)–(5) are grouped in the method section and used by the implementation: vehicle/clearance dynamics, causal LSTM offsets, MPC objective and constraints, trust/sample allocation, and DWA safety-set/feedback bounds. Every symbol used in the main equations is defined in the adjacent prose. The component-wise feedback box is not described as certifying every control combination inside it.
- The trust vector `[0.15, 0.15, 0.15, 0.55]` was selected before the 100-scene evaluation from six vectors across five integrated arms, 48 development scenes and three seeds: `6 × 5 × 48 × 3 = 4,320` episodes. Its equal-arm development macro-average was 0.8042. These are selection-set descriptions, not held-out comparative estimates.
- Language was shortened and made direct. Defensive discussion of prior work was removed from the main narrative; evidence boundaries remain explicit.

## Numerical and statistical consistency

The current 3-s exploratory bank contains 100 scenes × three matched seeds × seven arms = 2,100 planned episodes. The main paper focuses on the five integrated MPC–DWA arms (1,500 episodes):

| Integrated arm | Collision-free arrival | Swept contacts |
|---|---:|---:|
| Latest-position hold | 172/300 (57.3%) | 50 |
| Coupled CV | 204/300 (68.0%) | 0 |
| LSTM to MPC only | 219/300 (73.0%) | 0 |
| LSTM to DWA only | 224/300 (74.7%) | 0 |
| Shared LSTM | 221/300 (73.7%) | 0 |

The displayed shared-minus-integrated contrasts use scene-cluster resampling and the original simultaneous six-contrast max-|t| correction: position hold +16.3 percentage points [5.1, 27.6], coupled CV +5.7 [−3.4, 14.7], LSTM-to-MPC +0.7 [−9.0, 10.3], and LSTM-to-DWA −1.0 [−4.8, 2.8]. Thus shared LSTM improved collision-free arrival over latest-position hold; the other three integrated comparisons remain uncertain.

The cross-architecture standalone arms remain in Supplementary Tables S11–S12: standalone DWA-CV 234/300 (78.0%, zero swept contacts) and standalone MPC-CV 276/300 (92.0%, 15 swept contacts). They are not hidden or used to claim global superiority. The historical 1-s study remains separate in the supplement, including shared LSTM 62.4%, DWA-only LSTM integration 55.7% and their +6.7-point interval [4.2, 9.2]. No historical and current bank is pooled.

All figures, Table 1, main prose, abstract, conclusion, bilingual reader and source CSVs were checked against these counts and intervals. Scene 72, seed 2 is labelled as a post hoc route-visibility example: only shared LSTM safely arrived among the five integrated methods in that record. It is not presented as aggregate evidence.

## Figures and layout

- Figure 1: problem geometry, adjacent to Problem Formulation.
- Figure 2: five-module planning update, adjacent to Planning Method. MPC and DWA are parallel consumers of one forecast; normal and emergency branches are explicit.
- Figure 3: first figure in Results, showing integrated 3-s arrival rates and four displayed shared-minus-comparator intervals. Its caption states that multiplicity control covers all six original contrasts.
- Figure 4: five integrated scene-72/seed-2 routes, placed immediately after the corresponding result sentence. A small XY inset resolves early-route overlap. Start/goal and terminal outcome markers are explained in the caption.

The main Figure 2–4 PDFs passed vector collision audits with zero failures and zero warnings. Figure alignment audits passed. Route endpoint QA confirms that every path ends at its recorded terminal state; no route was extended, smoothed or bent. The all-seven-method four-view route, historical scene-404 example and CV/Kalman figures remain in the supplement.

## References, bilingual reader and supplement

- All five references cited by the four-page main paper were checked field by field in `reference_verification_v13.md` using publisher, DOI/Crossref and institutional records where available. No unverified bibliographic field was guessed. Historical references with incomplete metadata retain only verified fields.
- `03_bilingual/paper.md` matches the current title, abstract, method equations, figures, table numbers and evidence boundaries. `source_map.json` validates 51 anchors, and all four synchronization tests pass.
- Supplementary Tables S6 and S11–S12, Figure S5 and their bilingual labels were reconciled. Historical 1-s material and the current 3-s study are explicitly separated.

## Build and package verification

- `02_source/main.pdf`: 4 pages.
- `03_supplementary/supplementary_methods.pdf`: 21 pages.
- Final LaTeX logs contain no Overfull, Undefined, Fatal or LaTeX Error entries. The only remaining main-text diagnostics are harmless underfull bibliography lines caused by narrow IEEE columns.
- All four main pages and the updated/critical supplementary pages 6 and 19–21 were raster-rendered and visually inspected. No visible clipping, overlap, cropped formula, displaced float or large unintended blank region remains.
- The compact and full reproducibility builders require the current integrated Figure 3 and Figure 4 assets, their QA files, the figure generator and source CSV. Both archives perform required-entry checks and SHA-256 verification; the full archive also verifies the frozen predictor digest against Stage-1 provenance.

## Remaining limitations

The evidence is simulation-only. Obstacles follow prescribed tracks, the predictor supplies point forecasts, and uncertainty-aware planning, unseen motion families and real flight remain untested. The current evaluation is exploratory rather than external confirmation. Shared LSTM is the proposed coupled architecture and outperformed latest-position hold, but the present intervals do not establish an advantage over coupled CV or either one-layer LSTM ablation, and the standalone arms have higher observed arrival rates. These limitations are retained in the paper and supplement.

## Canonical delivery paths

- Paper PDF: `02_source/main.pdf`
- Editable paper: `02_source/main.tex`, `02_source/references.bib`
- Bilingual reader: `03_bilingual/paper.md`, `03_bilingual/source_map.json`
- Supplement: `03_supplementary/supplementary_methods.pdf`, `03_supplementary/supplementary_methods.tex`
- Compact package: `03_supplementary/reproducibility_package_v13.zip`
- Full package: `03_supplementary/reproducibility_package.zip`
- Delivery hashes: `03_supplementary/final_delivery_SHA256.txt` and ZIP `.sha256` sidecars
- This audit: `04_review/v13_final_submission_audit_20261019.md`
