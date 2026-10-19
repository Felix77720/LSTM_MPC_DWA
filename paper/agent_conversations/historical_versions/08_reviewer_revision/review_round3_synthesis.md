# Round 3 independent review synthesis / 第三轮独立评审综合

## Review setup / 评审范围

**English.** Three mutually blind reviewers independently assessed the same frozen five-page manuscript and four-page Supplementary Methods. Their lenses emphasized originality, technical reproducibility, and simulation evidence/statistics. The original source files were not part of this round's packet. The assessment is simulation-only and does not infer hardware, reactive-obstacle, or unseen-motion-family performance.

**中文。** 三位彼此隔离的评审基于同一份冻结材料独立审阅，包括五页主稿和四页补充方法；关注侧重分别为创新定位、技术可复现性以及仿真证据与统计分析。本轮评审包不含原始代码和逐次仿真输出。评估范围仅为仿真，不推断实飞、障碍物交互或未见运动类别上的表现。

## Shared strengths / 共同优点

- The paper states a concrete UAV trajectory-planning problem and gives the LSTM forecast, MPC optimization, DWA sampling/screening, fallback and cycle sequence in substantially more detail than the initial draft.
- The matched comparison distinguishes the 0.080-m mean clearance difference from the uncertain 36/36 versus 35/36 success contrast, and resamples at the scene level.
- The supplement supplies controller and training details. The paper acknowledges exogenous obstacle motion, overlapping training/evaluation maneuver families, sampled collision checks and the absence of flight tests.
- The three single-column figures make the scene, aggregate comparison and top-to-bottom planning cycle visible in the main paper.

## Consensus and recurring concerns / 共识与重复出现的问题

### 1. Collision outcomes are sampled at 0.1-s intervals

Reviewers B and C independently raise this as a Major Concern; Reviewer A raises the related wording as a Minor Comment. The evaluation correctly defines its implemented test, but sampled non-overlap does not establish that the paths between samples are collision-free. This is especially relevant to the fallback, which bypasses the DWA acceptance gates and can produce clearances below 0.25 m. Keep the metric and conclusions explicitly sampled unless a between-step check is performed.

**中文。** B、C 两位评审将此列为主要问题，A 评审也指出了相关措辞风险。论文已经说明实际采用的离散评估方式，但采样点无重叠并不能证明相邻采样点之间无碰撞。回退分支会绕过 DWA 接受门，且实测间隙可能低于 0.25 m，因此尤其需要限定表述。若不补做步间检查，应将指标和结论明确限定为离散采样结果。

### 2. The scene-level evidence supports a bounded result

Reviewer C makes a Major Concern of the twelve-scene environment sample and the lack of an operational clearance threshold. Reviewers A and B likewise describe the evidence as narrow and the practical significance as unestablished. The paired mean difference is positive, but its confidence interval is close to zero, only 8 of 12 scene means are positive, and the structural horizon ablation uses one scene. Show the scene-level paired values and describe 0.080 m as a geometric difference in this tested suite, not as an operational safety gain.

**中文。** C 将 12 个场景的样本量和缺少任务级间隙标准列为主要问题，A、B 也认为证据范围窄，实际意义尚未建立。配对均值差为正，但区间下界接近零，12 个场景均值中只有 8 个为正，预测时域结构消融也只用了一个场景。应展示逐场景配对值，并将 0.080 m 描述为当前测试集中的几何间隙差，而不是任务级安全收益。

### 3. Distinguish the contribution from cited predictive planners

Reviewer A raises a Blocking-Yes Major Concern on originality; Reviewer B independently raises the same positioning issue as a Minor Comment, and Reviewer C notes that distinctiveness remains underdeveloped. The reports agree that the paper should state what the cited predictive-DWA and forecast-informed UAV-MPC work already does, then identify the specific coupled planning and feedback mechanism evaluated here. The current simulations establish an internal layer comparison, not superiority over reproduced published planners.

**中文。** A 将创新性定位列为阻断性主要问题，B 独立提出同一定位问题但定为次要意见，C 也认为差异尚未阐明。各意见都指向同一修订方向：说明已引用的预测式 DWA 和预测式无人机 MPC 分别解决了什么，再界定本文实际评估的规划层耦合和反馈机制。现有仿真支持本文控制器内部的层间比较，不能证明优于已发表且重新实现的规划器。

### 4. Fallback and reproducibility details need a complete boundary

Reviewer B notes that the modified fallback command is executed without being rechecked by the clearance/corridor gates and requests its corridor outcomes. Reviewers A and C also emphasize that the fallback is outside the nominal acceptance screen. The supplement names `scene_clearance_sensitivity.csv`, but this round's frozen review packet contained PDFs only; the missing CSV is therefore a packet boundary, not evidence that the revision directory lacks it. Include the CSV and any available run-level outputs with the deliverables, clarify what the fallback does and does not recheck, and avoid calling its accepted candidates a safety guarantee.

**中文。** B 指出修改后的回退控制会直接执行，未重新通过间隙和走廊筛选，并要求报告走廊结果；A、C 也指出回退不在常规接受筛选保证范围内。补充方法引用了 `scene_clearance_sensitivity.csv`，但本轮冻结评审包只含 PDF，因此 CSV 缺失属于评审材料边界，不能据此认定修订目录没有该文件。交付时应附上 CSV 和可提供的逐次结果，说明回退分支哪些步骤没有复核，并避免把接受的候选集称为安全保证。

## Additional comments / 其他意见

- Expand “model-predictive control” and “dynamic window approach” at first use in the abstract (Reviewer A).
- Add the full corridor test to the main-text DWA gate or cross-reference its supplement definition (Reviewer C).
- Show individual seed outcomes for the three-seed structural ablation, and distinguish descriptive run-level standard deviations from the scene-cluster inferential interval (Reviewer C).
- Report the timing hardware, timed components and aggregation procedure for the horizon runtime comparison (Reviewer A).
- Reviewer A alone classifies originality as blocking. No technical concern is independently marked Blocking Yes by two reviewers.

**中文。**

- 在摘要中首次出现时展开“model-predictive control”和“dynamic window approach”（A）。
- 在正文 DWA 筛选条件中写全走廊约束，或交叉引用补充方法中的完整定义（C）。
- 展示三种子结构消融的单种子结果，并区分运行级描述性标准差和场景聚类推断区间（C）。
- 补充预测时域运行时间对比所用硬件、计时范围和汇总方法（A）。
- 仅 A 将创新定位标为阻断性意见；没有任何技术问题被至少两位评审独立标为阻断性。

## Overall assessment / 综合判断

**English.** The revised manuscript is substantially clearer and technically more complete. The strongest supported finding is a positive sampled-clearance difference within the tested scene suite; the success-rate contrast remains uncertain. Before delivery, the author pass should sharpen prior-work positioning, use consistent sampled-outcome and best-effort-fallback language, expose the scene- and seed-level evidence where available, and complete the corridor and runtime descriptions. No reviewer requires hardware flight for the stated simulation scope.

**中文。** 修订稿的逻辑和技术说明已明显完整。当前最有力的证据是在已测场景中离散采样最小间隙的配对差为正；成功率差异仍不确定。交付前应进一步明确与已有方法的差别，统一使用离散采样结果及尽力回退的措辞，提供可用的场景和种子级数据，并补齐走廊约束与运行时间描述。对于本文声明的仿真研究范围，没有评审要求必须增加实飞。

## Independent reports / 独立报告

- `review_round3_referee_A.md` — originality and positioning emphasis.
- `review_round3_referee_B.md` — technical and reproducibility emphasis.
- `review_round3_referee_C.md` — evidence, statistics and figure emphasis.
