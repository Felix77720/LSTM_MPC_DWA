function test_fixed_observation_stream()
% test_fixed_observation_stream - Regression check for causal noisy history.
%
% The noisy observation stream must be generated once per closed-loop run,
% rather than resampled every time predict_all is called.

here = fileparts(mfilename('fullpath'));
source = fileread(fullfile(here, 'simulate_dynamic.m'));
assert(contains(source, 'observation_stream = prepare_observation_stream(obstacles, cfg)'), ...
    'simulate_dynamic must prepare one observation stream per run.');

pred_start = strfind(source, 'function obs_pred = predict_all');
pred_end = strfind(source, 'function v = getfield_or');
assert(~isempty(pred_start) && ~isempty(pred_end) && pred_end(1) > pred_start(1), ...
    'Could not isolate predict_all for the regression check.');
predict_block = source(pred_start(1):pred_end(1)-1);
assert(~contains(predict_block, 'randn('), ...
    'predict_all must not resample the complete noisy history.');

cfg.dyn.obsNoise = 0.05;
obstacles = struct('traj', zeros(6, 6));
obstacles.traj(:, 1:3) = repmat([1, 2, 3], 6, 1);

rng(9001);
stream_a = prepare_observation_stream(obstacles, cfg);
rng(9001);
stream_b = prepare_observation_stream(obstacles, cfg);
assert(isequal(stream_a, stream_b), 'Observation stream generation is not deterministic under a fixed seed.');
assert(any(abs(stream_a{1}(:, 1:3) - obstacles.traj(:, 1:3)), 'all'), ...
    'Configured observation noise was not applied.');

fprintf('Fixed observation stream regression passed.\n');
end
