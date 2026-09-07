function run_s3_optimized()
% run_s3_optimized - Multi-seed closed-loop validation of the corrected S3.

here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));

rng(0);
cfg = config_LSTM();
cfg.mpc.wRoute = 3;
cfg.maxSteps = 650;
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;
outdir = fullfile(here, 'results', 's3_optimized');
if ~exist(outdir, 'dir'), mkdir(outdir); end

netfile = fullfile(here, 'results', 'lstm_predictor.mat');
S = load(netfile, 'net', 'muX', 'sigX', 'muY', 'sigY');
cfg.dyn.muX = S.muX; cfg.dyn.sigX = S.sigX;
cfg.dyn.muY = S.muY; cfg.dyn.sigY = S.sigY;
model_sha = file_sha256(netfile);

scenarios = generate_eval_scenarios(cfg);
scen = scenarios(3);
methods = {'static', 'cv', 'kalman', 'lstm'};
seeds = 1:3;
rows = {};

for seed = seeds
    for mi = 1:numel(methods)
        m = methods{mi};
        rng(seed * 1000 + 3);
        res = simulate_dynamic(scen, m, S.net, cfg);
        [detour_events, ~] = count_detour_events(res.horizontalOffset, 0.25, 5, 10);
        rows(end + 1, :) = {seed, m, model_sha, res.success, res.failureType, ...
            res.collisions, res.minClearance, res.pathLength, res.trackRMSE, ...
            max(abs(res.horizontalOffset)), std(res.horizontalOffset), detour_events, ...
            max(abs(res.verticalOffset)), res.fallbackSteps, res.steps, res.meanStepTime * 1000, ...
            res.meanPredictionTime * 1000, res.meanDwaTime * 1000, ...
            res.meanMpcTime * 1000, res.ADE, res.FDE}; %#ok<AGROW>
        save(fullfile(outdir, sprintf('seed%03d_%s.mat', seed, m)), ...
            'res', 'cfg', 'seed', 'scen', 'm', 'model_sha');
        fprintf('S3OPT seed=%d method=%s success=%d clear=%.3f maxOffset=%.3f events=%d fallback=%d\n', ...
            seed, m, res.success, res.minClearance, max(abs(res.horizontalOffset)), ...
            detour_events, res.fallbackSteps);
    end
end

R = cell2table(rows, 'VariableNames', {'Seed', 'Method', 'ModelSHA256', 'Success', ...
    'FailureType', 'Collisions', 'MinSafeDist_m', 'PathLength_m', 'TrackRMSE_m', ...
            'MaxAbsOffset_m', 'OffsetStd_m', 'DetourEvents', 'MaxAbsVerticalOffset_m', ...
            'FallbackSteps', 'Steps', ...
    'MeanStepTime_ms', 'MeanPredictionTime_ms', 'MeanDwaTime_ms', 'MeanMpcTime_ms', ...
    'ADE_m', 'FDE_m'});
writetable(R, fullfile(outdir, 's3_comparison.csv'));

summary = {};
for mi = 1:numel(methods)
    m = methods{mi};
    sel = strcmp(R.Method, m);
    summary(end + 1, :) = {m, sum(sel), sum(R.Success(sel)), mean(R.Collisions(sel)), ...
        mean(R.MinSafeDist_m(sel)), mean(R.MaxAbsOffset_m(sel)), std(R.MaxAbsOffset_m(sel)), ...
        mean(R.DetourEvents(sel)), mean(R.MaxAbsVerticalOffset_m(sel)), ...
        mean(R.FallbackSteps(sel)), mean(R.MeanStepTime_ms(sel)), ...
        mean(R.MeanPredictionTime_ms(sel)), mean(R.MeanDwaTime_ms(sel)), ...
        mean(R.MeanMpcTime_ms(sel)), mean(R.ADE_m(sel)), mean(R.FDE_m(sel))}; %#ok<AGROW>
end
S_ = cell2table(summary, 'VariableNames', {'Method', 'Trials', 'SuccessCount', ...
    'MeanCollisions', 'MeanMinSafeDist_m', 'MeanMaxAbsOffset_m', 'StdMaxAbsOffset_m', ...
    'MeanDetourEvents', 'MeanMaxAbsVerticalOffset_m', 'MeanFallbackSteps', 'MeanStepTime_ms', ...
    'MeanPredictionTime_ms', 'MeanDwaTime_ms', 'MeanMpcTime_ms', 'MeanADE_m', 'MeanFDE_m'});
writetable(S_, fullfile(outdir, 's3_summary.csv'));
disp(S_);
fprintf('S3_OPTIMIZED_DONE=%s\n', outdir);
end

function h = file_sha256(path)
md = java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(path, 'r'); bytes = fread(fid, Inf, '*uint8'); fclose(fid);
md.update(bytes); digest = typecast(md.digest(), 'uint8');
h = lower(reshape(dec2hex(digest)', 1, []));
end
