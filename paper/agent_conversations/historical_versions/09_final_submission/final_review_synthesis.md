# Final independent-review synthesis

**Revision:** `09_final_submission`  
**Review date:** 2026-10-10  
**Final decision:** **PASS — no blocking issue remains.**

## Review design

Three reviewers independently examined the same immutable eight-file final-review packet without access to one another's reports. Reviewer A covered method logic and implementation traceability; Reviewer B covered statistics, tabular consistency and evidence boundaries; Reviewer C covered rendered figures, readability, references and conference-format compliance. All eight initial manifest hashes matched for every reviewer. After the resulting minor clarifications were applied, the reviewers independently checked the same nine-file post-minor packet; all nine hashes matched in all three checks.

## Initial findings and resolution

All three initial decisions were **MINOR**, with **no blocking issue**.

- Reviewer A asked whether the online DWA safety gate checks swept distance continuously between predicted states. Supplementary Methods S1.2 now states that the gate evaluates ten time-aligned state pairs at 0.1-s intervals, while the reported collision-free-arrival endpoint separately applies continuous piecewise-linear closest-approach auditing to the saved true paths. The reviewer confirmed that this distinction matches `simulate_dynamic.m` and the confirmatory outcome scripts.
- Reviewer B requested an explicit definition of the planning-time contrast and the absolute confidence-interval values plotted in Figure 4(a). Supplementary Methods S4.3 now defines the estimand as the mean across 500 scenes of paired differences in each scene's median of the three run-level mean planning-step times, and distinguishes it from the pooled descriptive median in Table S6. `five_method_absolute_bootstrap.csv` was added to the post-minor packet and supports all five absolute scene-cluster intervals in Figure 4(a).
- Reviewer C found no clipping, overflow, destructive cropping or figure–caption mismatch. The only observation was non-blocking whitespace on supplementary pages 6, 12 and 15; the reviewer confirmed that the updated 15-page supplement remains readable and layout-safe after the clarifications.

## Evidence checks agreed by all reviews

The reviewers independently confirmed that the five controller arms each contain 1,500 matched runs; terminal categories close to 1,500 for every arm; the main and supplementary numbers agree with the frozen CSV files; and the two pre-specified paired effects are reported correctly: shared LSTM versus the integrated DWA-only forecast arm, +6.7 percentage points (95% scene-cluster CI +4.2 to +9.2), and shared LSTM versus the reconstructed latest-position MPC–DWA arm, +60.2 points (+56.2 to +64.2). They also confirmed that the manuscript identifies shared LSTM as the best tested **coupled MPC–DWA** variant while retaining the higher aggregate arrival rates of standalone DWA (76.4%) and standalone MPC (95.2%).

The scene-404, seed-2 trajectory is labelled as an illustrative matched example rather than population evidence. Simulation is not described as real-flight validation. The fixed trust weights are not described as learned, calibrated, source-paper values or simulation-optimized coefficients. The reconstructed baseline is not presented as a numerical reproduction of the source paper's published results.

## Post-minor disposition

Reviewer A: **PASS**; Reviewer B: **PASS**; Reviewer C: **PASS**. No reviewer identified a remaining blocking scientific, statistical, visual, bibliographic or formatting defect. The retained qualifications—simulation-only validation, prescribed obstacle motion, point forecasts, discrete online DWA screening, fixed trust weights, limited runtime headroom and weaker aggregate arrival than the standalone arms—are scientific scope limitations and are disclosed in the manuscript or supplement.

**Synthesis decision:** suitable for submission as a four-page simulation study under the supplied conference checklist.
