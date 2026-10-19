# Round 3 author actions / 第三轮评审意见落实记录

This file maps the frozen Round 3 concerns to changes made in the current manuscript and evidence. It does not alter the three reviewer reports or their synthesis.

| Concern | Revision and evidence |
|---|---|
| Discrete collision checks did not examine the path between 0.1-s states. | Added a reproducible piecewise-linear closest-approach audit of all 228 archived runs. It found no new between-state collisions and no change in success counts. Minimum clearances decreased in 198 runs, by at most 0.01048 m. The paper and Supplementary Methods identify the interpolation assumption and do not present it as a physical safety guarantee. Run-level outputs are in `03_supplementary/trajectory_clearance_audit.csv`; summary is in `trajectory_clearance_summary.csv`. |
| Scene evidence and practical meaning of the clearance difference needed clearer boundaries. | Added all 12 paired scene means and leave-one-scene-out estimates to Supplementary Table S2 and Figure S1. The shared-forecast minus DWA-only mean is 0.080 m, with a 95% scene-cluster interval of 0.007–0.166 m; 8/12 scene means are positive and leave-one-out means range 0.051–0.092 m. The paper calls this a within-suite geometric result, not an operational safety threshold. |
| The contribution needed distinction from forecast-aware DWA and UAV MPC work. | Rewrote the Introduction around three-dimensional path planning and the difficulty of anticipating turns, acceleration and stop–go obstacle motion. It states what prior predictive DWA and forecast-informed MPC work addresses, then defines the evaluated contribution as the shared-forecast LSTM–MPC–DWA planning and feedback interface. The paper does not claim superiority over independently reproduced planners. |
| The fallback bypassed normal candidate gates and was not rechecked after modification. | Main text and pseudocode now call it best-effort, state that the modified command is executed without another clearance/corridor rollout, and disclose that it can fall below 0.25 m. Four of 36 shared-LSTM random runs used 33 fallback actions; their point-sampled clearances ranged from 0.155 to 0.224 m. See `shared_lstm_fallback_audit.csv`. |
| Corridor, ablation and runtime details were incomplete. | Equation (6) now includes both the altitude range and nominal-line deviation corridor. Figure 2 shows each of the three horizon-ablation seeds. Runtime hardware/software and the measured loop scope are reported; the CPU model was not recorded, so no cross-platform real-time claim is made. |
| Figures and review reproducibility needed strengthening. | All three main figures remain single-column width in the two-column conference layout. The algorithm diagram is top-to-bottom and passed strict overlap inspection. Scene-level and trajectory audit CSVs are included in the supplementary folder and the frozen Round 4 review packet. |

## 中文对应

本文件逐项记录第三轮评审意见在当前稿件中的处理方式及相应证据，不修改已冻结的三份评审报告或综合意见。

| 问题 | 修订与证据 |
|---|---|
| 原碰撞检查只检查 0.1 s 状态点，未检查点间路径。 | 对归档的 228 次运行补做了可复现的分段线性最近接近审计。未发现新增状态间碰撞，成功次数未改变。198 次运行的最小间隙下降，最大降幅为 0.01048 m。正文和补充方法明确了插值假设，不将其表述为真实物理安全保证。逐次结果见 `03_supplementary/trajectory_clearance_audit.csv`，汇总见 `trajectory_clearance_summary.csv`。 |
| 场景证据和间隙差的实际含义需要进一步限定。 | 补充材料表 S2 和图 S1 展示了 12 个场景的配对均值及逐场景留一估计。共享预测相对仅 DWA 使用预测的平均差为 0.080 m，95% 场景聚类区间为 0.007–0.166 m；12 个场景中 8 个均值为正，留一均值为 0.051–0.092 m。正文将其称为测试集内的几何差异，不称为任务级安全阈值。 |
| 需要说明与预测式 DWA、无人机 MPC 相关研究的区别。 | 重写引言，围绕动态障碍物环境下的三维路径规划，以及转弯、加速和走停运动带来的预测困难展开。先交代已有预测式 DWA 和预测式 MPC 的工作，再界定本文评估的是共享 LSTM 预测的 MPC–DWA 规划与反馈接口。未声称优于独立复现的已有规划器。 |
| 回退动作绕过常规候选筛选，修改后也未重新检查。 | 正文和伪代码现将其称为尽力回退，并说明修改后的控制不会再经过间隙/走廊轨迹检查即被执行，也可能低于 0.25 m。36 次共享 LSTM 随机场景运行中有 4 次触发回退，共执行 33 个回退动作，点采样间隙为 0.155–0.224 m。见 `shared_lstm_fallback_audit.csv`。 |
| 走廊约束、消融和运行时间细节不完整。 | 式 (6) 写明高度范围和相对名义航线的偏差约束。图 2 展示时域消融的三个种子。正文报告软硬件环境和计时环节；由于未记录 CPU 型号，不做跨平台实时性声明。 |
| 图件与评审可复核性需要加强。 | 三幅主图在双栏版式中均为单栏宽度。算法图按自上而下重绘，并通过严格文字重叠检查。场景级和轨迹审计 CSV 已列入补充材料目录及第四轮冻结评审包。 |
