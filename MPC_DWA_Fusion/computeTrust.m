function tau = computeTrust(ref_traj, ref_ctrl, goal, obstacles, cfg, state)
% computeTrust - MPC 引导轨迹信任度评估 (论文式8~9)
%
% 输入 ref_traj 是 MPC 预测轨迹 (N+1)x6, ref_ctrl 是控制序列 Nx3。
% state 是当前状态 (6x1), 用于计算时效性的一步延迟偏移。
% 返回 tau = sigma1*tau_sa + sigma2*tau_g + sigma3*tau_t + sigma4*tau_sm,
% 各项都归一化到 [0,1]。tau 越高代表 MPC 引导越可靠, DWA 越信任它。

% --- tau_sa: 安全性 (轨迹到障碍物的最小间距) ---
min_d = inf;
for i = 1:size(ref_traj, 1)
    pos = ref_traj(i, 1:3);
    for j = 1:size(obstacles, 1)
        d = norm(pos - obstacles(j, 1:3)) - obstacles(j, 4) - cfg.UAV_radius;
        min_d = min(min_d, d);
    end
end
tau_sa = clamp01((min_d - cfg.coupling.dSafe) / ...
    (cfg.coupling.dSense - cfg.coupling.dSafe));

% --- tau_g: 目标接近性 (终点比起点更靠近目标的程度) ---
dist_start = norm(ref_traj(1, 1:3) - goal');
dist_end   = norm(ref_traj(end, 1:3) - goal');
if dist_start < 1e-6
    tau_g = 1;
else
    tau_g = clamp01(1 - dist_end / dist_start);
end

% --- tau_t: 时效性 (式9, 一步延迟造成的偏移, 偏移越小越新鲜) ---
Delta_p = norm(state(1:3) - ref_traj(1, 1:3)');  % 参考起点 vs 当前实际位置(列向量对齐)
tau_t = exp(-cfg.coupling.alphaT * Delta_p);     % 指数衰减

% --- tau_sm: 平滑性 (控制量变化越小越平滑) ---
du = diff(ref_ctrl, 1, 1);                     % (N-1)x3
max_du = [cfg.maxAcc; cfg.maxPitchAcc; cfg.maxYawAcc]' * cfg.dt;
ratio = mean(abs(du), 1) ./ max_du;            % 每轴平均变化率占比
tau_sm = clamp01(1 - mean(ratio));

% --- 加权合成 ---
tau = cfg.coupling.sigma * [tau_sa; tau_g; tau_t; tau_sm];
end

function y = clamp01(x)
    y = max(0, min(1, x));
end
