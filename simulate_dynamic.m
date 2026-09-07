function res = simulate_dynamic(scenario, method, net, cfg)
% simulate_dynamic - Run one complete closed-loop simulation for one scenario
% and one obstacle-prediction method.
%
% Inputs:
%   scenario - scenario struct with fields start, goal, and obstacles.
%   method   - prediction method key ('static'/'cv'/'kalman'/'lstm').
%   net      - trained LSTM network (used only for method 'lstm').
%   cfg      - configuration struct.
% Output:
%   res - result struct with trajectory, collisions, clearance, path length,
%         tracking error, step time, ADE/FDE, and scenario data.

start = scenario.start;
goal  = scenario.goal;
obstacles = scenario.obstacles;
M = numel(obstacles);
N_pred = cfg.dyn.N_pred;
injectH = cfg.dyn.injectHorizon;
cfg.routeStart = start;
[mpc_method, dwa_method] = split_prediction_method(method);

obs_radius = zeros(M, 1);
for j = 1:M
    obs_radius(j) = obstacles(j).radius;
end

% Initial heading points at the goal so the UAV flies along the straight
% start-to-goal route; otherwise diagonal obstacles would miss its path.
state   = [start; atan2(goal(3) - start(3), norm(goal(1:2) - start(1:2))); ...
           atan2(goal(2) - start(2), goal(1) - start(1)); 1];
control = [1; 0; 0];

traj_history    = state';
control_history = control';
time_history    = 0;
step_times      = [];
prediction_times = [];
dwa_times = [];
mpc_times = [];
plant_metric_times = [];
observation_stream = prepare_observation_stream(obstacles, cfg);

collisions    = 0;
collision_events = 0;
collision_prev = false;
min_clearance = inf;
step_clearance = zeros(0,1); nearest_obstacle = zeros(0,1);
along_track = zeros(0,1); horizontal_offset = zeros(0,1); vertical_offset = zeros(0,1);
solve_failures = 0;
fallback_steps = 0;
ade_sum = 0; fde_sum = 0; pred_count = 0;

% Initial MPC at t = 0
prev_mpc = struct('u_first', control);
startup_prediction_tic = tic;
obs_pred_mpc = predict_all(obstacles, 1, mpc_method, net, cfg, N_pred, M, observation_stream);
if strcmp(mpc_method, dwa_method), obs_pred_dwa = obs_pred_mpc; else, obs_pred_dwa = predict_all(obstacles, 1, dwa_method, net, cfg, N_pred, M, observation_stream); end
startup_prediction_time = toc(startup_prediction_tic);
startup_mpc_tic = tic;
    mpc      = MPC_UAV_dynamic_cached(state, goal, obs_pred_mpc, obs_radius, cfg, prev_mpc, [], control);
startup_mpc_time = toc(startup_mpc_tic);
solve_failures = solve_failures + double(mpc.exitflag == 0);
u_mpc    = mpc.u_first;
ref_traj = mpc.traj;
ref_ctrl = mpc.ctrl;
tau      = computeTrust_dynamic(ref_traj, ref_ctrl, goal, obs_pred_mpc, obs_radius, cfg, state);

