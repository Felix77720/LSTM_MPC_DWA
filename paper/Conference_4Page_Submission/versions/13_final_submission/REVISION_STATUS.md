# Version 13 revision status

**Current final-release status (2026-10-16):** The main paper compiles to four pages and the current supplement to 18 pages. Main text now reports the frozen 500-scene shared-versus-DWA-only contrast (62.4% versus 55.7%, +6.7 percentage points; 95% scene-cluster CI 4.2–9.2), explicitly identified as 3,000 episodes within the existing 7,500-run five-controller benchmark. A separate 2,100-episode exploratory evaluation reports shared LSTM at 73.7%, with no measurable advantage over DWA-only LSTM and standalone MPC-CV at 92.0%. The 4,320 Stage-1 episodes remain development evidence, not held-out results. Stage 2 is incomplete (2,263/5,760 checkpoints, unscored); the planned 10,500-run seven-method holdout was not run, consistent with the author's choice to conduct no further scientific experiments. No overall-best or real-flight claim is made. Version 08, historical results, source records and the invalid orphan attempt are preserved. The current README and audit addendum record cross-document synchronization, compilation and visual review.

**Finalization record (2026-10-15):** The current limited evaluation contains 2,100 valid planned keys; one extra checkpoint with an invalid sidecar (scene 58, seed 2) remains preserved but excluded. A compatibility analysis copy adjusted snapshot validation only; the frozen runner/analyzer and the reported numerical calculations were not changed. All four main-PDF pages and the updated supplementary pages were rendered for visual review. The matched scene-1/seed-1 seven-path panel is illustrative and does not replace aggregate statistics. No real-flight validation or overall-superiority conclusion is claimed.

**Historical checkpoint (2026-10-13, 17:25:05 Asia/Shanghai):** The frozen Stage 1 runner `run_v12a_pooled_weight_development(false,false)` was reported active: 2,485/4,320 episode MAT filenames, 0 files in the runner's `errors` directory, the expected `.pooled_development_lock` and manifest present, and six MATLAB processes alive (batch parent, engine/manager, four workers). The command line matched the frozen runner. Only directory-entry counts, existence checks and process metadata were read; no active episode contents, outcomes, CSV summaries or selection values were opened. This checkpoint predates Stage 1 completion and the Stage 2 run documented below.

**Historical-result consistency check (2026-10-13):** A read-only audit of the archived five-method result bundle and its category aggregation verified that each method has 1,500 runs and all terminal categories sum exactly to 1,500. The category counts match the supplement and the main-table arrival/collision columns; this verifies internal consistency of the historical bundle, not the new development run or any held-out claim.

**Artifact-only update (2026-10-13, 15:51 Asia/Shanghai):** The old SI route-comparison assets (PDF/SVG/PNG/TIFF) were archived before synchronizing the refreshed four-format, route-only Figure S4 into the supplement and bilingual reader. Figure 2 in the reader links to the same overlay; its caption/source map now match the SI legend and logged terminal semantics. The SI compiled twice via direct pdfLaTeX to 16 US Letter pages, and updated page 15 was rendered and visually inspected. `latexmk` itself could not start because MiKTeX could not find Perl. The updated source/SI/reader copies have matching per-format SHA-256 hashes; `03_supplementary/interim_route_sync_SHA256_20261013.txt` records this scoped, interim snapshot, not a final release manifest. No active-run episode, CSV or result content was inspected or modified. This artifact-only update does not change any experimental status, resolve release gates, or approve the submission.

**Historical state at the time of this checkpoint: in progress; not approved for submission.** This status is superseded by the final-release update above.

**Previous verified snapshot (2026-10-13, 14:45 Asia/Shanghai):** A metadata-only monitor found Stage 1 at 1,675/4,320 keyed episode MAT files, zero error files, the active lock, and the main MATLAB process, manager, and four workers alive. No MAT/CSV contents, outcomes or summaries were read. The frozen held-out runner's output directory and lock were absent, and its trust-scale calibration directory was also absent; its preflight therefore could not pass. The source, build and visual checks recorded there remain historical evidence; current release gates are listed below.

**Earlier authoritative update (2026-10-13, 10:24 Asia/Shanghai):** The endpoint-inclusive 4,320-episode pooled calibration was running under the frozen four-worker plan; its lock was present. A metadata-only check found 474 episode files and zero error files; no candidate outcomes or summaries were opened. The console's `1200/4320` line is the completed `parfor` job index, not a count of finished records, because jobs complete out of order. A maximum-iteration solver warning was verified in source as internally caught: MPC returns the recorded fallback, increments `solveFailures`, and the simulation continues. The original incomplete/strict-endpoint batch is preserved as historical and is not used for selection. A second, separately frozen development protocol covers trust-response parameters `alphaT` and `beta` on a 3 × 3 grid after pooled sigma selection. It scores all five integrated MPC–DWA branches equally, reuses the selected `(3,3)` cell only after all 720 records pass full trace/provenance validation, and requires 5,760 fresh episodes for the other grid cells. Both calibration stages must be independently audited before the seven-method held-out comparison. The held-out analyzer now has stronger independent trace/archive checks, and static assertions pass; a reproducible parameter-count/scope error was fixed in the manifest validation path. Its MATLAB parser and geometry self-test remain pending until the active calibration releases the session. The manuscript source remains a layout preview containing historical five-method results and must not be distributed as final.

All dated audit/progress entries below are retained as historical snapshots; statements there that a protocol is proposed/draft, that the old strict-endpoint batch is still active, or that the source compiled to five pages are superseded by this update. Their original observations are preserved for traceability.

## Historical completed-work checklist (retained; superseded by final-release update above)

- Preserved `versions/08_reviewer_revision` as the read-only audit baseline.
- Defined and froze the seven-method held-out comparison, the familywise statistical claim gate, endpoint/contact rules, and route-figure contracts before any held-out outcomes exist.
- The corrected endpoint-inclusive pooled calibration is running: five integrated arms × six frozen candidate vectors × 48 scenes × 3 matched seeds (4,320 episodes). The revised runner stores complete trajectories, timestamps, obstacle tracks, keys and provenance. The earlier strict-endpoint, summary-only batch and all source records remain untouched and are not selection-eligible.
- Audited the source MPC–DWA paper and documented that its dynamic-obstacle prediction details are insufficient for exact reproduction. The local comparator must be labeled an architecture-level reconstruction with an explicit predictor assumption.
- Began independent code, recovery, figure, packaging, reference, formula, and manuscript audits.
- Verified synthetic checkpoint/recovery and trace-geometry tests; corrected the held-out preflight's handling of simulator-local helper functions without changing simulation code or data.
- Corrected two bilingual-formula mismatches against the implementation (vehicle-state component order and the shifted previous MPC reference used by the trust goal-progress term). Removed non-template 4 pt float/display-spacing overrides, changed the scene schematic to a top float, and moved the historical route float after its first textual citation. These source-preview changes do not alter results; the historical figure and results still require replacement only after the new held-out audit.

## Historical release-gate checklist (retained; superseded or outside this bounded release)

1. Finish pooled development runs; verify all expected records, hashes, endpoint definitions, and errors; independently recompute the selected sigma vector and tie-break.
1a. Run the frozen 3 × 3 `alphaT`/`beta` development calibration across all five integrated branches, validate all 5,760 fresh traces and the reusable 720 `(3,3)` records, then independently recompute its finite-grid selection and hash the result.
2. Let the corrected 4,320-episode development run complete; independently audit keys, errors, hashes, trajectory completeness, boundary semantics, and recompute the frozen finite-grid selection. Do not use the summary-only 864 source records or any historical batch for coefficient selection.
3. Freeze/hash the final runner, analyzer, result schema, figure contract, manuscript captions, and preflight outputs before creating or opening held-out outcomes; verify a not-ready preflight exits before starting a worker pool or generating scenarios.
4. Run the seven methods on the frozen matched held-out scenario bank; audit run completeness, pairing, failure recovery, and statistical analysis.
5. Update the main paper, bilingual reader, supplement, figures, and reproducibility package from the audited held-out data without changing or omitting outcomes.
6. Reconcile the main/SI MPC command indices against the implemented optimization (including the previously applied command), and distinguish predicted discrete clearance from swept-path endpoint clearance. Keep DWA's screened samples distinct from the expanded MPC control box, which is not a pointwise safety certificate.
7. Unify the route-figure contracts: an X at the recorded route endpoint denotes that swept contact occurred somewhere along the route, not that the endpoint is the contact location. Keep the prospectively selected single-scene seven-route illustration separate from aggregate estimates.
8. Re-scan the final citation keys and re-verify every reference field; the existing seven-reference snapshot is stale relative to the current draft.
9. Compile the main paper to exactly four pages and compile the supplement; render and inspect every main page and every changed supplementary page.
10. Validate equations and symbol definitions, figure/table/caption mappings, references, bilingual parity, ZIP contents/CRC, and SHA-256 manifests; then write the final evidence-based audit and mark this status complete.

## Claim constraints

- Do not claim overall or universal superiority unless the frozen superiority gate passes; otherwise report the actual ranking and confidence intervals.
- Keep the historical scene 404/seed 2 route explicitly illustrative, not representative of aggregate performance.
- State simulation-only evidence; make no real-flight validation claim.
- Preserve original papers, results, and data. Do not tune to held-out outcomes or rerun simulation for a favorable result.

## Historical audit snapshots (2026-10-12; retained, superseded by the 2026-10-13 status above)

