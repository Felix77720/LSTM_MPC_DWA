function probe_steps(method)
% probe_steps - Print executed speed history for the first 60 control steps.
if nargin < 1, method = 'cv'; end
here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));
cfg = config_LSTM();
cfg.maxSteps = 60;
cfg.dyn.T_obs = 200;
cfg.dyn.injectHorizon = 30;
cfg.mpc.wRoute = 3;
cfg.routeStart = [1 1 1]';
S = load(fullfile(here, 'results', 'lstm_predictor.mat'), 'net', 'muX', 'sigX', 'muY', 'sigY');
cfg.dyn.muX = S.muX; cfg.dyn.sigX = S.sigX; cfg.dyn.muY = S.muY; cfg.dyn.sigY = S.sigY;
repeat = generate_repeat_scenario(cfg);
rng(10000);
res = simulate_dynamic(repeat, method, S.net, cfg);
for i = 1:min(size(res.ctrl, 1), numel(res.alongTrack))
    fprintf('step %2d: v=%.4f wt=%.4f wp=%.4f along=%.4f\n', i, res.ctrl(i,1), res.ctrl(i,2), res.ctrl(i,3), res.alongTrack(i));
end
end
