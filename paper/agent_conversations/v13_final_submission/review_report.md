# 论文评估报告

## Review setup

- **Input scope：**四页完整会议论文，`main_clear_flowchart.pdf` 及相应 `main.tex`。
- **Assessment boundary：**三份隔离评审只使用相同的 PDF、LaTeX 和稿内图表；未读代码、原始轨迹数据或外部论文，也未核验引文元数据。没有把评审意见写成编辑决定。
- **Shared manuscript claim summary：**因果 LSTM 从障碍物最近 1 s 观测预测未来 3 s 运动，并将同一时间对齐预测用于 MPC 路径代价和 DWA 候选动作筛选；作者报告仿真中目标到达率及最小间隙改善。
- **Visible evidence base：**无人机离散动力学和球形障碍物场景模型；LSTM 结构与训练/验证数量；MPC、DWA、安全门公式；静止、CV、Kalman 基线；固定与随机场景匹配对比、场景级 bootstrap、预测误差、消融、噪声与延迟实验；三幅图和五条参考文献。
- **Missing materials affecting confidence：**评审者没有检查实现、轨迹原始数据、随机种子文件、完整参数配置或独立的预测测试集，也没有外部核验创新性和参考文献。以下对复现性、独立预测测试和先前工作的评估受此范围限制。
- **角色隔离：**三份评审在独立上下文中完成，先冻结后进行综合；下文保留各自不同的严重性判断。综合阶段另行只读查看本地控制器源文件，以核对正文与图 3 的周期顺序，没有运行代码。

## Reviewer 1

**Emphasis：**论文定位、贡献与论证组织。

### Overall assessment

问题、方法和模拟结果已经形成基本清楚的论证链。作者用因果 LSTM 预测障碍物轨迹，并把同一时间对齐的预测用于 MPC 风险代价和 DWA 候选筛选。论文报告了多场景路径结果和单场景消融，也说明了仿真边界。最需要加强的是相对于已有预测式 MPC、DWA 及其组合的创新定位；若干实现细节和回退动作的安全边界也没有充分说明。

### Who would be interested in the results, and why

无人机导航、机器人和运动规划领域的读者会关注预测信息如何连接路径级优化与局部可执行指令。当前证据的兴趣主要在该专门领域。

### Major strengths

- 问题定义列出无人机状态、控制量、动力学、场景和成功判据（p.1–2，Problem Formulation）。
- 方法说明 LSTM、MPC、DWA 的职责，并指出两个规划层共享同一未来时间索引（p.2，式 (3)–(6)）。
- 实验采用匹配种子，并按 12 个场景簇计算随机场景间隙区间（p.2–3，Evaluation Design 与 Results）。
- 讨论限定了单场景消融、噪声/延迟条件和无硬件飞行证据（p.3–4）。
- 场景路径图和自上而下的闭环流程图展示了对比路径、安全筛选、回退及更新环节（图 1、图 3）。

### Major Concerns

#### R1-M1 [原创性与重要性]

**Severity：** Major  
**Blocking：** Yes  
**Claim pointer：**共享因果 LSTM 预测及其在 MPC、DWA 中的时间对齐使用，扩展了反应式 MPC-DWA 路径规划。  
**Evidence pointer：**p.1 Introduction，尤其是 “extends a reactive MPC-DWA planner” 及其后的两项扩展说明；同段引用预测式 DWA、航空 MPC 预测规划及 learned DWA 工作。  
**Concern：**稿件未具体比较相邻工作的预测来源、MPC/DWA 分工、共享时间索引和安全候选集反馈，也未说明 “reactive MPC-DWA planner” 指何种先前方案。读者难以判定本文是在扩展哪种既有组合，或在已有预测组件上做了怎样的新系统整合。  
**Why it matters：**共享预测框架是论文的主贡献。若相对已有工作的差异未被确立，性能改善不足以说明核心方法贡献的新颖边界。  
**Resolution test：**逐项比较最相关方法与本文在预测模型、MPC/DWA 是否共享预测、安全候选集如何反馈至 MPC 等方面的差异；给出 “reactive MPC-DWA planner” 的出处，或相应收窄 “extends” 与贡献表述。

#### R1-M2 [可复现性]

