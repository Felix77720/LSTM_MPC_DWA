function diagnose_s3_current()
% diagnose_s3_current - Fast S3 geometry/result diagnostic for regression checks.
%
% The check distinguishes a stale/incorrect plot from a controller that
% genuinely follows the nominal line.  It reports the distance of every
% true obstacle trajectory to the 3-D start-goal segment and the measured
% lateral offset of the current multi-seed LSTM runs.

here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));

cfg = config_LSTM();
cfg.maxSteps = 550;
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;
scenarios = generate_eval_scenarios(cfg);
scen = scenarios(3);

a = scen.start(:);
b = scen.goal(:);
ab = b - a;
L2 = dot(ab, ab);
fprintf('S3 geometry: UAV radius=%.3f, route length=%.3f, obstacles=%d\n', ...
    cfg.UAV_radius, sqrt(L2), numel(scen.obstacles));
for j = 1:numel(scen.obstacles)
    p = scen.obstacles(j).traj(:, 1:3);
    q = p - a';
    tau = max(0, min(1, (q * ab) / L2));
    proj = a' + tau * ab';
    d3 = sqrt(sum((p - proj).^2, 2));
    dxy = abs((p(:, 2) - a(2)) * ab(1) - (p(:, 1) - a(1)) * ab(2)) / norm(ab(1:2));
    [d3min, i3] = min(d3);
    [dxymin, ixy] = min(dxy);
    fprintf('obstacle=%d radius=%.2f min3D=%.3f(t=%d) minXY=%.3f(t=%d)\n', ...
        j, scen.obstacles(j).radius, d3min, i3, dxymin, ixy);
end

for seed = 1:3
    path = fullfile(here, 'results', sprintf('seed%03d_lstm_3.mat', seed));
    if exist(path, 'file') ~= 2
        fprintf('missing=%s\n', path);
        continue;
    end
    S = load(path, 'res');
    r = S.res;
    off = r.horizontalOffset(:);
    fprintf(['seed=%d success=%d failure=%s collisions=%d minClear=%.3f ', ...
        'maxAbsOffset=%.3f offsetStd=%.3f path=%.3f fallback=%d\n'], ...
        seed, r.success, r.failureType, r.collisions, r.minClearance, ...
        max(abs(off)), std(off), r.pathLength, r.fallbackSteps);
    if seed == 1
        fprintf('seed=1 time-aligned clearances (nominal line / actual path):\n');
        for j = 1:numel(scen.obstacles)
            n = min(r.steps, size(scen.obstacles(j).traj, 1) - 1);
            p = scen.obstacles(j).traj(2:n + 1, 1:3);
            s = r.alongTrack(1:n);
            tau = max(0, min(1, s / sqrt(L2)));
            nom = a' + tau * ab';
            dnom = sqrt(sum((nom - p).^2, 2)) - scen.obstacles(j).radius - cfg.UAV_radius;
            pact = r.traj(2:n + 1, 1:3);
            dact = sqrt(sum((pact - p).^2, 2)) - scen.obstacles(j).radius - cfg.UAV_radius;
            fprintf('  obstacle=%d nominalMin=%.3f actualMin=%.3f\n', ...
                j, min(dnom), min(dact));
        end
    end
end
end
