function run_random_multiseed()
% run_random_multiseed - Expanded random-scenario closed-loop comparison.
%
% The scenario set is generated once from a fixed seed and reused for every
% method.  A separate seed is used for the stochastic DWA sampling.  The
% runner writes one row per trial and one trajectory CSV per trial so that
% success, failure type, collision events, and timing can be audited.

here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));

cfg = config_LSTM();
cfg.mpc.wRoute = 3;
cfg.maxSteps = 650;
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;

outroot = fullfile(here, 'results', 'random_eval');
if ~exist(outroot, 'dir'), mkdir(outroot); end
runid = datestr(now, 'yyyymmdd_HHMMSS');
outdir = fullfile(outroot, ['random12_' runid]);
mkdir(outdir);

netfile = fullfile(here, 'results', 'lstm_predictor.mat');
assert(exist(netfile, 'file') == 2, 'Missing pretrained LSTM: %s', netfile);
S = load(netfile, 'net', 'muX', 'sigX', 'muY', 'sigY');
net = S.net;
cfg.dyn.muX = S.muX; cfg.dyn.sigX = S.sigX;
cfg.dyn.muY = S.muY; cfg.dyn.sigY = S.sigY;
model_sha = file_sha256(netfile);

nScenarios = getfield_or_local(cfg.dyn, 'randomEvalScenarios', 12);
evalSeeds = getfield_or_local(cfg.dyn, 'randomEvalSeeds', 1:3);
scenarioSeed = 20260905;
scenarios = generate_random_eval_scenarios(cfg, nScenarios, scenarioSeed);
methods = {'static', 'cv', 'kalman', 'lstm'};
rows = {};

scenario_meta = cell(nScenarios, 4);
for si = 1:nScenarios
    scenario_meta(si, :) = {si, scenarios(si).scenarioSeed, scenarios(si).name, ...
        strjoin(scenarios(si).obstacleKinds, '|')};
end
writetable(cell2table(scenario_meta, 'VariableNames', ...
    {'ScenarioIndex', 'ScenarioSeed', 'Scenario', 'ObstacleKinds'}), ...
    fullfile(outdir, 'random_scenarios.csv'));

for seed = evalSeeds
    for si = 1:nScenarios
        scen = scenarios(si);
        for mi = 1:numel(methods)
            method = methods{mi};
            rng(seed * 100000 + si);
            fprintf('random seed=%d R%02d %s\n', seed, si, method);
            res = simulate_dynamic(scen, method, net, cfg);
            p95 = percentile_or_local(res.stepTimes, 95) * 1000;
            rows(end + 1, :) = {seed, si, scen.name, method, model_sha, res.success, ...
                res.failureType, res.collisions, res.collisionEvents, res.solveFailures, ...
                res.fallbackSteps, res.steps, res.finalDist, res.minClearance, ...
                res.pathLength, res.trackRMSE, res.meanStepTime * 1000, p95, ...
                res.meanPredictionTime * 1000, res.meanDwaTime * 1000, ...
                res.meanMpcTime * 1000, res.meanPlantMetricTime * 1000, ...
                res.ADE, res.FDE}; %#ok<AGROW>
            save(fullfile(outdir, sprintf('seed%03d_R%02d_%s.mat', seed, si, method)), ...
                'res', 'cfg', 'seed', 'si', 'scen', 'method', 'model_sha');
            write_trial_csv(outdir, seed, si, method, res);
            fprintf('  success=%d failure=%s clearance=%.3f ADE=%.3f\n', ...
                res.success, res.failureType, res.minClearance, res.ADE);
        end
    end
end

T = cell2table(rows, 'VariableNames', {'Seed', 'ScenarioIndex', 'Scenario', 'Method', ...
    'ModelSHA256', 'Success', 'FailureType', 'Collisions', 'CollisionEvents', ...
    'SolveFailures', 'FallbackSteps', 'Steps', 'FinalDist_m', 'MinSafeDist_m', ...
    'PathLength_m', 'TrackRMSE_m', 'MeanStepTime_ms', 'P95StepTime_ms', ...
    'MeanPredictionTime_ms', 'MeanDwaTime_ms', 'MeanMpcTime_ms', ...
    'MeanPlantMetricTime_ms', 'ADE_m', 'FDE_m'});
writetable(T, fullfile(outdir, 'random_comparison.csv'));

summary = {};
for mi = 1:numel(methods)
    method = methods{mi};
    sel = strcmp(T.Method, method);
    summary(end + 1, :) = {method, sum(sel), sum(T.Success(sel)), ...
        mean(T.Collisions(sel)), mean(T.CollisionEvents(sel)), ...
        mean(T.MinSafeDist_m(sel)), std(T.MinSafeDist_m(sel)), ...
        mean(T.ADE_m(sel)), std(T.ADE_m(sel)), mean(T.FDE_m(sel)), ...
        std(T.FDE_m(sel)), mean(T.MeanStepTime_ms(sel)), ...
        median(T.MeanStepTime_ms(sel)), mean(T.MeanPredictionTime_ms(sel)), ...
        mean(T.MeanDwaTime_ms(sel)), mean(T.MeanMpcTime_ms(sel)), ...
        mean(T.MeanPlantMetricTime_ms(sel)), mean(T.FallbackSteps(sel)), ...
        sum(~T.Success(sel))}; %#ok<AGROW>
end
Sout = cell2table(summary, 'VariableNames', {'Method', 'Trials', 'SuccessCount', ...
    'MeanCollisions', 'MeanCollisionEvents', 'MeanMinSafeDist_m', ...
    'StdMinSafeDist_m', 'MeanADE_m', 'StdADE_m', 'MeanFDE_m', 'StdFDE_m', ...
    'MeanStepTime_ms', 'MedianStepTime_ms', 'MeanPredictionTime_ms', ...
    'MeanDwaTime_ms', 'MeanMpcTime_ms', 'MeanPlantMetricTime_ms', ...
    'MeanFallbackSteps', 'FailureCount'});
writetable(Sout, fullfile(outdir, 'random_summary.csv'));
save(fullfile(outdir, 'random_suite.mat'), 'T', 'Sout', 'cfg', 'scenarios', ...
    'methods', 'evalSeeds', 'scenarioSeed', 'model_sha');
disp(Sout);
fprintf('Random scenario run complete: %s\n', outdir);
end

function write_trial_csv(outdir, seed, si, method, res)
path = fullfile(outdir, sprintf('seed%03d_R%02d_%s_trajectory.csv', seed, si, method));
n = numel(res.stepTimes);
step = (1:n)';
v = [step, res.stepTimes(:) * 1000, res.predictionTimes(:) * 1000, ...
    res.dwaTimes(:) * 1000, res.mpcTimes(:) * 1000, res.plantMetricTimes(:) * 1000];
writetable(array2table(v, 'VariableNames', {'Step', 'StepTime_ms', ...
    'PredictionTime_ms', 'DwaTime_ms', 'MpcTime_ms', 'PlantMetricTime_ms'}), path);
end

function v = getfield_or_local(s, name, default)
if isfield(s, name) && ~isempty(s.(name)), v = s.(name); else, v = default; end
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