**Severity：** Major  
**Blocking：** No  
**Claim pointer：**预测风险代价、信任度采样、候选评分和安全集反馈共同构成所提规划器。  
**Evidence pointer：**p.2 Method，式 (4)–(6) 及其后说明。  
**Concern：**MPC 的目标、控制和平滑代价没有给出完整形式与权重；信任分量如何计算、DWA 候选评分的自适应权重如何取值，以及安全候选包围盒如何约束 MPC 重求解，也未充分定义。  
**Why it matters：**这些细节会影响路线、候选排序和预测风险对 MPC 解的作用，读者难以独立重建核心方法。  
**Resolution test：**提供完整目标项、所有权重、信任分量和候选评分公式、包围盒到 MPC 约束的映射及求解器设置，最好附参数表；按完整设置核对论文所报结果。

#### R1-M3 [主张边界]

**Severity：** Major  
**Blocking：** No  
**Claim pointer：**DWA 安全筛选和无通过候选时的最大间距回退共同支持动态障碍物避碰规划。  
**Evidence pointer：**p.2 Method，式 (6) 后的回退说明；p.4 图 3 第 5–7 步。  
**Concern：**没有候选通过安全门时，控制器仍执行预测间隙最大的可达候选；该动作可能不满足间隙、走廊或制动门槛。稿件没有报告回退触发频率，也没有明确其是否具有碰撞安全保证。  
**Why it matters：**回退行为属于闭环算法的一部分，决定读者如何理解安全筛选在局部不可行时的能力边界。  
**Resolution test：**说明回退动作实际满足的约束，报告每组实验中的触发次数、回退后的真实间隙和碰撞情况；如无安全保证，将其称为应急最大间距回退，并限定相关安全表述。

### Minor Comments

#### R1-m1 [图表说明]

**Affected element：**正文预测误差数值与图 2(c) 的数据范围。  
**Evidence pointer：**p.3 Route Outcomes and Forecast Accuracy；p.4 图 2(c) 图题。  
**Issue：**正文给出固定 history–future windows 的 ADE/FDE，而图 2(c) 标为随机场景 ADE/FDE。文本没有直接说明两者是否来自不同评估窗口。  
**Required correction：**说明正文与图 2(c) 所用场景、预测窗口和汇总方式，避免读者将固定窗口值误认为随机场景图中数据。

#### R1-m2 [图表说明]

**Affected element：**图 2(d) 中的 “route = 0” 标注。  
**Evidence pointer：**p.4 图 2(d)，Interface ablation。  
**Issue：**正文没有解释该标签是何种消融条件或代价设置。  
**Required correction：**在图注或消融段中定义该标签，并说明其与双层预测结果的关系。

### Assessment against Nature-style criteria

- **原创性：**组合式方法主张明确，但与预测式 MPC、DWA 及组合方法的差异尚不充分。
- **科学重要性：**对动态障碍无人机规划有领域内价值；仿真场景规模不足以支撑广泛外推。
- **跨学科读者兴趣：**机器人、控制、自主导航读者会直接关注；更广泛读者需要看到预测与闭环避障之间的意义。
- **技术严谨性：**匹配实验和场景级区间是优点；复现细节及回退行为限制了技术解释。
- **非专业读者可读性：**摘要逻辑易懂；信任度评分、障碍代价和回退机制还需更多解释。

### Technical failings that need to be addressed before the case is established

R1-M1 被评为 blocking；R1-M2 和 R1-M3 为非 blocking 的 Major Concerns。

### Recommendation posture

建议投稿前作实质性修改，优先明确创新边界，补充方法定义，并报告回退行为和结果。

## Reviewer 2

**Emphasis：**工程/控制方法、训练与验证、基线、统计和可复现性。

### Overall assessment

稿件所报固定与随机场景结果支持该方法在指定模拟条件下的路径规划表现。匹配对照、场景聚类区间和仿真边界表述是优点。当前仍需说明预测评估数据与训练数据的关系，补全核心算法参数，并解释没有安全候选时的回退动作。评审没有把未报告的信息推断为数据泄漏，也没有把仿真结果外推为实飞结论。

### Who would be interested in the results, and why

机器人、控制和无人机路径规划领域读者会关注多步障碍预测如何改善闭环成功率和间隙。