- At 16:16:50 Asia/Shanghai, the pooled development output contained 3,162 of 3,456 expected new episode files; the error directory was empty and six MATLAB processes existed. This is a metadata-only progress check: no active-run MAT contents or outcome values were read.
- Static code inspection confirmed that the candidate UAV rollout's first stored row is the next 0.1-s state and the forecast's first row is the obstacle position at that same next step. The fixed 48-scene bank was generated with `config_LSTM`, which inherits `config_UAV`'s 3-s DWA horizon; the seven-method held-out runner explicitly sets DWA and MPC to 30 steps over 3 s. The horizons and time indices therefore align across pooled calibration and held-out. The separate older one-second confirmatory protocol is historical; stale one-second claims in current result prose still require replacement.
- The current `02_source/main.tex` was modified after `01_manuscript/main_revised.pdf` was built. A preflight build of the same source produced five pages, with the old five-method route figure isolated on page 5. `supplementary_methods.tex` was also updated on 2026-10-12 after the existing 15-page supplement PDF was built. Neither PDF is a valid final output. Figure 1 itself remains correctly after the symbolic problem description and before Planning Method.
- Independent static review found blockers recorded in the working audit: manuscript sections mix five- and six-arm descriptions; the new seven-arm amendment and figure contract are still proposed/draft; current result text, SI, and bilingual reader contain old five-arm values; simulator stopping still uses strict `<` while the held-out endpoint contract requires inclusive `<=`; and bilingual trust-weight provenance is stale. These must be resolved before held-out preflight or final release.
- The seven-route figure generator was source-refined to use a 7.2 × 4.8 in vector-first canvas and equal route stroke emphasis. The nature-figure source preflight passed 21 checks (0 warnings, 0 failures). No result figure has been generated; endpoint/source-data and final-size visual audits remain open.

## Latest progress check (2026-10-12 16:30 Asia/Shanghai)

- The pooled calibration directory contained 3,239 / 3,456 expected new episode MAT files; the `errors` directory contained 0 files; six MATLAB processes were present and responsive. This is a metadata-only check; no MAT contents or outcomes were read.
- Static status-label verification confirms the amendment is still `proposed`, the result/figure contract is `draft`, and the seven-method route-figure contract is `draft`. Held-out generation must remain blocked until these documents, the runner/analyzer, and preflight artifacts are independently audited and frozen.
- The two simulator implementations still use strict `< goalTolerance` at their stop/classification predicates, while the held-out endpoint contract is inclusive `<=`. The active calibration workers must finish before any simulator edits; afterward, quantify whether any recorded trajectory or endpoint classification is affected and record any necessary common-implementation rerun before held-out evaluation.

## Progress check (2026-10-12 16:39 Asia/Shanghai)

- The pooled calibration directory contained 3,287 / 3,456 expected new episode MAT files, with 0 error files; six MATLAB processes were still responsive. No episode file was opened.
- Static manuscript review also found an abstract/introduction/results mismatch in the number and identities of controllers, and a DWA component-score notation mismatch between the main paper and supplement. These are source-level synchronization issues; no result was changed or inferred.

## Progress check (2026-10-12 17:20 Asia/Shanghai)

- The active historical pooled batch contained 2,660 / 3,456 supplemental episode MAT files; its error directory was empty, the run lock remained present, and six MATLAB processes were responsive. This was a metadata-only check. No active-run MAT contents or outcome values were read.
- The batch remains ineligible for coefficient selection because its strict goal-stop predicate and summary-only saved records cannot audit the frozen inclusive endpoint rule. It will be preserved unchanged after natural completion; the separately corrected full-trajectory development run remains required.
- The current manuscript source still contains mixed controller counts and historical result values. No replacement outcome has been asserted while the corrected development and held-out experiments remain incomplete.

## Progress check (2026-10-12 18:28 Asia/Shanghai)

- The active historical pooled batch contained 3,006 / 3,456 supplemental episode MAT files; the error directory was empty, the run lock remained present, and six MATLAB processes were present. This was a metadata-only check; no episode contents or outcome values were read.
- The existing batch remains ineligible for selecting trust weights because the simulator's strict goal-stop rule differs from the frozen inclusive rule and its episode records omit trajectories. It is being left untouched through natural completion.
- Static source audit matched the current 3-s / 30-step shared forecast, LSTM offset semantics, MPC objective terms, trust aggregation, DWA scoring and emergency re-screening to the implementation. Manuscript-only corrections now make the MPC state recursion explicit, unify predicted-clearance notation, label the fixed sample-budget sensitivity separately from the simulation-selected trust weights, and distinguish discrete candidate screening from the continuous swept-path outcome audit.
- The bilingual reader, main result section, seven-method figures, and released statistics still require synchronization after the corrected development and held-out evaluations; the current candidate remains not approved for submission.

## Progress check (2026-10-12 18:40 Asia/Shanghai)

- Corrected the run-state check to look for the actual hidden development lock: the pool is still active at 3,065 / 3,456 new episodes, with zero error files and six MATLAB processes. No active-run MAT contents or outcomes were opened.
- A read-only row audit confirmed the archived v08 confirmatory subset has 3,000 rows across its two integrated arms, 1,500 per arm, and no duplicate scene/seed/method keys. The completed five-arm historical bundle has 7,500 rows, no duplicate keys, and row-recomputed outcomes agree with its summary; the separate DWA+LSTM/MPC+LSTM bundle matches those corresponding rows on all 1,500 matched keys in each arm.
- Cross-version review found the standalone DWA+LSTM rate changed from 76.4% in Round 19 to 82.4% in the later rerun. The versioned runner/simulator hashes match each other across v10/v13, and the frozen rerun protocol explains the change: its emergency DWA screen allows strictly positive clearance rather than using the normal 0.25-m rejection margin. Preserve both results under their respective policy definitions; they are not interchangeable.
- This confirms record completeness/summary consistency for those historical files, not the planned seven-method comparison or overall superiority. Keep the old outcomes and images, clearly labeled as historical; the 3-s pooled development and held-out experiment remain pending.

## Progress checkpoint (2026-10-13 17:37 Asia/Shanghai)

- A metadata-only check found the frozen Stage-1 process tree still alive at 2,551 / 4,320 episode MAT filenames, with 0 files in `errors`, the expected lock and manifest present, and six MATLAB processes (batch parent, engine/manager, four workers). No active MAT/CSV contents, summaries, outcomes, or selected coefficients were read.
- Source-only runner audit confirms the frozen amendment/hash assertions, six predeclared weight vectors, five integrated arms, 48 scenes and three matched seeds (4,320 episodes), 3-s/30-step forecast and DWA horizon, inclusive goal/contact reclassification over full recorded routes, duplicate/coverage validation, and the predeclared equal-method selection rule. No active episode output was opened.
- Clarified in the main Methods that the historical DWA screened the first 10 of the LSTM's 30 forecast steps (1 s), while MPC used all 30 (3 s); the pending evaluation extends DWA screening to all 30. Synchronized the same distinction in both languages of the bilingual reader. Historical data and claims were unchanged.
- Recompiled the open `02_source/main.tex` twice with MiKTeX/pdfTeX after the source edit. `main.pdf` is 4 US Letter pages (330,658 bytes). All four pages were rendered at 150 dpi to `02_source/qa/render_resume_20261013_1737/` and visually inspected; no clipping, overlap, or overflow was observed. The log has no overfull boxes, undefined references, or unresolved rerun requests; it retains one underfull-vbox and one mild underfull-hbox notice.
- Stage-1 completion, the Stage-2 trust-scale calibration, and seven-method held-out evaluation remain open; this layout build is not a final submission release.

## Progress checkpoint (2026-10-13 18:02 Asia/Shanghai)

- Metadata-only check found the frozen Stage-1 run at 2,683 / 4,320 episode MAT files, 0 error files, with `pooled_development_manifest.mat` and `.pooled_development_lock` present. The parent, MATLAB engine/manager, and four workers remained active with increasing CPU time. No episode or summary contents were read.
- Added and froze `04_review/seven_method_heldout_protocol_v13.md` before held-out scene generation. It independently records all seven methods, 500 new scenes, three matched seeds, 10,500 total runs, the 3-s/30-step horizons, primary endpoint and scene-cluster analysis, secondary metric denominators, route-figure integrity, and the claim gates. The held-out runner's frozen-document snapshot and code-hash inventory, plus the independent analyzer's expected-document list, now bind this protocol.
- Hardened the Stage-2 independent analyzer to refuse overwriting either an existing analysis MAT or its SHA-256 sidecar. The Stage-2 output directory is not yet present; no calibration data were accessed and no calibration/analyzer/held-out command was run.
- This turn changed no manuscript results and did not modify the active Stage-1 runner or its files. Stage 1 remains the current gate; Stage 2 and held-out remain unstarted.
### Resume checkpoint — 2026-10-13 18:08 (+08:00)

