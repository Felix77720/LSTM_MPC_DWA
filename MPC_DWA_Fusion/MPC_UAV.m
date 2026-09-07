function result = MPC_UAV(state, goal, obstacles, cfg, prev, dwa_box, u_exec)
% MPC_UAV - MPC 规划层: 用 CasADi + IPOPT 求解滚动时域优化, 生成参考轨迹
%
% 输入:
%   state     : 6x1 当前状态 [x,y,z,theta,psi,v]
%   goal      : 3x1 目标点
%   obstacles : Mx4 障碍物 [x,y,z,r]
%   cfg       : 配置结构体 (cfg.mpc.N 等)
%   prev      : 可选, 上一次求解结果, 用于热启动 (字段 .X 和 .U)
%   dwa_box   : 可选, DWA 映射给 MPC 的可行控制盒 (式6), 格式
%               [v_min, v_max, wt_min, wt_max, wp_min, wp_max]
%   u_exec    : 可选, 上一时刻"真正执行"的控制量, 用于加速度约束锚点
%
% 输出 result:
%   traj     : (N+1) x 6 参考轨迹 (X 的数值解)
%   ctrl     : N x 3    控制序列 (U 的数值解)
%   u_first  : 3 x 1    第一个控制量 (紧耦合时交给 DWA 引导)
%   cost     : 最优代价值
%   exitflag : 1 表示求解成功
%   X, U     : 数值解 (供下一时刻热启动)

import casadi.*

N  = cfg.mpc.N;
dt = cfg.dt;

opti = Opti();

% ---- 决策变量 ----
X = opti.variable(6, N + 1);   % 状态轨迹 (每个节点一个 6 维状态)
U = opti.variable(3, N);       % 控制序列 (每个区间一个 3 维控制)

% ---- 参数 (每次 MPC 调用会变的量) ----
X0    = opti.parameter(6, 1);  % 当前状态
GOAL  = opti.parameter(3, 1);  % 目标点
UPREV = opti.parameter(3, 1);  % 上一时刻已执行的控制量

% ---- 1. 动力学约束 (multiple shooting: X(:,k+1) = f(X(:,k), U(:,k))) ----
for k = 1:N
    x_next = UAV_dynamics_sym(X(:, k), U(:, k), cfg);
    opti.subject_to(X(:, k + 1) == x_next);
end

% ---- 2. 初值约束 ----
opti.subject_to(X(:, 1) == X0);

% ---- 3. 代价函数 ----
J = 0;
% 逐时刻位置追踪 + 控制量代价
for k = 1:N
    J = J + cfg.mpc.wPos  * sumsqr(X(1:3, k) - GOAL) ...
          + cfg.mpc.wCtrl * sumsqr(U(:, k));
end
% 终端位置代价
J = J + cfg.mpc.wTerm * sumsqr(X(1:3, end) - GOAL);

% 控制量平滑代价 (相邻时刻变化尽量小)
for k = 2:N
    J = J + cfg.mpc.wSmooth * sumsqr(U(:, k) - U(:, k - 1));
end

% 障碍物软约束: 只惩罚进入膨胀球的情况
for k = 1:N
    for j = 1:size(obstacles, 1)
        d = norm_2(X(1:3, k) - obstacles(j, 1:3)') ...
            - obstacles(j, 4) - cfg.UAV_radius;
        J = J + cfg.mpc.wObs * fmax(0, -d)^2;
    end
end
opti.minimize(J);

% ---- 4. 控制量幅值约束 ----
opti.subject_to(0                        <= U(1, :) <= cfg.maxSpeed);
opti.subject_to(-cfg.maxPitchRate        <= U(2, :) <= cfg.maxPitchRate);
opti.subject_to(-cfg.maxYawRate          <= U(3, :) <= cfg.maxYawRate);

% DWA -> MPC 约束映射 (论文式6): V^MPC = V^DWA ⊕ B(delta)
% 这里把 DWA 安全动态窗口(已含 delta 松弛)作为 MPC 首个控制量的盒约束,
% 保证 MPC 的即时指令落在 DWA 的可达/安全空间内, 实现 "DWA 约束 MPC"。
if nargin >= 6 && ~isempty(dwa_box)
    opti.subject_to(dwa_box(1) <= U(1, 1) <= dwa_box(2));
    opti.subject_to(dwa_box(3) <= U(2, 1) <= dwa_box(4));
    opti.subject_to(dwa_box(5) <= U(3, 1) <= dwa_box(6));
end

% ---- 5. 控制量变化率约束 (加速度限制, 与 DWA 动态窗口一致) ----
rate = [cfg.maxAcc; cfg.maxPitchAcc; cfg.maxYawAcc] * dt;
opti.subject_to(-rate <= U(:, 1) - UPREV <= rate);   % 第1步相对上一时刻
for k = 2:N
    opti.subject_to(-rate <= U(:, k) - U(:, k - 1) <= rate);
end

% ---- 6. 求解器 ----
opti.solver('ipopt', struct('print_time', 0, ...
    'ipopt', struct('print_level', 0, 'max_iter', 300, 'tol', 1e-6)));

% ---- 7. 参数赋值 ----
opti.set_value(X0,    state);
opti.set_value(GOAL,  goal);

% 上一时刻已执行控制量: 这是加速度约束的锚点, 必须用真实值,
% 否则 MPC 会一直认为上一控制为 0, 导致速度永远无法加速上去。
if nargin >= 7 && ~isempty(u_exec)
    u_last = u_exec(:);
elseif nargin >= 5 && isfield(prev, 'u_first')
    u_last = prev.u_first(:);
else
    u_last = zeros(3, 1);
end
opti.set_value(UPREV, u_last);

% ---- 8. 初始猜测 (线性插值 + 热启动) ----
if nargin >= 5 && isfield(prev, 'X') && isfield(prev, 'U') ...
        && all(size(prev.X) == [6, N+1]) && all(size(prev.U) == [3, N])
    X0_init = prev.X;
    U0_init = prev.U;
else
    X0_init = zeros(6, N + 1);
    for k = 1:N + 1
        frac = (k - 1) / N;
        X0_init(1:3, k) = state(1:3) + frac * (goal - state(1:3));
        X0_init(4:6, k) = [0; 0; 1];
    end
    U0_init = zeros(3, N);
end
opti.set_initial(X, X0_init);
opti.set_initial(U, U0_init);

% ---- 9. 求解并整理输出 ----
try
    sol = opti.solve();
    X_val = full(sol.value(X));
    U_val = full(sol.value(U));
    cost_val = full(sol.value(J));
    result.exitflag = 1;
catch e
    % 求解失败时返回初始猜测, 不让整个仿真崩溃
    warning('MPC_UAV 求解失败: %s', e.message);
    X_val = X0_init;
    U_val = U0_init;
    cost_val = NaN;
    result.exitflag = 0;
end

result.traj    = X_val';          % (N+1) x 6
result.ctrl    = U_val';          % N x 3
result.u_first = U_val(:, 1);     % 3 x 1
result.cost    = cost_val;
result.X       = X_val;
result.U       = U_val;
end
