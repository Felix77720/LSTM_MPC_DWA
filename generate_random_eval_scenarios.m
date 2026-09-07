function scenarios = generate_random_eval_scenarios(cfg, nScenarios, seed)
% generate_random_eval_scenarios - Generate a fixed, reproducible random
% evaluation suite independent of the ego vehicle.
%
% The seed is used only to create the scenario set.  DWA sampling seeds are
% reset by the runner, so every method sees the same obstacle trajectories.
if nargin < 2 || isempty(nScenarios), nScenarios = 12; end
if nargin < 3 || isempty(seed), seed = 20260905; end

rng(seed);
T = cfg.dyn.T_obs;
dt = cfg.dyn.dt;
start = [1, 1, 1]';
goal = [18, 18, 8]';
empty = struct('traj', {}, 'radius', {});
scenarios = repmat(struct('name', [], 'start', [], 'goal', [], 'obstacles', empty, ...
    'scenarioSeed', [], 'obstacleKinds', []), nScenarios, 1);
kinds = {'straight', 'turn', 'sine_speed', 'accel', 'hover_go', 'zigzag', 'waypoints'};

for si = 1:nScenarios
    nObs = randi([3, 8]);
    centers = linspace(3.8, 14.6, nObs) + 0.25 * randn(1, nObs);
    centers = sort(max(3.2, min(15.2, centers)));
    obs = repmat(struct('traj', [], 'radius', []), 1, nObs);
    kindNames = cell(1, nObs);
    for j = 1:nObs
        kind = kinds{randi(numel(kinds))};
        kindNames{j} = kind;
        direction = 2 * (mod(j + si, 2) == 0) - 1;
        distance = 2.0 + 3.0 * rand;
        s = side_start(centers(j), distance, direction);
        p = base_params(s, 2.2 + 5.8 * rand, direction);
        p = maneuver_params(p, kind);
        obs(j) = mk(kind, p, 10000 + 100 * si + j, 1.0 + 0.8 * rand, T, dt);
    end
    scenarios(si).name = sprintf('R%02d 随机%d障碍混合机动', si, nObs);
    scenarios(si).start = start;
    scenarios(si).goal = goal;
    scenarios(si).obstacles = obs;
    scenarios(si).scenarioSeed = seed + si - 1;
    scenarios(si).obstacleKinds = kindNames;
end
end

function p = base_params(s, z, direction)
p = struct('x0', s(1), 'y0', s(2), 'z0', z, ...
    'psi0', direction * pi / 4 + 0.15 * randn, ...
    'v', 0.8 + 0.8 * rand, 'vz', 0.03 * randn);
end

function p = maneuver_params(p, kind)
switch kind
    case 'straight'
        p.omega = 0;
    case 'turn'
        p.omega = signed_uniform(0.10, 0.30);
    case 'sine_speed'
        p.vamp = 0.15 + 0.35 * rand;
        p.vfreq = 0.10 + 0.30 * rand;
        p.omega = signed_uniform(0.08, 0.25);
    case 'accel'
        p.a = signed_uniform(0.20, 0.50);
        p.vmin = 0.35;
        p.vmax = 1.9;
        p.omega = signed_uniform(0.08, 0.25);
    case 'hover_go'
        p.T_hover = 0.5 + 1.5 * rand;
        p.omega = signed_uniform(0.08, 0.25);
    case 'zigzag'
        p.omega_amp = 0.25 + 0.45 * rand;
        p.freq = 0.15 + 0.35 * rand;
    case 'waypoints'
        nw = 3 + randi(2);
        wp = [p.x0, p.y0, p.z0];
        for k = 2:nw
            wp(end + 1, :) = [3 + 14 * rand, 3 + 14 * rand, 2 + 6 * rand]; %#ok<AGROW>
        end
        p.waypoints = wp;
        p.wp_tol = 0.8;
        p.Kp_psi = 1.4;
        p.om_max = 0.8;
        p.Kp_z = 0.8;
        p.vz_max = 0.5;
end
end

function v = signed_uniform(lo, hi)
v = (lo + (hi - lo) * rand) * (2 * (rand < 0.5) - 1);
end

function s = side_start(c, d, dir)
u = d / sqrt(2);
if dir > 0
    s = [c + u, c - u];
else
    s = [c - u, c + u];
end
end

function o = mk(kind, p, seed, radius, T, dt)
o = struct('traj', generate_obstacle_trajectory(kind, p, T, dt, seed), ...
    'radius', radius);
end
