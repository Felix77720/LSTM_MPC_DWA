# Round 4 author action record

The referee reports are preserved without editing. Actions below respond to their issues in the editable revision.

| Review issue | Author action | Status |
|---|---|---|
| A-M1 / C-M1: distinguish the contribution from predictive DWA and forecast-guided UAV MPC | Rewrote the Introduction to state prior forecast placement and the proposed shared-forecast/control-bound feedback interface; clarified that the evidence evaluates forecast sharing and does not isolate trust-adaptive sampling. | Addressed in positioning; no claim of priority over external planners. |
| A-M2: calibrate scientific importance to the evidence | Kept the conclusion to the tested simulation suite and the measured clearance contrast; retained the success interval and scene heterogeneity. | Addressed in claim scope. |
| A-m1 / C-m1: supplementary numbering mismatch | Added S-prefixed numbering; runtime is Table S1, paired scene values are Table S2, and the plot is Fig. S1. | Addressed. |
| A-m2: remove repeated contribution summary and explain the interface plainly | Removed the second Introduction summary and added a short explanation of how accepted DWA controls connect local reachability to MPC route choice. | Addressed. |
| B-M1: fallback executes a modified command without rechecking it | Made the exact sequence explicit in Methods, pseudocode, Discussion and Supplementary Methods. The four affected random runs and their recorded clearance range are reported. Controller logic is unchanged to preserve the evaluated evidence. | Disclosed; algorithmic limitation remains. |
| B-M2: code, trained model and trajectories absent from frozen review packet | Built a local companion archive with MATLAB sources, trained model, archived run data and trajectories, DWA-only runs, audit scripts and analysis CSVs. | Addressed for local reproducibility; no public repository or DOI. |
| B-m1: fixed versus random setting counts | Clarified four fixed-scene forecast settings (48 runs) and five random-scene settings (180 runs); labeled the DWA-only S4 path as illustrative. | Addressed. |
| B-m2: 0.1-s simulation step could imply real-time execution | Figure label and supplement now distinguish simulated step size from measured wall-clock time. | Addressed. |
| C-M2: explain extreme runtime records | Verified both rows against archived runs; added the full five-setting distribution and the 4,149.47-s and 40,202.71-s individual-step maxima, with no causal attribution. | Addressed as recorded; causes remain unknown. |
| C-m2: bootstrap interval construction | Specified empirical 2.5th and 97.5th percentiles from 20,000 scene-cluster resamples. | Addressed. |
| C-m3: report all sensing conditions | Added clean, noise-only, delay-only and joint noise-plus-delay success counts. | Addressed. |

## Final checks completed

- Recompiled the main paper to five pages and the supplementary methods to six pages; both builds completed successfully.
- Synchronized the paired manuscript to the final PDF and ran strict equation/source-map validation: 0 errors and 0 warnings across 51 blocks.
- Rendered and inspected the final manuscript and supplementary pages. All four figures pass strict overlap/clipping audits; minimum text sizes are 5.4 pt, 6.2 pt, 6.2 pt and 7.8 pt respectively.
- Built the local reproducibility companion archive and verified all 665 packaged files against its SHA-256 manifest, including the code, model, timing summary and clearance audit.
- Confirmed the original `versions/final/01_manuscript/main.pdf` retains SHA-256 `dfd335334280d45823dd5c928bd1ec78173541f85c2239bdf8b4dd7d3d71c1b8`.
