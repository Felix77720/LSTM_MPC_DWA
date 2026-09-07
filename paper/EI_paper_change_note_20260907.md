# EI Paper Change Note 20260907

本轮补全范围：中文主稿、系统工程中文目标稿和 JIRS 英文目标稿；作者、单位、邮箱和 ORCID 等投稿元数据按要求不代填。

## Fact source

The sensing robustness revision uses only the reproducible files in `results/robustness_unified/sensing_20260906_160557/` and the saved LSTM model metadata. The sensing comparison contains 48 rows: one fixed S4 scene with six obstacles, four sensing conditions, three matched seeds and four methods. The model SHA-256 is `61d84f53263b9ed568c15a3a0fa2dc2fb04d7b1b4e4f669ae38effc4e3e3c25d`.

The model metadata records 800 training trajectories, a trajectory-level 640/160 split, 40,910 augmented training sequences, 10,228 augmented validation sequences, a 10-step history, a 30-step prediction horizon, a 96-unit LSTM, one 0.03 m noise view, one delayed-history view, validation noise at 0.03 m, training seed 20260905 and best-validation-loss selection. The selected output iteration is 5150; normalized validation loss/RMSE are 3.4524295/2.6277099. These values agree with the Markdown source and the regenerated DOCX/PDF.

## Conflicts found and resolved

1. `EI_paper_final_CN.pdf` was stale relative to the current Markdown/DOCX and latest evidence. It still reported the older 300-trajectory/3,600-window protocol, older fixed-scene success counts and prediction metrics, and an older robustness run. It was regenerated from the corrected Markdown source.
2. The Markdown/DOCX source had one protocol conflict: the DWA candidate rejection sentence said 0.05 m, whereas the saved run configuration and Table 1 used `dReject=0.25 m`. The sentence now uses 0.25 m; the English target manuscript was corrected to the same threshold.
3. The sensing result is a single fixed S4 six-obstacle scenario, not a four-scene or random-scene robustness suite. This scope is now stated in the experiment design, pressure-test results, conclusion and data/reproducibility note.
4. Reference [1] was replaced in all three manuscripts with the author-provided [J/OL] record: pages 1–9, date 2026-09-07 and the supplied CNKI URL. Volume, issue and DOI were not supplied and were not invented.
5. The evidence renderer was changed from an S3-only detour panel to four deterministic panels, `lstm_detour_evidence_S1` through `lstm_detour_evidence_S4`. Figures 8–11 and the accompanying text now cover all four fixed scenes. The `detours` marker remains code-defined; S1, S2 and S4 can legitimately show zero events.

## Values checked

All 16 rows of `sensing_summary.csv` match the pressure-test tables after the displayed rounding. LSTM success counts are 2/3, 2/3, 2/3 and 1/3 for clean, noise-only, delay-only and joint noise-plus-delay conditions; constant velocity and Kalman each reach 3/3 only in the joint condition. Every LSTM pressure failure is `goal_not_reached|dwa_no_safe_candidate` with zero collisions. The text therefore retains a bounded partial-robustness claim and does not claim universal sensing robustness.

Historical fixed-scene, fixed-window and random-scene evidence was kept as separate evidence layers; it was not relabeled as the single-scene sensing result.

## Completeness additions

- Added the complete MPC objective decomposition and the exact ADE/FDE, signed-clearance, collision-event and success definitions.
- Added control limits, arena, start/goal, solver/software versions, seed formulas, DWA trust/dynamic-weight parameters and the normalized model-selection record.
- Added Wilson 95% intervals to the 12-scene success rates and stated the wide uncertainty of the pressure-suite estimates at n=3.
- Removed the declaration/statements sections from the three manuscript bodies at the author’s request. No author or affiliation fields were altered.
- Standardized Chinese Word text, headings, table text and captions to SimSun (宋体); LaTeX Chinese outputs explicitly request SimSun. English letters and numerals remain Times New Roman/Arial as specified by each builder.
- Corrected active code defaults and comments: the standalone training-data fallback is 800 trajectories, random-scene fallback is 12 scenes, the main entry point uses 650 steps, and `run_multiseed.m` documents 48 rows across four methods. A redundant waypoint-gain assignment was removed without changing the effective value.
- Rebuilt the three active manuscript variants plus the EI submission copy; converted display formulas to readable editable Word math text, removed internal DOCX comments/metadata traces, and completed Word-to-PDF-to-PNG visual QA. The S4 prediction figure is kept intact with a column break in the EI two-column layout. No experiment result was changed.
- Added three source-equivalent XeLaTeX files for the EI Chinese manuscript, the 《系统工程与电子技术》 Chinese target manuscript and the JIRS English manuscript; figures, tables, references and evidence-boundary statements are generated from the same active Markdown sources.

## Reproducibility hashes

| File | SHA-256 |
|---|---|
| `results/lstm_predictor.mat` | `61d84f53263b9ed568c15a3a0fa2dc2fb04d7b1b4e4f669ae38effc4e3e3c25d` |
| `results/multiseed_comparison.csv` | `88d21b7681bd1ef4a763082d1691921aaebf5c601aa5ec2d86fdc428e522e802` |
| `results/multiseed_summary.csv` | `584be9010fbcbc29e06ec1d1ebd0c795b7b4af4fdd34c9cbec804fddd1349a9f` |
| `results/prediction_fixed/fixed_window_group_summary.csv` | `a68524109f29712185ca7c07b8d6d2a691600715d5abd39724bb1421b960aeb4` |
| `results/prediction_fixed/fixed_window_summary.csv` | `b1f8ca62e5c302aa61db7545275b35eb1189f34b41116a8d497af2e4b5136b66` |
| `results/random_eval/random12_20260906_134750/random_scenarios.csv` | `640ba3085a725f0f99077f09a36b9035c34074c8dd0727a7e91677c21aea0d96` |
| `results/random_eval/random12_20260906_134750/random_comparison.csv` | `31302bfd452fcafae0bdafd2316775a3c5058d1652803d3348a97486d6413ba1` |
| `results/random_eval/random12_20260906_134750/random_summary.csv` | `b45c5babec3e3979484e157a0eb1a3c58937b607d2e3051948578c3f2f0b83e0` |
| `results/robustness_unified/sensing_20260906_160557/sensing_comparison.csv` | `14877879bf5a3ea24397993d51699a325ef436c1afddd067848953c046c8da85` |
| `results/robustness_unified/sensing_20260906_160557/sensing_summary.csv` | `7f9ec7d2b2d6d155e84f6f69e5cdc48df37d70c766af55ef001d2892094fb16f` |
| `results/robustness_unified/sensing_20260906_160557/sensing_robustness.mat` | `6367a465db10ed8442d47fcd9105b572d1834d20abd4dbe6a388e7e4f70a06cc` |
