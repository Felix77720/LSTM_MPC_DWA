function outdir = analyze_cluster_bootstrap()
% analyze_cluster_bootstrap - Scene-clustered uncertainty analysis.
%
% The resampling unit is the generated scene, not an individual time step or
% a repeated DWA seed. Each bootstrap draw samples complete scenes with
% replacement and retains all matched runs within a sampled scene. The output
% contains scene-level summaries, method-wise 95% cluster-bootstrap intervals,
% and paired LSTM-minus-baseline contrasts.

clear; close all; clc;

here = fileparts(mfilename('fullpath'));
addpath(here);
outroot = fullfile(here, 'results', 'statistical_analysis');
if ~exist(outroot, 'dir'), mkdir(outroot); end
runid = datestr(now, 'yyyymmdd_HHMMSS');
outdir = fullfile(outroot, ['cluster_bootstrap_' runid]);
mkdir(outdir);

random_candidates = { ...
    fullfile(here, 'results', 'random_eval', ...
        'random12_20260906_134750', 'random_comparison.csv'), ...
    fullfile(here, '_local_archive', 'results', 'random_eval', ...
        'random12_20260906_134750', 'random_comparison.csv')};
fixed_candidates = { ...
    fullfile(here, 'results', 'multiseed_comparison.csv'), ...
    fullfile(here, '_local_archive', 'results', 'multiseed_comparison.csv')};

random_csv = first_existing(random_candidates);
fixed_csv = first_existing(fixed_candidates);
assert(~isempty(random_csv), 'Random comparison CSV not found.');
assert(~isempty(fixed_csv), 'Fixed comparison CSV not found.');

seed = 20260909;
B = 20000;
random_out = analyze_dataset(random_csv, 'random12', outdir, seed, B);
fixed_out = analyze_dataset(fixed_csv, 'fixed_S1_S4', outdir, seed + 1, B);

% If the new ablation runner has already completed, summarize it alongside
% the scene-cluster analyses. This section is descriptive because n=3 seeds
% on one mechanism-diagnostic scenario is not a generalization study.
ablation_csv = newest_file(fullfile(here, 'results', ...
    'ablation_multiseed'), 'ablation_multiseed_comparison.csv');
if ~isempty(ablation_csv)
    A = readtable(ablation_csv, 'TextType', 'string');
    writetable(group_summary(A, 'Variant'), ...
        fullfile(outdir, 'ablation_multiseed_summary_recomputed.csv'));
    write_ablation_pairwise(A, outdir);
end

manifest = table(string(random_csv), string(fixed_csv), string(ablation_csv), ...
    seed, B, string(outdir), ...
    'VariableNames', {'RandomCSV', 'FixedCSV', 'AblationCSV', ...
    'BootstrapSeed', 'BootstrapReplicates', 'OutputDirectory'});
writetable(manifest, fullfile(outdir, 'analysis_manifest.csv'));
fprintf('Cluster bootstrap analysis complete: %s\n', outdir);
end

function out = analyze_dataset(csv_path, label, outdir, seed, B)
T = readtable(csv_path, 'TextType', 'string');
if ismember('ScenarioIndex', T.Properties.VariableNames)
    T.SceneCluster = string(T.ScenarioIndex);
else
    T.SceneCluster = string(T.Scenario);
end

scene = group_summary(T, 'SceneCluster', 'Method');
writetable(scene, fullfile(outdir, [label '_scene_level_summary.csv']));

methods = unique(string(T.Method), 'stable');
metrics = {'Success', 'Collisions', 'MinSafeDist_m', 'ADE_m', 'FDE_m', ...
    'MeanStepTime_ms'};
summary_rows = cell(0, 10);
for mi = 1:numel(methods)
    method = methods(mi);
    sub = T(string(T.Method) == method, :);
    groups = unique(sub.SceneCluster, 'stable');
    for ki = 1:numel(metrics)
        metric = metrics{ki};
        assert(ismember(metric, sub.Properties.VariableNames), ...
            'Missing metric %s in %s', metric, csv_path);
        gmean = scene_metric(sub, groups, metric);
        rng(seed + mi * 100 + ki);
        draw_idx = randi(numel(groups), numel(groups), B);
        boot = mean(gmean(draw_idx), 1);
        ci = prctile(boot, [2.5 97.5]);
        summary_rows(end + 1, :) = {label, numel(groups), height(sub), ...
            char(method), metric, mean(gmean), ci(1), ci(2), ...
            B, 'scene-cluster bootstrap'}; %#ok<AGROW>
    end
end
summary = cell2table(summary_rows, 'VariableNames', {'Dataset', ...
    'SceneClusters', 'Trials', 'Method', 'Metric', 'Estimate', ...
    'CI95_Low', 'CI95_High', 'BootstrapReplicates', 'ResamplingUnit'});
writetable(summary, fullfile(outdir, [label '_cluster_bootstrap_summary.csv']));

