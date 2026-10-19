# Revision-10 final audit lens A: methods and equations

**Decision: PASS**  
**Date:** 2026-10-10  
**Scope:** frozen four-page manuscript, supplementary methods, formula/symbol audit, fair-rerun protocol and supplied Chang et al. source paper.

This is a structured author-side adversarial audit. The planned independent Luna reviewer could not access the workspace because its shell helper failed before file reading; it issued no content decision.

## Findings

- The research question is explicit: whether one causal obstacle forecast shared by both planning layers improves a bidirectionally coupled MPC--DWA planner over latest-position handling and over sending that forecast only to DWA.
- The implemented cycle is internally coherent and described in execution order. Ten observations covering 0.9 s enter the LSTM; it returns 30 three-dimensional displacement increments. All 30 accumulated obstacle positions enter MPC, whereas positions 1--10 enter DWA's 1-s screening. DWA executes the retained action and defines the safe first-control envelope; the re-solved 3-s MPC route guides the next DWA cycle.
- The four displayed equation blocks have operational roles: vehicle/clearance dynamics, causal LSTM forecast accumulation, MPC cost and DWA sampling/safety/action selection. Symbols used in the main equations are defined in adjacent prose; implementation-level expansions and numerical parameters are supplied in S1--S3.
- The coefficient vector `[0.35, 0.30, 0.15, 0.20]` is correctly described as a fixed unit-sum engineering priority for safety, goal progress, guide-current alignment and smoothness. It is not called a learned probability, calibrated confidence or simulation-optimized value. The paper states that no coefficient-sensitivity or component-ablation experiment was performed.
- Chang et al.'s 95% versus 80% result is used only as motivation within that source paper's simulation setting. The new 2.2% latest-position result is explicitly a project-local architectural reconstruction under the present protocol, not a numerical replication of the source table.
- The conclusion stays within the evidence: shared LSTM is the strongest tested coupled MPC--DWA variant, while standalone MPC and DWA retain higher aggregate arrival rates. Simulation is never represented as flight validation.

## Remaining scientific limits

Point forecasts, prescribed obstacle motion, represented training/test motion families, sampled online DWA clearance checks, fixed heuristic weights and no hardware experiment constrain generalization. These limits are disclosed and do not create an internal method contradiction.

**Blocking issues:** none.
