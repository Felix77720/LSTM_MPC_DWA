# Self-review after the four-controller comparison

## Overall assessment

The manuscript now asks a clear path-planning question and reports four matched controllers on the same obstacle scenes. The result supports a narrow, useful conclusion: within the integrated MPC–DWA architecture, supplying MPC with the LSTM forecast improves collision-free arrival over the otherwise matched DWA-only forecast condition. The standalone comparisons show that the integrated method does not rank first overall.

## Evidence and claims

The primary contrast is 936/1,500 versus 836/1,500 collision-free goal arrivals, a paired increase of 6.7 percentage points (95% scene-cluster bootstrap CI, +4.2 to +9.2). This interval is frozen from the confirmatory analysis.

The added standalone arms show:

- Standalone DWA + LSTM: 1,146/1,500 arrivals (76.4%), zero collisions, mean swept minimum clearance 1.573 m.
- Standalone MPC + LSTM: 1,428/1,500 arrivals (95.2%), 36 collision runs (2.4%), mean clearance 0.674 m.
- Shared integrated MPC–DWA: 936/1,500 arrivals (62.4%), zero collisions, mean clearance 1.245 m.

Thus, standalone DWA is better on the reported safe-arrival and clearance measures than the proposed integrated system. Standalone MPC has the highest arrival rate but worse collision and clearance outcomes. The manuscript states this as a trade-off and does not claim general superiority. Runtime also matters: median step times were 6.67 ms for DWA, 33.58 ms for MPC and 95.70 ms for integrated shared LSTM.

Standalone contrasts are secondary, use paired scene-cluster bootstrap intervals and are explicitly labeled unadjusted for multiplicity. The main figure displays absolute rates and paired shared-minus-comparator estimates; Table I uses counts and directly named safety measures.

## Manuscript structure and clarity

- The abstract proceeds from the planning problem to the method, matched simulation results and bounded conclusion.
- The problem section defines the workspace, start and goal, UAV geometry, dynamic-obstacle trajectories, observation access and collision-free arrival rule.
- The method states how LSTM feeds MPC and DWA, and how standalone DWA and MPC differ from the integrated controller.
- The top-to-bottom workflow diagram matches the method sequence; the problem schematic is separate from measured route plots.
- The 3D route figure shows the same scene and obstacle tracks for all four controllers, then the results figure reports aggregate performance.
- Earlier CV, Kalman, pilot and 48-scene figures and outcome tables remain supplementary and are not pooled with the new evaluation.
- The bilingual reader mirrors the revised four-arm abstract, controller definitions, figures, captions, table and discussion.

## Remaining technical limitations

All evidence is simulation-only. Obstacles follow prescribed tracks, evaluation motions share broad families with training, and the LSTM outputs point forecasts. The integrated planner is close to the 0.1-s update interval on the local computer. The result does not establish performance with reactive or unseen obstacles or on flight hardware.

## Review decision

The four-controller comparison fixes a major scope gap in the earlier manuscript. The work is now suitable for a carefully scoped simulation paper after visual and compile verification; a claim that the integrated controller outperforms standalone DWA or MPC would contradict the measured results.