### Major strengths

- 给出 UAV 状态、场景、工作空间和成功判据。
- 量化 LSTM 的历史与预测时域，并说明 MPC/DWA 使用相同时间索引。
- 使用匹配种子，区分固定和随机场景，并按 12 个场景对随机实验进行聚类。
- 报告成功次数、间隙、ADE/FDE、结构消融及感知压力结果。
- 说明单场景消融与仿真结论的适用范围。

### Major Concerns

#### R2-M1 [原创性]

**Severity：** Major  
**Blocking：** No  
**Claim pointer：**共享时间对齐的 LSTM 预测扩展反应式 MPC-DWA 路径规划。  
**Evidence pointer：**p.1 Introduction 第三段；p.2 Evaluation Design 与 Forecast-Sharing Ablation。  
**Concern：**实验可对比预测来源并提供内部消融，但没有直接比较相邻的预测式 DWA、预测式 MPC 或学习型 DWA 架构；单场景消融也没有单独识别时间对齐设计的收益。  
**Why it matters：**读者无法判断收益来自 LSTM、组件组合，还是时间对齐接口本身。  
**Resolution test：**补充最接近的预测式规划基线，在同场景、同种子和同约束下比较；若不可行，将贡献收窄至已实现的仿真集成，并说明消融实际支持的范围。

#### R2-M2 [实验设计与统计]

**Severity：** Major  
**Blocking：** No  
**Claim pointer：**LSTM 预测误差优于基线，并由此支持路径规划方法。  
**Evidence pointer：**p.2 III-A 报告 800 条轨迹分为 640 条训练和 160 条验证；Evaluation Design 报告四个固定与 12 个随机场景；p.3 报告固定窗口 ADE/FDE，p.4 图 2(c) 标出随机场景误差。  
**Concern：**没有明确独立测试集的来源，也没有说明固定窗口与随机场景误差分别使用哪些轨迹，这些轨迹是否与训练/验证轨迹分离，或八种训练运动模式与测试运动模式如何对应。  
**Why it matters：**预测误差是核心证据之一；若误差来自训练或模型选择所用数据，无法独立判断泛化表现。现有材料不足以判断此事，并不等于已证实发生泄漏。  
**Resolution test：**给出训练、验证、独立测试及闭环规划场景的来源与分割关系，并报告独立测试轨迹上的 ADE/FDE；若当前指标来自验证集，应限定相应结论。

#### R2-M3 [可复现性]

**Severity：** Major  
**Blocking：** No  
**Claim pointer：**LSTM–MPC–DWA 闭环及信任度自适应采样、安全筛选构成所提方法。  
**Evidence pointer：**p.2 III-B 式 (4)–(6) 及相邻说明；III-A 训练说明。  
**Concern：**MPC 目标的权重、信任分量计算、DWA 候选评分函数及权重没有完整报告；LSTM 训练损失、优化器和重要配置也未报告。  
**Why it matters：**这些设置会影响 MPC 风险代价、采样预算和候选排序，使独立读者难以重建论文所用实现。  
**Resolution test：**附上完整目标函数、DWA 评分及所有参数，说明训练配置、数据生成和模型选择指标。

#### R2-M4 [安全主张边界]

**Severity：** Major  
**Blocking：** No  
**Claim pointer：**安全候选筛选和最大预测间距回退支持动态障碍物路径规划。  
**Evidence pointer：**p.2 III-B 式 (6) 及无候选回退段；p.4 图 3 第 6B–7 步；p.3–4 结果成功率。  
**Concern：**最大间距回退并未说明是否继续满足原筛选门槛，也未报告触发频率或回退后的间隙。测得的成功率仅说明这些运行的结果，不能单独建立算法保证。  
**Why it matters：**读者需要区分正常安全筛选与没有合格候选时的尽力处置。  
**Resolution test：**报告触发次数、触发后的实际间隙和碰撞情况，写明回退动作的限制；若它不满足安全门，应将结论表述为实测仿真表现而非安全保证。

### Minor Comments

#### R2-m1 [图表说明]

