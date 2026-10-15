# Supplementary tables / 补充材料表格导读

This bilingual guide follows Tables S1–S12 in the supplementary PDF. It explains what each table supports and the limits readers should keep in mind.

本导读按补充材料中的表 S1–S12 排列，说明每张表提供什么信息，以及阅读时需要注意的结论边界。

## Table S1 — LSTM training and prediction settings

**English.** Table S1 gives the predictor's input history, network size, forecast length, synthetic training set, trajectory-level split, noise augmentation, optimizer, and stopping rule. The adjacent text explains that validation data select the model and therefore are not an independent test set.

**中文。** 表 S1 列出预测器的输入历史长度、网络规模、预测步数、合成训练集、按轨迹划分的数据集、噪声增强、优化器和早停设置。正文同时说明验证集用于模型选择，因此不能视作独立测试集。

## Table S2 — Simulated workspace and vehicle

**English.** Table S2 defines the 3D workspace, start and goal, altitude band, effective UAV radius, motion limits, and simulation time step. These settings describe the simulated problem and do not represent physical-flight validation.

**中文。** 表 S2 定义三维空间范围、起点和目标点、高度约束、无人机等效半径、运动限制及仿真步长。这些参数描述的是仿真问题，不构成真实飞行验证。

## Table S3 — MPC, DWA and shared trust-guided sampling

**English.** Table S3 separates the 30-position, 3-s network output from its use by the two planners: DWA screens its 10-step, 1-s rollout against predictions 1–10, whereas MPC uses predictions 1–30. It also lists the optimizer, safety thresholds, candidate budgets and fixed trust-score weights.

**中文。** 表 S3 区分网络输出的 30 个、3 秒预测位置与两层规划器的实际用法：DWA 用第 1–10 步检查其 10 步、1 秒滚动轨迹，MPC 则使用第 1–30 步。表中还列出优化器、安全阈值、候选采样预算和固定信任度权重。

## Table S4 — Computation time

**English.** Table S4 reports mean and median step times for the two primary methods. These are descriptive measurements from the stated computer and software environment; they are not a statistical timing comparison or a general real-time guarantee.

**中文。** 表 S4 报告两种主要方法的单步计算时间均值和中位数。这些数值是特定计算机与软件环境下的描述性测量，不是统计意义上的速度优劣检验，也不代表普遍的实时性保证。

## Table S5 — Primary 500-scene outcomes

**English.** Table S5 uses three columns: outcome, shared forecast (MPC and DWA), and DWA-only forecast. It spells out the primary endpoint and the reasons for stopped runs, shows counts and percentages directly, and highlights the goal-arrival row. A plain-language sentence below the table gives the main comparison and its paired confidence interval.

**中文。** 表 S5 采用三列：结果指标、MPC 与 DWA 共享预测、仅 DWA 接收预测。表中直接列出次数和比例，写明主要结果以及“没有安全动作可执行而停止”等情况，并高亮目标到达率。表格下方用一句白话说明主要差异和配对置信区间。

## Table S6 — Five-controller aggregate comparison

**English.** Table S6 reports arrival, collision, clearance and timing summaries for the latest-position MPC–DWA reconstruction, two standalone controllers and two integrated controllers. Standalone comparisons are secondary and unadjusted.

**中文。** 表 S6 汇总最新位置 MPC–DWA 重构、两个独立控制器和两个集成控制器的到达、碰撞、间隙与耗时。独立控制器对比为未校正的次要分析。

## Table S7 — Exhaustive terminal accounting

**English.** Table S7 assigns every run to one of five mutually exclusive terminal categories. Each controller row sums to 1,500, resolving the difference between overlapping event flags and final run classification.

**中文。** 表 S7 将每次运行归入五类互斥终止结局之一，每种控制器均合计 1,500 次，明确区分可重叠的过程事件标记与最终运行分类。

## Table S8 — One-scene sensing diagnostic

**English.** Table S8 summarizes four sensing conditions in one repeated-encounter scene, with three seeds per condition. All 12 runs ended at the fail-closed infeasible-action branch. Treat this as a diagnostic example, not an estimate of general sensing robustness.

**中文。** 表 S8 汇总一个重复遭遇场景下的四种传感条件，每种条件包含三个随机种子。12 次运行均在安全闭锁的“无可行动作”分支终止；它是诊断示例，不能用来估计总体传感鲁棒性。

## Table S9 — Retained 48-scene historical comparison

**English.** Table S9 preserves the earlier six-setting, 48-scene benchmark. Its shared-LSTM versus CV contrast was supported, whereas shared versus DWA-only remained inconclusive; these results are not pooled with either the historical 500-scene study or the current seven-method evaluation.

**中文。** 表 S9 保留此前六种设置、48 个场景的基准。共享 LSTM 相对 CV 的差异得到支持，而相对仅 DWA 使用预测的差异仍不确定；该结果不与历史 500 场景研究或当前七方法评估合并。

## Table S10 — Reproducibility-package index

**English.** Table S10 lists key files, their roles and expected row or run counts. It supports machine checking of the 7,500-run audit, terminal accounting, bootstrap outputs and frozen protocols; it is not a public repository citation.

**中文。** 表 S10 列出关键复现文件、用途和预期行数或运行数，用于机器核验 7,500 次运行审计、终止账目、bootstrap 输出和冻结协议；它不是公共数据仓库引用。

## Table S11 — Current seven-method outcomes

**English.** Table S11 gives observed collision-free goal arrivals and swept contacts for seven arms in 100 simulated scenes (300 episodes per arm). Standalone MPC-CV has the highest observed arrival rate (92.0%) but also 15 contacts; shared-LSTM MPC–DWA reaches safely in 73.7% with no contacts. Counts are descriptive and do not establish overall superiority.

**中文。** 表 S11 列出当前七种方法在 100 个仿真场景中的无碰撞到达次数和扫掠接触次数（每种方法 300 次）。独立 MPC-CV 的观测到达率最高（92.0%），但有 15 次接触；共享 LSTM 的 MPC–DWA 安全到达率为 73.7%，未发生接触。该表为描述性结果，不能证明总体优越性。

## Table S12 — Simultaneous paired contrasts

**English.** Table S12 reports all six shared-LSTM-minus-comparator differences with simultaneous 95% scene-cluster max-|t| intervals from 20,000 paired resamples. Only the latest-position-hold reconstruction contrast is positive with an interval excluding zero; standalone MPC-CV favors that baseline. The evaluation is exploratory and simulation-only.

**中文。** 表 S12 报告共享 LSTM 减各比较方法的六组差异及同时 95% 场景聚类 max-|t| 区间，使用 20,000 次配对重抽样。只有相对最新位置保持重构的区间为正且不含零；独立 MPC-CV 的结果更高。该评估属于探索性仿真，不代表真实飞行验证。