- Added `04_review/literature_positioning_check_20261013.md` after checking primary publisher/proceedings sources. It records the narrow novelty boundary: the contribution is the shared LSTM forecast consumed by both MPC and DWA and its controlled ablation—not the first use of LSTM with MPC, first MPC–DWA integration, or a universal claim of best UAV planner.
- The external references checked include an ICUAS 2023 LSTM–MPC/RL planner, ECC 2024 GP-forecast MPC, WACV 2024 prediction-and-planning work with real-world tests, and a 2025 MPC–DWA swarm-planning paper. These comparisons support keeping this study explicitly simulation-only and limiting any superiority claim to the prespecified held-out protocol.
- Local command execution failed repeatedly with `helper_unknown_error: setup refresh had errors`. Therefore the Stage-1 file count/process state has not been refreshed after the last successful metadata-only check at 18:01 (+08:00), when 2,683/4,320 MAT files, zero error files, and the lock file were observed. Do not infer that the run remains active from this stale snapshot; resume status inspection once the command executor recovers.
- No simulation was started or stopped, no result contents were opened, no main source or active held-out outputs were changed, and no compile was attempted during this checkpoint.
### Freeze-integrity checkpoint — 2026-10-13 18:10 (+08:00)

- Static fix completed in `scripts/analyze_v12a_seven_method_heldout.m`: the analysis entry point no longer accepts a caller-supplied bootstrap seed; it fixes `bootstrapSeed=20261018` as specified in the frozen protocol.
- Static fix completed in `scripts/run_v12a_seven_method_heldout.m`: root-level `predict_trajectory_constant.m` is included in the preflight existence check, fixed SHA-256 inventory, dynamic dependency list, and worker exact-path audit. SHA-256 observed by the static auditor: `B2D9E2D55CCF84C6646438C213D881ECBBA1E2E139A9EB485D7289F1D7C3B130`.
- The DWA rollout helper was a direct dependency controlling rollout length; adding it to frozen source checks binds this behavior to the held-out run identity. No MATLAB was run and no simulation outputs were opened.
- Follow-up audit is checking whether the protocol/analyzer distinguish stored proportion-scale contrasts from percentage-point presentation. No statistical computation or experimental outcome is being changed.
- Local command execution remains unavailable. The last verified Stage-1 metadata snapshot is still 2,683/4,320 MAT files, zero error files, lock present at 18:01 (+08); current run state remains unverified and must be checked before any downstream stage.
### Statistical-unit checkpoint — 2026-10-13 18:15 (+08:00)

- Analyzer outputs previously wrote raw 0–1 rates and rate differences without unit-bearing column names. Static fix renamed outputs to `...Proportion` / `...ProportionDifference`, including interval and bootstrap-SE columns and intermediate MAT fields; no percentage formatter was implicit in `writetable`.
- Frozen protocol now states that stored rates/endpoint intervals are proportions, and stored contrasts/intervals/SE are proportion differences. Multiply by 100 only for displayed percentages or percentage points; the claim gate remains on the original proportion scale.
- Statistical formula, bootstrap resampling, CI procedure, and claim thresholds were not changed. Static source search found no remaining consumers of the old analyzer field names. MATLAB was not run and no result files were used.
- Since the held-out job has not been started, these source/protocol clarifications precede the held-out freeze identity. Before the next stage, recheck the full frozen snapshot and confirm no prior Stage-2/held-out output exists.
### Scope and preservation checkpoint — 2026-10-13 18:23 (+08:00)

- Static callgraph review found no un-hashed direct project helper in the held-out runner/simulator path; seven protocol arms map one-to-one to runner keys/labels.
- Historical CV/Kalman supplementary figures are present and explicitly referenced in `03_supplementary/supplementary_methods.tex`: `figures/historical_36run_results.pdf`, `figures/historical_48scene_baselines.pdf`, and `figures/historical_scene2_four_controller_routes.pdf`. Their captions identify the historical controller comparisons. Archived Kalman MAT/CSV records also remain present by filename. No historical result or figure was deleted, moved, or overwritten.
- The command executor still fails with `helper_unknown_error: setup refresh had errors`; the 18:01 Stage-1 count of 2,683/4,320 and zero error files is stale and must not be treated as current. No process, lock, or episode count can be refreshed in this session.
- `main.tex` and supplementary LaTeX were not edited in this checkpoint. No compile/render was run; built-in LaTeX compilation was not exposed in the available tools. The prior main-PDF build/visual check is not a substitute for the required final build after all experiment-dependent manuscript updates.
### Packaging-coverage checkpoint — 2026-10-13 18:30 (+08:00)

- Updated `scripts/build_reproducibility_package.ps1` so `seven_method_heldout_protocol_v13.md` is a required file copied into the reproducibility ZIP; the package's recursive manifest/hash loop will therefore cover it.
- Added the frozen protocol and `literature_positioning_check_20261013.md` to the external `final_delivery_SHA256.txt` path list. Source-path presence and static hash-loop coverage were checked. The builder was not run, so no ZIP or checksum output was regenerated.
- Existing delivery checksum/ZIP consistency remains unverified and must be regenerated only after final manuscript, experiment outputs, and audit report are fixed. Do not distribute current checksum artifacts as final.
- The seven-method Stage-1 run status still cannot be refreshed: `exec_command` continues to fail at environment setup. No Stage-2/held-out run, final compile, or GitHub update occurred in this checkpoint.

### Resumed run-state and delivery-path checkpoint — 2026-10-13 18:39 (+08:00)

- Read-only PowerShell inspection is available through the approved local execution path. The corrected Stage-1 directory is `LSTM_MPC_DWA/results/v12a_pooled_weight_development_inclusive_dev48_20261012`: 2,904 / 4,320 episode MAT files, zero `.error` files, and the development lock remains present; newest write was 18:38:48. MATLAB parent/client and all four workers remain alive. No MAT/CSV or result values were opened.
- The active editor source is `02_source/main.tex`; the newest same-source PDF is `02_source/main.pdf` (Oct 13 17:38). The delivery builder, compile helper, audit helper, and bilingual sync scripts were found to still reference the older `01_manuscript/main_revised.pdf` (Oct 11). This mismatch could package a stale paper. A mechanical path correction is in progress; historical PDFs will remain untouched, and no separate replacement manuscript/PDF will be created.
- No Stage-2 or held-out run has been started. Do not advance until Stage 1 completes and its frozen analyzer plus code/data gates pass. The editor source/PDF have not been changed or rebuilt in this checkpoint.

### Figure, bilingual-map, and reference checkpoint — 2026-10-13 18:48 (+08:00)

- Refreshed Stage-1 metadata: 2,952 / 4,320 MAT records, zero error files, lock present; newest record was written at 18:47:51. All four MATLAB workers remain responsive. No run contents were read.
- Rendered the existing problem-scene and historical five-route PDFs for inspection. The scene schematic belongs in Problem Formulation and remains distinct from measured routes. The historical route plot is legible but its legend is small; the preselected seven-method generator enforces one 3-D axis, saved-state endpoints, no smoothing or extension, and endpoint audits. Raised its legend typography from 7.4 to 8 pt; the source-only Figure preflight passes 21/21 checks. No new figure was generated because the held-out route CSVs do not exist yet.
- A full bilingual-map diff found `03_bilingual/paper.md` is newer than `source_map.json`, but the JSON is materially stale: its LSTM equation still accumulates offsets, its mapped text has older section content, and its bibliography count differs. The current `paper.md` has the direct-offset explanation. The existing map-sync scripts embed obsolete data/protocol assumptions, so neither was run; update the map generator and rebuild it from the final bilingual text before packaging.
- Independent 2026-10-13 reference recheck was appended to `04_review/reference_verification.md`: seven cited records agree with authoritative/institutional/author records; Nair's page range is cross-source supported but not visible on IEEE in this recheck; Chang's CNKI fields could not be independently reconfirmed and remain explicitly uncertain. No BibTeX field was guessed or changed.
- No main manuscript source edit, compile, final audit, package build or GitHub push occurred in this checkpoint.

### Bilingual citation/map repair — 2026-10-13 18:49 (+08:00)

- Corrected the full bilingual reader's citation numbering to match the current compiled PDF: nine printed references, LSTM cited as [9], and the cited DWA/MPC prior-work span [3–8]. The uncited Dobrevski record remains in `references.bib` and historical audits; it is not misrepresented as a printed current citation.
- Added a source-map generator that reads `03_bilingual/paper.md` without editing it, validates anchored equations/figures, and writes only `source_map.json`. Its dry run reported 32 mapped blocks, five display equations, and three figure cards; the generated JSON now reflects the current reader and direct-offset LSTM equation. The generator is included in the reproducibility script list.
- The mapping/document updates describe the current historical five-controller PDF; they are not the final seven-controller results package. Both will be synchronized again after the held-out run and final PDF.

### Canonical build and run liveness — 2026-10-13 19:00 (+08:00)

- Independently verified the active build, audit, package and bilingual source paths now use `02_source/main.pdf`; the old `01_manuscript/main_revised.pdf` remains untouched and is no longer the release source. `compile_final.ps1` compiles the existing `02_source/main.tex` with jobname `main` and does not create a duplicate manuscript PDF.
- Current `paper.md` citations now match the current PDF's nine printed references; the map generator was rerun and its JSON checks passed for the canonical path, 32 blocks, all paragraph translations, five equations, three reader figure cards, and direct (non-cumulative) LSTM offsets. These describe the pending/historical working manuscript and will be regenerated after results.
- Stage-1 liveness at 18:59:32: recursive MAT-file count was 3,018 including the top-level manifest (3,017 episode files), zero `.error` files, lock present, all four workers responding. No result file contents or outcomes were read. Stage 2 and held-out remain unstarted.
- The built-in LaTeX editor compile tool is not exposed in the available tool list. No source edit was made to `main.tex` this checkpoint; after the final text edit, use the installed MiKTeX workflow against the same source/output path and visually inspect all pages.

### Resumed liveness and audit-script review — 2026-10-13 19:05 (+08:00)