**Affected element：**图 2(d) “route = 0”。  
**Evidence pointer：**p.4 图 2(d) 与正文 Forecast-Sharing Ablation。  
**Issue：**标签未在正文定义，也没有说明被移除的目标项或模块。  
**Required correction：**在图注或正文定义该条件。

#### R2-m2 [统计报告]

**Affected element：**固定与随机场景成功率差异。  
**Evidence pointer：**p.3–4 Results；随机场景 bootstrap 仅明确给出 clearance 区间。  
**Issue：**每场景三次运行，故 36 次运行并不等于 36 个独立场景；成功率差异没有相应场景级不确定性。  
**Required correction：**给出场景级配对成功结果或集群区间；若保留为描述性数字，应明确标注。

### Assessment against Nature-style criteria

- **原创性：**共享预测设计清楚，最近工作的增量还未建立。
- **科学重要性：**对专门的 UAV 规划领域有价值；目前结论限于仿真。
- **跨学科读者兴趣：**对机器人、控制、自主系统相关；面向更广泛读者的意义较窄。
- **技术严谨性：**实验匹配和场景级重采样是优点；数据分割、关键参数及回退行为不够完整。
- **非专业读者可读性：**摘要清楚；方法缩写密集，图 2(d) 标签待解释。

### Technical failings that need to be addressed before the case is established

未识别出必须判为 **Blocking Yes** 的技术缺陷。需实质性处理的是 R2-M1 至 R2-M4。

### Recommendation posture

建议先实质性修改，再判断投稿准备度。补齐预测测试集说明、方法参数和回退统计，并强化或收窄创新论证。

## Reviewer 3

**Emphasis：**反例压力测试、结论边界和跨领域可读性。

### Overall assessment

稿件围绕动态球形障碍场景下的三维无人机路径规划展开，核心是用 LSTM 预测未来轨迹并把同一预测提供给 MPC 与 DWA。文本与图示整体连贯。结果支持的结论限于指定仿真器、运动模式和感知条件，不能支持更广泛的实飞安全或响应式障碍交互结论。当前需优先补清评分细节并说明安全门失效时的回退行为。

### Who would be interested in the results, and why

机器人、控制和时序预测读者会关注共同时间索引如何连接未来障碍预测和可执行路径规划。

### Major strengths

- 问题定义列出状态、控制量、工作空间、起终点、障碍物及成功判据（p.1）。
- 式 (4)–(6) 区分 MPC 的软风险代价和 DWA 的候选动作筛选。
- 随机场景区间以 12 个场景为聚类单元，而不是把 36 次运行视为独立场景。
- 论文说明障碍物轨迹为外生给定，承认单场景消融和感知压力限制。
- 图 1 和图 3 展示路径比较与算法分支，版面未见明显文字重叠。

### Major Concerns

#### R3-M1 [可复现性]

**Severity：** Major  
**Blocking：** No  
**Claim pointer：**共享预测、信任度采样和候选排序构成 MPC–DWA 规划方法。  
**Evidence pointer：**p.2 Method，式 (4)–(6) 及式 (6) 后的候选排序文字。  
**Concern：**MPC 的目标误差、控制和平滑项没有公式或系数；四个信任分量没有计算定义；最终候选评分没有公式、权重或归一化方式。  
**Why it matters：**这些选择会改变路线、采样和动作，读者无法复建主要方法或判断增益来自哪一环节。  
**Resolution test：**补充代价项、信任分量、评分、归一化和完整参数，并报告所用训练设置。

#### R3-M2 [安全与回退处理]

**Severity：** Major  
**Blocking：** No  
**Claim pointer：**DWA 安全门控和最大间隙回退构成完整的安全动作选择流程。  
**Evidence pointer：**p.2 式 (6) 及其后回退说明；p.4 图 3 第 5–7 步。  
**Concern：**无候选通过安全门时，算法选择最大间隙的可达动作，但没有说明它是否仍满足安全门槛；图中写明回退时 MPC 的安全边界为空，也没有解释该情况下重求解的含义。论文未给出回退次数和后续碰撞/间隙结果。  
**Why it matters：**当前读者无法判断这是受约束的安全动作还是无安全候选时的尽力避险启发式。  
**Resolution test：**说明回退约束、空边界时 MPC 的处理和回退后的实测结果；将筛选规则与形式化安全保证区分。