steps = 0;
for step = 1:cfg.maxSteps
    dist_to_goal = norm(state(1:3) - goal);
    if dist_to_goal < cfg.goalTolerance
        break;
    end

    step_tic = tic;

    % Obstacle history is traj(1:step, :); the last row is the current time
    prediction_tic = tic;
    obs_pred_mpc = predict_all(obstacles, step, mpc_method, net, cfg, N_pred, M, observation_stream);
    if strcmp(mpc_method, dwa_method), obs_pred_dwa = obs_pred_mpc; else, obs_pred_dwa = predict_all(obstacles, step, dwa_method, net, cfg, N_pred, M, observation_stream); end

    [ade, fde] = eval_pred_error(obstacles, step, obs_pred_mpc, N_pred);
    ade_sum = ade_sum + ade; fde_sum = fde_sum + fde; pred_count = pred_count + 1;
    prediction_times(end + 1) = toc(prediction_tic); %#ok<AGROW>

    if step > 1
        tail = UAV_model(ref_traj(end,:)', ref_ctrl(end,:)', cfg.dt, cfg)';
        ref_traj = [ref_traj(2:end,:); tail];
        ref_ctrl = [ref_ctrl(2:end,:); ref_ctrl(end,:)];
        u_mpc = ref_ctrl(1,:)';
    end
    tau = computeTrust_dynamic(ref_traj, ref_ctrl, goal, obs_pred_mpc, obs_radius, cfg, state);

    dwa_tic = tic;
    [v_range, wt_range, wp_range] = createDynamicWindow3D(control, cfg);
    samples = sampleIntelligent3D(v_range, wt_range, wp_range, u_mpc, tau, cfg);

    valid_ctrls = [];
    valid_trajs = {};
    s_pos = []; s_head = []; s_vel = []; s_obs = []; s_vertical = [];
    all_ctrls = zeros(size(samples)); all_clearance = -inf(size(samples,1),1);
    all_corridor = false(size(samples,1),1);

    for i = 1:size(samples, 1)
        ctrl_i = samples(i, :)';
        traj = predictTrajectory3D(state, ctrl_i, cfg);
        min_dist = calcMinDist3D_dynamic(traj, obs_pred_dwa, obs_radius, cfg, injectH);
        all_ctrls(i,:) = ctrl_i'; all_clearance(i) = min_dist;
        all_corridor(i) = within_flight_corridor(traj, start, goal, cfg);
        if ~all_corridor(i), continue; end
        reject_clearance = 0;
        if isfield(cfg, 'coupling') && isfield(cfg.coupling, 'dReject')
            reject_clearance = cfg.coupling.dReject;
        end
        if min_dist <= reject_clearance, continue; end
        v_safe = sqrt(2 * cfg.maxDec * min_dist);
        if traj(end, 6) > v_safe
            continue;
        end

        valid_ctrls(end + 1, :) = ctrl_i';      %#ok<AGROW>
        valid_trajs{end + 1} = traj;            %#ok<AGROW>

        [sp, sh, sv] = referenceScores3D(traj, ref_traj, cfg);
        s_pos(end + 1)  = sp;                    %#ok<AGROW>
        s_head(end + 1) = sh;                    %#ok<AGROW>
        s_vel(end + 1)  = sv;                    %#ok<AGROW>
        s_obs(end + 1)  = scoreObstacle3D_dynamic(traj, obs_pred_dwa, obs_radius, cfg, injectH) / cfg.maxClearance; %#ok<AGROW>
        s_vertical(end + 1) = vertical_corridor_score(traj, start, goal); %#ok<AGROW>
    end

    if isempty(valid_ctrls)
        fallback_steps = fallback_steps + 1;
        % No candidate satisfies both collision and braking tests.  Choose the
        % least-overlap candidate and bias its yaw toward the free side of the
        % nearest predicted obstacle.  This is still bounded by the dynamic
        % window; it prevents the old straight-line zero-progress fallback.
        corridor_score = all_clearance;
        corridor_score(~all_corridor) = -inf;
        if any(isfinite(corridor_score))
            [~, risk_idx] = max(corridor_score);
        else
            [~, risk_idx] = max(all_clearance);
        end
        best_control = all_ctrls(risk_idx, :)';
        % Keep the emergency maneuver in the horizontal plane and level the
        % current pitch.  Leaving the pitch-rate unchanged can accumulate a
        % large vertical excursion even when the horizontal detour is safe.
        best_control(2) = max(-cfg.maxPitchRate, min(cfg.maxPitchRate, -state(4) / cfg.dt));
        ab = goal(1:2) - start(1:2); nline = [-ab(2); ab(1)] / max(norm(ab), 1e-12);
        oc = squeeze(obs_pred_dwa(1, 1:3, :));
        if ~isempty(oc)
            if size(oc,1) ~= 3, oc = oc'; end
            [~,oj] = min(sqrt(sum((oc' - state(1:3)').^2,2)));
        end
        % MATLAB does not permit indexed expressions as function inputs on
        % older releases; recompute the selected obstacle scalar explicitly.
        if ~isempty(oc)
            ovec = oc(:,oj(1:1)); obs_lat = dot(ovec(1:2) - start(1:2), nline);
            desired = -sign(obs_lat); if desired == 0, desired = 1; end
            hxy = [cos(state(5)); sin(state(5))]; yaw_sign = sign(hxy(1)*desired*nline(2) - hxy(2)*desired*nline(1));
            % Use a bounded horizontal sidestep and slow down while the
            % obstacle occupies the reachable set; taking the extreme yaw
            % sample caused a 5 m overshoot and merged all encounters.
            yaw_cap = min([0.35, abs(wp_range(1)), abs(wp_range(2))]);
            if yaw_sign >= 0, best_control(3) = yaw_cap; else, best_control(3) = -yaw_cap; end
            best_control(1) = v_range(1);
        end
        best_traj = [];
        mpc_box = [];
    else
        w = dynamicWeights(tau, cfg);
        total = w(1) * s_pos + w(2) * s_head + w(3) * s_vel + w(4) * s_obs;
        if isfield(cfg, 'coupling') && isfield(cfg.coupling, 'wVertical')
            total = total + cfg.coupling.wVertical * s_vertical;
        end
        [~, best_idx] = max(total);
        best_control  = valid_ctrls(best_idx, :)';
        best_traj     = valid_trajs{best_idx};
        mpc_box       = boundingBoxSafe(valid_ctrls, cfg);
        % Once the selected horizon is clear, actively damp residual lateral
        % error so a previous avoidance maneuver does not become a permanent
        % offset that masks later, independent encounters.
        ab = goal(1:2) - start(1:2); nline = [-ab(2); ab(1)] / max(norm(ab), 1e-12);
        lat_now = dot(state(1:2) - start(1:2), nline);
        clear_selected = calcMinDist3D_dynamic(best_traj, obs_pred_dwa, obs_radius, cfg, injectH);
        if clear_selected > 1.0 && abs(lat_now) > 0.5
            heading_target = atan2(goal(2) - state(2), goal(1) - state(1));
            yaw_err = atan2(sin(heading_target - state(5)), cos(heading_target - state(5)));
            best_control(3) = max(-cfg.maxYawRate, min(cfg.maxYawRate, 0.8 * yaw_err));
        end
    end
    dwa_times(end + 1) = toc(dwa_tic); %#ok<AGROW>

    mpc_tic = tic;
    mpc      = MPC_UAV_dynamic_cached(state, goal, obs_pred_mpc, obs_radius, cfg, mpc, mpc_box, control);
    mpc_times(end + 1) = toc(mpc_tic); %#ok<AGROW>
    solve_failures = solve_failures + double(mpc.exitflag == 0);
    u_mpc    = mpc.u_first;
    ref_traj = mpc.traj;
    ref_ctrl = mpc.ctrl;

    plant_metric_tic = tic;
    state   = UAV_model(state, best_control, cfg.dt, cfg);
    control = best_control;
    steps = steps + 1;

    traj_history(end + 1, :) = state';           %#ok<AGROW>
    control_history(end + 1, :) = control';      %#ok<AGROW>
    time_history(end + 1) = step * cfg.dt;       %#ok<AGROW>

    % Collision check: new ego position vs. true obstacle position at
    % t = step*dt (row step+1 of the obstacle trajectory)
    clear = inf; nearest = 0;
    for j = 1:M
        ob_pos = obstacles(j).traj(step + 1, 1:3)';   % 3x1, same orientation as state(1:3)
        d = norm(state(1:3) - ob_pos) - obstacles(j).radius - cfg.UAV_radius;
        if d < 0
            collisions = collisions + 1;
        end
        if d < clear, clear = d; nearest = j; end
    end
    min_clearance = min(min_clearance, clear);
    step_clearance(end + 1, 1) = clear; %#ok<AGROW>
    nearest_obstacle(end + 1, 1) = nearest; %#ok<AGROW>
    in_collision = clear < 0;
    collision_events = collision_events + double(in_collision && ~collision_prev);
    collision_prev = in_collision;
    dxy = goal(1:2) - start(1:2); Lxy = norm(dxy); exy = state(1:2) - start(1:2);
    if Lxy > eps
        txy = dot(exy, dxy) / Lxy^2;
        nxy = [-dxy(2); dxy(1)] / Lxy;
        along_track(end + 1, 1) = txy * Lxy; %#ok<AGROW>
        horizontal_offset(end + 1, 1) = dot(exy, nxy); %#ok<AGROW>
        z_nom = start(3) + max(0, min(1, txy)) * (goal(3) - start(3));
        vertical_offset(end + 1, 1) = state(3) - z_nom; %#ok<AGROW>
    else
        along_track(end + 1, 1) = 0; %#ok<AGROW>
        horizontal_offset(end + 1, 1) = 0; %#ok<AGROW>
        vertical_offset(end + 1, 1) = state(3) - start(3); %#ok<AGROW>
    end
    plant_metric_times(end + 1) = toc(plant_metric_tic); %#ok<AGROW>
    step_times(end + 1) = toc(step_tic); %#ok<AGROW>
