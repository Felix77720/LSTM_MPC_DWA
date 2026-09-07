function result = MPC_UAV_dynamic_cached(state, goal, obs_pred, obs_radius, cfg, prev, dwa_box, u_exec)
% MPC_UAV_dynamic_cached - Parameterized, cached CasADi MPC.
% The symbolic problem is compiled once per configuration. Subsequent calls
% update only state, goal, obstacle and first-control-bound parameters.

import casadi.*
N = cfg.mpc.N;
injectH = min(N, cfg.dyn.injectHorizon);
M = size(obs_pred, 3);
Mcache = max(1, M); % keep the no-obstacle case compilable
prob = cached_problem(cfg, N, Mcache, injectH);

obs_mat = zeros(3, N * Mcache);
for j = 1:M
    q = squeeze(obs_pred(1:N, :, j));
    obs_mat(:, (j-1)*N + (1:N)) = q';
end
rad = -100 * ones(Mcache, 1); % inactive dummy obstacle when M == 0
if M > 0, rad(1:M) = obs_radius(:); end

if nargin >= 7 && ~isempty(dwa_box)
    lb_first = [dwa_box(1); dwa_box(3); dwa_box(5)];
    ub_first = [dwa_box(2); dwa_box(4); dwa_box(6)];
else
    lb_first = [0; -cfg.maxPitchRate; -cfg.maxYawRate];
    ub_first = [cfg.maxSpeed; cfg.maxPitchRate; cfg.maxYawRate];
end

if nargin >= 6 && isfield(prev, 'X') && isfield(prev, 'U') ...
        && all(size(prev.X) == [6, N+1]) && all(size(prev.U) == [3, N])
    X0_init = prev.X; U0_init = prev.U;
else
    X0_init = zeros(6, N + 1);
    for k = 1:N + 1
        frac = (k - 1) / N;
        X0_init(1:3, k) = state(1:3) + frac * (goal - state(1:3));
        X0_init(4:6, k) = [0; 0; 1];
    end
    U0_init = zeros(3, N);
end

if nargin >= 8 && ~isempty(u_exec)
    u_last = u_exec(:);
elseif nargin >= 6 && isfield(prev, 'u_first')
    u_last = prev.u_first(:);
else
    u_last = zeros(3, 1);
end

opti = prob.opti;
opti.set_value(prob.X0, state);
opti.set_value(prob.GOAL, goal);
if isfield(cfg, 'routeStart'), opti.set_value(prob.START, cfg.routeStart);
else, opti.set_value(prob.START, state(1:3)); end
opti.set_value(prob.UPREV, u_last);
opti.set_value(prob.OBS, obs_mat);
opti.set_value(prob.RAD, rad);
opti.set_value(prob.LB_FIRST, lb_first);
opti.set_value(prob.UB_FIRST, ub_first);
opti.set_initial(prob.X, X0_init);
opti.set_initial(prob.U, U0_init);

try
    sol = opti.solve();
    X_val = full(sol.value(prob.X));
    U_val = full(sol.value(prob.U));
    cost_val = full(sol.value(prob.J));
    result.exitflag = 1;
catch e
    warning('MPC_UAV_dynamic_cached solve failed: %s', e.message);
    X_val = X0_init; U_val = U0_init; cost_val = NaN; result.exitflag = 0;
end

result.traj = X_val'; result.ctrl = U_val'; result.u_first = U_val(:, 1);
result.cost = cost_val; result.X = X_val; result.U = U_val;
end

function prob = cached_problem(cfg, N, M, injectH)
p = [getfield_or(cfg.mpc, 'wRoute', 0), getfield_or(cfg.mpc, 'wSafety', 0), ...
     getfield_or(cfg.mpc, 'safetyMargin', 0), cfg.mpc.wObs, cfg.mpc.wPos, ...
     cfg.mpc.wTerm, cfg.mpc.wCtrl, cfg.mpc.wSmooth, cfg.dt, cfg.tau];
key = sprintf('N%d_M%d_H%d_%s', N, M, injectH, sprintf('%.12g_', p));
persistent cache
if isempty(cache), cache = containers.Map('KeyType', 'char', 'ValueType', 'any'); end
if isKey(cache, key), prob = cache(key); return; end

import casadi.*
opti = Opti(); X = opti.variable(6, N + 1); U = opti.variable(3, N);
X0 = opti.parameter(6, 1); GOAL = opti.parameter(3, 1);
START = opti.parameter(3, 1); UPREV = opti.parameter(3, 1);
OBS = opti.parameter(3, N * M); RAD = opti.parameter(M, 1);
LB_FIRST = opti.parameter(3, 1); UB_FIRST = opti.parameter(3, 1);

J = 0;
for k = 1:N, opti.subject_to(X(:, k + 1) == UAV_dynamics_sym(X(:, k), U(:, k), cfg)); end
opti.subject_to(X(:, 1) == X0);
if getfield_or(cfg.mpc, 'wRoute', 0) > 0
    ab = GOAL - START; den = sumsqr(ab) + 1e-12;
    for k = 1:N
        e = X(1:3, k+1) - START;
        J = J + cfg.mpc.wRoute * sumsqr(e - (dot(e, ab) / den) * ab);
    end
end
for k = 1:N
    J = J + cfg.mpc.wPos * sumsqr(X(1:3, k) - GOAL) + cfg.mpc.wCtrl * sumsqr(U(:, k));
end
J = J + cfg.mpc.wTerm * sumsqr(X(1:3, end) - GOAL);
for k = 2:N, J = J + cfg.mpc.wSmooth * sumsqr(U(:, k) - U(:, k - 1)); end

for k = 1:injectH
    for j = 1:M
        v = X(1:3, k + 1) - OBS(:, (j-1)*N + k);
        d = sqrt(sumsqr(v) + 1e-12) - RAD(j) - cfg.UAV_radius;
        J = J + cfg.mpc.wObs * fmax(0, -d)^2;
        if getfield_or(cfg.mpc, 'wSafety', 0) > 0
            J = J + cfg.mpc.wSafety * fmax(0, cfg.mpc.safetyMargin - d)^2;
        end
    end
end
opti.minimize(J);
opti.subject_to(0 <= U(1, :) <= cfg.maxSpeed);
opti.subject_to(-cfg.maxPitchRate <= U(2, :) <= cfg.maxPitchRate);
opti.subject_to(-cfg.maxYawRate <= U(3, :) <= cfg.maxYawRate);
opti.subject_to(LB_FIRST <= U(:, 1) <= UB_FIRST);
rate = [cfg.maxAcc; cfg.maxPitchAcc; cfg.maxYawAcc] * cfg.dt;
opti.subject_to(-rate <= U(:, 1) - UPREV <= rate);
for k = 2:N, opti.subject_to(-rate <= U(:, k) - U(:, k - 1) <= rate); end
opti.solver('ipopt', struct('print_time', 0, ...
    'ipopt', struct('print_level', 0, 'max_iter', 300, 'tol', 1e-6)));

prob = struct('opti', opti, 'X', X, 'U', U, 'J', J, 'X0', X0, ...
    'GOAL', GOAL, 'START', START, 'UPREV', UPREV, 'OBS', OBS, 'RAD', RAD, ...
    'LB_FIRST', LB_FIRST, 'UB_FIRST', UB_FIRST);
cache(key) = prob;
end

function v = getfield_or(s, name, default)
if isfield(s, name), v = s.(name); else, v = default; end
end
