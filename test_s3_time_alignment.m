function test_s3_time_alignment()
% test_s3_time_alignment - Regression check for a genuinely interactive S3.
%
% At least three obstacles must approach the nominal route within the
% inflated safety radius at the same simulation time as the latest LSTM
% replay.  This prevents a 2-D-looking but temporally non-interacting S3.

here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));
cfg = config_LSTM();
cfg.maxSteps = 550;
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;
scen = generate_eval_scenarios(cfg);
S = load(fullfile(here, 'results', 'seed001_lstm_3.mat'), 'res');
r = S.res;
a = scen(3).start(:); b = scen(3).goal(:); ab = b - a;
L = norm(ab);
near = false(1, numel(scen(3).obstacles));
nominal_mins = inf(size(near));
for j = 1:numel(scen(3).obstacles)
    n = min(r.steps, size(scen(3).obstacles(j).traj, 1) - 1);
    p = scen(3).obstacles(j).traj(2:n + 1, 1:3);
    tau = max(0, min(1, r.alongTrack(1:n) / L));
    nom = a' + tau * ab';
    clearance = sqrt(sum((nom - p).^2, 2)) - scen(3).obstacles(j).radius - cfg.UAV_radius;
    nominal_mins(j) = min(clearance);
    near(j) = nominal_mins(j) < 0.5;
    [~, ix] = min(clearance);
    sample_ix = min([82, 102, 162], n);
    av = r.alongTrack(sample_ix);
    fprintf('  obstacle=%d minIndex=%d time=%.1fs egoAlong=%.2f\n', ...
        j, ix, ix * cfg.dt, r.alongTrack(ix));
end
fprintf('S3 time-aligned nominal clearances: %s\n', mat2str(nominal_mins, 4));
assert(sum(near) >= 3, ...
    'S3 regression failed: only %d/5 obstacles interact with the nominal route.', sum(near));
fprintf('S3_TIME_ALIGNMENT_PASS near=%d/5\n', sum(near));
end