end

res = struct();
res.name        = scenario.name;
res.method      = method;
res.steps       = steps;
res.finalDist   = norm(state(1:3) - goal);
res.success     = (res.finalDist < cfg.goalTolerance) && (collisions == 0);
res.collisions  = collisions;
res.collisionEvents = collision_events;
res.minClearance = min_clearance;
res.stepClearance = step_clearance;
res.nearestObstacle = nearest_obstacle;
res.alongTrack = along_track;
res.horizontalOffset = horizontal_offset;
res.verticalOffset = vertical_offset;
res.solveFailures = solve_failures;
res.fallbackSteps = fallback_steps;
res.pathLength  = sum(sqrt(sum(diff(traj_history(:, 1:3), 1, 1).^2, 2)));
res.trackRMSE   = cross_track_rmse(traj_history, start, goal);
res.meanStepTime = mean(step_times);
res.maxStepTime  = max(step_times);
res.stepTimes = step_times(:);
res.predictionTimes = prediction_times(:);
res.dwaTimes = dwa_times(:);
res.mpcTimes = mpc_times(:);
res.plantMetricTimes = plant_metric_times(:);
res.startupPredictionTime = startup_prediction_time;
res.startupMpcTime = startup_mpc_time;
res.meanPredictionTime = mean_or_zero(prediction_times);
res.meanDwaTime = mean_or_zero(dwa_times);
res.meanMpcTime = mean_or_zero(mpc_times);
res.meanPlantMetricTime = mean_or_zero(plant_metric_times);
res.p95StepTime = percentile_or_zero(step_times, 95);

