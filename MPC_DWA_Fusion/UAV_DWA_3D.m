clear; close all; clc;

%% ---- 1. 环境初始化 ----
cfg = config_UAV();
start  = [1, 1, 1]';      % 起点
goal   = [18, 18, 8]';    % 终点

% 三维球形障碍物: [x, y, z, radius]
obstacles = [
     6,  5,  3, 0.8;
    10, 10,  5, 1.0;
    14, 12,  4, 0.7;
     8, 15,  6, 0.9;
    16,  8,  7, 0.6;
    12, 18,  3, 0.8
];

% 无人机初始状态: [x, y, z, theta, psi, v]
state = [start; 3; 3; 1];        
control = [0; 0; 0];              
% 记录轨迹
traj_history = state';            % 每行: [x,y,z,theta,psi,v]
control_history = control';       % 每行: [v_c, omega_theta, omega_psi]
time_history = 0;

%% ---- 2. 可视化初始化 ----
figure('Name', '3D UAV DWA', 'Position', [100, 100, 1000, 700]);

%% ---- 3. DWA 主循环 ----
for step = 1:cfg.maxSteps
    % --- 3a. 到达判断 ---
    dist_to_goal = norm(state(1:3) - goal);
    if dist_to_goal < cfg.goalTolerance
        fprintf('到达目标! 步数=%d, 剩余距离=%.2fm\n', step, dist_to_goal);
        break;
    end

    % --- 3b. 构建动态窗口 (论文式3: Vp ∩ Vd) ---
    [v_range, wtheta_range, wpsi_range] = createDynamicWindow3D(...
        control, cfg);

    % --- 3c. 离散采样 ---
    samples = sampleControlSpace3D(v_range, wtheta_range, wpsi_range, cfg);
    n_samples = size(samples, 1);

    % --- 3d. 轨迹预测 + 评分 ---
    valid_ctrls  = [];
    valid_trajs  = {};
    heading_raw  = [];
    obstacle_raw = [];
    velocity_raw = [];

    for i = 1:n_samples
        v_c_i    = samples(i, 1);
        wtheta_i = samples(i, 2);
        wpsi_i   = samples(i, 3);
        ctrl_i = [v_c_i; wtheta_i; wpsi_i];

        % 预测轨迹
        traj = predictTrajectory3D(state, ctrl_i, cfg);

        % 安全刹车约束
        min_dist = calcMinDist3D(traj, obstacles, cfg);
        v_safe = sqrt(2 * cfg.maxDec * min_dist);
        if traj(end, 6) > v_safe   % 终点速度超过安全刹车速度
            continue;              % 毙掉
        end

        % 记录该轨迹的三项原始评分
        valid_ctrls  = [valid_ctrls; ctrl_i'];
        valid_trajs{end+1} = traj;
        heading_raw(end+1)  = scoreHeading3D(traj, goal);
        obstacle_raw(end+1) = scoreObstacle3D(traj, obstacles, cfg);
        velocity_raw(end+1) = scoreVelocity3D(traj);
    end

    % --- 3e. 兜底: 全部轨迹被毙时刹车 ---
    if isempty(valid_ctrls)
        best_control = [0; 0; 0];
        best_traj    = [];
        fprintf('警告: 第%d步无安全轨迹，紧急刹车\n', step);
    else
        % 归一化三项评分 (对应你的 normalizeScore.m)
        heading_norm  = normalizeScoreVec(heading_raw);
        obstacle_norm = normalizeScoreVec(obstacle_raw);
        velocity_norm = normalizeScoreVec(velocity_raw);

        % 加权求和
        total_score = cfg.headingWeight  * heading_norm ...
                    + cfg.obstacleWeight * obstacle_norm ...
                    + cfg.velocityWeight * velocity_norm;

        [~, best_idx] = max(total_score);
        best_control  = valid_ctrls(best_idx, :)';
        best_traj     = valid_trajs{best_idx};
    end

    % --- 3f. 执行控制, 更新状态 ---
    state   = UAV_model(state, best_control, cfg.dt, cfg);
    control = best_control;

    traj_history    = [traj_history; state'];
    control_history = [control_history; best_control'];
    time_history    = [time_history; step * cfg.dt];

    % --- 3g. 实时可视化 ---
    if mod(step, 5) == 0 || step == 1
        clf;
        visualize3DScene(traj_history, goal, obstacles, best_traj, cfg);
        title(sprintf('步数: %d  距离目标: %.1fm  速度: %.1fm/s', ...
            step, dist_to_goal, state(6)));
        drawnow;
    end
end

%% ---- 4. 最终结果图 ----
figure('Name', 'DWA 结果分析');

subplot(2,2,1);
plot3(traj_history(:,1), traj_history(:,2), traj_history(:,3), 'b-', 'LineWidth', 2);
hold on; grid on; axis equal;
xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
title('3D 飞行轨迹');
% 画障碍物
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


%% ==================== 辅助函数 ====================

function [v_range, wtheta_range, wpsi_range] = createDynamicWindow3D(ctrl, cfg)
    % 对应你的 createDynamicWindow.m, 扩展到3D控制空间
    v_c = ctrl(1); w_theta = ctrl(2); w_psi = ctrl(3);

    v_range = [max(0, v_c - cfg.maxAcc * cfg.dt), ...
               min(cfg.maxSpeed, v_c + cfg.maxAcc * cfg.dt)];

    wtheta_range = [max(-cfg.maxPitchRate, w_theta - cfg.maxPitchAcc * cfg.dt), ...
                    min( cfg.maxPitchRate, w_theta + cfg.maxPitchAcc * cfg.dt)];

    wpsi_range = [max(-cfg.maxYawRate, w_psi - cfg.maxYawAcc * cfg.dt), ...
                  min( cfg.maxYawRate, w_psi + cfg.maxYawAcc * cfg.dt)];
end

function samples = sampleControlSpace3D(v_range, wtheta_range, wpsi_range, cfg)
    % 对应你的 sampleVelocity.m, 3D网格采样
    v_list = v_range(1) : cfg.vRes : v_range(2);
    wt_list = wtheta_range(1) : cfg.omegaRes : wtheta_range(2);
    wp_list = wpsi_range(1)   : cfg.omegaRes : wpsi_range(2);

    [V, WT, WP] = meshgrid(v_list, wt_list, wp_list);
    samples = [V(:), WT(:), WP(:)];
end

function traj = predictTrajectory3D(state, ctrl, cfg)
    % 对应你的 predictTrajectory.m, 用 UAV_model 做前向积分
    n_steps = ceil(cfg.predictTime / cfg.dt);
    traj = zeros(n_steps, 6);
    s = state;
    for k = 1:n_steps
        s = UAV_model(s, ctrl, cfg.dt, cfg);
        traj(k, :) = s';
    end
end

function minDist = calcMinDist3D(traj, obstacles, cfg)
    % 对应你的 calculateMinDistance.m, 3D欧氏距离
    minDist = inf;
    for i = 1:size(traj, 1)
        pos = traj(i, 1:3);
        for j = 1:size(obstacles, 1)
            obs_center = obstacles(j, 1:3);
            obs_r = obstacles(j, 4);
            d = norm(pos - obs_center) - obs_r - cfg.UAV_radius;
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

function s = scoreHeading3D(traj, goal)
    % 对应你的 evaluateHeading.m, 3D朝向评分
    terminal = traj(end, :);
    pos_end  = terminal(1:3)';   % 转成列向量, 与 goal 尺寸一致
    theta_end = terminal(4);
    psi_end   = terminal(5);

    % 无人机朝向 (单位向量)
    uav_dir = [cos(theta_end) * cos(psi_end);
               cos(theta_end) * sin(psi_end);
               sin(theta_end)];

    % 指向目标的方向
    to_goal = goal - pos_end;
    to_goal = to_goal / norm(to_goal);

    % 夹角越小, 评分越高
    angle = acos(max(-1, min(1, dot(uav_dir, to_goal))));
    s = pi - angle;
end

function s = scoreObstacle3D(traj, obstacles, cfg)
    % 对应你的 evaluateObstacle.m
    d = calcMinDist3D(traj, obstacles, cfg);
    s = min(d, cfg.maxClearance);
end

function s = scoreVelocity3D(traj)
    % 对应你的 evaluateVelocity.m, 取终点速度
    s = traj(end, 6);
end

function score = normalizeScoreVec(scoreList)
    % 对应你的 normalizeScore.m: 每个分数除以总分, 消除尺度差异
    total = sum(scoreList);
    if total == 0
        score = scoreList;
    else
        score = scoreList / total;
    end
end

function visualize3DScene(traj_hist, goal, obstacles, best_traj, cfg)
    hold on; grid on; axis equal;
    view(45, 25);
    xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
    xlim(cfg.arenaSize(1,:));
    ylim(cfg.arenaSize(2,:));
    zlim(cfg.arenaSize(3,:));

    % 历史轨迹
    plot3(traj_hist(:,1), traj_hist(:,2), traj_hist(:,3), ...
        'b-', 'LineWidth', 2);

    % 当前最优预测轨迹
    if ~isempty(best_traj)
        plot3(best_traj(:,1), best_traj(:,2), best_traj(:,3), ...
            'r--', 'LineWidth', 1.2);
    end

    % 障碍物 (半透明球)
    for i = 1:size(obstacles, 1)
        [sx, sy, sz] = sphere(15);
        sx = sx * obstacles(i,4) + obstacles(i,1);
        sy = sy * obstacles(i,4) + obstacles(i,2);
        sz = sz * obstacles(i,4) + obstacles(i,3);
        surf(sx, sy, sz, 'FaceColor', [0.8 0.2 0.2], ...
            'EdgeColor', 'none', 'FaceAlpha', 0.4);
    end

    % 起点/目标
    plot3(traj_hist(1,1), traj_hist(1,2), traj_hist(1,3), ...
        'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
    plot3(goal(1), goal(2), goal(3), ...
        'r*', 'MarkerSize', 14);

    % 无人机当前位置
    current = traj_hist(end, :);
    plot3(current(1), current(2), current(3), ...
        'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
end
