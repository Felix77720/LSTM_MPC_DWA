function tau = computeTrust_dynamic(ref_traj, ref_ctrl, goal, obs_pred, obs_radius, cfg, state)
% computeTrust_dynamic - Compute MPC-DWA fusion trust weights for dynamic obstacles.
% Same as the baseline computeTrust except tau_sa uses the predicted obstacle
% positions at each time step.
%
% Inputs:
%   ref_traj   - MPC reference trajectory (N+1 x 6).
%   ref_ctrl   - MPC control sequence (N x 3).
%   goal       - goal position (3 x 1).
%   obs_pred   - predicted obstacle positions (N_pred x 3 x M).
%   obs_radius - obstacle radii (M x 1).
%   cfg        - configuration struct.
%   state      - current UAV state (6 x 1).
% Output:
%   tau - 4 x 1 trust vector [safety; goal progress; trajectory tracking;
%         smoothness], scaled by cfg.coupling.sigma.

N = min(size(ref_traj, 1)-1, size(obs_pred, 1));
M = size(obs_pred, 3);

min_d = inf;
for k = 1:N
    pos = ref_traj(k+1, 1:3)';
    for j = 1:M
        oc = obs_pred(k, :, j)';
        d = norm(pos - oc) - obs_radius(j) - cfg.UAV_radius;
        min_d = min(min_d, d);
    end
end
tau_sa = clamp01((min_d - cfg.coupling.dSafe) / (cfg.coupling.dSense - cfg.coupling.dSafe));

dist_start = norm(ref_traj(1, 1:3) - goal');
dist_end   = norm(ref_traj(end, 1:3) - goal');
if dist_start < 1e-6
    tau_g = 1;
else
    tau_g = clamp01(1 - dist_end / dist_start);
end

Delta_p = norm(state(1:3) - ref_traj(1, 1:3)');
tau_t = exp(-cfg.coupling.alphaT * Delta_p);

du = diff(ref_ctrl, 1, 1);
max_du = [cfg.maxAcc; cfg.maxPitchAcc; cfg.maxYawAcc]' * cfg.dt;
ratio = mean(abs(du), 1) ./ max_du;
tau_sm = clamp01(1 - mean(ratio));

tau = cfg.coupling.sigma * [tau_sa; tau_g; tau_t; tau_sm];
end

function y = clamp01(x)
    % clamp01 - Clip x to the interval [0, 1].
    % Input x: value to clip. Output y: clipped value.
    y = max(0, min(1, x));
end
