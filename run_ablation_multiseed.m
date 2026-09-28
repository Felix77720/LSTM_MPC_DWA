function run_ablation_multiseed()
% run_ablation_multiseed - Three-seed matched ablation protocol.
%
% The protocol keeps one independently generated encounter scenario fixed and
% repeats the structural ablations with three matched DWA sampling seeds:
% route-recovery weight, MPC-only/DWA-only injection, and injected horizon.
% The scenario is intentionally the same as the earlier mechanism-diagnostic
% experiment so that the new results are comparable without changing the
% scientific question. Main multi-scene generalization is evaluated by
% run_random_multiseed and summarized by analyze_cluster_bootstrap.

clear; close all; clc;

here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
casadi = fullfile(baseline, 'third_party', ...
    'casadi-3.8.0-windows64-matlab2018b');
addpath(here, baseline, casadi);

rng(0);
cfg = config_LSTM();
cfg.mpc.wRoute = 3;
cfg.maxSteps = 700;
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;

outroot = fullfile(here, 'results', 'ablation_multiseed');
if ~exist(outroot, 'dir'), mkdir(outroot); end
runid = datestr(now, 'yyyymmdd_HHMMSS');
outdir = fullfile(outroot, ['ablation_' runid]);
mkdir(outdir);

net_candidates = { ...
    fullfile(here, 'results', 'lstm_predictor.mat'), ...
    fullfile(here, '_local_archive', 'results', 'lstm_predictor.mat')};
netfile = '';
for i = 1:numel(net_candidates)
    if exist(net_candidates{i}, 'file') == 2
        netfile = net_candidates{i};
        break;
    end
end
assert(~isempty(netfile), 'Missing pretrained LSTM predictor.');

S = load(netfile, 'net', 'muX', 'sigX', 'muY', 'sigY');
net = S.net;
cfg.dyn.muX = S.muX;
cfg.dyn.sigX = S.sigX;
cfg.dyn.muY = S.muY;
cfg.dyn.sigY = S.sigY;
model_sha = file_sha256(netfile);

scenario = generate_repeat_scenario(cfg);
seeds = 1:3;
jobs = make_jobs();
rows = cell(0, 26);

for seed = seeds
    for ji = 1:numel(jobs)
        job = jobs(ji);
        cfg.mpc.wRoute = job.RouteWeight;
        cfg.dyn.injectHorizon = min(job.Horizon, cfg.dyn.N_pred);

        % Matched across ablation variants for each seed.
        rng(910000 + seed);
        fprintf('ablation seed=%d job=%d/%d variant=%s\n', ...
            seed, ji, numel(jobs), job.Variant);
        res = simulate_dynamic(scenario, job.Method, net, cfg);

        rows(end + 1, :) = {seed, scenario.name, job.Variant, job.Method, ...
            job.Horizon, job.RouteWeight, model_sha, res.success, ...
            res.failureType, res.collisions, res.collisionEvents, res.steps, ...
            res.minClearance, res.pathLength, res.trackRMSE, ...
            res.meanStepTime * 1000, prctile(res.stepTimes, 95) * 1000, ...
            res.meanPredictionTime * 1000, res.meanDwaTime * 1000, ...
            res.meanMpcTime * 1000, res.meanPlantMetricTime * 1000, ...
            res.ADE, res.FDE, res.finalDist, res.solveFailures, ...
            res.fallbackSteps}; %#ok<AGROW>

        safe_name = regexprep(job.Variant, '[^A-Za-z0-9_]+', '_');
        trial = fullfile(outdir, sprintf('seed%03d_%s.mat', seed, safe_name));
        save(trial, 'res', 'cfg', 'seed', 'job', 'scenario', 'model_sha');
    end
end

T = cell2table(rows, 'VariableNames', { ...
    'Seed', 'Scenario', 'Variant', 'Method', 'Horizon_steps', ...
    'RouteWeight', 'ModelSHA256', 'Success', 'FailureType', 'Collisions', ...
    'CollisionEvents', 'Steps', 'MinSafeDist_m', 'PathLength_m', ...
    'TrackRMSE_m', 'MeanStepTime_ms', 'P95StepTime_ms', ...
    'MeanPredictionTime_ms', 'MeanDwaTime_ms', 'MeanMpcTime_ms', ...
    'MeanPlantMetricTime_ms', 'ADE_m', 'FDE_m', 'FinalDist_m', ...
    'SolveFailures', 'FallbackSteps'});
writetable(T, fullfile(outdir, 'ablation_multiseed_comparison.csv'));

summary = cell(0, 17);
for ji = 1:numel(jobs)
    v = jobs(ji).Variant;
    sel = strcmp(T.Variant, v);
    summary(end + 1, :) = {v, sum(sel), sum(T.Success(sel)), ...
        mean(T.Success(sel)), mean(T.Collisions(sel)), std(T.Collisions(sel)), ...
        mean(T.MinSafeDist_m(sel)), std(T.MinSafeDist_m(sel)), ...
        mean(T.ADE_m(sel)), std(T.ADE_m(sel)), mean(T.FDE_m(sel)), ...
        std(T.FDE_m(sel)), mean(T.MeanStepTime_ms(sel)), ...
        std(T.MeanStepTime_ms(sel)), mean(T.P95StepTime_ms(sel)), ...
        mean(T.FallbackSteps(sel)), sum(~T.Success(sel))}; %#ok<AGROW>
