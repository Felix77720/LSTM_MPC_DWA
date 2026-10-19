# 评审意见逐条回应

以下为对原评审报告的修订对应表。原报告 `review_report.md` 保持不变；所有稿件改动均位于新建的 `08_reviewer_revision` 目录。

| 意见编号 | 修订回应 | 位置 |
| --- | --- | --- |
| R1-M1、R2-M1、R3-m2 | 将贡献收窄为共享时间对齐预测与 DWA 安全集反馈的具体实现接口；比较相关的预测式 DWA、GP 预测式 UAV MPC 和自适应 DWA；不再声称预测式 MPC/DWA 本身是新方法。增加匹配的 DWA-only LSTM 内部消融。外部论文算法未重实现，正文明确说明。 | 主稿 Introduction、Evaluation Design、Results、Discussion |
| R1-M2、R2-M3、R3-M1 | 补全 MPC 代价及权重、信任度分量、采样数量、DWA 安全门和评分、首控制约束映射及求解器信息；补充训练超参和完整参数表。 | 主稿 Method；Supplementary Methods S1–S3 |
| R1-M3、R2-M4、R3-M2 | 将无候选分支明确为最大预测间隙应急回退，不宣称保留筛选阈值或提供安全保证；新增 4/36 次运行、33 个动作的回放汇总，报告回退动作间隙 0.155–0.224 m、零回退步碰撞及四次均到达目标。 | 主稿 Results/Discussion；`shared_lstm_fallback_audit.csv`；Supplementary Methods S1.4 |
| R2-M2、R3-m3 | 说明训练/验证按轨迹分开；固定窗口误差用四条独立轨迹，闭环测试使用固定与随机场景；测试和训练运动类别重叠，不作未见类别泛化主张。 | 主稿 LSTM Forecast、Evaluation Design、Discussion；Supplementary Methods S2 |
| R1-m1 | 图 2(c) 的随机闭环在线 ADE/FDE 与正文固定历史—未来窗指标使用不同测试集和协议，已在正文及图注标明。 | 主稿 Results 图 2 图注；双语稿 Fig. 2 |
| R1-m2、R2-m1 | 将 `w_r=0` 定义为只关闭起终点参考线惩罚，且注明主对比均采用 `w_r=3`。 | 主稿 MPC 代价段、图 2 图注；Supplementary Methods S1.1 |
| R2-m2 | 对完整 LSTM 与 DWA-only LSTM 作场景配对 bootstrap：成功率差为 +2.8 个百分点（95% CI 0–8.3，包含无差异），真实最小间隙差为 +0.080 m（95% CI 0.006–0.167 m）。 | 主稿 Abstract、Results、Fig. 2；`layer_ablation_bootstrap.csv` |
| R3-m1 | 将文字与流程图统一为“DWA 选择动作—MPC 重求解—执行 DWA 动作—更新状态”的顺序；无安全候选时 MPC 只使用常规物理边界。 | 主稿 Method；Algorithm 1；Supplementary Methods S1.4 |

## 对原评审总意见的处理

原评审指出的方法可复现性、回退语义、训练/评估关系和图表标签均已在稿件中回应。创新性意见已通过相关方法定位和收窄贡献表述予以回应，但未用外部规划器基准声称优越性；因此这是降低主张范围，不是把内部消融包装成 SOTA 对比。回退安全边界仍是明确限制。硬件飞行未增加，因为本文当前证据范围限定为仿真。
