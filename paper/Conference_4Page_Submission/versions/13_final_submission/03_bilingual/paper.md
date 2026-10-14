---
title: "A Shared LSTM Forecast for 3-D UAV Planning with Coupled MPC–DWA in Dynamic Obstacle Fields"
source_pdf: "../02_source/main.pdf"
source_latex: "../02_source/main.tex"
source_type: "LaTeX manuscript; bilingual text follows the current source structure"
paper_type: "IEEE conference paper; three-dimensional UAV planning"
language: "English with complete Chinese translation"
pages: 4
---

# 论文中英对照全文

**底本说明：** 本稿逐段对应当前 02_source/main.tex。主文报告已完成的 7,500 次历史五控制器仿真；另将 4,320 次 Stage-1 记录作为独立的开发集权重选择证据，不与主结果合并。Stage 1 选出的权重未用于历史基准；不报告 Stage-2 或留出评估结果。公式、表格、图注和引用依照英文源文同步。

## 阅读索引

- Title, abstract, and keywords / 题名、摘要与关键词
- I. Introduction / 引言
- II. Problem Formulation / 问题建模
- III. Planning Method / 规划方法
  - Core equations / 核心公式
  - How the shared forecast is used / 共享预测的使用方式
- IV. Simulation and Results / 仿真与结果
- V. Discussion / 讨论
- VI. Conclusion / 结论
- Supplementary Methods clarification / 补充方法说明
- References / 参考文献

### 公式索引

