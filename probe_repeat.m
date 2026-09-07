function probe_repeat(wRoute, method)
% probe_repeat - Run one R1 repeated-encounter trial for rapid scenario tuning.
if nargin < 1, wRoute = 3; end
if nargin < 2, method = 'lstm'; end
here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));
cfg = config_LSTM();
cfg.maxSteps = 700;
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;
cfg.dyn.injectHorizon = 30;
cfg.mpc.wRoute = wRoute;
netfile = fullfile(here, 'results', 'lstm_predictor.mat');
S = load(netfile, 'net', 'muX', 'sigX', 'muY', 'sigY');
net = S.net;
cfg.dyn.muX = S.muX; cfg.dyn.sigX = S.sigX; cfg.dyn.muY = S.muY; cfg.dyn.sigY = S.sigY;
repeat = generate_repeat_scenario(cfg);
rng(10000);
res = simulate_dynamic(repeat, method, net, cfg);
[n, ev] = count_detour_events(res.horizontalOffset);
fprintf('PROBE method=%s wRoute=%g steps=%d success=%d collisions=%d events=%d detours=%d minClear=%.4f path=%.3f rmse=%.3f ADE=%.4f FDE=%.4f\n', ...
    method, wRoute, res.steps, res.success, res.collisions, res.collisionEvents, n, res.minClearance, res.pathLength, res.trackRMSE, res.ADE, res.FDE);
fprintf('lateral min/max/mean/std = %.4f / %.4f / %.4f / %.4f\n', ...
    min(res.horizontalOffset), max(res.horizontalOffset), mean(res.horizontalOffset), std(res.horizontalOffset));
fprintf('vertical min/max/mean/std = %.4f / %.4f / %.4f / %.4f\n', ...
    min(res.verticalOffset), max(res.verticalOffset), mean(res.verticalOffset), std(res.verticalOffset));
fprintf('solveFailures=%d fallbackSteps=%d finalDist=%.4f alongTrackEnd=%.4f\n', ...
    res.solveFailures, res.fallbackSteps, res.finalDist, res.alongTrack(end));
fprintf('final state = %.4f %.4f %.4f %.4f %.4f %.4f\n', res.traj(end, 1:6));
if ~isempty(ev)
    fprintf('detour events (start,end,peak):\n');
    for i = 1:size(ev, 1)
        fprintf('  [%d %d %.3f]\n', ev(i, 1), ev(i, 2), ev(i, 3));
    end
end
outdir = fullfile(here, 'results', 'probe');
if ~exist(outdir, 'dir'), mkdir(outdir); end
t = res.time(2:end); t = t(:); nrows = numel(res.horizontalOffset); t = t(1:nrows);
TT = table(t, res.horizontalOffset(:), res.verticalOffset(:), res.stepClearance(:), res.nearestObstacle(:), res.alongTrack(:), ...
    'VariableNames', {'Time', 'HorizontalOffset', 'VerticalOffset', 'Clearance', 'NearestObstacle', 'AlongTrack'});
writetable(TT, fullfile(outdir, sprintf('probe_%s_w%d_trajectory.csv', method, wRoute)));
save(fullfile(outdir, sprintf('probe_%s_w%d.mat', method, wRoute)), 'res', 'cfg');
noobs = struct('name', 'N0 无障碍对照', 'start', [1 1 1]', 'goal', [18 18 8]', ...
    'obstacles', struct('traj', {}, 'radius', {}));
visualize_detour_evidence(res, noobs, cfg, outdir);
fprintf('PROBE_DONE\n');
end
