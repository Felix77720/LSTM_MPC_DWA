# Referee B — Round 2 (independent report)

## Overall assessment

This is a clearly scoped simulation study of a shared, time-indexed LSTM forecast used by MPC and DWA. The matched layer ablation is useful, and the paper distinguishes improved clearance in the tested scenes from a demonstrated improvement in success rate or a formal safety guarantee.

The contribution appears incremental and relevant mainly to UAV planning and control researchers. Two details need resolution before the clearance comparison and fallback can be independently assessed: how minimum clearance is calculated across runs, and exactly what control the fallback executes. Broader applicability remains unestablished, consistent with the authors’ stated limits.

## Audience and interest

Researchers developing predictive planners for UAVs may find the shared forecast interface and matched MPC-layer ablation useful. The result is less compelling for a broad interdisciplinary readership because it concerns a narrowly defined simulated planner, with exogenous obstacles and evaluation on motion families that overlap predictor training.

## Major strengths

- The introduction bounds the novelty claim to the planning interface and avoids claiming that predictive planning itself is new or that baselines reproduce published architectures.
- The paper describes how both layers use the same 30-step forecast and reports matched comparisons and a layer ablation.
- The authors report uncertainty for random-scene comparisons and state that the 2.8-percentage-point success-rate difference includes no difference.
- The paper discloses fallback threshold breaches and limits conclusions to the tested simulator, motion profiles and sensing conditions.

## Major concerns

### B-M1 — Definition and inclusion rule for true minimum clearance (major; blocking for the central clearance claim)

**Claim/evidence pointer:** The shared-LSTM planner improves mean true minimum clearance over CV, Kalman and DWA-only LSTM; the layer ablation reports a 0.080-m increase. Main text lines 140–152 identifies outcome measures and scene-cluster bootstrap; lines 152 and 181 report the comparison. Equation 4 at lines 55–59 defines predicted clearance, but not the per-run true-clearance estimator.

**Concern:** The manuscript gives the scene-cluster resampling unit, but does not state how true minimum clearance is calculated across an executed run, whether every attempted run is included, or how collisions and early termination enter the metric. A minimum over shorter failed trajectories is not directly comparable with one over completed paths; restricting the metric to successful runs could select different subsets.

**Why it matters:** Clearance is the main quantitative result. Without an explicit estimator and inclusion rule, readers cannot determine whether the comparison reflects like-for-like trajectories.

**Resolution:** Define the per-run true-clearance calculation and state whether all runs, including failures and early terminations, enter means and intervals. Specify the collision-step rule and provide paired scene-level clearance summaries under that rule.

### B-M2 — Reproducible fallback control law (major)

**Claim/evidence pointer:** When no candidate passes the DWA gate, the method selects a reachable candidate with greatest predicted clearance, applies a bounded low-speed sidestep and solves MPC without the safe-set bound. Main text lines 135, 154 and 168–169 describe the fallback and report 33 fallback actions in four random-scene runs.

**Concern:** The fallback is part of the evaluated controller, but the low-speed sidestep is not defined, nor is it clear whether the executed control is the selected maximum-clearance candidate or a modified control. The reported replayed clearances do not make the action sequence reproducible.

**Why it matters:** Fallback occurred in four of 36 random-scene runs. Its control sequence affects their paths and clearance outcomes, and therefore reproducibility and safety interpretation.

**Resolution:** Specify the fallback control law, limits and tie-breaking rules; state how corridor-invalid candidates are treated, how the selected command relates to the sidestep and fresh MPC solve, and how replayed clearances are computed from executed controls.

## Minor comments

### B-m1 — Time reference under delayed sensing

For the one-step-delay sensing-pressure evaluation, define whether (t) in the forecast equation means the controller cycle or the timestamp of the delayed measurement, and whether a stale position is propagated before forecasting.

### B-m2 — Fixed-window prediction errors

ADE/FDE from four held-out trajectories are reported as point estimates. Report per-trajectory values or uncertainty, or keep this comparison explicitly descriptive; closed-loop results should remain the basis for planner-performance claims.

## Assessment against journal-style criteria

- **Originality:** Narrow; the shared forecast interface and layer ablation are clearly described but build on established components.
- **Scientific importance:** Potentially useful within the tested setup; broader importance is limited by a small simulated scene suite and no unseen-family or reactive-obstacle evaluation.
- **Interdisciplinary readership:** Primarily UAV planning and control researchers.
- **Technical soundness:** Model, objective and comparison setup are substantially specified; clearance estimator and fallback execution need clarification.
- **Readability:** Orderly but equation-dense and specialized.

## Provisional recommendation posture

Major revision before the quantitative case is considered established. Define the clearance metric and make fallback execution reproducible. The current evidence does not establish broader safety, hardware readiness or generalization to unseen motion families.

**Assessment boundary:** This report reviewed the specified main source and compiled PDF. Supplementary Methods were not supplied; no layout-based claims are made.
