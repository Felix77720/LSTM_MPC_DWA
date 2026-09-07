function probe_eval(si, method, wRoute)
% probe_eval - Run one S1-S4 evaluation scenario and report detour evidence.
if nargin < 1, si = 1; end
if nargin < 2, method = 'lstm'; end
if nargin < 3, wRoute = 3; end
here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));
cfg = config_LSTM();
cfg.maxSteps = 700;
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;
cfg.dyn.injectHorizon = 30;
cfg.mpc.wRoute = wRoute;
cfg.routeStart = [1 1 1]';
S = load(fullfile(here, 'results', 'lstm_predictor.mat'), 'net', 'muX', 'sigX', 'muY', 'sigY');
cfg.dyn.muX = S.muX; cfg.dyn.sigX = S.sigX; cfg.dyn.muY = S.muY; cfg.dyn.sigY = S.sigY;
evals = generate_eval_scenarios(cfg);
rng(10000);
res = simulate_dynamic(evals(si), method, S.net, cfg);
[n, ev] = count_detour_events(res.horizontalOffset);
fprintf('EVAL S%d method=%s wRoute=%g steps=%d success=%d collisions=%d events=%d detours=%d minClear=%.3f path=%.3f rmse=%.3f\n', ...
    si, method, wRoute, res.steps, res.success, res.collisions, res.collisionEvents, n, res.minClearance, res.pathLength, res.trackRMSE);
fprintf('lateral min/max/mean/std = %.3f / %.3f / %.3f / %.3f\n', ...
    min(res.horizontalOffset), max(res.horizontalOffset), mean(res.horizontalOffset), std(res.horizontalOffset));
fprintf('vertical min/max/mean/std = %.3f / %.3f / %.3f / %.3f\n', ...
    min(res.verticalOffset), max(res.verticalOffset), mean(res.verticalOffset), std(res.verticalOffset));
end
