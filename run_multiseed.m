% run_multiseed - Multi-seed comparison of static / cv / kalman / lstm methods.
%
% Loads a pretrained LSTM predictor and reuses the fixed evaluation scenarios,
% then runs the closed-loop simulation for four fixed scenes, three matched
% run seeds and four prediction methods (48 run-level records in total).
% DWA sampling is stochastic, so the summary reports matched multi-seed means
% and standard deviations.

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
assert(exist(netfile, 'file') == 2, 'Missing pretrained LSTM: %s', netfile);
S = load(netfile, 'net', 'muX', 'sigX', 'muY', 'sigY');
net = S.net;
cfg.dyn.muX = S.muX; cfg.dyn.sigX = S.sigX;
cfg.dyn.muY = S.muY; cfg.dyn.sigY = S.sigY;
model_sha = file_sha256(netfile);

scenarios = generate_eval_scenarios(cfg);
methods = {'static', 'cv', 'kalman', 'lstm'};
seeds = 1:3;

rows = {};
for seed = seeds
    for s = 1:numel(scenarios)
        scen = scenarios(s);
        for mi = 1:numel(methods)
            m = methods{mi};
            rng(seed * 1000 + s);
            res = simulate_dynamic(scen, m, net, cfg);
            [detour_events, ~] = count_detour_events(res.horizontalOffset);
            rows(end + 1, :) = {seed, scen.name, m, model_sha, res.success, res.failureType, res.collisions, ...
                res.collisionEvents, detour_events, res.solveFailures, res.fallbackSteps, res.steps, res.finalDist, ...
                res.minClearance, res.pathLength, res.trackRMSE, res.meanStepTime * 1000, res.p95StepTime * 1000, ...
                res.meanPredictionTime * 1000, res.meanDwaTime * 1000, res.meanMpcTime * 1000, ...
                res.meanPlantMetricTime * 1000, res.ADE, res.FDE}; %#ok<AGROW>
            save(fullfile(outdir, sprintf('seed%03d_%s_%d.mat', seed, m, s)), ...
                'res', 'cfg', 'seed', 'scen', 'm', 'model_sha');
            fprintf('seed=%d %s %s success=%d clearance=%.3f ADE=%.3f\n', ...
                seed, scen.name, m, res.success, res.minClearance, res.ADE);
        end
    end
end

R = cell2table(rows, 'VariableNames', {'Seed', 'Scenario', 'Method', 'ModelSHA256', 'Success', 'FailureType', ...
    'Collisions', 'CollisionEvents', 'DetourEvents', 'SolveFailures', 'FallbackSteps', 'Steps', 'FinalDist_m', ...
    'MinSafeDist_m', 'PathLength_m', 'TrackRMSE_m', 'MeanStepTime_ms', 'P95StepTime_ms', ...
    'MeanPredictionTime_ms', 'MeanDwaTime_ms', 'MeanMpcTime_ms', 'MeanPlantMetricTime_ms', 'ADE_m', 'FDE_m'});
writetable(R, fullfile(outdir, 'multiseed_comparison.csv'));

summary = {};
for mi = 1:numel(methods)
    m = methods{mi};
    sel = strcmp(R.Method, m);
    n = sum(sel);
    summary(end + 1, :) = {m, n, sum(R.Success(sel)), ...
        mean(R.Collisions(sel)), std(R.Collisions(sel)), ...
        mean(R.MinSafeDist_m(sel)), std(R.MinSafeDist_m(sel)), ...
        mean(R.ADE_m(sel)), std(R.ADE_m(sel)), ...
        mean(R.FDE_m(sel)), std(R.FDE_m(sel)), ...
        mean(R.MeanStepTime_ms(sel)), median(R.MeanStepTime_ms(sel)), ...
        mean(R.P95StepTime_ms(sel)), mean(R.MeanPredictionTime_ms(sel)), ...
        mean(R.MeanDwaTime_ms(sel)), mean(R.MeanMpcTime_ms(sel)), ...
        mean(R.MeanPlantMetricTime_ms(sel)), sum(~R.Success(sel))}; %#ok<AGROW>
end
S_ = cell2table(summary, 'VariableNames', {'Method', 'Trials', 'SuccessCount', ...
    'MeanCollisions', 'StdCollisions', 'MeanMinSafeDist_m', 'StdMinSafeDist_m', ...
    'MeanADE_m', 'StdADE_m', 'MeanFDE_m', 'StdFDE_m', ...
    'MeanStepTime_ms', 'MedianStepTime_ms', 'MeanP95StepTime_ms', ...
    'MeanPredictionTime_ms', 'MeanDwaTime_ms', 'MeanMpcTime_ms', ...
    'MeanPlantMetricTime_ms', 'FailureCount'});
writetable(S_, fullfile(outdir, 'multiseed_summary.csv'));

disp(S_);
fprintf('Multi-seed run complete. Outputs: multiseed_comparison.csv, multiseed_summary.csv\n');

function h = file_sha256(path)
md = java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(path, 'r'); bytes = fread(fid, Inf, '*uint8'); fclose(fid);
md.update(bytes); digest = typecast(md.digest(), 'uint8');
h = lower(reshape(dec2hex(digest)', 1, []));
end
