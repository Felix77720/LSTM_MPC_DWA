# Round 4 reviewer synthesis and post-revision assessment

## Scope

Three mutually blind reviews assessed the frozen five-page manuscript, five-page supplement, LaTeX source, bibliography and evidence CSVs. The reports are preserved as `review_round4_referee_A.md`, `review_round4_referee_B.md` and `review_round4_referee_C.md`. None identified a blocking issue for the manuscript's bounded simulation claims.

## Convergent assessment

The reviewers agree that the matched random-scene comparison supports a 0.080 m increase in piecewise-linear minimum clearance when the LSTM forecast is shared by MPC and DWA rather than supplied to DWA alone. The success-rate contrast is 36/36 versus 35/36 and its interval includes no difference. The result is limited to the tested simulator, exogenous obstacle paths and represented maneuver families.

The main issues were: (1) the Introduction did not distinguish the forecast-sharing and accepted-control feedback interface clearly enough from prior predictive DWA and UAV MPC work; (2) the fixed- and random-scene method counts could be read as if all five settings appeared in both suites; (3) the fallback modifies a selected command and executes it without a fresh rollout check; (4) the review packet lacked the code, model and per-time records needed for independent analysis; and (5) two DWA-only runs contain extreme logged wall-clock steps. The supplement also mislabeled its paired-scene table and figure, omitted the bootstrap percentile construction and showed only two of four sensing conditions.

## Revisions completed

1. **Positioning and scope.** The Introduction now identifies the roles of the closest cited work and states the specific integration: one causal LSTM forecast informs both MPC route optimization and DWA rollout screening, and accepted DWA-control bounds constrain MPC's next first input. A plain-language sentence explains how that feedback links a longer route to locally reachable actions. Trust-adaptive sampling remains part of the controller, with its separate effect identified as unmeasured.
2. **Evaluation counts.** The manuscript now states that the fixed-scene aggregate contains four settings (48 runs) and the random-scene suite contains five settings (180 runs). The DWA-only LSTM S4 path is marked as an illustrative route and is not included in the fixed-scene aggregate.
3. **Timing record.** The two DWA-only outlier runs were checked against archived `.mat` records and are reported without removing or attributing them. Supplementary Table S1 gives per-run timing distributions for all five settings. The timing boundary now includes post-step collision, clearance and offset logging; the 0.1-s value is labeled a simulated state step.
4. **Reproducibility.** A local companion archive packages MATLAB sources, model weights, archived run and trajectory data, the DWA-only random-scene records, audit scripts and analysis CSVs. The manuscript does not assign a public repository or DOI to this local archive.
5. **Traceability and statistics.** The supplementary outputs now use Table S1 for runtime, Table S2 for paired scene effects and Fig. S1 for the scene plot. The 95% bootstrap interval is defined by empirical 2.5th and 97.5th percentiles from 20,000 scene-level resamples. All four S4 sensing conditions are stated.
6. **Prose and figures.** The duplicated Introduction summary was removed. The path figure caption distinguishes the illustrative DWA-only route from fixed-scene aggregation. The flowchart remains top-to-bottom and labels 0.1 s as a simulated step.

## Remaining issues and final assessment

The fallback behavior is explicitly described and illustrated, but its post-selection command is still executed without a fresh clearance or corridor check. This is an algorithmic limitation retained in the evaluated controller; a change would require new simulations and a new evidence audit. Recorded fallback actions reached the goal in the four affected random runs, with post-action sampled clearances from 0.155 to 0.224 m.

The two extreme DWA-only timing records remain unexplained by the archived logs. The manuscript reports them as recorded and does not use the single-scene horizon ablation to imply a general real-time rate. No hardware flights, unseen-family tests, reactive-obstacle tests or standalone published-planner benchmarks were added. The independent effect of trust-adaptive sampling and the operational meaning of a 0.080 m clearance difference remain unmeasured.

**Post-revision assessment:** the central forecast-sharing result is now traceable, accurately bounded and supported by a reproducibility companion. The paper is positioned as a focused simulation study of an integrated trajectory-planning method for the UAV path-planning problem. The remaining fallback and external-validation limits are visible in the method, figures and discussion. The three reviews raise no blocking defect for the stated simulation result; claims of physical safety, deployment readiness, broad generalization or superiority to external planners remain outside the evidence.

## 中文摘要

三位互不知情的评审均未发现会阻断本文所述仿真结论的技术问题。评审共同认可：在测试的随机场景中，MPC 与 DWA 共享 LSTM 预测，相比仅向 DWA 输入预测，分段线性最小间隙增加 0.080 m；目标到达次数为 36/36 与 35/36，但成功率区间包含无差异。

修订已明确区分相关预测 DWA 和无人机 MPC 工作与本文的预测共享及控制反馈接口；更正固定场景四种设置、随机场景五种设置的实验范围；核实并披露两条极端运行时间记录；提供包含源码、模型、轨迹和审计脚本的本地复现包；统一补充表图编号、说明百分位 bootstrap 方法，并补齐四种感知条件。图 1 明确 DWA-only 路径仅作示例，流程图将 0.1 s 标为仿真步长。

仍需关注的限制是：回退分支在修改指令后未重新检查间隙和走廊；两条极端 DWA-only 运行时间的原因未记录；没有实机、未见运动类别、反应式障碍物或外部规划器基准测试；信任度自适应采样的独立贡献及 0.080 m 间隙差的运行意义尚未测量。因而最终评价将论文定位为一项范围明确、材料可追溯的仿真轨迹规划研究，不把结果扩展为实机安全、部署就绪或广泛泛化结论。