- Recursive metadata-only count at 19:05:16 was 3,050 MAT files including the top-level manifest (3,049 episode files); exact recheck at 19:06:31 found 3,056 / 4,320 episode files, latest episode write at 19:06:31, zero files in `errors`, and `.pooled_development_lock` still present. The existing MATLAB parent, client, and four workers remain active. No MAT/CSV outcomes were read and no process was touched.
- Read-only review confirmed `audit_revision_delivery.py` is currently read-only but still contains historical five-controller/1-s assumptions, old result assertions, and obsolete fixed-trust-weight wording. It must be updated to validate the final seven-method, 3-s bundle and calibrated coefficients after the frozen runs complete; it has not been executed.
- Existing `update_confirmatory_supplement.py` and `update_confirmatory_bilingual.py` are tied to the earlier 48-scene/six-setting analysis. They will not be run against the final package; final supplement and bilingual text will be synchronized from the validated seven-method held-out artifacts while preserving the archived historical results.
- Stage 2 calibration and held-out evaluation remain unstarted. No manuscript, figure, or supplementary source was changed in this checkpoint.

### Stage-1 progress — 2026-10-13 19:20 (+08:00)

- Exact count under `episodes/`: 3,142 / 4,320 complete MAT records, 1,178 remaining; zero files under `errors/`, development lock still present, latest episode write 19:20:36. No outcomes were opened, selected, or analyzed.
- Stage-2 and held-out output directories remain absent. Their preflight/run steps will begin only after Stage-1 manifest, inventory hashes, source identity, and error closure pass.
- PDF rendering tools (MiKTeX and Poppler) are available. The final source will remain the open `02_source/main.tex`; the project compiler targets the same canonical `02_source/main.pdf` and the existing supplementary PDF.
- Git inspection found the whole `/paper/` tree ignored and unrelated root-level worktree changes present. The current v13 directory is about 133 MiB, including generated `.pyc`, `.aux`, `.log`, and many raster exports; no broad force-add or cleanup will be used. Final Git staging will be limited to required manuscript, source, figure, bilingual, supplementary, audit, and reproducibility deliverables after exact file review.
- The existing `04_review/final_submission_audit.md` is a Revision-11 report, not a current final audit. Its historical 1-s/five-method results, fixed non-calibrated trust-weight statement, and old `01_manuscript/main_revised.pdf` delivery path conflict with the current frozen 3-s/seven-method work; it will be preserved as history, and a clearly named v13 final audit will be written after validated outcomes and final compilation.

### Stage-1 progress — 2026-10-13 19:30 (+08:00)

- Exact `episodes/` count reached 3,186 / 4,320, with 1,134 remaining; zero files in `errors/`; lock present; latest write 19:30:07. The run remains active. No results were opened and no tuning or restart was performed.
- Read-only timestamp audit of the exact Stage-1 dependency inventory found the runner was last modified at 23:18:17 on 2026-10-12, before the run started at 23:20; every other hashed simulator, predictor, configuration and baseline source predates that launch. No hashed simulation source changed during this run.

### Stage-1 progress — 2026-10-13 19:33 (+08:00)

- The exact episode count passed 3,200: 3,202 / 4,320 complete MAT records, 1,118 remaining, zero error files, and the pool lock remains present. The newest episode was written at 19:33:04.
- All runtime-dependency source timestamps remain earlier than the Stage-1 launch, so the continuing development run has a stable code identity. Stage 2 and held-out evaluation are still unstarted.

### Stage-1 progress — 2026-10-13 19:44 (+08:00)

- Exact episode-directory count: 3,257 / 4,320; 1,063 remaining; zero errors; lock present; latest write 19:44:03. Manifest files are excluded from episode counts.
- The manuscript, figure assets, final report, and bilingual reader remain unchanged pending calibrated and held-out results. Writing/statistics/reader audit rules have been loaded for the later final pass.
- A later short write gap was checked without touching MATLAB: all four workers accumulated approximately 4.98–5.03 CPU seconds during a 5-second observation, while the client waited on workers. At that check the episode count was 3,263 / 4,320 and the error directory remained empty.

### Stage-1 progress — 2026-10-13 19:53 (+08:00)

- Exact `episodes/` count is 3,289 / 4,320; 1,031 remaining; zero error files; latest write 19:53:01; lock remains present. No output content was inspected and no process configuration was changed.
- The seven-method route-figure legend now uses ASCII `MPC-DWA` hyphenation consistently; all seven method keys, labels, colors, and line styles remain present. Nature Figure strict static preflight passed 21/21 checks with no warnings or failures. Rendered visual and endpoint QA remains pending the held-out route export.
- Formula/source cross-check found the implementation uses a numeric envelope margin of 0.1 on each native control coordinate: speed (m/s), pitch rate (rad/s), and yaw rate (rad/s). The manuscript will index this margin as `delta_i` and state the per-coordinate units; the simulation code and running experiments remain unchanged.
- The existing `formula_symbol_audit.md` is also a dated 2026-10-10 historical audit; it describes four equation groups, cumulative LSTM offsets, a 1-s DWA horizon, and manually fixed trust weights. Those claims do not describe the current five-display-equation/direct-offset/3-s/calibrated protocol. It will remain preserved, while a new `formula_symbol_audit_v13.md` is prepared after calibration and held-out results.

### Stage-1 progress — 2026-10-13 19:58 (+08:00)

- Exact episode count is 3,327 / 4,320 with 993 remaining; zero errors, latest write 19:58:46, lock present. File count alone will not release Stage 2: the completed manifest, keyed coverage, full-trace checks, error closure, and provenance signatures must also pass.

### Stage-1 liveness — 2026-10-13 20:04 (+08:00)

- Episode count reached 3,344 / 4,320, with 976 remaining and zero errors. No MAT write occurred after 20:01:24 at this check, but all four worker MATLAB processes each accumulated approximately five CPU seconds during a five-second observation; the client was waiting normally. No process was restarted or modified.

### Stage-1 progress — 2026-10-13 20:05 (+08:00)

- Episode count advanced to 3,370 / 4,320, leaving 950; zero error files and a recent write at 20:05:16. Collision, failure, timeout, and infeasibility outcomes will remain in the all-attempt denominators during final analysis.

### Stage-1 progress — 2026-10-13 20:10 (+08:00)

- Exact Stage-1 count reached 3,402 / 4,320, with 918 remaining; no errors; lock present; latest write 20:10:50. No analysis or parameter selection has started.

### Stage-1 progress — 2026-10-13 20:24 (+08:00)

- Exact episode count reached 3,474 / 4,320, leaving 846; zero error files; lock present; latest write 20:24:01. The MATLAB task remains active, and no result contents have been read.

### Stage-1 progress — 2026-10-13 20:30 (+08:00)

- Exact count: 3,510 / 4,320 episodes; 810 remaining; zero errors; lock present; latest write 20:30:21. Stage-2 preflight and execution remain gated on the complete Stage-1 manifest and provenance checks.

### Stage-1 progress — 2026-10-13 20:32 (+08:00)

- Exact count is 3,521 / 4,320, 799 remaining; zero errors; lock present; latest write 20:32:47. The predeclared candidate ranking and tie-break will be reported in full once the runner completes.

### Stage-1 progress — 2026-10-13 20:35 (+08:00)

- Exact episode count: 3,533 / 4,320; 787 remain; zero error files; lock present; latest write 20:35:32. No exclusions, parameter changes, or route edits were made.

### Stage-1 progress — 2026-10-13 20:39 (+08:00)

- Exact count is 3,554 / 4,320, 766 remaining; zero errors; lock present; latest write 20:39:51. No partial development result has been copied into the manuscript.

### Stage-1 progress — 2026-10-13 20:44 (+08:00)

- Exact count reached 3,576 / 4,320, leaving 744; zero errors; lock present; latest write 20:44:02. No reproducible simulator/data error has been identified, so the existing run remains untouched.

### Stage-1 progress — 2026-10-13 20:50 (+08:00)

- Exact count reached 3,600 / 4,320; 720 remain; zero errors; lock present; latest write 20:50:57. Development outputs remain unopened until the run closes and its full inventory can be validated.

### Stage-1 progress — 2026-10-13 20:55 (+08:00)

- Exact count is 3,615 / 4,320; 705 remain; zero error files; lock present; latest write 20:54:55. Existing retry/failure history will be retained and audited rather than cleared.

### Stage-1 progress — 2026-10-13 20:58 (+08:00)

- Exact count is 3,627 / 4,320; 693 remain; zero errors; lock present; latest write 20:58:09. The stage remains active and its outputs remain unopened.

### Stage-1 progress — 2026-10-13 21:01 (+08:00)

- Exact count is 3,634 / 4,320; 686 remain; zero errors; lock present; latest write 21:01:04. No outcome estimate or manuscript update has been made from partial data.

### Stage-1 progress — 2026-10-13 21:05 (+08:00)

- Exact count is 3,647 / 4,320; 673 remain; zero errors; lock present; latest write 21:05:21. Historical 500-scene runs remain separate and are not being substituted for the current frozen test.

### Resumed audit and Stage-2 liveness — 2026-10-14 13:20 (+08:00)