### Minor Comments

#### R3-m1 [周期顺序]

**Affected element：**正文 Method B 与图 3 步骤 7 的执行顺序。  
**Evidence pointer：**p.2 Method B 写先执行 DWA 动作、再用安全候选包围盒重求解 MPC；p.4 图 3 写先 MPC 重求解，再执行 DWA 并更新状态。  
**Issue：**两处对当前动作执行和 MPC 重求解的顺序不同。  
**Required correction：**统一两处顺序，说明求解所用状态以及安全候选约束对应的周期。

#### R3-m2 [创新定位]

**Affected element：**Introduction 中相对预测型 MPC、DWA 及其组合的贡献表述。  
**Evidence pointer：**p.1 Introduction 第 2–3 段；p.2 Method。  
**Issue：**相关方向虽有引用，但未简明指出哪些已有方法具备动态障碍预测、哪些接口或时序设计是本文新增。  
**Required correction：**增加简短对照，并把贡献限定在稿件所实现和比较的范围内。

#### R3-m3 [泛化边界]

**Affected element：**LSTM 训练运动类型与评估场景的关系。  
**Evidence pointer：**p.2 LSTM Forecast and Time Alignment 与 Evaluation Design；p.3 预测结果；p.4 Discussion。  
**Issue：**文中报告八类训练运动，但未说明测试运动类型是否与训练重叠。按轨迹划分训练/验证不等于按运动类别留出，因此当前无法判断对未见运动类型的泛化。  
**Required correction：**说明训练、验证、测试运动类别的重叠；如未留出运动类别，应将适用范围限定于所测试类型与参数范围。

### Assessment against Nature-style criteria

- **原创性：**共享时序与安全反馈的设计清楚，但最近工作差异需要更具体。
- **科学重要性：**对 UAV 动态避障和 MPC 读者有专门领域价值；当前未确立更广泛的重要性。
- **跨学科读者兴趣：**机器人、控制和时序预测读者相关；更广泛读者需要理解信任评分及回退含义。
- **技术严谨性：**场景匹配和边界描述较清楚；打分定义与回退语义仍不完整。
- **非专业读者可读性：**摘要和图示清楚；公式密集且一些方法量未定义。

### Technical failings that need to be addressed before the case is established

没有需要标记为 **Blocking Yes** 的问题。R3-M1 和 R3-M2 仍需实质性澄清。

### Recommendation posture

这是一项可能有价值的专门仿真研究；在方法可复现性和回退边界得到补充前，核心方法论证尚未完全建立。

## Cross-review synthesis (post-review; not shown to reviewers)

### Consensus strengths

- 三份评审均认为，问题定义给出三维工作空间、无人机动力学、动态球形障碍物和目标到达判据，任务对象较明确。
- 三份评审均认为，论文把因果 LSTM、MPC 障碍风险和 DWA 可执行候选筛选放进同一闭环叙事，并以图示解释了场景和周期流程。
- 匹配场景/随机种子、按场景簇进行随机场景重采样，以及主动说明外生障碍物、噪声延迟和无硬件飞行，受到认可。
- 三份评审均认为结论应维持在稿件明确的模拟范围内。

### Consensus blocking concerns

None identified by at least two independent reports. Reviewer 1 将创新定位问题评为 Blocking Yes；Reviewer 2 同一问题评为 Blocking No，Reviewer 3 将其评为 Minor。因此不把它归类为共识 blocking concern。

### Other consensus major concerns

1. **创新边界仍不清楚**，R1-M1、R2-M1 评为 Major；R3-m2 同样提出该问题但评为 Minor。文内需解释本文相对预测式 MPC、预测式 DWA、学习型 DWA 和所称反应式 MPC-DWA 组合的实际新增内容。blocking 判断存在分歧。
2. **核心算法定义不足以复现**，R1-M2、R2-M3、R3-M1 均为 Major、非 blocking。完整 MPC 代价、权重、信任分量、候选评分和参数应补充。
3. **无安全候选时的回退边界不明确**，R1-M3、R2-M4、R3-M2 均为 Major、非 blocking。最大预测间隙回退不等同于通过原安全门，必须解释其约束并报告触发及后续碰撞结果。

### 其他问题及严重性判断不同的意见

