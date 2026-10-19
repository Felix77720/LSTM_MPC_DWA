# Referee C — Round 2 (independent report)

## Scope and overall assessment

This review covers `main.tex` and its compiled PDF only. The study is simulation-only; supplementary material, code and external literature were not assessed.

The paper gives a concrete account of a shared-forecast MPC–DWA interface and compares it with several forecast sources under matched simulation conditions. The clearest result is a modest increase in mean minimum clearance in the tested scenes. The DWA-only LSTM comparison is less conclusive for goal success: the difference is one run out of 36, and its interval includes no difference.

The study is appropriately cautious about safety, flight readiness and generalization to unseen motion families. Its evidence supports a narrow result within this simulator; it does not establish a general UAV safety advantage.

## Audience and interest

Robotics and control researchers may find the shared forecast interface and matched layer ablation useful. The results are less likely to interest a broad interdisciplinary audience without evidence beyond the specified simulator, especially given the narrow success comparison and acknowledged overlap between training and evaluation maneuver families.

## Major strengths

- The manuscript specifies the forecast horizon and future-time alignment used by both planning layers, and describes the interaction between MPC, DWA screening and fallback.
- It compares multiple forecast sources under matched scene and sampling conditions, including a DWA-only LSTM condition that helps isolate the layer contribution.
- It reports the uncertain success-rate contrast and the fallback’s below-threshold clearances rather than presenting either as an unqualified safety result.
- It limits its conclusions to the tested simulator and explicitly disclaims flight readiness, formal safety guarantees and unseen-family generalization.

## Major concerns

### C-M1 — Scene-level robustness of the clearance result (major)

**Claim/evidence pointer:** The shared-LSTM planner has 36/36 successes versus 35/36 for DWA-only LSTM, a 0.080-m clearance difference with 95% scene-cluster CI 0.006–0.167 m, and a success-rate interval of 0–8.3 percentage points. The evaluation uses 12 random scenes with three matched sampling-seed runs each; Fig. 2 error bars show run-level standard deviation.

**Concern:** The independent environmental replication is 12 scenes; three runs within each are matched seed replicates. The cluster bootstrap accounts for this structure, but 12 clusters provide limited information about variation across environments. Fig. 2 does not show the paired scene-level effects, making it difficult to assess whether the clearance gain is broadly distributed or driven by a few scenes.

**Why it matters:** Clearance is the strongest evidence for the contribution. Its robustness across tested environments matters; the current evidence does not establish a goal-success advantage over DWA-only LSTM.

**Resolution:** Show paired outcomes for each of the 12 scenes and a scene-cluster uncertainty summary in or alongside Fig. 2. Include leave-one-scene-out sensitivity. Keep the success claim descriptive unless additional evidence supports a difference.

### C-M2 — Random-scene generation and supplementary detail (major; packet-limited)

The main text describes four fixed scenes and refers to 12 independently generated random scenes, but does not provide their generation ranges or configurations. Optimizer settings and score components are deferred to Supplementary Methods, which were not in this review packet. This is a limit of the supplied evidence, not evidence that the supplement lacks those details.

**Resolution:** Include the supplement and document the random-scene generator, parameter ranges, tested configurations and scoring details. Provide scene-level outcomes or corresponding code and data where available.

### C-M3 — Discrete versus between-step collision evaluation (major)

The manuscript defines (Delta t=0.1) s and success as zero collision steps but does not state whether collision and minimum clearance are checked only at sampled states or between them. An intervening contact could be missed by a sampled-only metric.

**Resolution:** State how clearance is evaluated between states. If only discrete states are checked, qualify the result as sampled clearance; otherwise describe the between-step or swept-path check.

## Minor comment

### C-m1 — Fixed-window forecast accuracy

The small ADE/FDE differences are descriptive for four trajectories, with no trajectory-level uncertainty shown. Report per-trajectory values or uncertainty and keep the predictor-accuracy comparison explicitly descriptive.

## Assessment against journal-style criteria

- **Originality:** The time-aligned interface and layer ablation are credible but incremental.
- **Scientific importance:** The clearance gain is modest; broader importance is not established.
- **Interdisciplinary readership:** Primarily robotics, UAV autonomy and control.
- **Technical soundness:** Comparisons and outcome definitions are partly explicit; robustness across scenes, between-step collision evaluation and replication details need clarification.
- **Readability:** Abstract and introduction explain motivation; methods are equation-dense; the workflow figure helps.

## Provisional recommendation

Major revision before this could support a strong broad-interest case. Show scene-level evidence, include evaluation details, and define the collision metric. The current evidence supports a narrow sampled-clearance finding, not a success-rate advantage, continuous-time collision avoidance, flight readiness or unseen-family generalization.