- Stage 1 completed and its selected trust vector is recorded as $[0.15,0.15,0.15,0.55]$; the equal-arm macro safe-arrival score is 0.8042 across five integrated branches, 48 development scenes and three matched seeds. Stage 2 is running from `results/v13_trust_scale_calibration_inclusive_dev48_20261014_recovery`; metadata-only inventory found 119 / 5,760 new episode MAT files, zero error files and the active `.trust_scale_lock`. No episode contents, outcome values or partial selection summaries were opened.
- The active Stage-2 MATLAB batch remains live. No simulation code, parameter grid, worker count or protocol was changed. The held-out seven-method run remains gated on Stage-2 completion, independent validation, parameter freeze and preflight.
- Edited the canonical `02_source/main.tex` in place and rebuilt `02_source/main.pdf`: the current paper is four Letter pages. All four pages were rendered and visually checked; equations, references, table and figure placement show no clipping or overlap. The supplementary PDF is 16 pages and all pages were rendered; updated pages were checked. These are interim artifact checks only: experiment-dependent final results, bilingual synchronization, release packaging, final hashes and GitHub publication remain pending.
- Refreshed the top-level v13 README to distinguish completed Stage 1 from active Stage 2 and record the latest metadata-only count. Prior historical snapshots below are retained as audit history, not current run status.

### Stage-2 liveness — 2026-10-14 13:34 (+08:00)

- The frozen Stage-2 output directory contains 189 episode MAT files out of 5,760 expected, zero error files, a current latest write at 13:34:17, and the active `.trust_scale_lock`. This is filename/timestamp/lock metadata only; no outcome contents were opened. The held-out run remains gated, and no calibration settings, workers, or code were changed.

### Stage-2 liveness — 2026-10-14 13:42 (+08:00)

- Metadata-only inventory advanced to 219 of 5,760 episode MAT files; zero error files; the `.trust_scale_lock` directory remains present; the episode directory was written at 13:41:57. No episode payloads or outcomes were opened, and the held-out run remains gated.
- Recompiled the open `02_source/main.tex` in place. The Letter PDF remains four pages with no overfull boxes, undefined citations/references, or LaTeX errors. Rendered pages 2–3 show the trust-weight definition no longer strands its final word at the top of page 3. Final package synchronization and release checks remain pending.

### Stage-2 liveness and artifact review — 2026-10-14 13:52 (+08:00)

- Metadata-only inventory advanced to 269 of 5,760 fresh episode MAT files; zero `.error` files; the `.trust_scale_lock` directory is present; latest write 13:52:23. MAT payloads and partial outcomes remain unopened.
- Re-rendered and visually checked all four current main-PDF pages. It remains Letter format and four pages; Figure 1 depicts the problem geometry after the problem statement, the route example is explicitly historical/illustrative, and no clipping, equation overflow, or overlapping text was found.
- Re-rendered supplementary pages 10–11 and 15–16 after the text edits and inspected them. Historical controller outcomes, retained CV/Kalman figures, and pending v13 package status are legible and correctly distinguished. Bilingual text and source map are synchronized to the current LaTeX source; final experiment-dependent sync remains pending.

### Formula/source clarification and rebuild — 2026-10-14 13:59 (+08:00)

- A read-only code-to-method audit found wording ambiguity about which MPC route/control sequence supplies the trust components, missing startup initialization in the supplementary cycle, and undocumented provenance/units for fixed DWA heuristics. Checked `computeTrust_dynamic.m`, `simulate_dynamic.m`, `sampleIntelligent3D.m`, `dynamicWeights.m`, and the configuration files; no simulator change or data error was found.
- Clarified in the main text and supplement: startup uses the initial MPC solution; later cycles use the shifted prior route/control sequence; $σ_t$ labels timeliness, not the time index; the smoothness equation uses its defined $Δ\mathbf{u}_k$; and fixed sampling/logistic/vertical-score heuristics, including the native speed and angular-rate units, are distinct from calibrated trust weights and were not selected on held-out outcomes.
- Compiled the open `02_source/main.tex` in place: 4 Letter pages (326,880 bytes), no LaTeX errors, undefined references, or overfull boxes. Moved `\balance` to the first-column discussion boundary; the second-column warning disappeared and the final columns are visually balanced. Recompiled `03_supplementary/supplementary_methods.tex` in place: 16 pages (787,867 bytes); updated method pages 2–3 and 8 were rendered and visually inspected, as were retained/release-status pages 10–11 and 15–16.
- Stage 2 advanced to 298/5,760 fresh episode files at 13:59:06; zero `.error` files and active lock. This remains metadata-only; no partial outcomes were opened. Bilingual synchronization to these latest wording changes is in progress.

### Current visual, bilingual, and run-state check — 2026-10-14 14:02 (+08:00)

- Re-rendered the current in-place `02_source/main.pdf` after the column-balance adjustment and inspected all four pages. It remains a four-page Letter PDF (326,880 bytes); title/abstract/problem-geometry figure, numbered equations, results table, route figure, discussion and references show no clipping or overlap. This is still an interim historical-results manuscript pending the frozen calibration and held-out evaluation.
- The bilingual reviewer completed synchronization of the latest trust-score provenance, startup initialization, smoothness notation, fixed DWA heuristic units, and selection-status boundaries in `03_bilingual/paper.md` and `source_map.json`; its structural/math checks passed (39 mapped blocks). The final result-dependent sync remains pending.
- Metadata-only Stage-2 inventory advanced to 313/5,760 new episode files at 14:02:20; zero `.error` files; active `.trust_scale_lock` directory. No MAT payloads, outcomes or partial selection summaries were opened, and no run settings or code were changed.

### User-supplied conference checklist crosswalk — 2026-10-14

- Read and rendered both PDFs in `C:\Users\Felix\Desktop\command\Templates`: the two-page conference-submission notice and one-page bilingual checklist. The notice describes publication/indexing and author-rights administration, not a venue-specific technical style guide; it does not establish acceptance, publication timing, or indexing for this manuscript.
- The checklist's format items match the current source/PDF: `IEEEtran` conference class with Letter paper and two columns; four pages (within 4–20); named author, affiliation, city, postal code, country, and corresponding-author asterisk; six keywords; no subtitle; sequential in-text Figure/Table references with full labels and period-terminated captions; editable LaTeX table and numbered display equations; five cited references with superscript Arabic numerals and DOI or source links. The embedded schematic and route figures are vector PDFs and use English labels.
- Author-country coverage was checked against the source papers: the cited DWA paper lists Bonn (Germany) and Carnegie Mellon (United States), and the cited LSTM paper lists TU Munich (Germany) and IDSIA (Switzerland), establishing at least three countries. The evidence and links are recorded in `04_review/reference_verification_20261014.md`; no uncertain Chang metadata was filled in.
- The scene schematic is correctly placed in Problem Formulation. The historical route figure is legible but its compact legend is a known visual optimization target; the final seven-method comparison figure must use larger readable labels and be checked again at page scale. The user-supplied checklist is generic; the target venue's current official call/template remains the final authority.

### Seven-method figure preflight — 2026-10-14

- Figure contract: the representative route figure illustrates how the seven frozen controllers behave in one preselected matched episode; it is not population-level evidence. Aggregate table/statistics carry the comparative claim. The figure uses one shared 3-D axis, exact saved path states and terminal markers; route overlap/perspective, legibility of long method names, and separation of terminal-status symbols from swept-collision status are reviewer risks to recheck at final size.
- The project figure generator is Python/matplotlib and its source-only validator passed 21 checks with zero warnings/failures. Static code checks verify the frozen example selection, all seven methods, no smoothing/resampling/interpolation/extension, and vector plus 600-dpi exports. No new plot was generated and no outcome file was opened.
- Python plotting and PyMuPDF are absent from both available Python environments. Final figure regeneration, rendered glyph-size audit and automated collision audit therefore remain blocked pending permission to install dependencies into a project-local virtual environment. No cross-backend substitute will be used.

### Stage-2 progress — 2026-10-14 14:11 (+08:00)

- Metadata-only inventory found 356/5,760 fresh Stage-2 episode files, zero `.error` files, an active `.trust_scale_lock` directory, and a latest episode write at 14:11:45. No run payloads or outcomes were opened; no runner, parameter, or worker settings were changed.
- The figure generator source preflight remains clean (21 pass, 0 warnings/failures). The figure render/geometry QA awaits the user's answer about local Python dependencies; final paper assembly, archive creation, and GitHub publication remain gated on experiments and QA.
- Inventory found prior-round PDFs and LaTeX by-products in `01_manuscript/`; the current in-place four-page build is `02_source/main.pdf`, paired with the open editor source. Keep that as the single canonical PDF and final path; do not compile or copy a second PDF. Added `01_manuscript/README.md` to label those older PDFs as interim and point to the canonical source/PDF; none was deleted. The canonical build remains interim pending the frozen evaluation.

### Supplementary pagination correction and run-state check — 2026-10-14 14:20 (+08:00)

- Recompiled `03_supplementary/supplementary_methods.tex` in place after moving the acceleration-limit definition onto a complete sentence with a controlled page break. The PDF remains 16 pages (787,866 bytes); rendered pages 2–3 were visually checked. The split sentence is gone, and the formula block, numbering, explanatory text, and page boundaries are intact.
- Metadata-only Stage-2 inventory advanced to 402/5,760 new episode files; zero `.error` files; active `.trust_scale_lock`; latest episode write 14:20:08. No MAT payloads, partial results, or selection summaries were opened; the held-out run remains gated.
- `01_manuscript/` still contains prior-round builds, so no file has been called final or synchronized there. Folder cleanup, release packaging, checksums, and GitHub publication remain reserved for the completed evidence/QA gate; historical runs and v08 remain protected.

### Abstract terminology clarification and rebuild — 2026-10-14 14:26 (+08:00)

