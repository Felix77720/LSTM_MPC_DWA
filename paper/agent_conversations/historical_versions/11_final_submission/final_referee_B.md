# Revision-10 final audit lens B: statistics and evidence boundaries

**Decision: PASS**  
**Date:** 2026-10-10  
**Scope:** frozen main/supplement/bilingual texts, five-method CSVs, run-level audit, mutually exclusive terminal accounting and fair-rerun provenance.

This is a structured author-side adversarial audit. The planned independent Luna reviewer was runtime-blocked before reading any file and issued no content decision.

## Recalculated checks

- `five_method_run_audit.csv` contains 7,500 rows and exactly 1,500 unique scene-seed trials for each of five methods.
- Collision-free arrivals reproduce the manuscript: latest-position MPC--DWA 33/1,500 (2.2%); standalone DWA + LSTM 1,236/1,500 (82.4%); standalone MPC + LSTM 1,428/1,500 (95.2%); integrated DWA-only LSTM 836/1,500 (55.7%); shared LSTM 936/1,500 (62.4%).
- The frozen paired scene-cluster contrasts reproduce +60.2 percentage points (95% CI +56.2 to +64.2) versus latest-position MPC--DWA and +6.7 points (+4.2 to +9.2) versus integrated DWA-only prediction. Secondary contrasts reproduce -20.0 points (-24.8 to -15.1) versus standalone DWA and -32.8 points (-37.1 to -28.5) versus standalone MPC.
- The mutually exclusive terminal rows each sum to 1,500: `33/624/143/0/700`, `1236/0/264/0/0`, `1428/36/0/9/27`, `836/2/453/0/209`, and `936/0/366/0/198` in safe/collision/infeasible/solver/max-step order.
- Scene 404, seed 2 is consistently labelled as illustrative. Saved terminal steps are 20, 262, 220 and 253; only shared integration reaches without collision. No population claim is inferred from this example.
- The fair standalone rerun retains all 3,000 requested files and changes only the standalone-DWA emergency clearance rule; the normal gate and other safety checks remain unchanged, and standalone MPC is unchanged. No scene, seed or outcome was filtered.

## Interpretation

The evidence supports shared LSTM as the best tested coupled MPC--DWA variant. It does not support an overall advantage over the standalone controllers, and the paper says so in the abstract, Results, Discussion and Conclusion. The source paper's 95% is not pooled with the current repeated-run proportions because its denominator, seeds, raw trajectories and complete executable settings are unavailable.

**Blocking issues:** none.
