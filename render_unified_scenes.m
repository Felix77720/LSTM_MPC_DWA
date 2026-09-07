function render_unified_scenes(seed)
% render_unified_scenes - Render S1--S4 with one shared plotting protocol.
% The same seed, method order, colors, axes, labels, and prediction panels
% are used for every fixed scenario so visual differences reflect behavior,
% not figure-generation differences.
if nargin < 1, seed = 1; end

here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));

cfg = config_LSTM();
cfg.mpc.wRoute = 3;
cfg.maxSteps = 650;
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;
netfile = fullfile(here, 'results', 'lstm_predictor.mat');
S = load(netfile, 'net', 'muX', 'sigX', 'muY', 'sigY');
net = S.net;
cfg.dyn.muX = S.muX; cfg.dyn.sigX = S.sigX;
cfg.dyn.muY = S.muY; cfg.dyn.sigY = S.sigY;

scenarios = generate_eval_scenarios(cfg);
methods = {'static', 'cv', 'kalman', 'lstm'};
outdir = fullfile(here, 'results', 'figures_unified');
if ~exist(outdir, 'dir'), mkdir(outdir); end

for si = 1:numel(scenarios)
    trajs = cell(1, numel(methods));
    run_steps = [];
    for mi = 1:numel(methods)
        path = fullfile(here, 'results', sprintf('seed%03d_%s_%d.mat', seed, methods{mi}, si));
        assert(exist(path, 'file') == 2, 'Missing current run: %s', path);
        R = load(path, 'res');
        trajs{mi} = R.res.traj;
        run_steps(end + 1) = R.res.steps; %#ok<AGROW>
    end
    visualize_scenario(scenarios(si), methods, trajs, cfg, outdir);
    visualize_prediction(scenarios(si), net, cfg, max(10, round(min(run_steps) / 2)), outdir);
    % Keep one detour-evidence figure for every fixed scenario and use the
    % same representative LSTM run as the unified trajectory panel.
    lstm_file = fullfile(here, 'results', sprintf('seed%03d_lstm_%d.mat', seed, si));
    Rl = load(lstm_file, 'res');
    visualize_detour_evidence(Rl.res, struct(), cfg, outdir, sprintf('lstm_detour_evidence_S%d', si));
end

save(fullfile(outdir, sprintf('unified_render_seed%03d.mat', seed)), ...
    'cfg', 'scenarios', 'methods', 'seed');
fprintf('Unified S1-S4 figures written to %s\n', outdir);
end
