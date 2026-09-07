function scenario = generate_repeat_scenario(cfg)
% generate_repeat_scenario - Fixed, ego-independent repeated encounters.
% Three independent obstacles cross the nominal route at separated times and
% along-track locations.  Their trajectories are generated before simulation;
% no obstacle trajectory depends on the ego state.
dt = cfg.dyn.dt;
scenario = struct('name', 'R1 三次分离遭遇', 'start', [1 1 1]', ...
    'goal', [18 18 8]', 'obstacles', struct('traj', {}, 'radius', {}));
u = [1 1] / sqrt(2); n = [-1 1] / sqrt(2);
Lxy = norm([18 18]-[1 1]); svals = [3.5 12 20];
% Put each crossing near the ego's expected along-track position.  The
% obstacle trajectories are still generated before the closed-loop run and
% never depend on the ego state.
t_cross = [6 22 38]; side = [1 -1 1];
T = max(cfg.dyn.T_obs, ceil(max(t_cross) / dt) + cfg.dyn.N_pred + 1);
speed = [0.85 0.90 0.82]; speed_amp = [0.60 0.55 0.65];
speed_freq = [0.32 0.38 0.28];
for j = 1:3
    center = [1 1] + svals(j) * u;
    nj = side(j) * n;
    zc = 1 + svals(j)/Lxy*7;
    p = struct('x0', 0, 'y0', 0, 'z0', 0, ...
        'psi0', atan2(nj(2), nj(1)), 'v', speed(j), ...
        'vamp', speed_amp(j), 'vfreq', speed_freq(j), ...
        'omega', 0, 'vz', 0);
    % Translate a canonical variable-speed crossing so that its true position
    % at t_cross is exactly on the nominal route.  CV has a fair local
    % velocity estimate but cannot represent the observed speed variation.
    canonical = generate_obstacle_trajectory('sine_speed', p, T, dt, 900+j);
    delta = canonical(t_cross(j)/dt + 1, 1:3) - canonical(1, 1:3);
    p.x0 = center(1) - delta(1);
    p.y0 = center(2) - delta(2);
    p.z0 = zc;
    scenario.obstacles(j) = struct('traj', generate_obstacle_trajectory('sine_speed', p, T, dt, 900+j), ...
        'radius', 1.15);
end
end
