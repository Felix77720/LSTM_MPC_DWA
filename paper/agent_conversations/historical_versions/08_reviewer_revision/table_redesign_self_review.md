# Table redesign and author-side self-review

**Scope.** This focused review covers the seven tables in the ten-page supplementary PDF, the prose that introduces and interprets them, table values against the saved run-level summaries, and the retained 48-scene comparison figure. It is an author-side consistency and presentation check, not an independent peer review.

## What changed

- Rebuilt Tables S1–S7 as editable LaTeX tables with grouped sections, aligned units, consistent precision, clear denominators, and captions that define how the entries were calculated.
- Added explanatory paragraphs around the tables so readers can distinguish configuration, descriptive runtime, primary outcomes, the one-scene sensing diagnostic, and the retained historical benchmark.
- Expanded the DWA sampling explanation: the scalar trust score combines safety, goal progress, route tracking, and control smoothness; it changes the balance between MPC-guided samples and full-window exploration. The explicitly clipped MPC command is added after the stochastic budget and undergoes the same screening checks.
- Clarified that sensing results come from one repeated-encounter scene and that all 12 LSTM runs fail-closed without reaching the goal.
- Corrected a floating-point display artifact in Fig. S2: a bootstrap lower limit of -5.9e-16 is numerical zero and now prints as +0.0. The plotted estimate and source data are unchanged.
- Corrected the output description in computeTrust_dynamic.m: the weighted combination returned by the function is a scalar trust score, not a four-element vector. This changes documentation only.

## Value and claim checks

- **Table S4, runtime:** the two rows match the primary summary CSV (1,500 timed runs per method; mean 100.23 and 100.30 ms/step; medians 95.91 and 95.70 ms/step). The text treats these as machine-specific descriptive measurements and makes no inferential timing or general real-time claim.
- **Table S5, primary outcomes:** values match the 500-scene summary CSV: shared LSTM 936/1,500 (62.4%) and DWA-only LSTM 836/1,500 (55.7%); swept collisions 0 and 2; infeasible stops 366 and 455; solver failures 2 and 0. The success contrast is +6.67 percentage points (95% scene-cluster CI +4.20 to +9.20). The separate clearance contrast is +0.058 m (95% CI +0.027 to +0.090 m). The text keeps this secondary result distinct from the goal-arrival claim.
- **Table S6, sensing:** recomputed from the 12 LSTM rows in sensing_revised.csv; all four conditions have 0/3 goals, 0/3 collision runs, and 3/3 infeasible stops. The reported means and sample standard deviations for clearance, ADE, and FDE match to three decimals.
- **Table S7, historical outcomes:** all six rows match the separate 48-scene summary CSV. The accompanying text reports the prespecified Shared-LSTM versus CV contrast (+15.28 points; 95% CI +6.25 to +25.69) and correctly describes Shared LSTM versus DWA-only LSTM (+2.08 points; 95% CI -1.39 to +6.94) as inconclusive. Historical runs remain separate from the 500-scene primary analysis.
- **Table S1 and Table S2:** architecture/training split and simulated workspace/vehicle settings were checked against the manuscript's retained configuration and method descriptions. Validation data are explicitly identified as model-selection data, not an independent test set.
- **Table S3:** horizon entries distinguish DWA's 1-s action rollout, its 3-s forecast input, and MPC's 3-s route horizon. The trust-weight and sampling settings match the retained MATLAB configuration. The four-component trust output comment has been corrected to state that the weighted result is scalar.
- Failure flags in Tables S5 and S7 are explicitly allowed to overlap; they are not presented as mutually exclusive partitions.

## Layout and figure checks

- The SI recompiled to 10 pages after the changes; the table pages were rendered and inspected at page scale.
- Table text, headers, units, captions, and explanatory paragraphs remain legible, with no clipped or colliding table content observed.
- Fig. S2 passes the 6-pt PDF text-size floor, strict collision audit, and strict two-panel alignment audit (one comparison; zero warnings/failures).

## Remaining evidence boundary

The main conclusion remains specific to the tested simulation distribution and planner interface. The one-scene sensing table is diagnostic only; timing is descriptive; and the historical 48-scene study is not pooled with the primary test. No table establishes physical-flight safety or unseen-motion generalization.