- Clarified in the abstract that the historical 82.4% and 95.2% results are for standalone DWA+LSTM and MPC+LSTM, matching the table labels; no values, comparisons, or claim boundaries changed. Synchronized the English and Chinese abstract and its source-map entry in the bilingual Markdown; the JSON parses and the map still contains 39 blocks.
- Recompiled the open `02_source/main.tex` in place after the wording change: 4 Letter pages (326,958 bytes), no LaTeX errors, undefined citations/references, or overfull boxes. Rendered and visually checked all four pages; the abstract and problem schematic remain legible and correctly placed, and equations, table, example routes, references, and columns have no clipping or overlap. The log retains only benign underfull-box warnings; the bibliography line breaks and page balance remain visually acceptable.
- Metadata-only Stage-2 check: 439/5,760 new episode files, zero error files, active lock; latest write 14:25:41. No episode payloads or partial outcomes were opened. No held-out evaluation has started.

### Repository publication-safety preflight — 2026-10-14 14:28 (+08:00)

- Read-only audit found the existing GitHub README still presents the earlier four-method protocol and historical metrics. The repository also ignores the complete paper workspace and results, so the eventual release must use an explicit allowlist and update the README only after final values are validated.
- Added root `.gitignore` rules for workstation-only `.codex-tmp/`, `.matlab_prefs*/`, `local_cluster_jobs/`, and `tmp/`; `git check-ignore` confirms each exact directory is excluded. Nothing was deleted, staged, committed, or pushed. The untracked experiment scripts and two modified simulator files remain for later source review and deliberate selection.
- Metadata-only Stage-2 inventory: 455/5,760 new episode files; zero errors; active lock; latest write 14:28:31. Historical versions, the active run, and source records remain untouched.

### Original-baseline reference verification and rebuild — 2026-10-14 14:32 (+08:00)

- Re-read pages 1–2 of the user-supplied Chang et al. MPC–DWA paper. Its CNKI-formatted online-first cover directly verifies the Chinese author order and names, their printed Latin-script forms, Chinese and English titles, both journal names, and 2026-03-26 online-first date; it states that network-first publication is formal publication. The cover gives no volume, issue, pages, or DOI, so those remain absent. The bibliography no longer incorrectly labels the printed English title as our translation, and the repeat month was removed. The bilingual reference and the reference-audit table/summary were synchronized.
- Ran BibTeX and rebuilt the open `02_source/main.tex` in place. The Letter PDF remains four pages (326,924 bytes); no LaTeX errors, undefined citations/references, or overfull boxes. Rendered page 4 was checked after the reference change; author/title/date/link line breaks are readable and do not collide with the table or column boundary. The bilingual source map remains valid JSON with 39 blocks.
- Metadata-only Stage-2 check: 483/5,760 new episodes; zero error files; active lock; latest write 14:32:54. No episode contents or partial outcomes were inspected.

### Style and clarity scan — 2026-10-14 14:36 (+08:00)

- Read the complete current main source and ran a targeted AI-tone/overclaim scan across the main and supplement. The prose uses direct, evidence-bounded language; the only match for “guarantee” is the necessary methods boundary that a discrete DWA gate is not a continuous-time safety guarantee. No marketing phrasing or unsupported superiority wording was found, so no further prose rewrite was made while experimental results remain pending.
- Metadata-only Stage-2 inventory reached 500/5,760 new episodes; zero errors; lock active; latest write 14:36:25. No MAT payloads or partial outcomes were read.

### Stage-2 liveness — 2026-10-14 14:41 (+08:00)

- Metadata-only inventory advanced to 531/5,760 new episode files; zero `.error` files; active lock; latest episode write 14:41:24. No outcome files or payloads were opened. Held-out execution remains gated on completion and independent validation.

### Stage-2 liveness — 2026-10-14 14:45 (+08:00)

- Metadata-only inventory advanced to 555/5,760 new episode files; zero error entries; the `.trust_scale_lock` directory remains present; latest episode write 14:45:31. No MAT payloads, partial summaries, or outcomes were inspected. The frozen runner and settings remain untouched; held-out execution remains gated.
- Folder cleanup and GitHub publication are still deferred until experiment validation, manuscript synchronization, final rendering/hash checks, and the explicit publication-file allowlist are complete. No files were deleted, staged, committed, or uploaded in this update.

### Stage-2 liveness — 2026-10-14 14:54 (+08:00)

- The same metadata-only inventory now shows 604/5,760 new episode files, zero error entries, an active lock directory, and a latest write at 14:54:05. No MAT data, outcomes, or interim summaries were opened. The frozen calibration protocol remains unchanged; the seven-method held-out evaluation has not started.

### Stage-2 liveness and repository preflight — 2026-10-14 14:57 (+08:00)

- The metadata-only Stage-2 inventory reached 616/5,760 new episode files; zero error entries; lock active; latest write 14:57:02. No outcome or MAT payload was inspected.
- A read-only release preflight confirmed that the existing Git remote is named `LSTM_MPC_DWA.git` and that the root README still documents the earlier four-method protocol. The repository update remains deferred; no files were staged, committed, tagged, or pushed.

### Stage-2 liveness — 2026-10-14 15:02 (+08:00)

- Metadata-only inventory advanced to 641/5,760 new episode files; zero error entries; lock active; latest write 15:02:28. No episode contents or outcome summaries were opened. The preselected figure dependencies remain uninstalled pending user confirmation for an isolated project environment.

### Stage-2 liveness and literature cross-check — 2026-10-14 15:07 (+08:00)

- Metadata-only inventory reached 666/5,760 new episodes, with zero error entries, active lock, and a latest write at 15:06:36. Outcomes remain unopened.
- Added three source-verified primary-study notes (2020 NMPC, 2023 velocity-aware chance constraints, and 2025 intent-prediction MPC) to the review-only literature file. No new reference or literature claim was added to the four-page manuscript; these sources reinforce predictor/planner interface clarity and the simulation-versus-flight evidence boundary.

### Stage-2 liveness — 2026-10-14 15:12 (+08:00)

- Metadata-only inventory now contains 692/5,760 new episode files; zero error entries; active lock; latest write at 15:12:19. No MAT payloads or outcomes were inspected. Stage 2 remains active, and Stage 3 is still gated.

### Stage-2 liveness — 2026-10-14 15:16 (+08:00)

- Metadata-only inventory reached 714/5,760 new episode files; zero error entries; lock active; latest write 15:15:41. This confirms liveness only; no output values were inspected or used to change the paper.

### Stage-2 liveness — 2026-10-14 15:22 (+08:00)

- Metadata-only inventory reached 741/5,760 new episode files; zero error entries; lock active; latest write 15:21:41. The frozen parameter grid and workers remain untouched; no held-out run or manuscript result update has begun.

### Figure-runtime installation attempt — 2026-10-14 15:25 (+08:00)

- With user approval, created an isolated Python virtual environment under the project `tmp/` directory. Installing Matplotlib and PyMuPDF from PyPI failed because the TLS connection ended during package-index access; no packages were installed and global Python was not modified. The saved figure backend is Python, so the nature-figure workflow forbids switching to R/MATLAB for plotting or visual QA. Figure generation remains pending a permitted Python package source/runtime.
- Concurrent metadata-only Stage-2 inventory shows 757/5,760 files, zero error entries, active lock, latest write 15:24:38. No episode contents were inspected.

### Frozen figure and calibration-gate preflight — 2026-10-14 15:27 (+08:00)

- The seven-method plotting source passed the dependency-free `nature-figure` validator: 21 PASS, zero warnings/failures, Python backend, single 3-D plot area. Its static contract fixes scene 1/seed 1 before held-out generation; validates recorded timestamps, state count, terminal coordinates and status; and forbids smoothing, interpolation/resampling, and extension beyond the saved terminal state. Rendering remains blocked by the missing Python packages.
- Source audit of `run_v13_trust_scale_parameter_calibration.m` confirms that, before creating any fresh Stage-2 output episode, it checks hashes and provenance for all 720 reused Stage-1 episodes, validates keys, timestamps, control/obstacle trace hashes, and independently recomputes inclusive swept clearance and arrival. The recovery run has progressed past this preflight; the final independent all-candidate analyzer remains pending.

### Stage-2 and isolated-runtime liveness — 2026-10-14 18:06 (+08:00)

- Metadata-only inventory now shows 1,433/5,760 fresh Stage-2 episodes, zero error entries, active lock, latest write 18:06:47. No result payloads or partial selection files were read.
- Python figure-source validation remains 21 PASS / 0 WARN / 0 FAIL. The project-local venv is isolated and ignored by Git. Initial package installation failed on a TLS connection to PyPI; a single retry is planned under the user's installation approval. No alternative plotting backend or global Python changes are permitted.

### Stage-2 metadata and figure-runtime retry — 2026-10-14 18:09 (+08:00)

- Metadata-only inventory reached 1,447/5,760 fresh Stage-2 episode files; zero error entries; lock active; latest write 18:09:22. No MAT payloads, candidate values, or partial summaries were opened.
- Retried the user-approved project-local Matplotlib/PyMuPDF installation in the same ignored virtual environment. PyPI index access again ended with TLS EOF before package resolution; no dependencies were installed and global Python was untouched. TLS verification remains enabled. Final figure rendering is blocked until an approved, reachable Python package source or local wheelhouse is available.

### Seven-arm updater and figure-runtime preflight — 2026-10-14 18:15 (+08:00)

