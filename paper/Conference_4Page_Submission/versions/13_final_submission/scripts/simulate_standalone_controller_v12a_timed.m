function res = simulate_standalone_controller_v12a_timed(scenario, controller, net, cfg)
%SIMULATE_STANDALONE_CONTROLLER_V12A_TIMED Isolated timed standalone DWA/MPC copy.
% The method suffix selects the common causal obstacle predictor (CV or LSTM).
% DWA does not call MPC; MPC does not sample, rank, or execute DWA actions.

controller = lower(string(controller));
assert(any(controller == ["standalone_dwa_lstm", "standalone_mpc_lstm", ...
    "standalone_dwa_cv", "standalone_mpc_cv"]), ...
    'Unknown standalone controller: %s', controller);
useMPC = contains(controller, "mpc");
if endsWith(controller, "lstm"), predictor = 'lstm'; else, predictor = 'cv'; end
start = scenario.start(:);
goal = scenario.goal(:);
obstacles = scenario.obstacles;
M = numel(obstacles);
Npred = cfg.dyn.N_pred;
obsRadius = zeros(M,1);
for j = 1:M, obsRadius(j) = obstacles(j).radius; end

cfg.routeStart = start;
state = [start; atan2(goal(3)-start(3), norm(goal(1:2)-start(1:2))); ...
    atan2(goal(2)-start(2), goal(1)-start(1)); 1];
control = [1;0;0];
observationStream = prepare_observation_stream(obstacles, cfg);
trajHistory = state';
controlHistory = control';
timeHistory = 0;
stepTimes = zeros(0,1);
predictionTimes = zeros(0,1);
dwaTimes = zeros(0,1);
mpcTimes = zeros(0,1);
planningTimes = zeros(0,1);
planningCallCount = 0;
collisions = 0;
collisionEvents = 0;
collisionPrev = false;
minClearance = inf;
piecewiseSweptMinClearance = inf;
piecewiseSweptCollision = false;
piecewiseSweptCollisionEvents = 0;
sweptCollisionPrev = false;
stepClearance = zeros(0,1);
solveFailures = 0;
infeasibleStops = 0;
adeSum = 0;
fdeSum = 0;
predictionCount = 0;
steps = 0;
mpcPrev = struct('u_first', control);

