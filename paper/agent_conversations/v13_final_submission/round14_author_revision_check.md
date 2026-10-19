# Round 14 author-side manuscript review

## Overall assessment

The paper now presents one clear question: in a 3D UAV path planner where DWA already screens actions with an LSTM forecast, does giving that same forecast to MPC improve the longer route? The method, matched comparison, and conclusion address this question consistently. The contribution is the trajectory-planning interface that shares learned obstacle motion across MPC route formation and DWA action screening.

## Revision quality

- The Discussion explains the planning difficulty in a split-input MPC–DWA design, then traces how the LSTM positions enter the 3-s MPC route and 1-s DWA rollout.
- The four-method 3D path figure is interpreted as a historical, route-level illustration; the 500-scene chart carries the current aggregate comparison. Earlier CV, Kalman, and six-setting results remain in the supplement.
- The primary experiment is stated consistently: 500 matched scenes, three seeds per scene, 1,500 runs per condition; DWA receives the same LSTM forecast in both arms, and the MPC input is the changed factor.
- Discussion paragraphs interpret the scene distribution, clearance, path length and runtime, then name concrete next tests. Repeated statements about comparisons the paper did not run have been removed from the manuscript prose.
- The complete English–Chinese reader now includes the Figure 3 caption and synchronized source map.

## Evidence and interpretation

The primary goal-arrival rates are 936/1,500 (62.4%) for shared LSTM and 836/1,500 (55.7%) for DWA-only LSTM. The paired difference is +6.7 percentage points (95% scene-cluster bootstrap CI, +4.2 to +9.2). The scene counts are 72 shared-favored, 404 tied and 24 DWA-only-favored. Clearance increased by +0.058 m; mean route length increased by 1.40 m; infeasible stops declined from 455 to 366; swept collisions were 0/1,500 versus 2/1,500. No simulation outcome or figure data was changed in this language and structure pass.

The evidence is drawn from prescribed obstacle tracks, clean current-time observations, point forecasts and motion families represented in training. The paper identifies these as the evaluated setting and proposes reactive obstacles, held-out maneuvers, sensing and dynamics perturbations, uncertainty-aware planning and flight-hardware measurements as follow-up studies.

## Deliverable checks

- Main manuscript: four compiled pages; four display-equation blocks; no inline dollar-delimited formulas.
- Bilingual reader: 32 mapped source blocks, four equations, four figures; all figure assets resolve.
- Render audit: no text outside page bounds; the main and supplementary PDFs were rendered for visual inspection.
- Scenario schematic and historical 3D route comparison retain their verified original SHA-256 hashes.
- The prior versions/final manuscript retains its verified SHA-256 hash.

## Recommendation

The manuscript has a coherent, reviewable path-planning contribution and a directly matched simulation result. It is ready for another venue-specific reviewer pass; the scope and evidence wording should remain tied to the current simulator study.