end
Sout = cell2table(summary, 'VariableNames', { ...
    'Variant', 'Trials', 'SuccessCount', 'SuccessRate', ...
    'MeanCollisions', 'StdCollisions', 'MeanMinSafeDist_m', ...
    'StdMinSafeDist_m', 'MeanADE_m', 'StdADE_m', 'MeanFDE_m', ...
    'StdFDE_m', 'MeanStepTime_ms', 'StdStepTime_ms', 'MeanP95StepTime_ms', ...
    'MeanFallbackSteps', 'FailureCount'});
writetable(Sout, fullfile(outdir, 'ablation_multiseed_summary.csv'));

% Matched seed-level differences make the small ablation honest: no
% significance claim is made, but the direction and spread are visible.
pair_names = {'Full_LSTM_H30', 'LSTM_MPC_only_H30', ...
    'LSTM_DWA_only_H30', 'LSTM_H10', 'LSTM_H20'};
pair_rows = cell(0, 10);
for pi = 1:numel(pair_names)
    if strcmp(pair_names{pi}, 'Full_LSTM_H30')
        continue;
    end
    ref = table_for_variant(T, 'Full_LSTM_H30');
    alt = table_for_variant(T, pair_names{pi});
    [~, ia, ib] = intersect(ref.Seed, alt.Seed);
    pair_rows(end + 1, :) = {pair_names{pi}, numel(ia), ...
        mean(ref.Success(ia) - alt.Success(ib)), ...
        mean(ref.MinSafeDist_m(ia) - alt.MinSafeDist_m(ib)), ...
        std(ref.MinSafeDist_m(ia) - alt.MinSafeDist_m(ib)), ...
        mean(ref.ADE_m(ia) - alt.ADE_m(ib)), ...
        mean(ref.FDE_m(ia) - alt.FDE_m(ib)), ...
        mean(ref.MeanStepTime_ms(ia) - alt.MeanStepTime_ms(ib)), ...
        mean(ref.FallbackSteps(ia) - alt.FallbackSteps(ib)), ...
        sprintf('%s - %s', 'Full_LSTM_H30', pair_names{pi})}; %#ok<AGROW>
end
P = cell2table(pair_rows, 'VariableNames', {'ComparedVariant', ...
    'MatchedSeeds', 'DeltaSuccess', 'DeltaMinSafeDist_m', ...
    'SDDeltaMinSafeDist_m', 'DeltaADE_m', 'DeltaFDE_m', ...
    'DeltaMeanStepTime_ms', 'DeltaFallbackSteps', 'Contrast'});
writetable(P, fullfile(outdir, 'ablation_multiseed_paired_differences.csv'));

save(fullfile(outdir, 'ablation_multiseed.mat'), 'T', 'Sout', 'P', ...
    'cfg', 'scenario', 'jobs', 'seeds', 'model_sha');
fprintf('Three-seed ablation complete: %s\n', outdir);
end

function jobs = make_jobs()
jobs = struct('Variant', {}, 'Method', {}, 'Horizon', {}, 'RouteWeight', {});
jobs(end + 1) = struct('Variant', 'LSTM_route0_H30', ...
    'Method', 'lstm', 'Horizon', 30, 'RouteWeight', 0);
jobs(end + 1) = struct('Variant', 'Full_LSTM_H30', ...
    'Method', 'lstm', 'Horizon', 30, 'RouteWeight', 3);
jobs(end + 1) = struct('Variant', 'LSTM_MPC_only_H30', ...
    'Method', 'lstm_mpc_only', 'Horizon', 30, 'RouteWeight', 3);
jobs(end + 1) = struct('Variant', 'LSTM_DWA_only_H30', ...
    'Method', 'lstm_dwa_only', 'Horizon', 30, 'RouteWeight', 3);
jobs(end + 1) = struct('Variant', 'LSTM_H10', ...
    'Method', 'lstm', 'Horizon', 10, 'RouteWeight', 3);
jobs(end + 1) = struct('Variant', 'LSTM_H20', ...
    'Method', 'lstm', 'Horizon', 20, 'RouteWeight', 3);
end

function T = table_for_variant(Tall, variant)
T = Tall(strcmp(Tall.Variant, variant), :);
end

function h = file_sha256(path)
md = java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(path, 'r');
assert(fid >= 0, 'Cannot open model file: %s', path);
bytes = fread(fid, Inf, '*uint8');
fclose(fid);
md.update(bytes);
digest = typecast(md.digest(), 'uint8');
h = lower(reshape(dec2hex(digest)', 1, []));
end
