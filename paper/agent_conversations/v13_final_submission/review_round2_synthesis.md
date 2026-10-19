# Round 2 review synthesis / 第二轮评审综合

## Overall decision / 总体判断

**English.** The three independent reviews converge on **major revision before the quantitative case is considered established**. The manuscript supports a narrowly bounded simulation result: the shared-LSTM planner has higher mean true minimum clearance in the tested scenes, while the 2.8-percentage-point success-rate difference has a confidence interval that includes no difference. The likely readership is UAV planning and control specialists.

**中文。** 三份独立评审一致建议：**在定量证据充分成立前仍需大修**。当前稿件支持的是范围有限的仿真结果：在已测场景中，共享 LSTM 规划器的平均真实最小间隙更大；成功率高出 2.8 个百分点，但置信区间包含无差异。主要读者群是无人机路径规划与控制领域研究者。

## Consensus findings / 共识意见

1. **Metric and collision definition / 指标与碰撞定义。** Define the per-run true minimum-clearance estimator, its inclusion rule for failed or early-terminated runs, and whether collisions/clearance are checked only at 0.1-s samples or between states. / 明确每次运行的真实最小间隙算法、失败或提前终止运行的纳入规则，以及碰撞和间隙仅按 0.1 s 离散采样还是也检查采样间状态。
2. **Fallback reproducibility / 回退策略可复现性。** Give the executed fallback control law, speed and sidestep bounds, tie-breaking, corridor-invalid handling, and the relationship between the selected DWA action and the fresh MPC solve. / 给出实际执行的回退控制律、速度和侧移边界、并列候选的决策规则、走廊无效候选的处理方式，以及 DWA 选中动作与新一次 MPC 求解之间的关系。
3. **Claim attribution and originality / 结论归因与创新定位。** The current comparison shows the effect of supplying the LSTM forecast to MPC under the tested setup. It does not isolate the effect of time alignment itself. Compare the interface with the closest cited methods and either test alignment directly or keep the claim at the level supported by the ablation. / 当前对比说明在该测试设置下向 MPC 提供 LSTM 预测的效果，但没有单独验证时间对齐本身的作用。应将接口与最接近的已引用方法作明确比较，并直接测试时间对齐机制，或把主张收窄至消融实际支持的范围。
4. **Scene-level robustness / 场景层面的稳健性。** Show paired results for the 12 random scenes and leave-one-scene-out sensitivity for the clearance effect; retain the uncertainty-aware, descriptive wording for success. / 展示 12 个随机场景的配对结果，并对间隙效应进行逐场景剔除敏感性分析；成功率差异继续采用考虑不确定性的描述方式。
5. **Scope / 结论范围。** Keep the conclusions limited to the tested simulator, exogenous obstacle paths, sensing conditions and overlapping maneuver families. The study does not establish hardware readiness, formal safety or generalization to unseen motion families. / 结论继续限定于已测仿真器、外生障碍物轨迹、感知条件及训练与测试存在重叠的运动类别；当前研究不能证明硬件可用性、形式化安全性或对未见运动类别的泛化能力。

## Reviewer-specific emphasis / 各评审关注重点

| Review | English emphasis | 中文概述 |
|---|---|---|
| A | Originality relative to prior predictive DWA/MPC; time alignment is not isolated. | 与已有预测式 DWA/MPC 方法的差别尚不清楚；时间对齐机制未被单独检验。 |
| B | Clearance estimator and fallback action law are insufficiently specified; delayed-sensing time reference needs clarification. | 间隙指标算法与回退控制律说明不足；延迟感知下的时间基准需明确。 |
| C | Twelve scene clusters limit environmental robustness; report paired per-scene outcomes and clarify between-step collision checking. | 12 个场景簇限制环境稳健性判断；需报告逐场景配对结果并说明是否检查采样间碰撞。 |

## Assessment-packet boundary / 评审材料边界

Two reports note that Supplementary Methods were absent from their review packet. That limitation applied to the independent assessment packet: the current revision directory contains `03_supplementary/supplementary_methods.pdf` and the associated source/data files. Include those materials in any submission package; the omission should not be described as a defect in the current directory.

两份报告指出评审材料中未提供补充方法。这是独立评审材料包的范围限制；当前修订目录实际包含 `03_supplementary/supplementary_methods.pdf` 及相应源文件和数据文件。正式提交时应将补充材料一并提交，不应把评审包未提供误写成当前修订目录缺少补充材料。

## Figure legibility verification / 图件字迹核验

The three figures were checked at the size used in the compiled manuscript. Minimum embedded text sizes are 10.0 pt for the scene/path figure, 6.2 pt for the single-column results figure, and 6.8 pt for the full-width top-to-bottom algorithm figure. Strict collision audits pass for the results and algorithm figures. The scene/path audit reports two text-versus-filled-pane edge warnings; visual inspection at final size found the axis labels complete and legible, with no text-to-text overlap or clipping. The results figure was redrawn at 3.5-in single-column width so its text is not halved by LaTeX scaling.

三幅图均按其在终稿中的实际尺寸检查。场景与路径图的最小嵌入字号为 10.0 pt；单栏结果图为 6.2 pt；通栏自上而下算法图为 6.8 pt。结果图和算法图均通过严格碰撞审查。场景与路径图审查器提示两处文字与填充坐标背景边界相交；按终稿尺寸目视核对后，轴标签完整清晰，没有文字互相遮挡或裁切。结果图已按 3.5 英寸单栏宽度重绘，避免 LaTeX 缩放将字号减半。

## Recommended revision priorities / 建议修改顺序

1. Add a concise, exact clearance and collision-evaluation definition to the evaluation design and supplement.
2. Make the fallback command sequence deterministic and fully specified; state what is actually applied to the UAV.
3. Add a compact 12-scene paired plot/table and leave-one-scene-out check; avoid adding redundant aggregate metrics.
4. Revise the contribution and conclusion to distinguish shared forecast access from the untested causal effect of time alignment.
5. Keep the supplementary methods in the submission bundle and retain the simulation-only scope.

1. 在评估设计和补充材料中简明、精确地定义间隙及碰撞计算。
2. 将回退命令序列规定为确定、可复现的流程，并明确无人机实际执行的控制量。
3. 增加紧凑的 12 场景配对图表和逐场景剔除检查，避免重复堆叠汇总指标。
4. 修改贡献与结论表述，区分“共享预测输入”的已测效果和“时间对齐本身”的未测因果效果。
5. 正式提交时附上补充方法，并继续保持仅仿真的证据范围。

## Deliverables / 本轮交付

- Independent reports: `review_round2_referee_A.md`, `review_round2_referee_B.md`, `review_round2_referee_C.md`.
- Revised manuscript and full bilingual reader remain in `01_manuscript/` and `03_bilingual/`.
- The original `versions/final/01_manuscript/main.pdf` remains preserved.
