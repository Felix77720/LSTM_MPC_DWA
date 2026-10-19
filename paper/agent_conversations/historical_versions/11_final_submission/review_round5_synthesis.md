# Round 5 review synthesis and revision record

## Review scope

Three independent, mutually blind reviews assessed the same frozen round-5 packet. The packet manifest records 22 files; the reviewers report that the listed hashes matched. The reports are preserved unchanged in `review_round5_referee_A.md`, `review_round5_referee_B.md`, and `review_round5_referee_C.md`. None marks a concern as blocking, and none makes an editorial decision.

The frozen packet did not contain the separate code-and-data reproducibility ZIP, and the supplementary source referenced a nested figure file that was absent from that packet. Those points describe the review packet at the time; the companion archive and figure asset are included in the final project delivery.

## Consolidated assessment

The simulation evidence supports a bounded comparison of forecast sharing within the tested LSTM–MPC–DWA planner. It does not establish a hard safety guarantee, superiority over standalone DWA or MPC controllers, an independent causal effect of DWA-to-MPC feedback, or generalization to unseen obstacle-motion families. The positive minimum-clearance contrast and the uncertain goal-success contrast remain distinguished in the revised text.

The central contribution is framed as a tested trajectory-planning integration: one causal LSTM forecast is supplied to both planning layers; DWA screens locally reachable actions; accepted control bounds constrain the first input of a fresh MPC solve; and the selected DWA action is executed. The manuscript does not attribute novelty to LSTM, MPC or DWA individually, and states that its experiments do not isolate the feedback constraint or heuristic sample allocation.

## Revisions made

1. **Contribution and related work:** The Introduction distinguishes prior DWA motion-aware collision modeling, observation-driven DWA weight adaptation, and UAV MPC methods using dynamic-obstacle forecasts or intent prediction. It narrows the novelty claim to the tested planner integration and forecast-sharing comparison.
2. **Heuristic score and fallback:** The manuscript and supplementary methods identify $\tau$ as a heuristic sampling score, not a probability or calibrated forecast-uncertainty estimate. The Methods section now states that the modified fallback bypasses the acceptance gates and that the complete planner has no hard collision-safety guarantee. The Results section reports the four audited runs, 33 fallback actions, their 0.155–0.224 m sampled clearances, no sampled collision in those replays, and four goal successes.
3. **Figures and placement:** The final layout separates the conceptual problem scene (Fig. 1), the top-to-bottom planning cycle (Fig. 2), the measured 3D routes (Fig. 3) and quantitative outcomes (Fig. 4). The flowchart labels no longer overlap.
4. **Figure legibility:** The final figure PDFs pass the Nature collision audit with zero failures and zero warnings. Text-size audits report minimum sizes of 5.2 pt for Fig. 1, 5.0 pt for Fig. 2, 5.8 pt for Fig. 3 and 5.0 pt for Fig. 4.
5. **Results caption and bilingual alignment:** Figure 4's caption identifies the 12 independent random scenes, paired clearance estimate and scene-cluster interval, and distinguishes descriptive run-level standard deviations. The bilingual reader includes the audited fallback paragraph and matches the final figure numbering and page locations.
6. **Reproducibility materials:** The supplementary README now describes the companion ZIP that is delivered with the paper. The package builder copies the nested `scene_clearance_sensitivity` figure asset, so its included supplementary LaTeX source can reproduce the compiled supplement.

No new simulations or results were introduced in response to the reviews; reported values come from the existing simulation records and fallback replay audit.

## Remaining scope limits

- The accepted-control feedback and score-guided sampling were not independently ablated.
- Obstacle trajectories are exogenous, and evaluation maneuver families overlap predictor training families.
- Physical flight and tests on unseen motion families remain future validation work.
- The compiled manuscript has five pages. The directory name contains “4Page,” but no target venue or binding four-page limit was supplied; the content has not been compressed to an assumed limit.

## Overall assessment

The reviewers identified no blocking technical error for the manuscript's narrowed, simulation-bounded clearance claim. The final revision addresses the fallback interpretation, contribution boundaries, figure clarity and supplementary-asset packaging. The unresolved limits are stated in the manuscript and are not presented as completed evidence.

## Post-review visual follow-up — 3 October 2026

After the frozen round-5 reports, the figure sequence was revised to keep the planning problem and measured outcomes visually distinct. This is a focused post-review check of the updated layout; the original referee reports remain unchanged.

- **Figure 1, Problem Formulation, p. 2:** contains only the conceptual scene model. The UAV is shown as a detailed top-view quadrotor pointing from the start toward the goal; moving spherical obstacles and their directions are shown separately. The caption identifies the drawing as conceptual and not to scale.
- **Figure 2, Method, p. 4:** retains the compact top-to-bottom planner flow.
- **Figure 3, Results, p. 4:** independently plots the five matched three-dimensional route outcomes and obstacle-center tracks.
- **Figure 4, Results, p. 5:** presents the quantitative comparison and ablations.

The standalone artwork is one column wide. Final-PDF collision audits report zero failures and zero warnings for all four figures. The minimum rendered text sizes are 5.2 pt (scene schematic), 5.8 pt (3D route comparison), 5.0 pt (planning flow) and 5.0 pt (results summary). The compiled page was inspected at final size; the route and quantitative figures occupy separate figure numbers and image files.

The full bilingual reader and source map were synchronized to the five-page PDF and pass the strict Nature Reader math/link validation. The refreshed reproducibility ZIP contains the separate scene and route PDFs and verifies its required entries. This visual update introduces no new simulation or numerical claim.

## Accessibility and equation-separation follow-up — 3 October 2026

This is an editorial and layout check of the current revision, not a new blinded referee round.

- The abstract states the UAV path-planning problem and forecast difficulty first, then summarizes LSTM prediction, MPC route optimization, DWA action screening, simulation outcomes and the bounded conclusion in that order.
- The problem description names the workspace, UAV approximation, target, moving-obstacle behavior and clearance meaning in ordinary prose. The Method section explains what each of LSTM, MPC and DWA contributes and how the three stages connect.
- Mathematical content is set as standalone numbered display equations. The repeated control-variable line in the motion model was removed. Equation-related prose now explains the quantities and consequences without inline symbolic expressions; the paired reader passes the strict Nature Reader equation/source-map validator with no findings.
- The paired reader now includes plain-language English and Chinese definitions of the UAV, LSTM, MPC, DWA, clearance and evaluation measures; its English paragraphs were aligned to the final manuscript prose.
- The final main PDF remains five pages, with Fig. 1 on p. 2, Figs. 2–3 on p. 4, and Fig. 4 on p. 5. The top-to-bottom flowchart has no overlapping labels, the 3D route comparison is separate from the scene schematic, and the main build has no overfull boxes or unresolved references. The supplementary PDF is seven pages; its half-width sensitivity figure sits by itself on p. 7, which remains a minor layout inefficiency.
- Figure 4 panel (d) now labels forecast input to MPC, DWA or both within the same planner; the caption states that these are forecast-placement and horizon comparisons. Its legend is clear of the plotted points, the minimum text size is 5 pt, and the strict collision audit passes.
- The evidence still compares forecast sources and forecast placement within the integrated MPC–DWA controller. It does not provide a direct matched benchmark against standalone DWA and standalone MPC; any claim of superiority over those standalone controllers would require additional simulations. Results also remain limited to the simulator and obstacle-motion families represented in training and testing.

No new simulation results or blinded reviews were added in this follow-up.