- [E001 · Eq. (1)](#E001)：无人机运动模型与带符号表面间隙
- [E002 · Eq. (2)](#E002)：CV 与 LSTM 障碍物位置预测
- [E003 · Eq. (3)](#E003)：MPC 目标函数与耦合约束
- [E004 · Eq. (4)](#E004)：信任评分与自适应采样预算
- [E005 · Eq. (5)](#E005)：DWA 安全筛选、评分与 MPC 控制包络

## 题名与作者

<a id="S001"></a>
**Source:** 02_source/main.tex, title and author

**Original:** A Shared LSTM Forecast for 3-D UAV Planning with Coupled MPC--DWA in Dynamic Obstacle Fields  
Zhenhui Fu*, Beijing University of Chemical Technology, Beijing 100029, China. *Corresponding author: 2025090094@buct.edu.cn.

**中文:** 动态障碍场中共享 LSTM 预测的三维无人机耦合 MPC–DWA 规划  
作者：Zhenhui Fu*；北京化工大学，中国北京 100029。*通讯作者：2025090094@buct.edu.cn。

## Abstract / 摘要

<a id="S002"></a>
**Source:** 02_source/main.tex, abstract

**Original:** First, 3-D UAV planning is difficult because moving obstacles can turn, accelerate, or pause, making recent positions unreliable. Second, we couple model predictive control (MPC) and the dynamic window approach (DWA) with one causal 30-step long short-term memory (LSTM) forecast. MPC uses it to optimize the route; DWA screens reachable actions and constrains MPC's first command. Then, in the completed simulation of 500 scenes with three matched seeds and 1-s DWA rollouts, shared LSTM achieved 62.4% collision-free arrival. This exceeded DWA-only integration by 6.7 percentage points (95% scene-cluster CI, 4.2--9.2) and a latest-position-hold MPC--DWA reconstruction by 60.2 points (56.2--64.2). Standalone DWA+LSTM and MPC+LSTM reached 82.4% and 95.2%, respectively. Finally, sharing improved the tested integrated planner, but these results do not establish overall superiority.

**中文:** 首先，动态障碍物可能转向、加速或暂停，使近期位置难以可靠预测，增加无人机三维路径规划的难度。其次，我们将模型预测控制（MPC）与动态窗口法（DWA）耦合，并让两层共享同一条因果的 30 步长短期记忆网络（LSTM）预测。MPC 利用该预测优化路线；DWA 筛选可达动作，并约束 MPC 的首个控制指令。然后，在已完成的仿真中，我们对 500 个场景、每个场景三个匹配种子进行测试，DWA 滚动筛选时域为 1 s；共享 LSTM 的无碰撞到达率为 62.4%。该结果比仅向 DWA 输入 LSTM 的集成方法高 6.7 个百分点（按场景聚类的 95% CI：4.2–9.2），比最新位置保持的 MPC–DWA 重构高 60.2 个百分点（56.2–64.2）。独立 DWA+LSTM 和 MPC+LSTM 的到达率分别为 82.4% 和 95.2%。最后，预测共享改善了所测集成规划器，但这些结果不能证明其总体优越性。

<a id="S003"></a>
**Source:** 02_source/main.tex, IEEE keywords

**Original:** UAV, 3D path planning, dynamic obstacles, LSTM, model predictive control, dynamic window approach

**中文:** 无人机；三维路径规划；动态障碍物；长短期记忆网络；模型预测控制；动态窗口法。

## I. Introduction / 引言

<a id="S004"></a>
**Source:** 02_source/main.tex, Introduction, paragraph 1

**Original:** Unmanned aerial vehicles (UAVs) must avoid obstacles that move during flight; turns, acceleration and pauses make recent-position forecasts unreliable. Model predictive control (MPC) optimizes future controls, while the dynamic window approach (DWA) selects an action the vehicle can execute now [1, 2]. Prior UAV work has combined MPC--DWA planning or obstacle-intent prediction with MPC [3, 4]. We test whether one causal long short-term memory (LSTM) forecast improves moving-obstacle planning when shared by both layers rather than supplied to DWA alone.

**中文:** 无人机（UAV）在飞行过程中必须避开移动障碍物；障碍物转向、加速和暂停会使仅依据近期位置作出的预测不可靠。模型预测控制（MPC）优化未来控制序列，而动态窗口法（DWA）选择飞行器当前能够执行的动作 [1, 2]。已有无人机研究将 MPC–DWA 规划结合起来，或将障碍物意图预测与 MPC 结合 [3, 4]。我们检验：与仅向 DWA 提供预测相比，将同一条因果长短期记忆网络（LSTM）预测共享给两个规划层，是否能改善移动障碍物环境中的规划。

## II. Problem Formulation / 问题建模

<a id="S005"></a>
**Source:** 02_source/main.tex, Problem Formulation

**Original:** We model the UAV as a collision sphere in a bounded 3-D workspace with a start, goal and moving spherical obstacles. Each obstacle has an observed center, radius and time-varying path; future ground-truth positions are hidden from the planner. At each update, it chooses a dynamically feasible action to reach the goal without intersecting an obstacle along the simulated motion. Figure 1 shows the scene geometry; recorded planner paths are compared separately.

**中文:** 我们将无人机建模为一个碰撞球体，在有界三维工作空间内从起点飞向目标，并避让球形移动障碍物。每个障碍物具有观测到的中心、半径和随时间变化的路径；规划器无法获知其未来真实位置。每次更新时，规划器选择满足动力学可行性的动作，以便到达目标且在仿真运动过程中不与障碍物相交。图 1 展示场景几何；记录到的规划器路径另行比较。

<a id="F001"></a>
### Figure 1 / 图 1：问题几何示意

![三维问题几何示意：无人机从起点朝目标移动，球形障碍物沿预设路径运动](assets/Fig1_scenario.png)

<a id="C001"></a>
**Original caption:** Problem geometry: the quadrotor is centered at the start and moves toward the goal among spherical obstacles following prescribed paths (arrows). The dashed line marks the direct start-to-goal direction, not a simulated route; planner trajectories appear separately in Figure 2.

**中文图注：** 问题几何：四旋翼无人机以起点为中心位置，朝目标移动；球形障碍物沿预设路径运动（箭头所示）。虚线表示起点到目标的直达方向，并非仿真路线；规划器轨迹另见图 2。

## III. Planning Method / 规划方法

<a id="S006"></a>
**Source:** 02_source/main.tex, Planning Method, introductory paragraph

**Original:** With the task geometry defined, we use one causal obstacle forecast to connect route optimization with locally reachable action selection.

**中文:** 明确任务几何后，我们使用同一条因果障碍物预测，将路线优化与局部可达动作选择连接起来。

### Core equations / 核心公式

<a id="S007"></a>
**Source:** 02_source/main.tex, Core equations, introductory paragraph

**Original:** The vehicle model, causal obstacle forecasts, MPC objective and DWA coupling are collected here. The first four relations update position, speed and attitude; the final relation defines signed surface clearance:

**中文:** 这里汇总飞行器模型、因果障碍物预测、MPC 目标函数以及 DWA 耦合关系。前四个关系更新位置、速度和姿态，最后一个关系定义带符号表面间隙：

<a id="E001"></a>
**Source:** 02_source/main.tex, Eq. (1), eq:model

$$
\begin{aligned}
\mathbf p_{t+1}&=\mathbf p_t+\Delta t\,v_t[\cos\theta_t\cos\psi_t,\cos\theta_t\sin\psi_t,\sin\theta_t]^{\mathsf T},\\
v_{t+1}&=v_t+\frac{\Delta t}{\tau_v}(v_{c,t}-v_t),\\
\theta_{t+1}&=\theta_t+\Delta t\,\omega_{\theta,t},\quad
\psi_{t+1}=\psi_t+\Delta t\,\omega_{\psi,t},\\
\hat d_{j,k}&=\|\mathbf p_{t+k|t}-\hat{\mathbf o}_{j,t+k|t}\|_2-r_u-r_j.
\end{aligned}
$$

<a id="S008"></a>
**Source:** 02_source/main.tex, paragraph after Eq. (1)

**Original:** In (1), $t$ and $k$ denote current and future steps; $j=1,\ldots,M$ indexes the $M$ obstacles. The UAV position, speed, pitch and yaw are $\mathbf p$, $v$, $\theta$ and $\psi$; commands $v_c$, $\omega_\theta$ and $\omega_\psi$ set speed and angular rates. The update interval is $\Delta t$, $\tau_v$ is the speed-response time, $r_u$ is the UAV radius and $r_j$ is obstacle $j$'s radius. Thus $\hat d_{j,k}$ is signed surface clearance: positive means separated, zero contact and negative overlap.

**中文:** 在式（1）中，$t$ 和 $k$ 分别表示当前步与未来步；$j=1,\ldots,M$ 为 $M$ 个障碍物的索引。无人机的位置、速度、俯仰角和偏航角分别为 $\mathbf p$、$v$、$\theta$ 和 $\psi$；指令 $v_c$、$\omega_\theta$ 和 $\omega_\psi$ 分别设定速度及角速度。更新间隔为 $\Delta t$，$\tau_v$ 为速度响应时间，$r_u$ 为无人机半径，$r_j$ 为障碍物 $j$ 的半径。因此，$\hat d_{j,k}$ 是带符号表面间隙：正值表示分离，零表示接触，负值表示重叠。

<a id="S009"></a>
**Source:** 02_source/main.tex, paragraph introducing CV and LSTM forecasts

**Original:** The constant-velocity (CV) baselines extrapolate from the two latest observed positions; at startup, when only one position is available, the initial velocity is set to zero. A separate latest-position-hold baseline keeps the latest observed center fixed over the forecast horizon. The causal LSTM [5] maps ten consecutive observations to thirty three-dimensional offsets from the latest position:

**中文:** 恒定速度（CV）基线根据最近两次观测位置进行外推；启动时若只有一次位置观测，则初始速度设为零。另一个独立的最新位置保持基线则在整个预测时域内固定使用最近观测到的中心位置。因果 LSTM [5] 将连续十次观测映射为以最新位置为基准的 30 个三维偏移量：

<a id="E002"></a>
**Source:** 02_source/main.tex, Eq. (2), eq:forecast

$$
\begin{aligned}
\hat{\mathbf v}_{j,t}&=(\mathbf o^{\rm obs}_{j,t}-\mathbf o^{\rm obs}_{j,t-1})/\Delta t,\\
\hat{\mathbf o}^{\rm CV}_{j,t+k|t}&=\mathbf o^{\rm obs}_{j,t}+k\Delta t\,\hat{\mathbf v}_{j,t},\\
\mathbf q_{j,s}&=[(\mathbf o^{\rm obs}_{j,s})^{\mathsf T},(\mathbf v^{\rm obs}_{j,s})^{\mathsf T},\cos\chi_{j,s},\sin\chi_{j,s}]^{\mathsf T},\\
\hat{\boldsymbol\delta}_{j,t+1:t+30|t}&=f_{\Theta}(\mathbf q_{j,t-9:t}),\\
\hat{\mathbf o}^{\rm LSTM}_{j,t+k|t}&=\mathbf o^{\rm obs}_{j,t}+\hat{\boldsymbol\delta}_{j,t+k|t}.
\end{aligned}
$$

<a id="S010"></a>
**Source:** 02_source/main.tex, paragraph after Eq. (2)

**Original:** In (2), $s$ indexes history samples; $\mathbf q$ contains eight features (3-D position, 3-D velocity, and sine/cosine of heading $\chi$), and $f_\Theta$ is the trained LSTM with learned parameters $\Theta$. Ten observations span 0.9 s; the LSTM predicts 30 offsets, each anchored to the latest observed center rather than cumulatively summed. At startup, the earliest available state fills missing history. The forecast is causal: at planning time $t$, the network receives only observations through $t$. The benchmark compares configured controllers: LSTM receives simulated position, velocity and heading, whereas CV extrapolates the latest two observed positions. Training details are in Supplementary Methods.

**中文:** 在式（2）中，$s$ 表示历史采样索引；$\mathbf q$ 含八个特征（三维位置、三维速度，以及航向角 $\chi$ 的正弦和余弦），$f_\Theta$ 表示经训练且具有学习参数 $\Theta$ 的 LSTM。十次观测覆盖 0.9 s；LSTM 预测 30 个偏移量，每个偏移量均以最新观测中心为基准，而不是逐步累加。系统启动时，以最早可用状态填补缺失历史。该预测具有因果性：在规划时刻 $t$，网络仅接收截至 $t$ 的观测。基准比较的是配置后的控制器：LSTM 接收仿真位置、速度和航向，CV 则根据最近两次观测位置进行外推。训练细节见补充方法。

<a id="S011"></a>
**Source:** 02_source/main.tex, paragraph introducing the MPC objective and coupling

**Original:** In the shared-LSTM arm, the same time-aligned forecast reaches both layers: MPC uses it over the route horizon, and DWA screens reachable actions against it. The historical DWA-only ablation supplies LSTM to DWA and holds the latest obstacle positions in MPC, isolating the effect of forecast sharing within this implementation. MPC represents obstacle safety with soft penalties, so DWA also applies explicit clearance, corridor and braking gates. The MPC objective and coupling constraints are:

**中文:** 在共享 LSTM 条件下，同一条与时间步对齐的预测输入 MPC 和 DWA：MPC 用它优化规划时域，DWA 用它筛选可达动作。历史 DWA-only 消融仅向 DWA 输入 LSTM，并在 MPC 中保持障碍物的最新位置，从而检验这一实现中共享预测的作用。MPC 对障碍物使用软惩罚，因此 DWA 还执行显式间隙、飞行走廊与制动筛查。MPC 目标函数与耦合约束如下：

<a id="E003"></a>
**Source:** 02_source/main.tex, Eq. (3), eq:mpc

$$
\begin{aligned}
\mathbf a&=\mathbf g-\mathbf s,\\
\eta_{\mathbf a}&=\mathbf a^{\mathsf T}\mathbf a+10^{-12}\,\mathrm m^2,\\
P_{\mathbf a}&=I_3-\frac{\mathbf a\mathbf a^{\mathsf T}}{\eta_{\mathbf a}},\\
\mathbf e_{t+k|t}^{\perp}&=P_{\mathbf a}(\mathbf p_{t+k|t}-\mathbf s),\\
J_r&=\sum_{k=1}^{30}\|\mathbf e_{t+k|t}^{\perp}\|_2^2,\\
\min_{\mathbf u_1,\ldots,\mathbf u_{30}}\ J_{\rm MPC}={}&\sum_{k=0}^{29}w_p\|\mathbf p_{t+k|t}-\mathbf g\|_2^2\\
&+\sum_{k=1}^{30}w_u\|\mathbf u_k\|_2^2\\
&+w_f\|\mathbf p_{t+30|t}-\mathbf g\|_2^2+w_rJ_r\\
&+w_{\Delta u}\sum_{k=2}^{30}\|\mathbf u_k-\mathbf u_{k-1}\|_2^2\\
&+\sum_{k=1}^{30}\sum_{j=1}^{M}w_o[-\hat d_{j,k}]_+^2\\
&+\sum_{k=1}^{30}\sum_{j=1}^{M}w_s[d_{\rm soft}-\hat d_{j,k}]_+^2,\\
&\text{subject to }\mathbf x_{t|t}=\mathbf x_t,\\
&\mathbf x_{t+k|t}=f(\mathbf x_{t+k-1|t},\mathbf u_k),\\
&\qquad k=1,\ldots,30,\\
&\mathbf u_1\in\mathcal U_t\quad\text{when }\mathcal A_t\ne\varnothing,\\
&|\mathbf u_k-\mathbf u_{k-1}|\preceq\mathbf a_u\Delta t,\\
&\qquad k=1,\ldots,30.
\end{aligned}
$$

<a id="S012"></a>
**Source:** 02_source/main.tex, paragraph after Eq. (3)

**Original:** Here $\mathbf x_t=[\mathbf p_t^{\mathsf T},\theta_t,\psi_t,v_t]^{\mathsf T}$ is the position--pitch--yaw--speed state; $f$ is defined by the first four state-update relations in (1). The MPC command is $\mathbf u_k=[v_c,\omega_\theta,\omega_\psi]^{\mathsf T}$; $\mathbf u_0$ is the last applied DWA command and $\mathbf a_u$ gives componentwise rate limits. The start and goal are $\mathbf s,\mathbf g$, and $\mathbf a=\mathbf g-\mathbf s$ is the route vector. The scalar $\eta_{\mathbf a}$ is its squared length plus the implementation's $10^{-12}\,\mathrm m^2$ numerical safeguard; $P_{\mathbf a}$ is the resulting regularized cross-track operator, and $J_r$ penalizes the residual distance from the direct line. $I_3$ is the 3-D identity. The index $k$ runs over the prediction horizon and $\hat d_{j,k}$ is signed clearance for obstacle $j$. Weights $w_p,w_u,w_f,w_r,w_{\Delta u},w_o,w_s$ penalize, respectively, stage goal distance, control effort, terminal distance, route deviation, command changes, overlap and clearance below $d_{\rm soft}=0.35$ m. The positive-part operator is $[x]_+=\max(0,x)$. Controls retain their native units; numerical weights and physical speed and angular-rate command limits are given in Supplementary Methods. The MPC solver imposes no separate state-box bounds. When the normal safe set $\mathcal A_t$ is nonempty, its passing actions provide componentwise bounds $\mathcal U_t$ for MPC's first input; this box constrains MPC but is not itself a safety certificate for every enclosed action.

**中文:** 这里，$\mathbf x_t=[\mathbf p_t^{\mathsf T},\theta_t,\psi_t,v_t]^{\mathsf T}$ 是由位置、俯仰角、偏航角和速度组成的状态；$f$ 由式（1）中前四个状态更新关系定义。MPC 指令为 $\mathbf u_k=[v_c,\omega_\theta,\omega_\psi]^{\mathsf T}$；$\mathbf u_0$ 是最近一次实际执行的 DWA 指令，$\mathbf a_u$ 给出各分量的变化率限值。起点和目标分别为 $\mathbf s,\mathbf g$，$\mathbf a=\mathbf g-\mathbf s$ 是起点到目标的路线向量。标量 $\eta_{\mathbf a}$ 是路线长度平方加上实现中的 $10^{-12}\,\mathrm m^2$ 数值保护项；$P_{\mathbf a}$ 是相应的正则化横向偏差算子，$J_r$ 惩罚预测位置到直达路线的横向残差。$I_3$ 是三维单位矩阵。索引 $k$ 遍历预测时域，$\hat d_{j,k}$ 是相对于障碍物 $j$ 的带符号间隙。权重 $w_p,w_u,w_f,w_r,w_{\Delta u},w_o,w_s$ 依次惩罚阶段目标距离、控制消耗、终端距离、路线偏差、指令变化、重叠以及低于 $d_{\rm soft}=0.35$ m 的间隙。正部算子为 $[x]_+=\max(0,x)$。控制量保留各自的原生单位；数值权重以及速度和角速度指令的物理限值列于补充方法。MPC 求解器不设置单独的状态盒约束。当普通安全集 $\mathcal A_t$ 非空时，通过筛选的动作提供分量级边界 $\mathcal U_t$，用于约束 MPC 的首个输入；该控制盒会约束 MPC，但并不构成对盒内每个动作的安全保证。

<a id="S013"></a>
**Source:** 02_source/main.tex, trust-score introduction

**Original:** Trust score $\tau$ combines predicted safety, goal progress, agreement with the previous MPC guide, and control smoothness. It sets the sample budget and guided/exploratory split. Components and weights lie in $[0,1]$; weights sum to one.

**中文:** 信任评分 $\tau$ 综合预测安全性、目标推进、与上一轮 MPC 引导路线的一致程度以及控制平滑性。它用于设定采样预算，并划分引导采样与探索采样。各评分分量和权重均在 $[0,1]$ 内，权重之和为 1。

<a id="E004"></a>
**Source:** 02_source/main.tex, Eq. (4), eq:trust

$$
\begin{aligned}
\tau&=\sigma_s\tau_{\rm sa}+\sigma_g\tau_g\\
&+\sigma_t\tau_{\rm ref}+\sigma_m\tau_{\rm sm},\\
\tau_{\rm ref}&=\exp(-\alpha_T\Delta_p),\\
B&=\operatorname{round}[300(1+\alpha e^{-\beta\tau})],\\
B_g&=\operatorname{round}(B\tau),\quad B_e=B-B_g.
\end{aligned}
$$

<a id="S014"></a>
**Source:** 02_source/main.tex, paragraph after Eq. (4)

**Original:** In \eqref{eq:trust}, $\sigma_s,\sigma_g,\sigma_t,\sigma_m$ weight safety, goal progress, reference tracking and smoothness; they sum to one, and $\sigma_t$ denotes tracking rather than time. At startup, scores use the initial MPC solution; later they use the shifted route and controls. The four scores measure clearance-based safety, route progress, agreement with the previous route's first point, and control smoothness. The mismatch $\Delta_p=\|\mathbf p_t-\mathbf p_{\mathrm{ref},1|t-1}\|_2$ makes $\tau_{\rm ref}$ decrease as the UAV departs from the previous guide; the implementation calls this score $\tau_t$. The historical benchmark retained inherited weights $[0.35,0.30,0.15,0.20]$, not tuned on its 500 scenes. A separate 4,320-episode development sweep (six vectors, five integrated branches, 48 scenes and three matched seeds) selected $[0.15,0.15,0.15,0.55]$, with equal-arm macro-average collision-free arrival of 0.8042 (branch rates in Supplementary Methods S1.2). Because the same runs selected the vector, this score is descriptive, not held-out evidence; the selected weights were not applied to the historical benchmark. Both protocols used $\alpha_T=3$ m$^{-1}$ and dimensionless $\beta=3$. $B$ is split into MPC-guided ($B_g$) and exploratory ($B_e$) samples, and the clipped MPC command is also tested. The dimensionless budget gain $\alpha=1$ is distinct from $\alpha_T$; higher trust reduces exploration and sample count, 300 is the base budget, and $\beta$ sets sensitivity.

**中文:** 在式（4）中，$\sigma_s$、$\sigma_g$、$\sigma_t$ 和 $\sigma_m$ 分别对安全性、目标推进、参考跟踪和控制平滑性加权，且权重和为 1；$\sigma_t$ 表示跟踪项而非时间。启动时，各评分使用初始 MPC 解；之后使用移位后的路线和控制序列。四个分项分别衡量基于间隙的安全性、路线推进、当前位置与上一条参考路线首个预测点的一致程度，以及控制平滑性。$\Delta_p=\|\mathbf p_t-\mathbf p_{\mathrm{ref},1|t-1}\|_2$ 表示无人机偏离上一条参考路线的程度，偏离越大，$\tau_{\rm ref}$ 越低；代码中该分数命名为 $\tau_t$。历史基准沿用了权重 $[0.35,0.30,0.15,0.20]$，没有在其 500 个场景上调参。另有一项 4,320 次仿真的开发集校准：六组权重在五个集成分支、48 个场景和每场景三个匹配种子上评估，选出 $[0.15,0.15,0.15,0.55]$，等权宏平均无碰撞到达率为 0.8042（各分支开发率见补充方法 S1.2）。由于这些数据用于选权重，该数值是开发集描述统计，不是留出验证；所选权重没有回用于历史基准。两个实验中 $\alpha_T=3$ m$^{-1}$，$\beta=3$ 且无量纲。$B$ 分为 MPC 引导样本 $B_g$ 和探索样本 $B_e$，裁剪后的 MPC 指令也加入候选。无量纲预算增益 $\alpha=1$ 与 $\alpha_T$ 不同；信任度越高，探索和样本总数越少，基础预算为 300，$\beta$ 控制预算敏感度。

<a id="S015"></a>
**Source:** 02_source/main.tex, DWA screening and scoring introduction

**Original:** DWA rejects candidate $b$ unless its rollout meets the clearance, flight-corridor and braking checks. It ranks the remaining actions and bounds the MPC first control using their componentwise control limits:

**中文:** 除非候选动作 $b$ 的滚动轨迹通过间隙、飞行走廊和制动检查，否则 DWA 会将其剔除。随后，DWA 对剩余动作排序，并依据其各控制分量的范围约束 MPC 的首个控制量：

<a id="E005"></a>
**Source:** 02_source/main.tex, Eq. (5), eq:dwa

$$
\begin{aligned}
\mathcal A_t&=\{b:d_{\min}^{(b)}>0.25~\mathrm m,\ \mathcal C_b=1,\\
&\hspace{1em}(v_{\rm end}^{(b)})^2\leq2a_{\max}d_{\min}^{(b)}\},\\
S_b&=w_p^{\mathrm{DWA}}S_{p,b}+w_h^{\mathrm{DWA}}S_{h,b}\\
&+w_v^{\mathrm{DWA}}S_{v,b}+w_o^{\mathrm{DWA}}S_{o,b}+w_zS_{z,b},\\
b^*&=\arg\max_{b\in\mathcal A_t}S_b,\\
u_{i,t}^{-}&=\max(u_i^{\min},\min_{b\in\mathcal A_t}u_i^{(b)}-\delta),\\
u_{i,t}^{+}&=\min(u_i^{\max},\max_{b\in\mathcal A_t}u_i^{(b)}+\delta),\\
\mathcal U_t&=\prod_{i=1}^{3}[u_{i,t}^{-},u_{i,t}^{+}].
\end{aligned}
$$

<a id="S016"></a>
**Source:** 02_source/main.tex, paragraph after Eq. (5)

**Original:** In (5), candidate $b$ passes when its discrete predicted clearance $d_{\min}^{(b)}>0.25$ m, corridor flag $\mathcal C_b=1$ and braking test pass; $v_{\rm end}^{(b)}$ and $a_{\max}$ are terminal speed and available deceleration. Scores $S_p,S_h,S_v,S_o$ measure MPC-endpoint agreement, heading agreement, speed tracking with a forward-speed reward, and normalized obstacle clearance; $S_z$ penalizes vertical-profile deviation. Trust-dependent weights on the first four scores sum to one; $w_z=0.25$ is fixed and not renormalized. The margin $\delta=0.1$ expands the screened candidates' componentwise command ranges; $i$ indexes speed, pitch rate and yaw rate, and $u_i^{\min},u_i^{\max}$ are physical limits. The top-scoring safe candidate is normally applied. A yaw-rate correction is triggered when the selected rollout's minimum predicted clearance exceeds 1.0 m while the UAV's current horizontal cross-track offset from the start--goal line exceeds 0.5 m; the adjusted command is re-screened by the same clearance, corridor and braking tests, and the original safe command is restored if it fails. Collision outcomes are independently checked on continuous swept paths. If the normal set is empty, the emergency branch is screened and the run stops if none passes. Full score formulas and settings are in Supplementary Methods.

**中文:** 在式（5）中，候选动作满足离散预测间隙 $d_{\min}^{(b)}>0.25$ m、走廊标志 $\mathcal C_b=1$ 且通过制动检查时，才被保留；$v_{\rm end}^{(b)}$ 和 $a_{\max}$ 分别表示末端速度和可用减速度。评分 $S_p,S_h,S_v,S_o$ 分别衡量与 MPC 端点的一致程度、航向一致性、速度跟踪及前向速度奖励、以及归一化障碍物间隙；$S_z$ 惩罚垂直剖面偏差。前四项评分的信任度相关权重之和为 1；固定权重 $w_z=0.25$ 不再归一化。裕度 $\delta=0.1$ 用于扩展通过筛查的候选动作在各控制分量上的范围；$i$ 索引速度、俯仰角速度和偏航角速度，$u_i^{\min},u_i^{\max}$ 为物理限值。通常执行得分最高的安全候选动作。若所选滚动轨迹的最小预测间隙超过 1.0 m，且当前无人机位置相对起点—目标线的水平横向偏移超过 0.5 m，则触发偏航角速度修正，使航向转向目标方向；修正后的指令会再次接受相同的间隙、走廊和制动检查，若未通过则恢复原安全指令。碰撞结果另依据连续扫掠路径独立检查。若普通安全集为空，则筛查应急分支；若没有应急动作通过，运行即停止。完整评分公式与设置见补充方法。

### How the shared forecast is used / 共享预测的使用方式

<a id="S017"></a>
**Source:** 02_source/main.tex, How the shared forecast is used

**Original:** At startup, an unconstrained MPC route initializes DWA. At each 0.1-s update, the same 30-step LSTM forecast informs MPC's route optimization and DWA's reachable-action rollouts. In the reported historical benchmark, MPC used all 30 steps (3 s), while DWA screened the first 10 (1 s). DWA selects the action to execute; when its normal safe set is nonempty, the expanded candidate box constrains MPC's first command on re-solve, and that updated route guides the next DWA search. Thus, sharing links route-level anticipation with local action screening. The fallback sequence is in Supplementary Methods S1.4.

**中文:** 启动时，先用无约束 MPC 路线初始化 DWA。在每个 0.1 s 更新周期，同一条 30 步 LSTM 预测同时用于 MPC 路线优化和 DWA 可达动作滚动评估。在本文报告的历史基准中，MPC 使用全部 30 步（3 s），DWA 筛查前 10 步（1 s）。DWA 选择实际执行的动作；当普通安全集非空时，扩展候选控制盒会在 MPC 重求解时约束首个指令，更新后的路线再用于引导下一次 DWA 搜索。因此，共享预测将路线级前瞻与局部动作筛查连接起来。回退顺序见补充方法 S1.4。

## IV. Simulation and Results / 仿真与结果

<a id="S018"></a>
**Source:** 02_source/main.tex, Simulation and Results, opening paragraph

**Original:** We report the completed historical five-controller simulation. The bounded workspace measured $20\times20\times10$ m; the start was $(1,1,1)$ m and the goal $(18,18,8)$ m. Controllers updated every 0.1 s, with a 650-step limit. Five methods were tested in 500 mixed-motion scenes with three matched seeds (1,500 runs per method); DWA screened 1-s rollouts and MPC retained a 30-step horizon. The no-forecast controller was a project-local latest-position-hold reconstruction, not an exact reproduction of the cited MPC--DWA method. In the DWA-only integrated arm, LSTM informed DWA while MPC held obstacle positions; the shared arm used LSTM in both layers. Standalone controllers are contextual comparisons, not matched tests of forecast allocation. Collision-free arrival was scored from continuous piecewise-linear swept paths; paired differences used 20,000 scene-cluster bootstrap draws. Historical CV/Kalman studies and full settings are in the supplement. Figure 2 shows a matched example; Table 1 summarizes outcomes.

**中文:** 本文报告已完成的历史五控制器仿真。工作空间为 $20\times20\times10$ m，起点为 $(1,1,1)$ m，目标为 $(18,18,8)$ m。控制器每 0.1 s 更新一次，最多运行 650 步。五种方法在 500 个混合运动场景和三个匹配种子上测试（每种方法 1,500 次）；DWA 筛查 1 s 滚动轨迹，MPC 保留 30 步时域。无预测控制器是项目内构建的最新位置保持 MPC–DWA 重构，并非对所引算法的精确复现。DWA-only 集成组在 DWA 中使用 LSTM、在 MPC 中保持障碍物位置；共享组则在两层中都使用 LSTM。独立控制器作为背景对照，不是隔离预测分配效应的匹配消融。无碰撞到达依据连续分段线性扫掠路径判定；配对差异使用 20,000 次按场景聚类的 bootstrap 抽样。历史 CV/Kalman 研究和完整设置见补充材料。图 2 展示一个匹配示例，表 1 汇总总体结果。

<a id="F002"></a>
### Figure 2 / 图 2：历史五控制器路径示例

![历史五控制器/1 s 筛查评估中，场景 404、种子 2 的匹配三维路径](assets/route_comparison.svg)

<a id="C002"></a>
**Original caption:** Historical five-controller routes from the completed 1-s DWA-screening evaluation in matched scene 404, seed 2. The five recorded 3-D paths end at their logged terminal states: the latest-position-hold MPC--DWA reconstruction (collision recorded, step 224); standalone DWA + LSTM (stopped, step 20); standalone MPC + LSTM (collision recorded, step 262); integrated DWA-only LSTM (stopped, step 220); and shared LSTM (collision-free arrival, step 253). Only the shared controller arrived in this illustrative case; Table~\ref{tab:main_results} reports aggregate outcomes. Dashed lines show the saved obstacle tracks through step 262. Endpoint markers show the logged terminal states: circle, arrival; square, non-collision stop; X, swept collision somewhere along the run, not at the marker.

**中文图注：** 已完成的 1 s DWA 筛查历史评估中，场景 404、种子 2 的五条记录三维路径均以日志记录的终止状态为终点：最新位置保持的 MPC–DWA 重构（记录到碰撞，第 224 步）；独立 DWA + LSTM（停止，第 20 步）；独立 MPC + LSTM（记录到碰撞，第 262 步）；仅向 DWA 提供 LSTM 的集成方法（停止，第 220 步）；以及共享 LSTM（无碰撞到达，第 253 步）。在该示例中只有共享控制器到达目标；汇总结果见表 1。虚线表示保存的障碍物轨迹，绘制至第 262 步。端点标记表示日志记录的终止状态：圆形表示到达，方形表示无碰撞停止，X 表示运行过程中某处发生扫掠碰撞，而非标记所在位置发生碰撞。

<a id="S019"></a>
**Source:** 02_source/main.tex, first results paragraph

**Original:** Shared LSTM reached without collision in 936/1,500 runs (62.4%), compared with 33/1,500 (2.2%) for the no-forecast reconstruction and 836/1,500 (55.7%) for DWA-only integration. The paired gains were 60.2 points (95% scene-cluster CI, 56.2 to 64.2) and 6.7 points (4.2 to 9.2), respectively.

**中文:** 共享 LSTM 在 1,500 次运行中有 936 次无碰撞到达（62.4%）；无预测重构为 33/1,500 次（2.2%），DWA-only 集成为 836/1,500 次（55.7%）。与两者相比，共享方法的配对增幅分别为 60.2 个百分点（按场景聚类的 95% CI：56.2 至 64.2）和 6.7 个百分点（4.2 至 9.2）。

<a id="S020"></a>
**Source:** 02_source/main.tex, second results paragraph

**Original:** Standalone DWA and MPC reached 82.4% and 95.2%, respectively. Shared integration was lower by 20.0 points versus DWA (95% CI, -24.8 to -15.1) and 32.8 points versus MPC (-37.1 to -28.5); these separate implementations provide context, not a matched forecast-allocation contrast.

**中文:** 独立 DWA 和 MPC 的到达率分别为 82.4% 和 95.2%。共享集成方法分别低 20.0 个百分点（相对 DWA 的 95% CI：−24.8 至 −15.1）和 32.8 个百分点（相对 MPC：−37.1 至 −28.5）；这些独立实现仅作背景对照，并非对预测分配效应的匹配比较。

<a id="T001"></a>
### Table 1 / 表 1：历史五控制器结果

**Original caption:** Collision-free arrival and swept collisions in the completed historical study (1,500 runs per method). The no-forecast MPC--DWA is a project-local latest-position-hold reconstruction, not an exact reproduction.

**中文表注：** 已完成的历史研究中，每种方法各运行 1,500 次；表中列出无碰撞到达和扫掠碰撞。无预测 MPC–DWA 是项目内构建的最新位置保持重构，并非精确复现。

| Controller / 控制器 | Goal without collision / 无碰撞到达目标 | Swept collision runs / 扫掠碰撞运行次数 |
|---|---:|---:|
| MPC–DWA reconstruction (position hold) / MPC–DWA 重构（位置保持） | 33/1,500 (2.2%) | 624 (41.6%) |
| Integrated MPC–DWA (LSTM to DWA only) / 集成 MPC–DWA（仅 DWA 使用 LSTM） | 836/1,500 (55.7%) | 2 (0.13%) |
| **Integrated MPC–DWA (shared LSTM) / 集成 MPC–DWA（共享 LSTM）** | **936/1,500 (62.4%)** | **0 (0%)** |
| Standalone DWA + LSTM / 独立 DWA + LSTM | 1,236/1,500 (82.4%) | 0 (0%) |
| Standalone MPC + LSTM / 独立 MPC + LSTM | 1,428/1,500 (95.2%) | 36 (2.4%) |

<a id="S021"></a>
## V. Discussion / 讨论

**Source:** 02_source/main.tex, Discussion, paragraph 1

**Original:** Within integrated MPC--DWA, sharing the forecast improved collision-free arrival over DWA-only input and the local no-forecast reconstruction. The independent controllers reached more often, so overall superiority is not established. Evidence is limited to prescribed simulated tracks, point forecasts and a 1-s DWA screen; there was no real-flight validation.

**中文:** 在集成 MPC–DWA 内部，共享预测使无碰撞到达率高于仅向 DWA 输入 LSTM 的方法及项目内无预测位置保持重构。独立控制器的到达率更高，因此结果不能证明总体优越性。现有证据仅来自预设障碍物轨迹、点预测和 1 s DWA 筛查的仿真；尚无真实飞行验证。

## VI. Conclusion / 结论

<a id="S023"></a>
**Source:** 02_source/main.tex, Conclusion

**Original:** In the tested simulation, a shared causal LSTM forecast improved collision-free arrival within integrated MPC--DWA relative to DWA-only and position-hold inputs, but not relative to the standalone controllers. This bounded result under 1-s DWA screening does not establish overall or real-flight superiority.

**中文:** 在所测仿真中，共享同一条因果 LSTM 预测的集成 MPC–DWA，其无碰撞到达率高于仅向 DWA 输入预测和保持障碍物最新位置的重构，但低于独立 DWA 和独立 MPC。该结论仅适用于 1 s DWA 筛查下的仿真结果，不能据此证明方法整体最优，也不代表真实飞行表现。

## Supplementary Methods clarification / 补充方法说明

<a id="S024"></a>
**Source:** ../03_supplementary/supplementary_methods.tex, S1.2–S1.3

**Original:** Smoothness uses consecutive MPC control increments $\Delta\mathbf u_k=\mathbf u_k-\mathbf u_{k-1}$. The score is $\tau_{\rm sm}=\operatorname{clip}_{[0,1]}\!\left[1-\frac{1}{3(N-1)}\sum_{i=1}^{3}\sum_{k=2}^{N}\frac{|\Delta u_{k,i}|}{a_{u,i}\Delta t}\right]$.

Here $i$ indexes desired speed, pitch rate and yaw rate; $N=30$, $\Delta t=0.1$ s, and $\mathbf a_u=[1~\mathrm{m\,s^{-2}},\ 0.5~\mathrm{rad\,s^{-2}},\ 0.5~\mathrm{rad\,s^{-2}}]^{\mathsf T}$. At startup, the initial MPC solution initializes the aligned reference and control sequence; thereafter, the preceding solution is shifted before the trust scores are computed. Guided controls are sampled within $r_{\rm Guide}=0.35$ per control component of the clipped MPC command, then clipped to the dynamic window. The logistic map is $q=[1+\exp(-8(\tau-0.5))]^{-1}$. The half-width 0.35, slope 8, midpoint 0.5 and additive vertical-score coefficient $w_z=0.25$ are fixed implementation heuristics, held constant in every integrated arm that uses them and not selected using held-out outcomes. The half-width uses native control units ($\mathrm{m\,s^{-1}}$ for speed and $\mathrm{rad\,s^{-1}}$ for pitch and yaw rates); slope and midpoint are dimensionless. The $w_z$ term is added after the four normalized DWA weights and is not renormalized with them.

**中文:** 平滑度分量使用相邻 MPC 控制量的增量 $\Delta\mathbf u_k=\mathbf u_k-\mathbf u_{k-1}$。其评分定义为 $\tau_{\rm sm}=\operatorname{clip}_{[0,1]}\!\left[1-\frac{1}{3(N-1)}\sum_{i=1}^{3}\sum_{k=2}^{N}\frac{|\Delta u_{k,i}|}{a_{u,i}\Delta t}\right]$。其中，$i$ 依次表示期望速度、俯仰角速度和偏航角速度；$N=30$，$\Delta t=0.1$ s，且 $\mathbf a_u=[1~\mathrm{m\,s^{-2}},\ 0.5~\mathrm{rad\,s^{-2}},\ 0.5~\mathrm{rad\,s^{-2}}]^{\mathsf T}$。启动时，以初始 MPC 解初始化对齐后的参考路线与控制序列；此后在计算信任评分前，对上一周期解进行时移。引导控制在裁剪后的 MPC 指令周围按每个控制分量的 $r_{\rm Guide}=0.35$ 半宽采样，随后裁剪到动态窗口内。逻辑映射为 $q=[1+\exp(-8(\tau-0.5))]^{-1}$。半宽 0.35、斜率 8、中点 0.5 和附加垂直评分系数 $w_z=0.25$ 均为固定实现启发式参数；所有使用这些参数的集成分支均保持不变，且未依据留出结果选择。半宽采用各控制量的原生单位（速度为 $\mathrm{m\,s^{-1}}$，俯仰和偏航角速度为 $\mathrm{rad\,s^{-1}}$）；斜率和中点无量纲。$w_z$ 项在四个归一化 DWA 权重之后加入，且不与它们一起重新归一化。

<a id="S025"></a>
**Source:** ../scripts/run_v12a_pooled_weight_development.m:123,164; ../04_review/v12a_stage1_recovery_audit_20261014.md:5,9,13

**Original:** The Stage-1 trust-weight calibration evaluated six candidate vectors across five trust-using integrated MPC--DWA branches, 48 development scenes and three matched seeds ($6\times5\times48\times3=4{,}320$ simulation episodes). The selected vector $[0.15,0.15,0.15,0.55]$ had an equal-arm macro-average collision-free arrival rate of 0.8042. Development rates were 0.8958 for shared LSTM, 0.7431 for CV-coupled MPC--DWA, 0.8194 for LSTM-to-MPC-only, 0.8958 for LSTM-to-DWA-only and 0.6667 for latest-position hold. These are selection-set descriptions, not held-out comparisons. The earlier 864-episode six-setting comparison used a different protocol and was not reused; a separate recovery audit validated all 4,320 Stage-1 episode records without creating new simulations.

**中文:** 阶段 1 信任权重校准在五种使用信任评分的集成 MPC--DWA 分支、48 个开发场景和每场景 3 个匹配种子上评估六个候选向量（$6\times5\times48\times3=4{,}320$ 次仿真）。选出的向量为 $[0.15,0.15,0.15,0.55]$，其五分支等权宏平均无碰撞到达率为 0.8042。开发率分别为：共享 LSTM 0.8958、CV 耦合 MPC--DWA 0.7431、仅 MPC 使用 LSTM 0.8194、仅 DWA 使用 LSTM 0.8958、最新位置保持 0.6667。这些是用于选参的开发集描述值，不是留出对比结果。此前 864 次六设置实验采用不同协议，未用于本次选择；单独的恢复审计对全部 4,320 条记录进行了校验，没有新增仿真。

## References / 参考文献

以下五条文献对应当前英文源文中的引用顺序；出版信息和文献原始标题保留英文。

1. <a id="R001"></a> Mayne, D. Q., Rawlings, J. B., Rao, C. V. & Scokaert, P. O. M. Constrained model predictive control: Stability and optimality. *Automatica* 36(6), 789–814 (2000). https://doi.org/10.1016/S0005-1098(99)00214-9
2. <a id="R002"></a> Fox, D., Burgard, W. & Thrun, S. The dynamic window approach to collision avoidance. *IEEE Robotics & Automation Magazine* 4(1), 23–33 (1997). https://doi.org/10.1109/100.580977
3. <a id="R003"></a> Chang, X., Wang, J., Dang, S., Pei, Y. & Zhu, F. Research on UAV path planning algorithm based on MPC–DWA strategy. *Electronics Optics & Control* (online first, 26 March 2026; bilingual Chinese article). https://link.cnki.net/urlid/41.1227.TN.20260325.1153.006
4. <a id="R004"></a> Xu, Z., Jin, H., Han, X., Shen, H. & Shimada, K. Intent prediction-driven model predictive control for UAV planning and navigation in dynamic environments. *IEEE Robotics and Automation Letters* 10(5), 4946–4953 (2025). https://doi.org/10.1109/LRA.2025.3555937
5. <a id="R005"></a> Hochreiter, S. & Schmidhuber, J. Long short-term memory. *Neural Computation* 9(8), 1735–1780 (1997). https://doi.org/10.1162/NECO.1997.9.8.1735

## 术语表

| English term | 中文 | 本文中的含义 |
|---|---|---|
| UAV | 无人机 | 本文模拟的飞行器 |
| constant velocity (CV) | 恒定速度 | 根据最近位置差外推障碍物位置的预测基线 |
| latest-position-hold | 最新位置保持 | 在预测时域内固定障碍物最近观测位置的基线 |
| LSTM forecast | LSTM 预测 | 根据因果历史观测预测障碍物未来位置 |
| MPC | 模型预测控制 | 优化多步控制路线并在每次更新时重规划 |
| DWA | 动态窗口法 | 筛选当前动力学可达动作并选择要执行的动作 |
| shared forecast | 共享预测 | 同一 LSTM 预测同时供 MPC 与 DWA 使用 |
| signed surface clearance | 带符号表面间隙 | 两个物体中心距离减去两者半径；正值分离、负值重叠 |
| collision-free arrival | 无碰撞到达目标 | 到达目标容差范围且连续扫掠路径无碰撞 |
| scene-cluster bootstrap | 按场景聚类的自助法 | 以场景为聚类单位进行重抽样的比较方法 |
| componentwise control bounds | 分量级控制边界 | 对速度、俯仰角速度和偏航角速度分别施加的上下界 |

## 阅读提示

当前稿件报告的是已完成的历史五控制器/1 s DWA 筛查结果；计划中的七控制器/3 s 评估仍待完成。历史评估中，共享 LSTM 是已测试集成 MPC–DWA 变体中表现最佳者，但独立 DWA 与独立 MPC 的无碰撞到达率更高。主文未报告七控制器/3 s 评估或真实飞行的结果。

