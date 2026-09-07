function probe_mpc_init()
% probe_mpc_init - Print the first MPC reference and first control for the
% repeat scenario under a chosen method, without running the closed loop.
here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));
cfg = config_LSTM();
cfg.maxSteps = 700;
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;
cfg.dyn.injectHorizon = 30;
cfg.mpc.wRoute = 3;
cfg.routeStart = [1 1 1]';
repeat = generate_repeat_scenario(cfg);
S = load(fullfile(here, 'results', 'lstm_predictor.mat'), 'net', 'muX', 'sigX', 'muY', 'sigY');
cfg.dyn.muX = S.muX; cfg.dyn.sigX = S.sigX; cfg.dyn.muY = S.muY; cfg.dyn.sigY = S.sigY;
start = repeat.start; goal = repeat.goal;
state = [start; atan2(goal(3)-start(3), norm(goal(1:2)-start(1:2))); atan2(goal(2)-start(2), goal(1)-start(1)); 1];
control = [1; 0; 0];
M = numel(repeat.obstacles); N_pred = cfg.dyn.N_pred;
obs_radius = zeros(M,1);
for j = 1:M, obs_radius(j) = repeat.obstacles(j).radius; end
for method = {'cv','static','lstm'}
    obs_pred = zeros(N_pred,3,M);
    for j = 1:M
        obs_pred(:,:,j) = predict_obstacle_traj(repeat.obstacles(j).traj(1:1,:), method{1}, cfg, S.net);
    end
    prev = struct('u_first', control);
    mpc = MPC_UAV_dynamic(state, goal, obs_pred, obs_radius, cfg, prev, [], control);
    fprintf('%s u_first=%.4f %.4f %.4f exit=%d refEnd=%.3f %.3f %.3f refFirst=%.3f %.3f %.3f\n', ...
        method{1}, mpc.u_first, mpc.exitflag, mpc.traj(end,1:3), mpc.traj(2,1:3));
end
end