- **训练/测试独立性和类别外泛化**：R2-M2 认为预测测试数据与训练/验证关系未交代；R3-m3 以较低严重性提出训练与测试运动类别是否重叠。现有文稿并未证明数据泄漏，但目前不足以评估对独立轨迹或未见运动模式的泛化。
- **图 2(d) “route = 0”**：R1-m2 与 R2-m1 均指出该消融标签没有在正文定义。建议加一句说明其含义和与两层预测基线的关系。
- **预测误差样本说明**：R1-m1 提醒正文固定 history–future 窗口数值与图 2(c) 随机场景数值的上下文可能被混读。图题并未证明数值错误；建议把两组指标的样本来源与评估方式直接写清。
- **成功率的不确定性**：R2-m2 建议为成功率差异给出场景级结果或置信区间，或明确其仅作描述性对比。
- **正文与流程图的周期顺序**：R3-m1 指出文字将动作执行放在 MPC 重求解前，图 3 则相反。综合阶段只读核对了当前 `simulate_dynamic.m`，该实现先按 DWA 选出动作，再以安全候选集重求解 MPC，最后执行 DWA 动作；因此图 3 与实现顺序一致，建议改正文句序使其一致。

### Where emphasis differs across reviewers

- 对创新性问题的严重程度判断不同。Reviewer 1 认为目前无法建立中央贡献，因此给出 Blocking Yes；另外两位认为这是重要但可通过定位、比较或收窄主张解决的问题。共同点是三份报告均要求加强创新比较。
- 对独立预测测试的担忧主要来自方法/统计视角；范围视角将其看作泛化边界的次要澄清。建议先明确数据来源和划分，再决定是否需补实验。
- 图 2(c) 的评审意见是澄清要求，不是发现可证实的数据矛盾。图 2(d) 标签则有两位独立评审指出，优先解释成本低。

### Minor revision checklist

- 定义图 2(d) 中的 `route = 0`（R1-m2、R2-m1）。
- 说明图 2(c) 与正文 fixed-window ADE/FDE 各自的场景、窗口和汇总方法（R1-m1）。
- 统一正文 Method B 与图 3 的周期顺序（R3-m1）。本地控制器源文件支持“DWA 选动作 → MPC 重求解 → 执行动作 → 更新状态”的流程。
- 为 36 次运行的成功率对比补充场景层面的配对分布/不确定性，或注明只作描述性统计（R2-m2）。

### Broad-interest / significance readout

这项工作对 UAV 导航、机器人路径规划和控制领域有明确相关性，尤其涉及障碍预测如何连接有限时域路径优化与局部动作筛选。现有证据来自少量仿真场景和单场景消融，足以支持一项领域内模拟结果，但尚未显示更广泛的科学或实地影响。

### Most important issues to resolve before a strong case is established

1. 定义完整的 LSTM–MPC–DWA 方法及其参数，使实现可独立重建（R1-M2、R2-M3、R3-M1）。
2. 说明独立预测评估与闭环测试的训练/验证/测试关系及运动类型覆盖（R2-M2、R3-m3）。
3. 解释无 DWA 安全候选时回退动作的约束、频率和实际结果，避免将经验筛选误读为安全保证（R1-M3、R2-M4、R3-M2）。
4. 将共享时间对齐与安全候选集反馈相对相关规划方法的贡献边界说清（R1-M1、R2-M1、R3-m2）。

## Risk / unsupported claims

- **没有将仿真写成实飞验证。**摘要、讨论和结论明确限定于测试过的模拟设置。
- **碰撞自由应解释为观测到的实验结果，而非理论保证。**MPC 障碍项是软惩罚，DWA 无安全候选时会执行回退动作。
- **新颖性无法由所给稿件自身完全判定。**本次审稿未检索外部先前工作或验证参考文献内容；评价的是稿件如何建立自身差异。
- **预测泛化范围有限定信息。**正文提供训练/验证轨迹数量与运动家族，但未充分说明预测误差所用独立数据及训练、测试运动类型重叠情况。
- **小样本成功率仍是描述性证据。**区间围绕 12 个场景簇，而图和正文还报告了 36 次运行成功次数；读者应按场景而非仅按运行次数理解结果。