if pred_count > 0
    res.ADE = ade_sum / pred_count;
    res.FDE = fde_sum / pred_count;
else
    res.ADE = NaN; res.FDE = NaN;
end

res.traj       = traj_history;
res.ctrl       = control_history;
res.time       = time_history;
res.start      = start;
res.goal       = goal;
res.obstacles  = obstacles;
res.obsNoise = getfield_or(cfg.dyn, 'obsNoise', 0);
res.obsDelaySteps = getfield_or(cfg.dyn, 'obsDelaySteps', 0);
res.observationStream = observation_stream;
res.failureType = classify_failure(res.success, res.collisions, res.finalDist, ...
    cfg.goalTolerance, res.solveFailures, res.fallbackSteps);
end

function [mpc_method, dwa_method] = split_prediction_method(method)
key = lower(method);
switch key
    case 'lstm_mpc_only'
        mpc_method = 'lstm'; dwa_method = 'static';
    case 'lstm_dwa_only'
        mpc_method = 'static'; dwa_method = 'lstm';
    otherwise
        mpc_method = key; dwa_method = key;
end
end

function obs_pred = predict_all(obstacles, step, method, net, cfg, N_pred, M, observation_stream)
% predict_all - Predict future positions for every obstacle from its history.
% Inputs: obstacle structs, current step, method key, net, cfg, prediction
% length, and obstacle count. Output obs_pred: N_pred x 3 x M predictions.
obs_pred = zeros(N_pred, 3, M);
for j = 1:M
    delay = getfield_or(cfg.dyn, 'obsDelaySteps', 0);
    observed_step = max(1, step - delay);
    noise = getfield_or(cfg.dyn, 'obsNoise', 0);
    if noise > 0 && (nargin < 8 || isempty(observation_stream))
        error('No fixed observation stream was supplied for a noisy prediction.');
    end
    if nargin >= 8 && ~isempty(observation_stream)
        hist = observation_stream{j}(1:observed_step, :);
    else
        hist = obstacles(j).traj(1:observed_step, :);
    end
    if noise > 0
        smooth_steps = getfield_or(cfg.dyn, 'obsSmoothingSteps', 1);
        if smooth_steps > 1 && size(hist, 1) >= 2
            % Use a causal window and preserve the latest measured position.
            % This suppresses sensor noise without leaking future information.
            smooth_steps = min(smooth_steps, size(hist, 1));
            raw_last = hist(end, 1:3);
            hist(:, 1:3) = movmean(hist(:, 1:3), [smooth_steps - 1, 0], 1);
            hist(:, 1:3) = hist(:, 1:3) + raw_last - hist(end, 1:3);
        end
        if size(hist, 1) >= 2
            hist(:, 4:6) = [hist(1, 4:6); diff(hist(:, 1:3), 1, 1) / cfg.dyn.dt];
            % A short trailing slope is more stable than a single noisy
            % difference and is shared by CV and the LSTM input features.
            slope_steps = min(4, size(hist, 1) - 1);
            hist(end, 4:6) = (hist(end, 1:3) - hist(end - slope_steps, 1:3)) / ...
                (slope_steps * cfg.dyn.dt);
        end
    end
    pred = predict_obstacle_traj(hist, method, cfg, net);
    delay_comp = getfield_or(cfg.dyn, 'delayCompensation', false);
    if delay_comp && delay > 0 && N_pred > 1
        % The predictor starts at observed_step. Discard delayed samples so
        % row k again denotes the next step after current time.
        shift = min(delay, N_pred - 1);
        tail_steps = min(4, N_pred - 1);
        tail_v = (pred(end, :) - pred(end - tail_steps, :)) / ...
            (tail_steps * cfg.dyn.dt);
        tail_t = (1:shift)' * cfg.dyn.dt;
        pred = [pred(shift + 1:end, :); pred(end, :) + tail_t * tail_v];
    end
    obs_pred(:, :, j) = pred;
