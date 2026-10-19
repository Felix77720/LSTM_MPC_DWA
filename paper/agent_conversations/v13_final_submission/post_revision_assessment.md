# Updated referee-style assessment

## Summary

This study addresses three-dimensional UAV path planning among moving obstacles. A causal LSTM predicts obstacle positions and supplies the same forecast to an integrated MPC route planner and DWA action screen. A matched 500-scene simulation compares standalone LSTM-guided DWA, standalone LSTM-guided MPC, integrated DWA-only forecast and integrated shared forecast.

## Strengths

1. **The planning task is now explicit.** The workspace, UAV, goal, obstacle motion, information available to the planner and collision-free endpoint are defined.
2. **The forecast integration is reproducible.** The paper explains the 0.9-s observation span, 3-s position forecast, MPC horizon, DWA rollout and how forecast access differs across arms.
3. **The comparisons use matched scenes.** All four arms share the same scene set, LSTM predictor, obstacle tracks, vehicle model and sampling seeds. The main contrast preserves the frozen confirmatory estimate.
4. **The results now include independent controllers.** The paper reports the performance and computation trade-offs rather than implying the forecast ablation is a stand-alone baseline comparison.
5. **Figures follow the argument.** A scene schematic defines the task; the workflow explains the planner; four 3D routes illustrate matched behavior; the results chart summarizes aggregate rates and paired effects.

## Major interpretation

The primary integrated contrast favors forecast sharing: 62.4% versus 55.7% collision-free goal arrival, paired difference +6.7 percentage points (95% scene-cluster CI +4.2 to +9.2). The standalone comparison prevents a broader claim. In the versioned fairness rerun, standalone DWA reached 82.4% with no collision runs and greater mean clearance than the integrated shared system. Standalone MPC reached 95.2%, but 2.4% of its runs collided and its mean clearance was smaller. The integrated method also had a higher median planning time than either standalone controller.

These results support an architecture-specific improvement from sharing the forecast. They do not support a general claim that the integrated method is better than independent DWA or MPC. The manuscript adopts this narrower interpretation.

## Remaining review points

- The obstacle paths are prescribed rather than reactive, and motion families overlap between predictor training and evaluation.
- The prediction model provides point forecasts without calibrated uncertainty.
- Runtime is near the nominal control interval on the local environment and requires target-hardware profiling.
- Standalone differences are secondary and unadjusted; the paper marks that status in text and figures.

## Recommendation

The manuscript's central claim is now aligned with its data and the independent baselines are directly compared. Final acceptance of the revised artifact depends on successful four-page compilation, PDF visual inspection and the updated delivery audit.
