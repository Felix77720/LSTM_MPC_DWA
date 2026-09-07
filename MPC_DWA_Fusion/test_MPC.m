% test_MPC - 单独验证第1步: MPC 规划层 (滚动时域, 闭环 MPC)
% 反复调用 MPC_UAV, 只执行第一个控制量, 再重新规划, 得到完整的参考轨迹。
clear; close all; clc;

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

state = [start; 0; 0; 1];   % [x,y,z,theta,psi,v]
traj_history = state';
prev = [];

for step = 1:cfg.maxSteps
    dist = norm(state(1:3) - goal);
    if dist < cfg.goalTolerance
        fprintf('MPC 到达目标! 步数=%d, 剩余距离=%.2fm\n', step, dist);
        break;
    end

    result = MPC_UAV(state, goal, obstacles, cfg, prev);
    prev = result;            % 用上一次解做热启动

    state = UAV_model(state, result.u_first, cfg.dt, cfg);
    traj_history = [traj_history; state'];

    if mod(step, 20) == 0 || step == 1
        fprintf('step=%d, dist=%.2fm, exitflag=%d\n', ...
            step, dist, result.exitflag);
    end
end

figure('Name', 'MPC 参考轨迹 (Step 1 闭环)');
hold on; grid on; axis equal; view(45, 25);
xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');

plot3(traj_history(:,1), traj_history(:,2), traj_history(:,3), ...
    'g-', 'LineWidth', 2);
plot3(start(1), start(2), start(3), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
plot3(goal(1), goal(2), goal(3), 'r*', 'MarkerSize', 14);

for i = 1:size(obstacles,1)
    [sx, sy, sz] = sphere(15);
    sx = sx * obstacles(i,4) + obstacles(i,1);
    sy = sy * obstacles(i,4) + obstacles(i,2);
    sz = sz * obstacles(i,4) + obstacles(i,3);
    surf(sx, sy, sz, 'FaceColor', [0.7 0.2 0.2], 'EdgeColor', 'none', ...
        'FaceAlpha', 0.5);
end
title('MPC 规划层生成的参考轨迹');
