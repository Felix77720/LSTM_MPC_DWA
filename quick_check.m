% quick_check - Run one seed over all scenarios and print ADE/FDE/success
% for the three methods, used to sanity-check the scenario design.

clear; close all; clc;
here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
casadi = fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b');
addpath(here, baseline, casadi);

rng(0);
cfg = config_LSTM();
netfile = fullfile(here, 'results', 'lstm_predictor.mat');
S = load(netfile, 'net', 'muX', 'sigX', 'muY', 'sigY');
net = S.net;
cfg.dyn.muX = S.muX; cfg.dyn.sigX = S.sigX;
cfg.dyn.muY = S.muY; cfg.dyn.sigY = S.sigY;

scenarios = generate_eval_scenarios(cfg);
methods = {'static', 'cv', 'lstm'};

for s = 1:numel(scenarios)
    for mi = 1:numel(methods)
        rng(1000 + s);
        res = simulate_dynamic(scenarios(s), methods{mi}, net, cfg);
        fprintf('%s | %s | success=%d clear=%.3f ADE=%.3f FDE=%.3f step=%.0fms\n', ...
            scenarios(s).name, methods{mi}, res.success, res.minClearance, ...
            res.ADE, res.FDE, 1000 * res.meanStepTime);
    end
end
