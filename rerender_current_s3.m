function rerender_current_s3()
% rerender_current_s3 - Replot S3 from the latest multi-seed MAT outputs.

here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));

cfg = config_LSTM();
cfg.maxSteps = 550;
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;
scenarios = generate_eval_scenarios(cfg);
scen = scenarios(3);
methods = {'static', 'cv', 'kalman', 'lstm'};
seed = 1;
resultdir = fullfile(here, 'results', 's3_optimized');
trajs = cell(1, numel(methods));
for i = 1:numel(methods)
    path = fullfile(resultdir, sprintf('seed%03d_%s.mat', seed, methods{i}));
    S = load(path, 'res');
    trajs{i} = S.res.traj;
end

outdir = fullfile(resultdir, 'plots');
if ~exist(outdir, 'dir'), mkdir(outdir); end
visualize_scenario(scen, methods, trajs, cfg, outdir);

S = load(fullfile(resultdir, 'seed001_lstm.mat'), 'res');
noobs = struct('name', 'N0 无障碍对照', 'start', scen.start, 'goal', scen.goal, ...
    'obstacles', struct('traj', {}, 'radius', {}));
visualize_detour_evidence(S.res, noobs, cfg, outdir);
fprintf('CURRENT_S3_PLOTS=%s\n', outdir);
end
