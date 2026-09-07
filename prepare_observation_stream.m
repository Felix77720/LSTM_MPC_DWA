function stream = prepare_observation_stream(obstacles, cfg)
% prepare_observation_stream - Sample one noisy observation history per run.
%
% Positions are perturbed once and then reused by every prediction call.
% This preserves a fixed causal observation stream across MPC and DWA.

noise = getfield_or_local(cfg.dyn, 'obsNoise', 0);
if noise <= 0
    stream = [];
    return;
end

M = numel(obstacles);
stream = cell(M, 1);
for j = 1:M
    obs = obstacles(j).traj;
    obs(:, 1:3) = obs(:, 1:3) + noise * randn(size(obs(:, 1:3)));
    stream{j} = obs;
end
end

function v = getfield_or_local(s, name, default)
if isfield(s, name)
    v = s.(name);
else
    v = default;
end
end
