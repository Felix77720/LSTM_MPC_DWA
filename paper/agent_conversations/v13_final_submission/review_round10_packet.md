# Round 10 manuscript review packet

## Immutable files for this review

- Manuscript PDF: `01_manuscript/main_revised.pdf`
- LaTeX source: `02_source/main.tex`
- Bibliography: `02_source/references.bib`
- Supplementary methods and results: `03_supplementary/supplementary_methods.pdf`
- Frozen confirmatory protocol: `03_supplementary/confirmatory_experiment_protocol.md`
- Primary result tables and scene-cluster bootstrap: `03_supplementary/confirmatory_method_summary.csv`, `03_supplementary/confirmatory_cluster_bootstrap.csv`
- Four-page English manuscript; venue is not specified. Assess it as an engineering conference paper and use Nature-style criteria only as a review lens, not as an assumed target venue.

## Shared claim summary (descriptive, not evaluative)

The manuscript studies three-dimensional UAV path planning among moving spherical obstacles. It combines a causal LSTM obstacle-position forecast with MPC and DWA. Both experimental conditions use the same LSTM forecast in DWA's 1-s action screen. MPC plans over 3 s and either holds obstacles at their latest observed positions or receives the same time-stamped LSTM forecast. The confirmatory simulation includes 500 matched scenes and three matched sampler seeds per scene (1,500 runs per condition). The paper reports goal success of 936/1,500 (62.4%) for shared LSTM and 836/1,500 (55.7%) for DWA-only LSTM, with a +6.7 percentage-point paired difference and 95% scene-cluster bootstrap interval [+4.2, +9.2]. The manuscript also reports clearance, collisions, path length, infeasible stops, solver failures, runtime, scene heterogeneity and the limits of prescribed obstacle motion. It explicitly does not claim superiority to standalone MPC or DWA, unseen-motion generalization or physical-flight safety.

## Source anchors

- Problem model and scenario figure: manuscript pp. 1–2, Section II, Fig. 1.
- LSTM, MPC, DWA and safety-screen method: manuscript pp. 1–3, Section III, Eqs. (1)–(4), Fig. 2.
- Confirmatory protocol and aggregate comparison: manuscript pp. 2–4, Section IV, Fig. 3; see the frozen protocol and CSVs above.
- Historical CV/Kalman and earlier forecast comparisons: manuscript Fig. 4 and Supplementary Figs. S1–S2; the paper identifies them as separate settings.
- Discussion, limitations and conclusion: manuscript pp. 3–4.

## Review criteria

Assess originality, scientific importance, interdisciplinary readership, technical soundness and readability for nonspecialists. Ground every concern in the listed files and distinguish supported claims, weak claims and claims not assessable from the supplied evidence. Do not assume unreported experiments or treat the historical experiment as pooled with the 500-scene study.
