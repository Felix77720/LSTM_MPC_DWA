function probe_s4_dreject()
% Probe the terminal-progress trade-off for the dense S4 case.
here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));
cfg = config_LSTM();
cfg.mpc.wRoute = 3; cfg.maxSteps = 650;
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;
S = load(fullfile(here, 'results', 'lstm_predictor.mat'), 'net', 'muX', 'sigX', 'muY', 'sigY');
cfg.dyn.muX=S.muX; cfg.dyn.sigX=S.sigX; cfg.dyn.muY=S.muY; cfg.dyn.sigY=S.sigY;
sc = generate_eval_scenarios(cfg);
for d = [0.35 0.30 0.25]
    cfg.coupling.dReject = d;
    rng(3004);
    res = simulate_dynamic(sc(4), 'lstm', S.net, cfg);
    fprintf('dReject=%.2f success=%d failure=%s collisions=%d minClear=%.3f finalDist=%.3f steps=%d fallback=%d\n', ...
        d, res.success, res.failureType, res.collisions, res.minClearance, res.finalDist, res.steps, res.fallbackSteps);
end
end
