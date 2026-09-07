function run_robustness_experiments()
% run_robustness_experiments - Stress test under delayed, noisy observations.
%
% The main comparison uses clean observations. This complementary experiment
% keeps the held-out dense S4 scene and controller settings fixed, then adds a
% 50-mm isotropic position-observation noise and one-step observation delay.
% The same seeds are reset for each method so that the stochastic observation
% sequence is matched across methods.

here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));

cfg = config_LSTM();
cfg.mpc.wRoute = 3;
cfg.maxSteps = 650;
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;
cfg.dyn.obsNoise = 0.05;
cfg.dyn.obsDelaySteps = 1;

outroot = fullfile(here, 'results', 'robustness');
if ~exist(outroot, 'dir'), mkdir(outroot); end
runid = datestr(now, 'yyyymmdd_HHMMSS');
outdir = fullfile(outroot, ['noise005_delay1_' runid]);
mkdir(outdir);

netfile = fullfile(here, 'results', 'lstm_predictor.mat');
assert(exist(netfile, 'file') == 2, 'Missing pretrained LSTM: %s', netfile);
S = load(netfile, 'net', 'muX', 'sigX', 'muY', 'sigY');
net = S.net;
cfg.dyn.muX = S.muX; cfg.dyn.sigX = S.sigX;
cfg.dyn.muY = S.muY; cfg.dyn.sigY = S.sigY;
model_sha = file_sha256(netfile);

scenarios = generate_eval_scenarios(cfg);
scenario = scenarios(4);
methods = {'static', 'cv', 'kalman', 'lstm'};
seeds = 1:3;
rows = {};

for seed = seeds
    for mi = 1:numel(methods)
        method = methods{mi};
        rng(700000 + seed);
        fprintf('robustness seed=%d %s noise=%.3f delay=%d\n', ...
            seed, method, cfg.dyn.obsNoise, cfg.dyn.obsDelaySteps);
        res = simulate_dynamic(scenario, method, net, cfg);
        p95 = NaN;
        if ~isempty(res.stepTimes), p95 = prctile(res.stepTimes, 95) * 1000; end
        rows(end + 1, :) = {seed, scenario.name, method, cfg.dyn.obsNoise, ...
            cfg.dyn.obsDelaySteps, model_sha, res.steps, res.success, res.failureType, ...
            res.collisions, res.collisionEvents, res.minClearance, ...
            res.pathLength, res.trackRMSE, res.meanStepTime * 1000, p95, ...
            res.meanPredictionTime * 1000, res.meanDwaTime * 1000, ...
            res.meanMpcTime * 1000, res.meanPlantMetricTime * 1000, ...
            res.ADE, res.FDE, res.finalDist, res.solveFailures, ...
            res.fallbackSteps}; %#ok<AGROW>
        save(fullfile(outdir, sprintf('seed%03d_%s.mat', seed, method)), ...
            'res', 'cfg', 'seed', 'method', 'model_sha');
    end
end

T = cell2table(rows, 'VariableNames', {'Seed', 'Scenario', 'Method', ...
    'ObsNoise_m', 'ObsDelaySteps', 'ModelSHA256', 'Steps', 'Success', 'FailureType', ...
    'Collisions', 'CollisionEvents', 'MinClearance_m', 'PathLength_m', ...
    'TrackRMSE_m', 'MeanStepTime_ms', 'P95StepTime_ms', 'MeanPredictionTime_ms', ...
    'MeanDwaTime_ms', 'MeanMpcTime_ms', 'MeanPlantMetricTime_ms', 'ADE_m', 'FDE_m', ...
    'FinalDist_m', 'SolveFailures', 'FallbackSteps'});
writetable(T, fullfile(outdir, 'robustness_comparison.csv'));

summary = {};
for mi = 1:numel(methods)
    method = methods{mi};
    sel = strcmp(T.Method, method);
    summary(end + 1, :) = {method, sum(sel), sum(T.Success(sel)), ...
        mean(T.Collisions(sel)), mean(T.CollisionEvents(sel)), ...
        mean(T.MinClearance_m(sel)), std(T.MinClearance_m(sel)), ...
        mean(T.ADE_m(sel)), std(T.ADE_m(sel)), mean(T.FDE_m(sel)), ...
        std(T.FDE_m(sel)), mean(T.MeanStepTime_ms(sel)), ...
        median(T.MeanStepTime_ms(sel)), mean(T.MeanPredictionTime_ms(sel)), ...
        mean(T.MeanDwaTime_ms(sel)), mean(T.MeanMpcTime_ms(sel)), ...
        mean(T.MeanPlantMetricTime_ms(sel)), mean(T.FallbackSteps(sel)), ...
        sum(~T.Success(sel))}; %#ok<AGROW>
end
Sout = cell2table(summary, 'VariableNames', {'Method', 'Trials', ...
    'SuccessCount', 'MeanCollisions', 'MeanCollisionEvents', ...
    'MeanMinClearance_m', 'StdMinClearance_m', 'MeanADE_m', 'StdADE_m', ...
    'MeanFDE_m', 'StdFDE_m', 'MeanStepTime_ms', 'MedianStepTime_ms', ...
    'MeanPredictionTime_ms', 'MeanDwaTime_ms', 'MeanMpcTime_ms', ...
    'MeanPlantMetricTime_ms', 'MeanFallbackSteps', 'FailureCount'});
writetable(Sout, fullfile(outdir, 'robustness_summary.csv'));
save(fullfile(outdir, 'robustness.mat'), 'T', 'Sout', 'cfg', 'scenario', ...
    'methods', 'seeds', 'model_sha');
disp(Sout);
fprintf('Robustness run complete: %s\n', outdir);
end

function h = file_sha256(path)
md = java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(path, 'r');
bytes = fread(fid, Inf, '*uint8');
fclose(fid);
md.update(bytes);
digest = typecast(md.digest(), 'uint8');
h = lower(reshape(dec2hex(digest)', 1, []));
end
