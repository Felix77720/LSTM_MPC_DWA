# Referee A — Round 2 (independent report)

## Overall assessment

The manuscript describes a specific LSTM–MPC–DWA implementation and reports matched simulation results. The evidence supports a narrow finding: in the tested scenes, giving MPC access to the LSTM forecast increased mean minimum clearance relative to the DWA-only LSTM condition. The success-rate contrast remains uncertain.

The manuscript is appropriately cautious about simulation limits, fallback behavior and generalization to unseen motion families. However, the text does not establish how the shared, time-aligned interface differs from the cited predictive-planning approaches, and its ablation does not isolate the effect of time alignment itself. The broader scientific significance is also limited by the evaluation scope. Novelty relative to prior work is not assessable from the manuscript alone.

## Audience and interest

Researchers in UAV path planning, model-predictive control and dynamic-window methods may be interested in the described interface and its simulation results. The current evidence is unlikely to engage a broad interdisciplinary readership because it establishes performance only within a limited simulator and set of motion profiles.

## Major strengths

- The authors specify the planner’s components and timing, and distinguish prediction accuracy from closed-loop path outcomes.
- The matched comparisons and layer ablation help assess the effect of giving MPC the LSTM forecast.
- The reported uncertainty and limitations are candid. In particular, the manuscript does not treat 36/36 successes as proof of a success-rate advantage or claim flight readiness.

## Major concerns

### A-M1 — Originality and positioning (major; blocking for the originality case)

**Claim/evidence pointer:** Introduction, lines 36–38; Conclusion, line 181. The introduction names related predictive DWA and MPC approaches but says only that they evaluate distinct architectures. The evaluation describes the comparisons as an internal layer ablation rather than reproductions of published planners.

**Concern:** The contribution is the particular shared forecast interface, but the related-work discussion does not explain which elements of that interface differ from the cited architectures. Priority and distinctiveness cannot be assessed from the supplied manuscript.

**Why it matters:** The interface is the paper’s main contribution. Without a clearer distinction from cited methods, readers cannot judge originality or importance.

**Resolution:** Specify how the closest cited approaches handle forecast sharing, future-time alignment and interaction between MPC and DWA. State the precise contribution that remains after that comparison, and keep the novelty claim within that boundary.

### A-M2 — Time alignment is not isolated (major; blocking for a causal claim about alignment)

**Claim/evidence pointer:** Introduction, line 38; Evaluation Design, lines 140 and 144; Results, lines 152 and 172–176. The DWA-only versus shared-LSTM comparison changes whether MPC receives the LSTM forecast. The single-scene structural ablation varies forecast exposure across layers and horizons, but does not compare shared, time-aligned forecasts with an otherwise equivalent condition lacking that sharing or alignment.

**Concern:** Results support a benefit from supplying MPC with LSTM predictions in the tested conditions. They do not isolate whether a common forecast matrix or matching future-time indices account for that benefit.

**Why it matters:** The unisolated feature is the mechanism used to position the contribution. The current evidence cannot attribute the observed clearance increase to time alignment itself.

**Resolution:** Add a matched comparison that varies sharing or time alignment while keeping forecast source, horizon and planner settings fixed, or limit the interpretation to the measured effect of exposing MPC to the LSTM forecast.

### A-M3 — Narrow evidence limits broad significance (major; blocking for broad-interest claims)

**Claim/evidence pointer:** Abstract, line 27; Method, line 85; Evaluation Design, lines 140–144; Discussion, lines 176–178. The evaluation uses 12 random scenes with three runs each and a single-scene structural ablation. Training and evaluation maneuver families overlap; conclusions are limited to exogenous obstacle trajectories and tested simulator and sensing conditions.

**Concern:** The evidence establishes a benchmark-specific simulation result rather than a broadly demonstrated advance in dynamic-obstacle planning. The 0.080-m clearance increase over DWA-only LSTM is measured in the tested scenes, while the success-rate interval includes no difference.

**Why it matters:** Findings may interest specialist robotics researchers, but wider relevance is not established.

**Resolution:** Strengthen evidence across independent scene and motion-profile families, or position the contribution explicitly as a narrowly scoped simulation study and make no broader significance inference.

## Minor comment

### A-m1 — Supplementary material in the review packet

The source and compiled PDF refer to Supplementary Methods for optimizer settings and component scores, but the supplementary file was not included in the assessment packet. Ensure the referenced supplement accompanies the full submission; if the paper must stand alone, include essential score definitions and training settings in the manuscript.

## Assessment against journal-style criteria

- **Originality:** Weakly established. The implementation is described, but its distinction from cited predictive-planning methods is not sufficiently developed.
- **Scientific importance:** Supported for a narrow simulation comparison; weak for broad significance.
- **Interdisciplinary readership:** Likely limited to UAV planning and control researchers.
- **Technical soundness:** Comparisons do not isolate the claimed alignment mechanism. Some details were not assessable from the supplied files.
- **Readability:** Compact and technically dense; the workflow figure helps, but equations and terminology limit access outside the field.

## Provisional recommendation

Major revision. The present evidence does not support a broad-interest contribution. Clarify positioning against cited work and either directly test the time-alignment mechanism or state more narrowly what the ablation establishes.

**Assessment boundary:** This report reviewed the specified main source and compiled PDF. Supplementary Methods were not supplied in that assessment packet.