for step = 1:cfg.maxSteps
    if norm(state(1:3)-goal) <= cfg.goalTolerance, break; end
    stepTic = tic;
    planningTic = tic;
    predictionTic = tic;
    obsPred = predict_all_method(obstacles, step, predictor, net, cfg, ...
        Npred, observationStream);
    predictionTimes(end+1,1) = toc(predictionTic); %#ok<AGROW>

    if useMPC
        mpcTic = tic;
        plan = MPC_UAV_dynamic_cached(state, goal, obsPred, obsRadius, ...
            cfg, mpcPrev, [], control);
        mpcTimes(end+1,1) = toc(mpcTic); %#ok<AGROW>
        if plan.exitflag == 0
            solveFailures = solveFailures + 1;
            planningTimes(end+1,1) = toc(planningTic); %#ok<AGROW>
            planningCallCount = planningCallCount + 1;
            [ade, fde] = prediction_error(obstacles, step, obsPred, Npred);
            adeSum = adeSum + ade;
            fdeSum = fdeSum + fde;
            predictionCount = predictionCount + 1;
            break; % no unchecked command is issued after solver failure
        end
        selected = plan.u_first;
        mpcPrev = plan;
    else
        dwaTic = tic;
        [selected, feasible] = standalone_dwa_action(state, control, ...
            start, goal, obsPred, obsRadius, cfg);
        dwaTimes(end+1,1) = toc(dwaTic); %#ok<AGROW>
        if ~feasible
            infeasibleStops = infeasibleStops + 1;
            planningTimes(end+1,1) = toc(planningTic); %#ok<AGROW>
            planningCallCount = planningCallCount + 1;
            [ade, fde] = prediction_error(obstacles, step, obsPred, Npred);
            adeSum = adeSum + ade;
            fdeSum = fdeSum + fde;
            predictionCount = predictionCount + 1;
            break; % no unchecked emergency command is issued
        end
    end

    planningTimes(end+1,1) = toc(planningTic); %#ok<AGROW>
    planningCallCount = planningCallCount + 1;
    [ade, fde] = prediction_error(obstacles, step, obsPred, Npred);
    adeSum = adeSum + ade;
    fdeSum = fdeSum + fde;
    predictionCount = predictionCount + 1;

    previousState = state;
    state = UAV_model(state, selected, cfg.dt, cfg);
    control = selected;
    steps = steps + 1;
    trajHistory(end+1,:) = state'; %#ok<AGROW>
    controlHistory(end+1,:) = control'; %#ok<AGROW>
    timeHistory(end+1,1) = step * cfg.dt; %#ok<AGROW>

    currentClearance = inf;
    intervalSweptCollision = false;
    for j = 1:M
        obstacleStart = obstacles(j).traj(step,1:3)';
        obstacleEnd = obstacles(j).traj(step+1,1:3)';
        relativeStart = previousState(1:3)-obstacleStart;
        relativeEnd = state(1:3)-obstacleEnd;
        effectiveRadius = obsRadius(j)+cfg.UAV_radius;
        gap = norm(relativeEnd)-effectiveRadius;
        if gap < 0, collisions = collisions + 1; end
        currentClearance = min(currentClearance, gap);
        deltaRelative = relativeEnd-relativeStart;
        denominator = dot(deltaRelative,deltaRelative);
        if denominator > 0
            alpha = min(1,max(0,-dot(relativeStart,deltaRelative)/denominator));
        else
            alpha = 0;
        end
        sweptGap = norm(relativeStart+alpha*deltaRelative)-effectiveRadius;
        piecewiseSweptMinClearance = min(piecewiseSweptMinClearance,sweptGap);
        intervalSweptCollision = intervalSweptCollision || sweptGap < 0;
    end
    piecewiseSweptCollision = piecewiseSweptCollision || intervalSweptCollision;
    piecewiseSweptCollisionEvents = piecewiseSweptCollisionEvents + ...
        double(intervalSweptCollision && ~sweptCollisionPrev);
    sweptCollisionPrev = intervalSweptCollision;
    minClearance = min(minClearance, currentClearance);
    stepClearance(end+1,1) = currentClearance; %#ok<AGROW>
    inCollision = currentClearance < 0;
    collisionEvents = collisionEvents + double(inCollision && ~collisionPrev);
    collisionPrev = inCollision;
    stepTimes(end+1,1) = toc(stepTic); %#ok<AGROW>
end

finalDistance = norm(state(1:3)-goal);
sampledSuccess = finalDistance <= cfg.goalTolerance && collisions == 0;
success = finalDistance <= cfg.goalTolerance && ~piecewiseSweptCollision;
res = struct();
res.name = scenario.name;
res.method = char(controller);
res.controller = char(controller);
res.steps = steps;
res.finalDist = finalDistance;
res.success = success;
res.sampledSuccess = sampledSuccess;
res.collisions = collisions;
res.collisionEvents = collisionEvents;
res.minClearance = minClearance;
res.piecewiseSweptMinClearance = piecewiseSweptMinClearance;
res.piecewiseSweptCollision = piecewiseSweptCollision;
res.betweenStateCollision = piecewiseSweptCollision && collisions == 0;
res.piecewiseSweptCollisionEvents = piecewiseSweptCollisionEvents;
res.stepClearance = stepClearance;
res.solveFailures = solveFailures;
res.emergencyInfeasibleSteps = infeasibleStops;
res.fallbackSteps = infeasibleStops;
res.pathLength = sum(sqrt(sum(diff(trajHistory(:,1:3),1,1).^2,2)));
res.trackRMSE = cross_track_rmse(trajHistory, start, goal);
res.meanStepTime = mean_or_zero(stepTimes);
res.maxStepTime = max_or_zero(stepTimes);
res.stepTimes = stepTimes;
res.predictionTimes = predictionTimes;
res.dwaTimes = dwaTimes;
res.mpcTimes = mpcTimes;
res.PlanningTimes = planningTimes;
res.PlanningCallCount = planningCallCount;
if planningCallCount > 0
    res.MeanPlanningCallTime = mean(planningTimes);