end
end

function v = getfield_or(s, name, default)
if isfield(s, name), v = s.(name); else, v = default; end
end

function [ade, fde] = eval_pred_error(obstacles, step, obs_pred, N_pred)
% eval_pred_error - Compute ADE and FDE between predictions and true futures.
% Inputs: obstacle structs, current step, predictions, prediction length.
% Outputs: ADE and FDE averaged over all obstacles.
M = numel(obstacles);
ade = 0; fde = 0; cnt = 0;
for j = 1:M
    fut = obstacles(j).traj(step + 1 : step + N_pred, 1:3);
    err = sqrt(sum((obs_pred(:, :, j) - fut).^2, 2));
    ade = ade + mean(err);
    fde = fde + err(end);
    cnt = cnt + 1;
end
ade = ade / max(1, cnt);
fde = fde / max(1, cnt);
end

function rmse = cross_track_rmse(traj, start, goal)
% cross_track_rmse - Root-mean-square lateral error relative to start-goal line.
% Inputs: ego trajectory, start and goal positions. Output rmse: scalar error.
a = start(1:3); b = goal(1:3);
ab = b - a; L = norm(ab);
if L < 1e-9
    rmse = 0; return;
end
errs = zeros(size(traj, 1), 1);
for i = 1:size(traj, 1)
    p = traj(i, 1:3)';
    t = clamp01(dot(p - a, ab) / (L * L));
    proj = a + t * ab;
    errs(i) = norm(p - proj);
end
rmse = sqrt(mean(errs.^2));
end

function [v_range, wt_range, wp_range] = createDynamicWindow3D(ctrl, cfg)
% createDynamicWindow3D - Compute reachable speed, pitch-rate, and yaw-rate ranges.
% Inputs: current control and config. Outputs: three 1 x 2 ranges.
v_c = ctrl(1); wt = ctrl(2); wp = ctrl(3);
v_range = [max(0, v_c - cfg.maxAcc * cfg.dt), ...
           min(cfg.maxSpeed, v_c + cfg.maxAcc * cfg.dt)];
wt_range = [max(-cfg.maxPitchRate, wt - cfg.maxPitchAcc * cfg.dt), ...
            min( cfg.maxPitchRate, wt + cfg.maxPitchAcc * cfg.dt)];
wp_range = [max(-cfg.maxYawRate, wp - cfg.maxYawAcc * cfg.dt), ...
            min( cfg.maxYawRate, wp + cfg.maxYawAcc * cfg.dt)];
end

function traj = predictTrajectory3D(state, ctrl, cfg)
% predictTrajectory3D - Propagate the UAV state under a constant control.
% Inputs: UAV state, control, config. Output traj: predicted state trajectory.
traj = predict_trajectory_constant(state, ctrl, cfg);
end

