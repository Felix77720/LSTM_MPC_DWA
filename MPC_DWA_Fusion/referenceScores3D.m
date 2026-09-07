function [s_pos, s_heading, s_vel] = referenceScores3D(traj, ref_traj, cfg)
% referenceScores3D - DWA 候选轨迹相对 MPC 引导轨迹的评价子项 (论文式14~16)
%
% 三项都设计成 "越大越好", 范围大致在 [0,1]:
%   s_pos     位置跟踪: DWA 终点离 MPC 参考终点越近越高
%   s_heading 航向跟踪: DWA 终点朝向与 MPC 参考朝向夹角越小越高
%   s_vel     速度跟踪 + 巡航激励

% --- 位置跟踪 (式14) ---
dist_pos = norm(traj(end, 1:3) - ref_traj(end, 1:3));
s_pos = 1 / (1 + dist_pos);

% --- 航向跟踪 (式15), 用最小角距离处理朝向 ---
d_dwa = headingVector(traj(end, 4), traj(end, 5));
d_ref = headingVector(ref_traj(end, 4), ref_traj(end, 5));
cos_angle = max(-1, min(1, dot(d_dwa, d_ref)));
s_heading = (1 + cos_angle) / 2;

% --- 速度跟踪 + 巡航激励 (式16) ---
v_dwa = traj(end, 6);
v_ref = ref_traj(end, 6);
track     = 1 / (1 + abs(v_dwa - v_ref));
incentive = v_dwa / cfg.maxSpeed;
s_vel = 0.5 * track + 0.5 * incentive;
end

function d = headingVector(theta, psi)
    d = [cos(theta) * cos(psi);
         cos(theta) * sin(psi);
         sin(theta)];
end
