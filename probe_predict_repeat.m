function probe_predict_repeat()
% probe_predict_repeat - Report fixed-window LSTM/CV/static prediction error
% on the repeat scenario without running the closed loop.
here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));
cfg = config_LSTM();
cfg.maxSteps = 700;
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;
cfg.dyn.injectHorizon = 30;
S = load(fullfile(here, 'results', 'lstm_predictor.mat'), 'net', 'muX', 'sigX', 'muY', 'sigY');
cfg.dyn.muX = S.muX; cfg.dyn.sigX = S.sigX; cfg.dyn.muY = S.muY; cfg.dyn.sigY = S.sigY;
sc = generate_repeat_scenario(cfg);
methods = {'static', 'cv', 'lstm'};
for mi = 1:numel(methods)
    ade = 0; fde = 0; cnt = 0;
    for j = 1:numel(sc.obstacles)
        for step = 10:10:min(200, cfg.maxSteps)
            fut = sc.obstacles(j).traj(step+1:step+cfg.dyn.N_pred, 1:3);
            hist = sc.obstacles(j).traj(1:step, :);
            p = predict_obstacle_traj(hist, methods{mi}, cfg, S.net);
            e = sqrt(sum((p - fut).^2, 2));
            ade = ade + mean(e); fde = fde + e(end); cnt = cnt + 1;
        end
    end
    fprintf('%s repeat ADE=%.4f FDE=%.4f (n=%d)\n', methods{mi}, ade/max(1,cnt), fde/max(1,cnt), cnt);
end
end
