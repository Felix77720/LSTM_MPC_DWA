% run_experiments - Main entry point for LSTM-enhanced MPC-DWA experiments.
% Usage: cd to this folder in MATLAB, then run run_experiments.

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

%% 1. Training data + LSTM training (cached in results/lstm_predictor.mat)
netfile = fullfile(outdir, 'lstm_predictor.mat');
trainingInfo = [];
trainingProtocol = struct();
if exist(netfile, 'file')
    S = load(netfile, 'net', 'muX', 'sigX', 'muY', 'sigY', 'trainingInfo', 'trainingProtocol');
    net = S.net;
    cfg.dyn.muX = S.muX; cfg.dyn.sigX = S.sigX;
    cfg.dyn.muY = S.muY; cfg.dyn.sigY = S.sigY;
    if isfield(S, 'trainingInfo'), trainingInfo = S.trainingInfo; end
    if isfield(S, 'trainingProtocol'), trainingProtocol = S.trainingProtocol; end
    fprintf('已加载预训练 LSTM: %s\n', netfile);
else
    rng(cfg.dyn.trainingSeed);
    [X, Y, muX, sigX, muY, sigY, groupId, splitInfo] = generate_training_data(cfg);
    cfg.dyn.muX = muX; cfg.dyn.sigX = sigX;
    cfg.dyn.muY = muY; cfg.dyn.sigY = sigY;
    fprintf('开始训练 LSTM 轨迹预测器...\n');
    [net, trainingInfo, trainingProtocol] = train_lstm_predictor(X, Y, cfg, groupId, splitInfo);
    save(netfile, 'net', 'muX', 'sigX', 'muY', 'sigY', 'trainingInfo', ...
        'trainingProtocol', 'splitInfo', '-v7.3');
    fprintf('LSTM 训练完成并保存。\n');
end

%% 2. Evaluation scenarios
scenarios = generate_eval_scenarios(cfg);

%% 3. Four-method comparison: static | cv | kalman | lstm
methods = {'static', 'cv', 'kalman', 'lstm'};

C = {};
results = cell(numel(scenarios), numel(methods));

for s = 1:numel(scenarios)
    scen = scenarios(s);
    for mi = 1:numel(methods)
        m = methods{mi};
        rng(1000 + s);   % same random sampling across methods in one scenario
        fprintf('运行: %s | %s\n', scen.name, m);
        res = simulate_dynamic(scen, m, net, cfg);
        results{s, mi} = res;

        C(end + 1, :) = {scen.name, method_label(m), res.success, res.collisions, ...
            res.minClearance, res.pathLength, res.trackRMSE, ...
            res.meanStepTime * 1000, res.ADE, res.FDE}; %#ok<AGROW>
    end
end

T = cell2table(C, 'VariableNames', {'Scenario', 'Method', 'Success', 'Collisions', ...
    'MinSafeDist_m', 'PathLength_m', 'TrackRMSE_m', 'MeanStepTime_ms', 'ADE_m', 'FDE_m'});
writetable(T, fullfile(outdir, 'metrics.csv'));

fprintf('\n================ 四组对比 ================\n');
disp(T);

fprintf('\n======== 避障成功率 (按方法聚合) ========\n');
for mi = 1:numel(methods)
    m = methods{mi};
    sel = strcmp(T.Method, method_label(m));
    sr = mean(T.Success(sel));
    avg_col = mean(T.Collisions(sel));
    avg_ade = mean(T.ADE_m(sel));
    avg_fde = mean(T.FDE_m(sel));
    fprintf('%-16s | 成功率 %3.0f%% | 平均碰撞 %.1f | ADE %.3f m | FDE %.3f m\n', ...
        method_label(m), 100 * sr, avg_col, avg_ade, avg_fde);
end

%% 4. Ablation: prediction horizon length (injected look-ahead steps)
fprintf('\n======== 消融: 预测时域长度 (LSTM) ========\n');
horizons = [10, 20, 30];
Ah = {};
for hi = 1:numel(horizons)
    cfg.dyn.injectHorizon = horizons(hi);
    sr = 0; col = 0; clr = 0; ade = 0; fde = 0; stp = 0;
    for s = 1:numel(scenarios)
        rng(2000 + s);  % reset for each method/horizon trial
        res = simulate_dynamic(scenarios(s), 'lstm', net, cfg);
        sr = sr + res.success; col = col + res.collisions;
        clr = clr + res.minClearance; ade = ade + res.ADE; fde = fde + res.FDE;
        stp = stp + res.meanStepTime;
    end
    ns = numel(scenarios);
    Ah(end + 1, :) = {horizons(hi), 100 * sr / ns, col / ns, clr / ns, ...
        ade / ns, fde / ns, 1000 * stp / ns}; %#ok<AGROW>
end
Ah = cell2table(Ah, 'VariableNames', {'Horizon_steps', 'SuccessRate_pct', ...
    'AvgCollisions', 'AvgMinSafeDist_m', 'AvgADE_m', 'AvgFDE_m', 'AvgStepTime_ms'});
disp(Ah);
writetable(Ah, fullfile(outdir, 'ablation_horizon.csv'));
cfg.dyn.injectHorizon = cfg.dyn.N_pred;   % restore default

%% 5. Visualization
fprintf('\n生成轨迹可视化...\n');
for s = 1:numel(scenarios)
    trajs = cell(1, numel(methods));
    for mi = 1:numel(methods)
        trajs{mi} = results{s, mi}.traj;
    end
    visualize_scenario(scenarios(s), methods, trajs, cfg, outdir);

    % Prediction comparison plot at a mid-simulation step
    lstm_idx = find(strcmp(methods, 'lstm'), 1);
    mid = max(10, round(results{s, lstm_idx}.steps / 2));
    visualize_prediction(scenarios(s), net, cfg, mid, outdir);
end

save(fullfile(outdir, 'results.mat'), 'results', 'scenarios', 'methods', 'T', 'Ah', ...
    'trainingInfo', 'trainingProtocol');

fprintf('\n全部实验完成。输出目录: %s\n', outdir);


function lbl = method_label(m)
% method_label - Map a method key to its display label for tables and figures.
% Input m: method key. Output lbl: display label.
switch lower(m)
    case 'static',  lbl = 'MPC-DWA 静态';
    case 'cv',      lbl = 'MPC-DWA 匀速外推';
    case 'kalman',  lbl = 'MPC-DWA 卡尔曼';
    case 'lstm',    lbl = '本文 LSTM';
    otherwise,      lbl = m;
end
end
