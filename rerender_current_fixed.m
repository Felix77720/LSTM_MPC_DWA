function rerender_current_fixed()
% rerender_current_fixed - Replot all fixed scenes from the latest seed-1 MATs.

here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));
cfg = config_LSTM();
cfg.maxSteps = 650;
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;
S = load(fullfile(here, 'results', 'lstm_predictor.mat'), 'net', 'muX', 'sigX', 'muY', 'sigY');
cfg.dyn.muX = S.muX; cfg.dyn.sigX = S.sigX;
cfg.dyn.muY = S.muY; cfg.dyn.sigY = S.sigY;
scenarios = generate_eval_scenarios(cfg);
methods = {'static', 'cv', 'kalman', 'lstm'};
for si = 1:numel(scenarios)
    trajs = cell(1, numel(methods));
    for mi = 1:numel(methods)
        R = load(fullfile(here, 'results', sprintf('seed001_%s_%d.mat', methods{mi}, si)), 'res');
        trajs{mi} = R.res.traj;
    end
    visualize_scenario(scenarios(si), methods, trajs, cfg, fullfile(here, 'results'));
    R = load(fullfile(here, 'results', sprintf('seed001_lstm_%d.mat', si)), 'res');
    visualize_prediction(scenarios(si), S.net, cfg, max(10, round(R.res.steps / 2)), fullfile(here, 'results'));
end
fprintf('CURRENT_FIXED_PLOTS=%s\n', fullfile(here, 'results'));
end
