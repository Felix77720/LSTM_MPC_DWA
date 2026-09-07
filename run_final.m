% run_final - Single-seed final experiment: comparison, visualization, and
% the CSV outputs consumed by build_paper_docx_cn.py.

clear; close all; clc;

here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
casadi = fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b');
addpath(here, baseline, casadi);

rng(0);
cfg = config_LSTM();
cfg.mpc.wRoute = 3;
cfg.maxSteps = 650;
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;
outdir = fullfile(here, 'results');
if ~exist(outdir, 'dir'), mkdir(outdir); end

netfile = fullfile(outdir, 'lstm_predictor.mat');
S = load(netfile, 'net', 'muX', 'sigX', 'muY', 'sigY');
net = S.net;
cfg.dyn.muX = S.muX; cfg.dyn.sigX = S.sigX;
cfg.dyn.muY = S.muY; cfg.dyn.sigY = S.sigY;

scenarios = generate_eval_scenarios(cfg);
methods = {'static', 'cv', 'kalman', 'lstm'};

rows = {};
results = cell(numel(scenarios), numel(methods));

for s = 1:numel(scenarios)
    scen = scenarios(s);
    for mi = 1:numel(methods)
        m = methods{mi};
        rng(1000 + s);
        res = simulate_dynamic(scen, m, net, cfg);
        results{s, mi} = res;
        rows(end + 1, :) = {1, scen.name, m, res.success, res.failureType, res.collisions, ...
            res.collisionEvents, res.solveFailures, res.fallbackSteps, res.minClearance, res.pathLength, res.trackRMSE, ...
            res.meanStepTime * 1000, res.p95StepTime * 1000, res.meanPredictionTime * 1000, ...
            res.meanDwaTime * 1000, res.meanMpcTime * 1000, res.meanPlantMetricTime * 1000, res.ADE, res.FDE}; %#ok<AGROW>
        fprintf('%s | %s | success=%d clear=%.3f coll=%d len=%.3f rmse=%.3f ADE=%.3f FDE=%.3f\n', ...
            scen.name, m, res.success, res.minClearance, res.collisions, ...
            res.pathLength, res.trackRMSE, res.ADE, res.FDE);
    end
end

comp = cell2table(rows, 'VariableNames', {'Seed', 'Scenario', 'Method', 'Success', 'FailureType', ...
    'Collisions', 'CollisionEvents', 'SolveFailures', 'FallbackSteps', 'MinSafeDist_m', ...
    'PathLength_m', 'TrackRMSE_m', 'MeanStepTime_ms', 'P95StepTime_ms', ...
    'MeanPredictionTime_ms', 'MeanDwaTime_ms', 'MeanMpcTime_ms', ...
    'MeanPlantMetricTime_ms', 'ADE_m', 'FDE_m'});
writetable(comp, fullfile(outdir, 'single_seed_comparison.csv'));

summary = {};
for mi = 1:numel(methods)
    m = methods{mi};
    sel = strcmp(comp.Method, m);
    summary(end + 1, :) = {m, sum(sel), sum(comp.Success(sel)), ...
        mean(comp.Collisions(sel)), std(comp.Collisions(sel)), ...
        mean(comp.MinSafeDist_m(sel)), std(comp.MinSafeDist_m(sel)), ...
        mean(comp.ADE_m(sel)), std(comp.ADE_m(sel)), ...
        mean(comp.FDE_m(sel)), std(comp.FDE_m(sel)), ...
        mean(comp.MeanStepTime_ms(sel)), median(comp.MeanStepTime_ms(sel)), ...
        mean(comp.P95StepTime_ms(sel)), mean(comp.MeanPredictionTime_ms(sel)), ...
        mean(comp.MeanDwaTime_ms(sel)), mean(comp.MeanMpcTime_ms(sel)), ...
        mean(comp.MeanPlantMetricTime_ms(sel)), sum(~comp.Success(sel))}; %#ok<AGROW>
end
sumT = cell2table(summary, 'VariableNames', {'Method', 'Trials', 'SuccessCount', ...
    'MeanCollisions', 'StdCollisions', 'MeanMinSafeDist_m', 'StdMinSafeDist_m', ...
    'MeanADE_m', 'StdADE_m', 'MeanFDE_m', 'StdFDE_m', ...
    'MeanStepTime_ms', 'MedianStepTime_ms', 'MeanP95StepTime_ms', ...
    'MeanPredictionTime_ms', 'MeanDwaTime_ms', 'MeanMpcTime_ms', ...
    'MeanPlantMetricTime_ms', 'FailureCount'});
writetable(sumT, fullfile(outdir, 'single_seed_summary.csv'));
disp(sumT);

% metrics.csv (kept in the same single-seed form as run_experiments)
M = {};
for s = 1:numel(scenarios)
    for mi = 1:numel(methods)
        res = results{s, mi};
        M(end + 1, :) = {scenarios(s).name, method_label(methods{mi}), ...
            res.success, res.collisions, res.minClearance, res.pathLength, ...
            res.trackRMSE, res.meanStepTime * 1000, res.ADE, res.FDE}; %#ok<AGROW>
    end
end
metrics = cell2table(M, 'VariableNames', {'Scenario', 'Method', 'Success', ...
    'Collisions', 'MinSafeDist_m', 'PathLength_m', 'TrackRMSE_m', ...
    'MeanStepTime_ms', 'ADE_m', 'FDE_m'});
writetable(metrics, fullfile(outdir, 'metrics.csv'));

% Visualization
for s = 1:numel(scenarios)
    trajs = cell(1, numel(methods));
    for mi = 1:numel(methods)
        trajs{mi} = results{s, mi}.traj;
    end
    visualize_scenario(scenarios(s), methods, trajs, cfg, outdir);
    lstm_idx = find(strcmp(methods, 'lstm'), 1);
    mid = max(10, round(results{s, lstm_idx}.steps / 2));
    visualize_prediction(scenarios(s), net, cfg, mid, outdir);
end

save(fullfile(outdir, 'results.mat'), 'results', 'scenarios', 'methods', 'comp', 'sumT', 'metrics');
fprintf('Single-seed final run complete. Outputs in %s\n', outdir);

function lbl = method_label(m)
switch lower(m)
    case 'static',  lbl = 'MPC-DWA 静态';
    case 'cv',      lbl = 'MPC-DWA 匀速外推';
    case 'kalman',  lbl = 'MPC-DWA 卡尔曼';
    case 'lstm',    lbl = '本文 LSTM';
    otherwise,      lbl = m;
end
end