baselines = {'static', 'cv', 'kalman'};
pair_rows = cell(0, 11);
lstm = T(string(T.Method) == 'lstm', :);
for bi = 1:numel(baselines)
    base = T(string(T.Method) == baselines{bi}, :);
    groups = intersect(unique(lstm.SceneCluster, 'stable'), ...
        unique(base.SceneCluster, 'stable'), 'stable');
    for ki = 1:numel(metrics)
        metric = metrics{ki};
        lmean = scene_metric(lstm, groups, metric);
        bmean = scene_metric(base, groups, metric);
        delta = lmean - bmean;
        rng(seed + 10000 * bi + ki);
        draw_idx = randi(numel(groups), numel(groups), B);
        boot = mean(delta(draw_idx), 1);
        ci = prctile(boot, [2.5 97.5]);
        pair_rows(end + 1, :) = {label, 'lstm', baselines{bi}, metric, ...
            numel(groups), mean(delta), ci(1), ci(2), mean(boot > 0), ...
            B, 'LSTM minus baseline; scene-cluster bootstrap'}; %#ok<AGROW>
    end
end
pairs = cell2table(pair_rows, 'VariableNames', {'Dataset', 'MethodA', ...
    'MethodB', 'Metric', 'SceneClusters', 'DeltaAminusB', 'CI95_Low', ...
    'CI95_High', 'BootstrapProbabilityDeltaGT0', 'BootstrapReplicates', ...
    'ResamplingUnit'});
writetable(pairs, fullfile(outdir, [label '_cluster_bootstrap_pairwise.csv']));

out = summary;
end

function S = group_summary(T, group_var, varargin)
grouping = string(T.(group_var));
if isempty(varargin)
    methods = "all";
    method_values = "all";
else
    method_var = varargin{1};
    methods = unique(string(T.(method_var)), 'stable');
    method_values = methods;
end

rows = cell(0, 12);
groups = unique(grouping, 'stable');
has_method = ~isempty(varargin);
for gi = 1:numel(groups)
    g = groups(gi);
    for mi = 1:numel(method_values)
        if ~has_method
            sel = grouping == g;
            method_label = "all";
        else
            method_label = method_values(mi);
            sel = grouping == g & string(T.(method_var)) == method_label;
        end
        if ~any(sel), continue; end
        rows(end + 1, :) = {g, method_label, sum(sel), mean(T.Success(sel)), ...
            mean(T.Collisions(sel)), mean(T.MinSafeDist_m(sel)), ...
            mean(T.ADE_m(sel)), mean(T.FDE_m(sel)), ...
            mean(T.MeanStepTime_ms(sel)), std(T.Success(sel)), ...
            std(T.MinSafeDist_m(sel)), std(T.ADE_m(sel))}; %#ok<AGROW>
    end
end
S = cell2table(rows, 'VariableNames', {'SceneCluster', 'Method', 'Trials', ...
    'SuccessRate', 'MeanCollisions', 'MeanMinSafeDist_m', 'MeanADE_m', ...
    'MeanFDE_m', 'MeanStepTime_ms', 'SD_Success', 'SD_MinSafeDist_m', ...
    'SD_ADE_m'});
end

function values = scene_metric(T, groups, metric)
values = zeros(1, numel(groups));
for i = 1:numel(groups)
    sel = T.SceneCluster == groups(i);
    values(i) = mean(T.(metric)(sel));
end
end

function path = first_existing(candidates)
path = '';
for i = 1:numel(candidates)
    if exist(candidates{i}, 'file') == 2
        path = candidates{i};
        return;
    end
end
end

function path = newest_file(root, filename)
path = '';
if ~exist(root, 'dir'), return; end
items = dir(fullfile(root, '**', filename));
if isempty(items), return; end
[~, idx] = max([items.datenum]);
path = fullfile(items(idx).folder, items(idx).name);
end

function write_ablation_pairwise(A, outdir)
variants = unique(string(A.Variant), 'stable');
ref = "Full_LSTM_H30";
rows = cell(0, 8);
for i = 1:numel(variants)
    if variants(i) == ref, continue; end
    r = A(string(A.Variant) == ref, :);
    a = A(string(A.Variant) == variants(i), :);
    [seeds, ir, ia] = intersect(r.Seed, a.Seed);
    if isempty(seeds), continue; end
    rows(end + 1, :) = {char(variants(i)), numel(seeds), ...
        mean(r.Success(ir) - a.Success(ia)), ...
        mean(r.MinSafeDist_m(ir) - a.MinSafeDist_m(ia)), ...
        std(r.MinSafeDist_m(ir) - a.MinSafeDist_m(ia)), ...
        mean(r.ADE_m(ir) - a.ADE_m(ia)), ...
        mean(r.FDE_m(ir) - a.FDE_m(ia)), ...
        'matched seed descriptive contrast'}; %#ok<AGROW>
end
P = cell2table(rows, 'VariableNames', {'ComparedVariant', 'MatchedSeeds', ...
    'DeltaSuccess', 'DeltaMinSafeDist_m', 'SDDeltaMinSafeDist_m', ...
    'DeltaADE_m', 'DeltaFDE_m', 'Interpretation'});
writetable(P, fullfile(outdir, 'ablation_multiseed_paired_differences_recomputed.csv'));
end
