function run_sensing_robustness()
% run_sensing_robustness - Matched clean/noise/delay/joint stress evaluation.
%
% Every condition uses the same dense S4 scenario and the same stochastic
% seeds across static, CV, Kalman, and LSTM.  This keeps the observation and
% DWA randomness matched while exposing the individual effects of noise,
% delayed observations, and their combination.

here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));

cfg0 = config_LSTM();
cfg0.mpc.wRoute = 3;
cfg0.maxSteps = 650;
cfg0.dyn.T_obs = cfg0.maxSteps + cfg0.dyn.N_pred + cfg0.dyn.T_hist + 10;

outroot = fullfile(here, 'results', 'robustness_unified');
if ~exist(outroot, 'dir'), mkdir(outroot); end
runid = datestr(now, 'yyyymmdd_HHMMSS');
outdir = fullfile(outroot, ['sensing_' runid]);
mkdir(outdir);

netfile = fullfile(here, 'results', 'lstm_predictor.mat');
assert(exist(netfile, 'file') == 2, 'Missing pretrained LSTM: %s', netfile);
S = load(netfile, 'net', 'muX', 'sigX', 'muY', 'sigY');
net = S.net;
cfg0.dyn.muX = S.muX; cfg0.dyn.sigX = S.sigX;
cfg0.dyn.muY = S.muY; cfg0.dyn.sigY = S.sigY;
model_sha = file_sha256(netfile);

scenarios = generate_eval_scenarios(cfg0);
scenario = scenarios(4);  % fixed dense S4 is the pressure case
methods = {'static', 'cv', 'kalman', 'lstm'};
seeds = 1:3;
conditions = struct( ...
    'Name', {'clean', 'noise005', 'delay1', 'noise005_delay1'}, ...
    'ObsNoise_m', {0, 0.05, 0, 0.05}, ...
    'ObsDelaySteps', {0, 0, 1, 1});
rows = {};

for ci = 1:numel(conditions)
    cond = conditions(ci);
    cfg = cfg0;
    cfg.dyn.obsNoise = cond.ObsNoise_m;
    cfg.dyn.obsDelaySteps = cond.ObsDelaySteps;
    for seed = seeds
        for mi = 1:numel(methods)
            method = methods{mi};
            % Reset before every method so stochastic observations and DWA
            % sampling are matched across methods within each trial.
            rng(700000 + ci * 10000 + seed);
            fprintf('sensing condition=%s seed=%d %s noise=%.3f delay=%d\n', ...
                cond.Name, seed, method, cfg.dyn.obsNoise, cfg.dyn.obsDelaySteps);
            res = simulate_dynamic(scenario, method, net, cfg);
            p95 = percentile_or_local(res.stepTimes, 95) * 1000;
            rows(end + 1, :) = {cond.Name, cond.ObsNoise_m, cond.ObsDelaySteps, ...
                seed, scenario.name, method, model_sha, res.steps, res.success, ...
                res.failureType, res.collisions, res.collisionEvents, ...
                res.minClearance, res.pathLength, res.trackRMSE, ...
                res.meanStepTime * 1000, p95, res.meanPredictionTime * 1000, ...
                res.meanDwaTime * 1000, res.meanMpcTime * 1000, ...
                res.meanPlantMetricTime * 1000, res.ADE, res.FDE, ...
                res.finalDist, res.solveFailures, res.fallbackSteps}; %#ok<AGROW>
            save(fullfile(outdir, sprintf('%s_seed%03d_%s.mat', ...
                cond.Name, seed, method)), 'res', 'cfg', 'seed', 'method', ...
                'cond', 'model_sha');
        end
    end
end

T = cell2table(rows, 'VariableNames', {'Condition', 'ObsNoise_m', ...
    'ObsDelaySteps', 'Seed', 'Scenario', 'Method', 'ModelSHA256', 'Steps', ...
    'Success', 'FailureType', 'Collisions', 'CollisionEvents', ...
    'MinClearance_m', 'PathLength_m', 'TrackRMSE_m', 'MeanStepTime_ms', ...
    'P95StepTime_ms', 'MeanPredictionTime_ms', 'MeanDwaTime_ms', ...
    'MeanMpcTime_ms', 'MeanPlantMetricTime_ms', 'ADE_m', 'FDE_m', ...
    'FinalDist_m', 'SolveFailures', 'FallbackSteps'});
writetable(T, fullfile(outdir, 'sensing_comparison.csv'));

summary = {};
for ci = 1:numel(conditions)
    cond = conditions(ci);
    for mi = 1:numel(methods)
        method = methods{mi};
        sel = strcmp(T.Condition, cond.Name) & strcmp(T.Method, method);
        summary(end + 1, :) = {cond.Name, cond.ObsNoise_m, cond.ObsDelaySteps, ...
            method, sum(sel), sum(T.Success(sel)), mean(T.Collisions(sel)), ...
            mean(T.CollisionEvents(sel)), mean(T.MinClearance_m(sel)), ...
            std(T.MinClearance_m(sel)), mean(T.ADE_m(sel)), std(T.ADE_m(sel)), ...
            mean(T.FDE_m(sel)), std(T.FDE_m(sel)), mean(T.MeanStepTime_ms(sel)), ...
            median(T.MeanStepTime_ms(sel)), mean(T.P95StepTime_ms(sel)), ...
            mean(T.MeanPredictionTime_ms(sel)), mean(T.MeanDwaTime_ms(sel)), ...
            mean(T.MeanMpcTime_ms(sel)), mean(T.MeanPlantMetricTime_ms(sel)), ...
            mean(T.FallbackSteps(sel)), sum(~T.Success(sel))}; %#ok<AGROW>
    end
end
Sout = cell2table(summary, 'VariableNames', {'Condition', 'ObsNoise_m', ...
    'ObsDelaySteps', 'Method', 'Trials', 'SuccessCount', 'MeanCollisions', ...
    'MeanCollisionEvents', 'MeanMinClearance_m', 'StdMinClearance_m', ...
    'MeanADE_m', 'StdADE_m', 'MeanFDE_m', 'StdFDE_m', 'MeanStepTime_ms', ...
    'MedianStepTime_ms', 'MeanP95StepTime_ms', 'MeanPredictionTime_ms', ...
    'MeanDwaTime_ms', 'MeanMpcTime_ms', 'MeanPlantMetricTime_ms', ...
    'MeanFallbackSteps', 'FailureCount'});
writetable(Sout, fullfile(outdir, 'sensing_summary.csv'));
save(fullfile(outdir, 'sensing_robustness.mat'), 'T', 'Sout', 'cfg0', ...
    'scenario', 'methods', 'seeds', 'conditions', 'model_sha');
disp(Sout);
fprintf('Unified sensing robustness run complete: %s\n', outdir);
end

function v = percentile_or_local(x, q)
if isempty(x), v = NaN; else, v = prctile(x, q); end
end

function h = file_sha256(path)
md = java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(path, 'r'); bytes = fread(fid, Inf, '*uint8'); fclose(fid);
md.update(bytes); digest = typecast(md.digest(), 'uint8');
h = lower(reshape(dec2hex(digest)', 1, []));
end