- Found the machine already has Python 3.14 with Matplotlib 3.11.1 and PyMuPDF 1.28.2. Created an ignored project-local Python 3.14 venv with `--system-site-packages --without-pip`; it imports those pre-existing packages read-only. No packages were installed and no global Python files were changed. This is a local venv but not a hermetic dependency install; use it only if the user accepts this arrangement.
- Re-ran `nature-figure/scripts/validate_figure.py` against `generate_seven_method_route_figure.py` with the project-local interpreter: 21 PASS, 0 WARN, 0 FAIL. The renderer itself was not run because its preselected held-out route-export directory does not exist until the frozen seven-method run completes.
- Static review found `update_confirmatory_bilingual.py` and `update_confirmatory_supplement.py` embed a prior 48-scene/six-setting result (864 runs); `update_shared_lstm_*` scripts target an earlier two-method/3,000-run study. None was run. Final synchronization must be newly driven by the frozen seven-method analysis outputs, with the older analyses retained only as clearly labeled historical records.
- Metadata-only Stage-2 inventory at 18:15: 1,476/5,760 fresh episode files, zero errors, lock active, latest write 18:14:55. No MAT payloads or outcome summaries were read.

### Stage-2 liveness and final synchronization safeguards — 2026-10-14 18:20 (+08:00)

- Metadata-only inventory reached 1,498/5,760 fresh episode MAT files, zero filenames indicating errors, and latest episode write 18:20:19. The run-local `.trust_scale_lock` directory is present. No MAT payloads, outcomes, or partial calibration summaries were opened; the seven-method held-out run remains gated.
- Reconfirmed that all four existing bilingual/supplement updater scripts target older, structurally incompatible studies. They remain preserved but must not be used to populate the final seven-method release. The reproducibility-package builder's current bilingual-asset allowlist also names a legacy route figure, so that allowlist must be updated and validated when the final figure is generated.
- The user has reconfirmed approval for project-local dependency installation. PyPI TLS EOF prevented package installation on two attempts; existing Python 3.14 packages are available only through a local venv that inherits system site-packages. No global Python files were modified. Use of this non-hermetic fallback is still awaiting explicit user acceptance; until then, visual rendering remains pending.

### Method/code concordance corrections — 2026-10-14 18:25 (+08:00)

- A read-only implementation audit found four wording/formula mismatches and one inherited-config check to resolve. Applied the source-evidenced wording corrections to the main paper, supplementary methods and bilingual reader: CV initializes with zero velocity when startup has only one position; the DWA obstacle term is a normalized clearance score (not agreement with MPC); the recenter trigger is horizontal cross-track offset (matching the XY-only implementation); and the adaptive sample-budget equation now includes its fixed gain coefficient $\alpha=1$, distinguished from $\alpha_T$.
- Also clarified that the speed score combines tracking with a forward-speed reward. Kept the correction synchronized in the English and Chinese text. The bilingual source map, compilation and visual QA will be regenerated after the final data-driven synchronization.
- The static audit found that $w_{\mathrm{Route}}=3$ comes from the stored baseline configuration, while calibration/held-out runners inherit that configuration. Its exact saved-bundle value will be verified after Stage 2 completes; no active runner or frozen parameter was modified.

### Stage-2 liveness and bilingual-map tooling — 2026-10-14 18:29 (+08:00)

- Metadata-only Stage-2 inventory reached 1,538/5,760 fresh episode files; zero error files; the run-local lock remains present; latest write 18:29:51. No episode payloads, outcome values or partial calibration summaries were read.
- The existing `sync_bilingual_source_map.py --dry-run` is incompatible with the maintained bilingual reader: it requires page-source annotations that the current source format does not contain. The dry run failed before writing anything. The 39-block existing map and 39 Markdown anchors still correspond; replace or repair only the synchronizer in a schema-preserving way before final synchronization.

### Isolated figure-runtime smoke test — 2026-10-14 18:33 (+08:00)

- Created a fresh project-local Python 3.14 venv with `include-system-site-packages=false` and copied Matplotlib 3.11.1, PyMuPDF 1.28.2, NumPy 2.5.1, and required local dependencies into its own `site-packages`. Source packages were copied read-only from the machine's existing installation; no network/TLS bypass and no global Python writes were used.
- A 3-D Agg canvas render and PyMuPDF import both passed. The Nature Figure validator again reported 21 PASS / 0 WARN / 0 FAIL for the preselected seven-method route plot. The actual data figure and visual PDF QA remain gated on completed held-out routes.
- Metadata-only calibration inventory at 18:33: 1,552/5,760 fresh episodes, zero error files, run-local lock present, latest write 18:33:11. No payloads or outcomes were opened.

### Bilingual source-map synchronization and Stage-2 liveness — 2026-10-14 18:38 (+08:00)

- Replaced the rebuild-style bilingual map updater with an anchor-driven, schema-preserving synchronizer. Four mechanical tests pass; a dry run and write both validated all 39 anchors. The update changed 21 content fields only; original section/layout/source metadata, references, and unknown fields are preserved. UTF-8 JSON parsing passed.
- Metadata-only Stage-2 inventory reached 1,571/5,760 fresh episodes; zero error files; lock present; latest write 18:38:13. No episode payloads, outcome fields, or interim summaries were opened. The held-out stage remains gated.

### Formula/implementation and source-reference corrections — 2026-10-14 18:45 (+08:00)

- Clarified that lateral recentering uses the current UAV's horizontal cross-track offset, while the selected rollout supplies the minimum predicted clearance. Applied consistently in the main text, supplement and bilingual text.
- Added the MPC's hard speed/angular-rate command bounds to the supplementary constraints; removed the inaccurate claim that the implementation applies hard state-box limits. Clarified the candidate corridor check applies at every rollout state and explicitly bounded the MPC-reference clearance minimum over all obstacles and horizon steps.
- Checked the supplied Chang et al. source PDF's title/author page: English title and five-author order match the BibTeX entry; it is an online-first Chinese article dated 26 March 2026. The issue/volume/pages/DOI are not supplied in that PDF and were not guessed. Other BibTeX records and used citation keys are separately cross-checked in the reference audit.
- After text edits, the source-map updater changed four existing bilingual content fields only; all 39 anchors validate, 4 synchronizer tests pass, and a final dry-run reports zero differences. No experiment payloads were read.
- Metadata-only Stage-2 inventory at 18:45: 1,601/5,760 fresh episodes, zero error files, lock present, latest write 18:44:58.

### Abstract, comparison, bilingual and consistency corrections — 2026-10-14 19:00 (+08:00)

- Reworked the abstract in the requested First/Second/Then/Finally sequence, expanded MPC/DWA/LSTM at first use, and stated the historical simulation result with its matched design, confidence intervals, and standalone-rate boundary. No result values or comparison directions were changed.
- Removed a defensive clause about predictor inputs by stating the configured inputs directly. Corrected a main-text comparison that had paired DWA-only infeasible-stop counts with the latest-position-hold timing baseline; the text now distinguishes DWA-only (95.9 ms median), shared LSTM (95.7 ms), and latest-position-hold reconstruction (79.5 ms). Rounded repeated historical differences/intervals and medians consistently to one decimal place.
- Standardized the baseline label as `latest-position-hold`. Updated the English/Chinese abstract and discussion in `paper.md`; the source-map synchronizer changed only the corresponding source-map fields. All 39 anchors validate, four synchronizer tests pass, dry-run reports zero differences, and strict bilingual-math validation reports no findings. The reader contains the two main-text figures and five display-equation anchors; the supplementary smoothness expression remains inline within its bilingual clarification block.
- Full manuscript consistency scan was reviewed in context: remaining numeric precision notices refer to distinct quantities, mathematical constants, or range separators rather than repeated outcomes. The repeated historical CIs and timing values identified in the scan were unified. No active experiment payloads were read.
- Metadata-only Stage-2 inventory at 19:00: 1,672/5,760 fresh episodes, zero error files, lock present, latest write 19:00:13. The held-out evaluation and final figure/PDF build remain gated on calibration completion and independent validation. The project-local Matplotlib/PyMuPDF environment is authorized and ready; global Python was not modified.

### Final language alignment and timing-boundary caveat — 2026-10-14 19:04 (+08:00)