else
    res.MeanPlanningCallTime = NaN;
end
res.TotalPlanningTime = sum(planningTimes);
res.meanPredictionTime = mean_or_zero(predictionTimes);
res.meanDwaTime = mean_or_zero(dwaTimes);
res.meanMpcTime = mean_or_zero(mpcTimes);
res.p95StepTime = percentile_or_zero(stepTimes,95);
res.ADE = adeSum / max(predictionCount,1);
res.FDE = fdeSum / max(predictionCount,1);
res.traj = trajHistory;
res.ctrl = controlHistory;
res.time = timeHistory;
res.start = start;
res.goal = goal;
res.failureType = classify_failure(success, collisions, finalDistance, ...
    cfg.goalTolerance, solveFailures, infeasibleStops, piecewiseSweptCollision);
end

function [selected, feasible] = standalone_dwa_action(state, control, ...
    start, goal, obsPred, obsRadius, cfg)
% Conventional reachable-window grid, without MPC guidance or trust coupling.
[vRange, pitchRange, yawRange] = dynamic_window(control, cfg);
vSamples = closed_grid(vRange, cfg.vRes);
pitchSamples = closed_grid(pitchRange, cfg.omegaRes);
yawSamples = closed_grid(yawRange, cfg.omegaRes);
candidateControls = zeros(numel(vSamples)*numel(pitchSamples)*numel(yawSamples),3);
idx = 0;
for iv = 1:numel(vSamples)
    for it = 1:numel(pitchSamples)
        for iy = 1:numel(yawSamples)
            idx = idx + 1;
            candidateControls(idx,:) = [vSamples(iv), pitchSamples(it), yawSamples(iy)];
        end
    end
end

safeControls = zeros(0,3);
scores = zeros(0,1);
clearances = zeros(0,1);
for i = 1:size(candidateControls,1)
    u = candidateControls(i,:)';
    predicted = predict_trajectory_constant(state, u, cfg);
    clearance = predicted_clearance(predicted, obsPred, obsRadius, cfg);
    if ~passes_dwa_safety(predicted, clearance, start, goal, cfg), continue; end
    direction = heading_vector(predicted(end,4), predicted(end,5));
    toGoal = goal - predicted(end,1:3)';
    if norm(toGoal) > 1e-10
        headingScore = (1 + dot(direction,toGoal)/norm(toGoal))/2;
    else
        headingScore = 1;
    end
    clearanceScore = min(max(clearance,0),cfg.maxClearance) / max(cfg.maxClearance,eps);
    speedScore = predicted(end,6) / max(cfg.maxSpeed,eps);
    weights = [cfg.headingWeight, cfg.obstacleWeight, cfg.velocityWeight];
    weights = weights / sum(weights);
    score = weights(1)*headingScore + weights(2)*clearanceScore + weights(3)*speedScore;
    safeControls(end+1,:) = u'; %#ok<AGROW>
    scores(end+1,1) = score; %#ok<AGROW>
    clearances(end+1,1) = clearance; %#ok<AGROW>
end

if ~isempty(safeControls)
    [~,best] = max(scores);
    selected = safeControls(best,:)';
    feasible = true;
    return;
end