function ok = within_flight_corridor(traj, start, goal, cfg)
% within_flight_corridor - Reject candidates that leave the allowed flight band.
if ~isfield(cfg, 'flight'), ok = true; return; end
pos = traj(:, 1:3);
zmin = getfield_or(cfg.flight, 'zMin', -inf);
zmax = getfield_or(cfg.flight, 'zMax', inf);
band = getfield_or(cfg.flight, 'zRouteBand', inf);
if any(pos(:, 3) < zmin | pos(:, 3) > zmax)
    ok = false; return;
end
ab = goal - start;
den = dot(ab, ab) + 1e-12;
q = pos - start';
t = max(0, min(1, (q * ab) / den));
z_nom = start(3) + t * (goal(3) - start(3));
ok = all(abs(pos(:, 3) - z_nom) <= band + 1e-9);
end

function s = vertical_corridor_score(traj, start, goal)
% Score candidates by maximum deviation from the nominal altitude profile.
ab = goal - start;
den = dot(ab, ab) + 1e-12;
q = traj(:, 1:3) - start';
t = max(0, min(1, (q * ab) / den));
z_nom = start(3) + t * (goal(3) - start(3));
s = 1 / (1 + max(abs(traj(:, 3) - z_nom)));
end

function minDist = calcMinDist3D_dynamic(traj, obs_pred, obs_radius, cfg, injectH)
% calcMinDist3D_dynamic - Minimum clearance along a trajectory against predictions.
% Inputs: candidate trajectory, predictions, radii, config, injection horizon.
% Output minDist: minimum signed clearance; negative values indicate overlap.
n = min([size(traj, 1), size(obs_pred, 1), injectH]);
M = size(obs_pred, 3);
minDist = inf;
for k = 1:n
    pos = traj(k, 1:3)';
    for j = 1:M
        oc = obs_pred(k, :, j)';
        d = norm(pos - oc) - obs_radius(j) - cfg.UAV_radius;
        if d < minDist
            minDist = d;
        end
    end
end
end

function s = scoreObstacle3D_dynamic(traj, obs_pred, obs_radius, cfg, injectH)
% scoreObstacle3D_dynamic - Obstacle score based on capped minimum clearance.
% Inputs: same geometry as calcMinDist3D_dynamic. Output s: capped clearance score.
d = calcMinDist3D_dynamic(traj, obs_pred, obs_radius, cfg, injectH);
s = min(d, cfg.maxClearance);
end

function box = boundingBoxSafe(valid_ctrls, cfg)
% boundingBoxSafe - Return expanded control bounds around all valid DWA samples.
% Inputs: valid controls and config. Output box: 1 x 6 expanded bounds.
delta = cfg.coupling.delta;
box = [min(valid_ctrls(:, 1)) - delta, max(valid_ctrls(:, 1)) + delta, ...
       min(valid_ctrls(:, 2)) - delta, max(valid_ctrls(:, 2)) + delta, ...
       min(valid_ctrls(:, 3)) - delta, max(valid_ctrls(:, 3)) + delta];
box(1) = max(0, box(1)); box(2) = min(cfg.maxSpeed, box(2));
box(3) = max(-cfg.maxPitchRate, box(3)); box(4) = min(cfg.maxPitchRate, box(4));
box(5) = max(-cfg.maxYawRate, box(5)); box(6) = min(cfg.maxYawRate, box(6));
end

function y = clamp01(x)
    % clamp01 - Clip x to the interval [0, 1].
    % Input x: value to clip. Output y: clipped value.
    y = max(0, min(1, x));
end

function v = mean_or_zero(x)
if isempty(x), v = 0; else, v = mean(x); end
end

function v = percentile_or_zero(x, p)
if isempty(x), v = 0; else, v = prctile(x, p); end
end

function label = classify_failure(success, collisions, finalDist, goalTol, solveFailures, fallbackSteps)
if success
    label = 'success';
    return;
end
flags = {};
if collisions > 0, flags{end + 1} = 'collision'; end %#ok<AGROW>
if finalDist >= goalTol, flags{end + 1} = 'goal_not_reached'; end %#ok<AGROW>
if solveFailures > 0, flags{end + 1} = 'mpc_solve_failure'; end %#ok<AGROW>
if fallbackSteps > 0, flags{end + 1} = 'dwa_no_safe_candidate'; end %#ok<AGROW>
if isempty(flags), flags = {'other'}; end
label = strjoin(flags, '|');
end
