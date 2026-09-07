% 结构: MPC 规划层(引导) <-> DWA 执行层(约束), 双向信息流。
clear; close all; clc;
rng(1);   % 固定随机种子, 保证智能采样可复现

casadi_dir = fullfile(fileparts(mfilename('fullpath')), 'third_party', ...
    'casadi-3.8.0-windows64-matlab2018b');
addpath(casadi_dir);

cfg = config_UAV();
start = [1, 1, 1]';
goal  = [18, 18, 8]';

obstacles = [
     6,  5,  3, 0.8;
    10, 10,  5, 1.0;
    14, 12,  4, 0.7;
     8, 15,  6, 0.9;
    16,  8,  7, 0.6;
    12, 18,  3, 0.8
];

state   = [start; 0; pi/2; 1];   % [x,y,z,theta,psi,v]
control = [1; 0; 0];          % 初始指令与实际速度 v=1 保持一致

traj_history    = state';
control_history = control';
time_history    = 0;

%% ---- 0. 引导初始化: 先求解一次 MPC, 得到初始引导量 u_mpc 与信任度 tau ----
prev_mpc = struct('u_first', control);
mpc      = MPC_UAV(state, goal, obstacles, cfg, prev_mpc, [], control);
u_mpc    = mpc.u_first;
ref_traj = mpc.traj;
ref_ctrl = mpc.ctrl;
tau      = computeTrust(ref_traj, ref_ctrl, goal, obstacles, cfg, state);

figure('Name', 'MPC-DWA 双向耦合', 'Position', [80, 80, 1050, 720]);

