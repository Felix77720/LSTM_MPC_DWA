function [X, Y, muX, sigX, muY, sigY, groupId, splitInfo] = generate_training_data(cfg)
% generate_training_data - Sample LSTM training windows from many independent
% random dynamic-obstacle maneuvers.
% Each trajectory contributes only a few randomly selected windows so the
% dataset covers a large number of independent trajectories.
%
% Input:
%   cfg - configuration struct.
% Outputs:
%   X    - 1 x N cell array of raw input feature windows.
%   Y    - (3*N_pred) x N raw displacement targets.
%   muX, sigX - per-feature normalization statistics for training inputs only.
%   muY, sigY - per-axis normalization statistics for training targets only.
%   groupId   - independent trajectory identifier for each window.
%   splitInfo - trajectory-level train/validation split metadata.

T_hist = cfg.dyn.T_hist;
N_pred = cfg.dyn.N_pred;
T      = cfg.dyn.T_obs;
dt     = cfg.dyn.dt;
kinds  = {'straight', 'turn', 'helix', 'hover_go', 'zigzag', 'waypoints', ...
          'accel', 'sine_speed'};

nTraj          = getfield_or_local(cfg.dyn, 'trainTrajectories', 800);
windowsPerTraj = getfield_or_local(cfg.dyn, 'windowsPerTrajectory', 16);

X = {};
Y = zeros(3 * N_pred, 0);
groupId = zeros(1, 0);

for t = 1:nTraj
    kind = kinds{randi(numel(kinds))};
    p = random_maneuver(kind);
    traj = generate_obstacle_trajectory(kind, p, T, dt, []);
    F = features_from_traj(traj);

    maxStart = T - T_hist - N_pred;
    if maxStart < 1
        continue;
    end
    starts = randperm(maxStart, min(windowsPerTraj, maxStart));
    delaySteps = getfield_or_local(cfg.dyn, 'delayAugmentSteps', 0);
    for s = starts
        % The clean window ends at the current observation.  A delayed
        % window ends one or more samples earlier.  Each window is paired
        % with a displacement target relative to its own last observation;
        % this matches the causal delayed-observation interface used by
        % simulate_dynamic and avoids a one-step label shift.
        delays = [0, 1:min(delaySteps, T_hist - 1)];
        for delay = delays
            winStart = s - delay;
            if winStart < 1, continue; end
            win = F(:, winStart : winStart + T_hist - 1);
            winEnd = winStart + T_hist - 1;
            cur = traj(winEnd, 1:3)';
            fut = traj(winEnd + 1 : winEnd + N_pred, 1:3)';
            dY  = fut - cur;
            X{end + 1} = win;           %#ok<AGROW>
            Y(:, end + 1) = dY(:);      %#ok<AGROW>
            groupId(end + 1) = t;       %#ok<AGROW>
        end
    end
end

% Split by independent trajectory, not by overlapping windows.  The caller
% sets the documented seed before entering this function.
groups = unique(groupId, 'stable');
nTrainGroups = max(1, min(numel(groups) - 1, floor(getfield_or_local(cfg.dyn, 'trainFraction', 0.8) * numel(groups))));
perm = randperm(numel(groups));
trainGroups = groups(perm(1:nTrainGroups));
valGroups = groups(perm(nTrainGroups + 1:end));
trainMask = ismember(groupId, trainGroups);
valMask = ismember(groupId, valGroups);

allX = [X{trainMask}];
muX  = mean(allX, 2);
sigX = std(allX, 0, 2);
sigX(sigX < 1e-8) = 1;

muY  = mean(Y(:, trainMask), 2);
sigY = std(Y(:, trainMask), 0, 2);
muY  = reshape(muY,  3, N_pred);   muY  = mean(muY, 2);
sigY = reshape(sigY, 3, N_pred);   sigY = sqrt(mean(sigY.^2, 2));
sigY(sigY < 1e-8) = 1;

splitInfo = struct('allGroups', groups, 'trainGroups', trainGroups, ...
    'validationGroups', valGroups, 'trainMask', trainMask, 'validationMask', valMask, ...
    'nTrajectories', nTraj, 'nTrainTrajectories', numel(trainGroups), ...
    'nValidationTrajectories', numel(valGroups));
fprintf('Training data: %d windows from %d independent trajectories (%d train, %d validation trajectories)\n', ...
    size(Y, 2), nTraj, numel(trainGroups), numel(valGroups));
end

function v = getfield_or_local(s, name, default)
if isfield(s, name), v = s.(name); else, v = default; end
end

function p = random_maneuver(kind)
% random_maneuver - Build random maneuver parameters for one obstacle kind.
% Input kind: maneuver type. Output p: parameter struct used by the generator.
arena = [0 20; 0 20; 0 10];
p.x0   = arena(1,1) + 4 + 12 * rand;
p.y0   = arena(2,1) + 3 + 14 * rand;
p.z0   = 2 + 5 * rand;
p.psi0 = 2 * pi * rand;
p.v    = 0.5 + 0.8 * rand;
p.vz   = 0.15 * randn;

switch kind
    case 'straight'
    case {'turn', 'helix'}
        p.omega = (0.3 + 1.2 * rand) * (2 * (rand < 0.5) - 1);
    case 'hover_go'
        p.T_hover = 0.5 + 3.0 * rand;
        p.omega   = (0.3 + 1.2 * rand) * (2 * (rand < 0.5) - 1);
    case 'zigzag'
        p.omega_amp = 0.4 + 1.1 * rand;
        p.freq      = 0.2 + 0.7 * rand;
    case 'waypoints'
        nw = 3 + randi(2);
        wp = [p.x0, p.y0, p.z0];
        for i = 2:nw
            wp(end+1, :) = [arena(1,1)+2+16*rand, arena(2,1)+2+16*rand, 1+8*rand]; %#ok<AGROW>
        end
        p.waypoints = wp;
        p.wp_tol    = 0.8;
        p.Kp_psi    = 1.6;
        p.om_max    = 1.2;
        p.Kp_z      = 0.8;
        p.vz_max    = 0.5;
    case 'accel'
        p.a     = (0.5 + 0.7 * rand) * (2 * (rand < 0.5) - 1);
        p.vmin  = 0.3;
        p.vmax  = 1.6;
        p.omega = (0.2 + 0.8 * rand) * (2 * (rand < 0.5) - 1);
    case 'sine_speed'
        p.vamp  = 0.4 + 0.3 * rand;
        p.vfreq = 0.2 + 0.5 * rand;
        p.omega = (0.2 + 0.8 * rand) * (2 * (rand < 0.5) - 1);
end
end