% Apply the same reachable low-speed emergency screen used by the integrated
% planner; it is a safety fallback, not MPC guidance.
pitchBrake = max(pitchRange(1), min(pitchRange(2), -state(4)/cfg.dt));
yawEmergency = unique([yawRange(1), max(yawRange(1),min(yawRange(2),0)), yawRange(2)]);
emergency = candidateControls;
for iy = 1:numel(yawEmergency)
    emergency(end+1,:) = [vRange(1), pitchBrake, yawEmergency(iy)]; %#ok<AGROW>
end
emergencyClearance = -inf(size(emergency,1),1);
emergencySafe = false(size(emergency,1),1);
terminalSpeed = inf(size(emergency,1),1);
for i = 1:size(emergency,1)
    predicted = predict_trajectory_constant(state, emergency(i,:)', cfg);
    emergencyClearance(i) = predicted_clearance(predicted,obsPred,obsRadius,cfg);
    emergencySafe(i) = passes_dwa_safety(predicted,emergencyClearance(i),start,goal,cfg);
    terminalSpeed(i) = predicted(end,6);
end
if ~any(emergencySafe)
    selected = [0;0;0];
    feasible = false;
    return;
end
ids = find(emergencySafe);
[~,order] = sortrows([-emergencyClearance(ids),terminalSpeed(ids)],[1 2]);
selected = emergency(ids(order(1)),:)';
feasible = true;
end

function [vRange, pitchRange, yawRange] = dynamic_window(control,cfg)
vRange = [max(0,control(1)-cfg.maxAcc*cfg.dt), ...
    min(cfg.maxSpeed,control(1)+cfg.maxAcc*cfg.dt)];
pitchRange = [max(-cfg.maxPitchRate,control(2)-cfg.maxPitchAcc*cfg.dt), ...
    min(cfg.maxPitchRate,control(2)+cfg.maxPitchAcc*cfg.dt)];
yawRange = [max(-cfg.maxYawRate,control(3)-cfg.maxYawAcc*cfg.dt), ...
    min(cfg.maxYawRate,control(3)+cfg.maxYawAcc*cfg.dt)];
end

function values = closed_grid(bounds,resolution)
if bounds(2)-bounds(1) < eps
    values = bounds(1); return;
end
values = bounds(1):resolution:bounds(2);
if isempty(values) || values(end) < bounds(2)-1e-10
    values = [values,bounds(2)];
end
values = unique(values);
end

function ok = passes_dwa_safety(traj,clearance,start,goal,cfg)
reject = 0;
if isfield(cfg,'coupling') && isfield(cfg.coupling,'dReject')
    reject = cfg.coupling.dReject;
end
stopSpeed = sqrt(2*cfg.maxDec*max(clearance,0));
ok = clearance > reject && within_flight_corridor(traj,start,goal,cfg) && ...
    traj(end,6) <= stopSpeed;
end

function d = predicted_clearance(traj,obsPred,obsRadius,cfg)
n = min(size(traj,1),size(obsPred,1));
d = inf;
for k = 1:n
    for j = 1:size(obsPred,3)
        gap = norm(traj(k,1:3)'-squeeze(obsPred(k,:,j))') - ...
            obsRadius(j)-cfg.UAV_radius;
        d = min(d,gap);
    end
end
end

function obsPred = predict_all_method(obstacles,step,method,net,cfg,Npred,stream)
M = numel(obstacles);
obsPred = zeros(Npred,3,M);
for j = 1:M
    delay = field_or(cfg.dyn,'obsDelaySteps',0);
    observedStep = max(1,step-delay);
    if isempty(stream), hist = obstacles(j).traj(1:observedStep,:);
    else, hist = stream{j}(1:observedStep,:); end
    noise = field_or(cfg.dyn,'obsNoise',0);
    if noise > 0
        smoothSteps = min(field_or(cfg.dyn,'obsSmoothingSteps',1),size(hist,1));
        if smoothSteps > 1
            latest = hist(end,1:3);
            hist(:,1:3) = movmean(hist(:,1:3),[smoothSteps-1,0],1);
            hist(:,1:3) = hist(:,1:3) + latest-hist(end,1:3);
        end
        if size(hist,1) >= 2
            hist(:,4:6) = [hist(1,4:6);diff(hist(:,1:3),1,1)/cfg.dyn.dt];
            slopeSteps = min(4,size(hist,1)-1);
            hist(end,4:6) = (hist(end,1:3)-hist(end-slopeSteps,1:3)) / ...
                (slopeSteps*cfg.dyn.dt);
        end
    end
    pred = predict_obstacle_traj(hist,method,cfg,net);
    if field_or(cfg.dyn,'delayCompensation',false) && delay > 0 && Npred > 1
        shift = min(delay,Npred-1);
        tailSteps = min(4,Npred-1);
        tailV = (pred(end,:)-pred(end-tailSteps,:))/(tailSteps*cfg.dyn.dt);
        tailT = (1:shift)'*cfg.dyn.dt;
        pred = [pred(shift+1:end,:);pred(end,:)+tailT*tailV];
    end
    obsPred(:,:,j) = pred;
end
end

function [ade,fde] = prediction_error(obstacles,step,pred,Npred)
if isempty(obstacles), ade = NaN; fde = NaN; return; end
ade = 0; fde = 0;
for j = 1:numel(obstacles)
    truth = obstacles(j).traj(step+1:step+Npred,1:3);
    errorByStep = sqrt(sum((pred(:,:,j)-truth).^2,2));
    ade = ade + mean(errorByStep);
    fde = fde + errorByStep(end);
end
ade = ade/numel(obstacles);
fde = fde/numel(obstacles);
end

function ok = within_flight_corridor(traj,start,goal,cfg)
if ~isfield(cfg,'flight'), ok = true; return; end
pos = traj(:,1:3);
if any(pos(:,3) < field_or(cfg.flight,'zMin',-inf) | ...
       pos(:,3) > field_or(cfg.flight,'zMax',inf))
    ok = false; return;
end
ab = goal-start;
q = pos-start';
t = max(0,min(1,(q*ab)/(dot(ab,ab)+1e-12)));
zNom = start(3)+t*(goal(3)-start(3));
ok = all(abs(pos(:,3)-zNom) <= field_or(cfg.flight,'zRouteBand',inf)+1e-9);
end

function h = heading_vector(theta,psi)
h = [cos(theta)*cos(psi);cos(theta)*sin(psi);sin(theta)];
end

function rmse = cross_track_rmse(traj,start,goal)
ab = goal-start; den = dot(ab,ab);
if den < 1e-12, rmse = 0; return; end
err = zeros(size(traj,1),1);
for i = 1:size(traj,1)
    p = traj(i,1:3)';
    t = max(0,min(1,dot(p-start,ab)/den));
    err(i) = norm(p-(start+t*ab));
end
rmse = sqrt(mean(err.^2));
end

function label = classify_failure(success,collisions,finalDist,goalTol,solveFailures,infeasible,sweptCollision)
if success, label = 'success'; return; end
flags = {};
if collisions > 0 || sweptCollision, flags{end+1} = 'collision'; end %#ok<AGROW>
if finalDist > goalTol, flags{end+1} = 'goal_not_reached'; end %#ok<AGROW>
if solveFailures > 0, flags{end+1} = 'mpc_solve_failure'; end %#ok<AGROW>
if infeasible > 0, flags{end+1} = 'infeasible_stop'; end %#ok<AGROW>
if isempty(flags), flags = {'other'}; end
label = strjoin(flags,'|');
end

function value = field_or(s,name,default)
if isfield(s,name), value = s.(name); else, value = default; end
end
function value = mean_or_zero(x)
if isempty(x), value = 0; else, value = mean(x); end
end
function value = max_or_zero(x)
if isempty(x), value = 0; else, value = max(x); end
end
function value = percentile_or_zero(x,p)
if isempty(x), value = 0; else, value = prctile(x,p); end
end