%% ---- 主循环 ----
for step = 1:cfg.maxSteps
    dist_to_goal = norm(state(1:3) - goal);
    if dist_to_goal < cfg.goalTolerance
        fprintf('到达目标! 步数=%d, 剩余距离=%.2fm\n', step, dist_to_goal);
        break;
    end

    % ---- 0. 更新信任度: 用"上一时刻参考轨迹" vs "当前状态"反映一步延迟 ----
    tau = computeTrust(ref_traj, ref_ctrl, goal, obstacles, cfg, state);

    % ---- 1. DWA 动态窗口 ----
    [v_range, wt_range, wp_range] = createDynamicWindow3D(control, cfg);

    % ---- 2. 基于 MPC 信任度的智能采样 (式10~12) ----
    samples = sampleIntelligent3D(v_range, wt_range, wp_range, u_mpc, tau, cfg);
    n_samples = size(samples, 1);

    % ---- 3. 轨迹预测 + 多目标评分 ----
    valid_ctrls = [];
    valid_trajs = {};
    s_pos = []; s_head = []; s_vel = []; s_obs = [];

    for i = 1:n_samples
        ctrl_i = samples(i, :)';
        traj = predictTrajectory3D(state, ctrl_i, cfg);

        % 安全刹车约束
        min_dist = calcMinDist3D(traj, obstacles, cfg);
        v_safe = sqrt(2 * cfg.maxDec * min_dist);
        if traj(end, 6) > v_safe
            continue;
        end

        valid_ctrls = [valid_ctrls; ctrl_i'];
        valid_trajs{end+1} = traj;

        [sp, sh, sv] = referenceScores3D(traj, ref_traj, cfg);
        s_pos(end+1)  = sp;
        s_head(end+1) = sh;
        s_vel(end+1)  = sv;
        s_obs(end+1)  = scoreObstacle3D(traj, obstacles, cfg) / cfg.maxClearance;
    end

    % ---- 4. 选最优 + DWA->MPC 约束盒 ----
    if isempty(valid_ctrls)
        best_control = [0; 0; 0];
        best_traj = [];
        mpc_box = [];
        fprintf('警告: 第%d步无安全轨迹, 紧急刹车\n', step);
    else
        w = dynamicWeights(tau, cfg);   % 式22~25 动态权重
        total = w(1)*s_pos + w(2)*s_head + w(3)*s_vel + w(4)*s_obs;
        [~, best_idx] = max(total);
        best_control  = valid_ctrls(best_idx, :)';
        best_traj     = valid_trajs{best_idx};
        mpc_box = boundingBoxSafe(valid_ctrls, cfg);   % 式6 约束映射
    end

    % ---- 5. 重新求解 MPC (DWA 约束 MPC, 式6) ----
    mpc      = MPC_UAV(state, goal, obstacles, cfg, mpc, mpc_box, control);
    u_mpc    = mpc.u_first;
    ref_traj = mpc.traj;
    ref_ctrl = mpc.ctrl;

    % ---- 6. 执行 DWA 控制, 更新状态 ----
    state   = UAV_model(state, best_control, cfg.dt, cfg);
    control = best_control;

    traj_history    = [traj_history; state'];
    control_history = [control_history; best_control'];
    time_history    = [time_history; step * cfg.dt];

    % ---- 7. 实时可视化 ----
    if mod(step, 5) == 0 || step == 1
        clf;
        visualize3DCoupled(traj_history, goal, obstacles, best_traj, ref_traj, cfg);
        title(sprintf('步数: %d  距离: %.1fm  速度: %.1fm/s  \\tau=%.2f', ...
            step, dist_to_goal, state(6), tau));
        drawnow;
    end
end

%% ---- 最终结果图 ----
figure('Name', 'MPC-DWA 结果分析');
subplot(2,2,1);
plot3(traj_history(:,1), traj_history(:,2), traj_history(:,3), 'b-', 'LineWidth', 2);
hold on; grid on; axis equal;
xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)'); title('3D 飞行轨迹');
for i = 1:size(obstacles,1)
    [sx, sy, sz] = sphere(15);
    sx = sx * obstacles(i,4) + obstacles(i,1);
    sy = sy * obstacles(i,4) + obstacles(i,2);
    sz = sz * obstacles(i,4) + obstacles(i,3);
    surf(sx, sy, sz, 'FaceColor', [0.7 0.2 0.2], 'EdgeColor', 'none', ...
        'FaceAlpha', 0.5);
end
plot3(start(1), start(2), start(3), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
plot3(goal(1),  goal(2),  goal(3),  'r*', 'MarkerSize', 14);

subplot(2,2,2);
plot(time_history, traj_history(:,6), 'b-', 'LineWidth', 1.5);
xlabel('时间 (s)'); ylabel('速度 (m/s)'); title('速度曲线'); grid on;

subplot(2,2,3);
plot(time_history, control_history(:,2), 'r-', 'LineWidth', 1.5);
xlabel('时间 (s)'); ylabel('\omega_\theta (rad/s)'); title('俯仰角速度'); grid on;

subplot(2,2,4);
plot(time_history, control_history(:,3), 'b-', 'LineWidth', 1.5);
xlabel('时间 (s)'); ylabel('\omega_\psi (rad/s)'); title('偏航角速度'); grid on;

fprintf('仿真完成。总步数=%d, 最终距离=%.2fm\n', step, dist_to_goal);


%% ==================== 局部函数 ====================

function [v_range, wt_range, wp_range] = createDynamicWindow3D(ctrl, cfg)
    v_c = ctrl(1); wt = ctrl(2); wp = ctrl(3);
    v_range = [max(0, v_c - cfg.maxAcc*cfg.dt), ...
               min(cfg.maxSpeed, v_c + cfg.maxAcc*cfg.dt)];
    wt_range = [max(-cfg.maxPitchRate, wt - cfg.maxPitchAcc*cfg.dt), ...
                min( cfg.maxPitchRate, wt + cfg.maxPitchAcc*cfg.dt)];
    wp_range = [max(-cfg.maxYawRate, wp - cfg.maxYawAcc*cfg.dt), ...
                min( cfg.maxYawRate, wp + cfg.maxYawAcc*cfg.dt)];
end

function traj = predictTrajectory3D(state, ctrl, cfg)
    n_steps = ceil(cfg.predictTime / cfg.dt);
    traj = zeros(n_steps, 6);
    s = state;
    for k = 1:n_steps
        s = UAV_model(s, ctrl, cfg.dt, cfg);
        traj(k, :) = s';
    end
end

function minDist = calcMinDist3D(traj, obstacles, cfg)
    minDist = inf;
    for i = 1:size(traj, 1)
        pos = traj(i, 1:3);
        for j = 1:size(obstacles, 1)
            d = norm(pos - obstacles(j, 1:3)) - obstacles(j, 4) - cfg.UAV_radius;
            if d < 0
                minDist = 0;
                return;
            end
            if d < minDist
                minDist = d;
            end
        end
    end
end

function s = scoreObstacle3D(traj, obstacles, cfg)
    d = calcMinDist3D(traj, obstacles, cfg);
    s = min(d, cfg.maxClearance);
end

function box = boundingBoxSafe(valid_ctrls, cfg)
    delta = cfg.coupling.delta;
    box = [min(valid_ctrls(:,1)) - delta, max(valid_ctrls(:,1)) + delta, ...
           min(valid_ctrls(:,2)) - delta, max(valid_ctrls(:,2)) + delta, ...
           min(valid_ctrls(:,3)) - delta, max(valid_ctrls(:,3)) + delta];
    box(1) = max(0, box(1)); box(2) = min(cfg.maxSpeed, box(2));
    box(3) = max(-cfg.maxPitchRate, box(3)); box(4) = min(cfg.maxPitchRate, box(4));
    box(5) = max(-cfg.maxYawRate, box(5)); box(6) = min(cfg.maxYawRate, box(6));
end

function visualize3DCoupled(traj_hist, goal, obstacles, best_traj, ref_traj, cfg)
    hold on; grid on; axis equal; view(45, 25);
    xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
    xlim(cfg.arenaSize(1,:)); ylim(cfg.arenaSize(2,:)); zlim(cfg.arenaSize(3,:));

    plot3(traj_hist(:,1), traj_hist(:,2), traj_hist(:,3), ...
        'b-', 'LineWidth', 2);              % 已飞轨迹
    if ~isempty(ref_traj)
        plot3(ref_traj(:,1), ref_traj(:,2), ref_traj(:,3), ...
            'g--', 'LineWidth', 1.2);       % MPC 参考轨迹
    end
    if ~isempty(best_traj)
        plot3(best_traj(:,1), best_traj(:,2), best_traj(:,3), ...
            'r--', 'LineWidth', 1.0);       % DWA 当前最优预测
    end

    for i = 1:size(obstacles, 1)
        [sx, sy, sz] = sphere(15);
        sx = sx * obstacles(i,4) + obstacles(i,1);
        sy = sy * obstacles(i,4) + obstacles(i,2);
        sz = sz * obstacles(i,4) + obstacles(i,3);
        surf(sx, sy, sz, 'FaceColor', [0.8 0.2 0.2], ...
            'EdgeColor', 'none', 'FaceAlpha', 0.4);
    end

    plot3(traj_hist(1,1), traj_hist(1,2), traj_hist(1,3), ...
        'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
    plot3(goal(1), goal(2), goal(3), 'r*', 'MarkerSize', 14);
    current = traj_hist(end, :);
    plot3(current(1), current(2), current(3), ...
        'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
end
