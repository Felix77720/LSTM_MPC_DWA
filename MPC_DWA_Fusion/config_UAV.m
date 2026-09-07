function cfg = config_UAV()
% config_UAV - 3D无人机DWA的配置参数

cfg = struct();

% ---- 无人机物理参数 (论文1.1节) ----
cfg.tau = 0.5;              % 速度响应时间常数 [s]
cfg.maxSpeed   = 2.0;       % 最大速度 [m/s]
cfg.maxPitchRate  = 0.8;    % 最大俯仰角速度 [rad/s]
cfg.maxYawRate    = 0.8;    % 最大偏航角速度 [rad/s]
cfg.maxAcc     = 1.0;       % 最大加速度 [m/s^2]
cfg.maxPitchAcc   = 0.5;    % 最大俯仰角加速度 [rad/s^2]
cfg.maxYawAcc     = 0.5;    % 最大偏航角加速度 [rad/s^2]
cfg.maxDec     = 1.0;       % 最大减速度(用于刹车安全约束)

% ---- DWA采样参数 ----
cfg.predictTime  = 3.0;     % 预测时域 [s]
cfg.dt           = 0.1;     % 仿真步长 [s]
cfg.vRes         = 0.05;    % 速度采样分辨率 [m/s]
cfg.omegaRes     = 0.1;     % 角速度采样分辨率 [rad/s]

% ---- 评价函数权重 (对应论文式(5): alpha1, alpha2, alpha3) ----
cfg.headingWeight   = 0.35;  % 航向代价权重
cfg.obstacleWeight  = 0.45;  % 避障代价权重
cfg.velocityWeight  = 0.20;  % 速度代价权重

% ---- 安全参数 ----
cfg.maxClearance = 5.0;      % 障碍物评分上限距离 [m]
cfg.UAV_radius    = 0.3;     % 无人机安全半径 [m]
cfg.goalTolerance = 0.5;     % 到达目标的判定距离 [m]

% ---- 仿真环境 ----
cfg.maxSteps = 500;          % 最大仿真步数
cfg.arenaSize = [0, 20; 0, 20; 0, 10];  % 仿真空间范围 [xmin,xmax; ymin,ymax; zmin,zmax]

% ---- MPC 规划层参数 (论文第2章 MPC-DWA 耦合) ----
cfg.mpc.N        = 30;        % 预测时域步数 (predictTime/dt)
cfg.mpc.wPos     = 1.0;       % 位置追踪代价权重 (stage)
cfg.mpc.wTerm    = 1.0;       % 终端位置代价权重
cfg.mpc.wCtrl    = 10.0;      % 控制量代价权重
cfg.mpc.wSmooth  = 50.0;      % 控制量变化率(平滑)代价权重
cfg.mpc.wObs     = 20000.0;   % 障碍物软约束惩罚权重

% ---- MPC-DWA 双向耦合参数 (论文 2.1~2.2 节) ----
cfg.coupling.rGuide    = 0.35;  % 引导采样区域半径 (式11, 围绕 u_MPC)
cfg.coupling.delta     = 0.1;   % DWA->MPC 约束映射松弛球半径 B(delta) (式6)
cfg.coupling.alpha     = 1.0;   % 采样总量扩展系数 (式10)
cfg.coupling.beta      = 3.0;   % 信任度敏感性参数 (式10)
cfg.coupling.Nbase     = 300;   % 基础采样数量 (式10)
cfg.coupling.sigma     = [0.35, 0.30, 0.15, 0.20]; % 信任度权重 sigma1..4 (式8)
cfg.coupling.dSafe     = 1.0;   % 安全临界距离 (式9)
cfg.coupling.dSense    = 5.0;   % 感知范围 (式9)
cfg.coupling.alphaT    = 3.0;   % 时效性偏移系数 (式9, 单位 1/m)

% 动态权重 (式22~25): sigmoid 映射与阈值
cfg.coupling.sigmoidK  = 8;     % sigmoid 陡峭度
cfg.coupling.sigmoidX0 = 0.5;   % sigmoid 中点
cfg.coupling.wPosRange = [0.10, 0.30];  % 位置跟踪权重范围
cfg.coupling.wHeadRange= [0.08, 0.22];  % 航向跟踪权重范围
cfg.coupling.wVelBase  = 0.12;          % 速度权重基础值 (式24)
cfg.coupling.wObsRange = [0.20, 0.45];  % 避障权重范围 [wObsMin,wObsMax] (式25)
end