- Clarified that the historical 453-to-366 infeasible-stop contrast is specifically shared LSTM versus DWA-only integration, in both the main text and bilingual reader.
- Recast the three historical median planning-time values as descriptive only and stated that differing timing boundaries make them unsuitable for controller-speed ranking. This matches the SI timing-table caveat and avoids implying an apples-to-apples efficiency result.
- Changed the abstract translation to “仅依据近期位置作出的预测不可靠” and aligned the trust-score description with the protocol’s reference-tracking meaning for $\sigma_t$; the subscript is explicitly distinguished from elapsed time.
- Source-map synchronization updated three existing translation/source fields; 39 anchors validate, all four synchronizer tests pass, dry-run reports zero differences, and strict reader-math validation reports no findings. No experimental outcome payloads were read.
- Metadata-only Stage-2 inventory at 19:04: 1,693/5,760 episode files, zero error files, run-local lock present, latest write 19:04:27. Held-out evaluation remains gated on completed calibration and the independent audit.
- The editor integration currently reports no connected document session, so the editor-specific compile command is unavailable. The designated same-source `compile_final.ps1` remains the fallback after the held-out seven-method figure is generated; no stale-figure PDF was built.
- A broader final terminology scan found the older “timeliness” wording still in bilingual block S014. Replaced it with the same reference-tracking definition now used in `main.tex`, preserving the subscript clarification, and synchronized the bilingual source map. All 39 anchors validate; 4 sync tests pass; dry-run is clean; strict math validation has no findings.
- Metadata-only Stage-2 inventory at 19:06: 1,701/5,760 episode files, zero error files, run-local lock present, latest write 19:05:58. No outcome-bearing files were opened.
- Extended the terminology correction into Supplementary Methods and the active v13 terminology/calibration records: $\alpha_T$ is now called reference-mismatch decay, and $\sigma_t$ explicitly denotes the reference-tracking component. Revised the historical timing paragraph to describe the medians without labeling them a comparative efficiency effect. Metadata-only inventory at 19:10: 1,717/5,760 files, zero error files, lock present, latest write 19:09:43.
- Marked the embedded `final_submission_audit.md` as the preserved revision-11 historical audit; it contains obsolete revision, figure and trust-weight details and must not be mistaken for the v13 report. A separate v13 audit will be generated after calibration, held-out evaluation and layout QA finish.
- Inspected the frozen seven-method figure contract and generator: it uses the prospectively selected scene 1/seed 1, draws all seven recorded routes in one 3-D coordinate frame, verifies their starts/endpoints, and does not smooth or extend paths. Final handoff check recorded: the current historical source still includes `route_comparison.pdf`, while the new generator emits `route_comparison_seven_method.pdf`; switch the main include and caption only when the seven-method output exists, preserving the historical asset.
- Local process enumeration/CIM is unavailable in this environment (CIM access denied; `tasklist` returned an authentication error). Do not infer liveness solely from the lock; no worker was restarted or result payload read. The episode-file count advanced from 1,721 to 1,724 during this audit, with the newest file timestamp 19:11:37 and zero error files.
- Rechecked the route-regularization provenance statically: `run_v12_redesigned.m` sets `cfg.mpc.wRoute=3` before saving the source bundle; Stage 2 and held-out runners load that bundle's `cfg` rather than reconstructing from `config_LSTM.m` (whose default is 0). The saved-bundle field still requires post-calibration verification without reading active payloads.

### Calibration episode accounting and reporting — 2026-10-14 19:34 (+08:00)

- The 4,320 Stage-1 count is six candidate trust-weight vectors × five integrated branches × 48 development scenes × three matched seeds. Each vector/branch/scene/seed combination is one simulation episode; these are development-calibration runs, not the held-out performance sample. The post-run recovery audit validated all 4,320 existing records and recomputed the frozen selection; it created zero new episodes.
- The earlier 864-episode six-setting benchmark used a different protocol and was not reused in the 4,320-episode selection. This distinction is now explicit in Supplementary Methods and the bilingual supplementary clarification; the final audit report will include the full run-count ledger and the validation status.
- Metadata-only Stage-2 inventory at 19:34: 1,823/5,760 fresh files, zero `.error` files, `.trust_scale_lock` present, latest write 19:34:43. MATLAB process enumeration returned none. This establishes recent file writes and lock presence, not a verified live worker; no payload or outcome was opened, and the run was not restarted or modified.
- The seven-method held-out evaluation remains planned at 500 new scenes × three matched seeds × seven methods = 10,500 episodes and has not started.

### Forecast-sharing and trust-parameter reproducibility follow-up — 2026-10-14 19:23 (+08:00)

- Clarified in the main text, Supplementary Methods, and bilingual reader that the shared arm sends one time-aligned LSTM forecast to both MPC and DWA, while each one-layer ablation uses CV extrapolation in the other layer. Matched the manuscript's $τ_{\\rm ref}$ notation explicitly to the implementation variable `tau_t`; the subscript denotes tracking, not elapsed time.
- Documented that v13 runners import Stage-1 weights and assign them to `cfg.coupling.sigma`; the generic `config_LSTM.m` default remains for legacy runs and is not the calibrated v13 setting. No active simulation code or protocol was changed.
- Bilingual synchronization updated only the four existing `S011`/`S014` content fields. All 39 anchors validate, 4 synchronizer tests pass, and strict math validation reports no findings.
- Recompiled Supplementary Methods in place with direct pdfLaTeX after the standard MiKTeX registry access failed in the sandbox; `latexmk` is unavailable because MiKTeX has no Perl script engine. The PDF is 16 pages. Rendered pages 1–3 and visually checked the revised method and trust sections. One 3.23-pt overfull-box warning at source line 77 and an unrelated underfull paragraph at line 486 remain under review; neither shows visible clipping in the inspected pages.
- Metadata-only Stage-2 inventory at 19:23: 1,778/5,760 fresh episodes, zero error files, lock present, latest write 19:23:06. No episode payloads, candidate outcomes, or interim summaries were opened; the held-out evaluation and seven-method figure remain gated.

### Current calibration and document checkpoint — 2026-10-14 19:38 (+08:00)

- Stage 1 comprised 4,320 development-calibration episodes: six candidate trust vectors × five integrated branches × 48 scenes × three matched seeds. The recovery audit validated all 4,320 existing records and generated zero additional episodes; the earlier 864-episode protocol was not reused. These counts and roles are now stated in the supplementary methods, bilingual manuscript, README and this audit ledger.
- Recursive metadata-only inventory of the corrected Stage-2 directory found 1,839/5,760 fresh MAT files, zero error files, the run-local lock and latest file timestamp 19:38:41. A PowerShell process query returned no MATLAB process. This confirms neither worker liveness nor outcome validity; no payload or summary was opened and the run was not restarted. The 720 center-cell Stage-1 records still require trace/provenance validation before reuse.
- The seven-method held-out test remains planned, not started: 500 new scenes × three matched seeds × seven controllers = 10,500 episodes. Historical five-controller results (7,500 episodes) and the earlier 864-episode experiment remain separate evidence sets.
- Recompiled the edited Supplementary Methods source in place with pdfLaTeX: 16 pages, no compilation error. Rendered pages 1–3; the newly added Stage-1 count on page 3 is legible and does not overlap or clip. A 3.23-pt overfull-box warning at source line 77 remains in the log without visible clipping in the inspected pages.
- The bilingual source-map original and Chinese translation fields now both contain the Stage-1 count paragraph; at that checkpoint, all 39 anchors validated. The open editor had no connected compile session; the main four-page PDF had not been rebuilt because the held-out seven-method route figure and results were not yet available.
- The authorized project-local Matplotlib/PyMuPDF installation could not complete because the configured package proxy failed; global Python was not changed. Poppler rendered the supplementary PDF pages. Seven-method figure rendering and visual QA remain pending rather than passed.

### Current Stage-2 and route-equation checkpoint — 2026-10-14 19:53 (+08:00)

- Stage 2 is still producing records: metadata-only inventory rose from 1,853 MAT files at 19:42:49 to 1,892 at 19:53:30 (of 5,760 planned fresh records), with zero `.error` files and the run-local lock present. No MATLAB process was visible in `Get-Process`; the CIM query was unavailable. Because the output count and timestamps advanced, the run was not restarted. This is output-liveness evidence only, not outcome validation; no active MAT/CSV payload was opened.
- The route projection safeguard is now presented consistently in `main.tex`, Supplementary Methods, `paper.md` and the bilingual source map: `eta_a = a^T a + 10^-12 m^2`, `P_a = I_3 - aa^T/eta_a`, and `e_perp = P_a(p-s)`. The adjacent prose defines these quantities as a regularized route-length scalar and cross-track residual/operator. Source-map sync validates 40 anchors; all four synchronizer tests pass and dry-run reports zero changes.
- Supplementary Methods was recompiled twice after the change (17 pages, exit code 0). Pages 1–4 were rendered and checked; no visible equation overlap or clipping was found. The log still reports a 3.23-pt overfull box at source line 78 and one underfull paragraph near line 487. The main open-source compile tool is unavailable because no connected document session is exposed; the release script remains gated on the required route-figure artifacts, so the four-page main PDF is not signed off.
- The seven-method held-out evaluation remains unstarted at this checkpoint. The 7,500-run historical comparison remains valid only within its original 1-s DWA-screening protocol; the 4,320 Stage-1 episodes remain development calibration, not held-out performance evidence.

### Final continuation and input-stream limitation — 2026-10-16

- Per author instruction, no new scientific experiments were run. The 4,320 completed Stage-1 development records and 2,100 completed exploratory seven-arm comparison remain the quantitative evidence. Stage 2 is incomplete at 2,263/5,760 records and unscored; the planned 500-scene holdout remains unrun and is not claimed as confirmation.
- Code inspection confirmed that obstacle history is truncated at the current observed step before prediction. The LSTM path uses position, velocity and heading features recorded by the simulator, whereas CV derives velocity from the latest positions. The Discussion and Chinese translation now state that the arm contrast reflects configured input streams, not predictor architecture alone; no overall-superiority claim was added.
- Main text was compiled in place with the existing MiKTeX installation: 4 Letter pages; the unchanged supplement rebuilt to 19 pages. All four fresh main-page renders and all 19 supplementary page renders were visually checked. No clipping, overlap, missing figure/caption, blank page or formula collision was seen; page 17 of the supplement is a sparse text continuation, not a blank page. Main log has no overfull box or unresolved citation; nonfatal underfull and balance warnings remain.
- The bilingual source map validates 45 anchors and its four regression tests pass. The 2026-10-16 audit addendum records the code, data, citation and layout checks. Current PDF, audit, reader and package hashes are regenerated by the allowlisted package builder.
