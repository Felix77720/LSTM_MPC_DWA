function result = MPC_UAV_dynamic(state, goal, obs_pred, obs_radius, cfg, prev, dwa_box, u_exec)
% MPC_UAV_dynamic - Solve the MPC planning layer with time-varying dynamic
% obstacle constraints using CasADi and IPOPT.
% Unlike the baseline MPC_UAV, obstacle centers are not fixed; row k of
% obs_pred is the predicted position of every obstacle at MPC step k.
%
% Inputs:
%   state      - current UAV state (6 x 1).
%   goal       - goal position (3 x 1).
%   obs_pred   - predicted obstacle positions (N x 3 x M).
%   obs_radius - obstacle radii (M x 1).
%   cfg        - configuration struct.
%   prev       - optional previous result with X, U, and/or u_first for warm
%                starting (may be empty).
%   dwa_box    - optional 1 x 6 bounds restricting the first control.
%   u_exec     - optional executed control from the previous step.
% Output:
%   result - struct with exitflag, traj, ctrl, u_first, cost, X, and U.

import casadi.*

N = cfg.mpc.N;
dt = cfg.dt;
M = size(obs_pred, 3);
injectH = min(N, cfg.dyn.injectHorizon);

opti = Opti();

X = opti.variable(6, N + 1);
U = opti.variable(3, N);

X0    = opti.parameter(6, 1);
GOAL  = opti.parameter(3, 1);
START = opti.parameter(3, 1);
UPREV = opti.parameter(3, 1);
J = 0;

% Dynamics
for k = 1:N
    opti.subject_to(X(:, k + 1) == UAV_dynamics_sym(X(:, k), U(:, k), cfg));
end
if isfield(cfg.mpc, 'wRoute') && cfg.mpc.wRoute > 0
    ab = GOAL - START; den = sumsqr(ab) + 1e-12;
    for k = 1:N
        e = X(1:3,k+1)-START; J = J + cfg.mpc.wRoute*sumsqr(e - (dot(e,ab)/den)*ab);
    end
end
opti.subject_to(X(:, 1) == X0);

% Cost
for k = 1:N
    J = J + cfg.mpc.wPos  * sumsqr(X(1:3, k) - GOAL) ...
          + cfg.mpc.wCtrl * sumsqr(U(:, k));
end
J = J + cfg.mpc.wTerm * sumsqr(X(1:3, end) - GOAL);
for k = 2:N
    J = J + cfg.mpc.wSmooth * sumsqr(U(:, k) - U(:, k - 1));
end

% Time-varying soft obstacle constraints injected over the first injectH steps
for k = 1:injectH
    for j = 1:M
        % obs_pred(k,:) is the obstacle position at the end of control step k.
        % Compare it with the corresponding propagated state X(:,k+1).
        v = X(1:3, k + 1) - obs_pred(k, :, j)';
        % Epsilon avoids a 0/0 gradient (NaN) when X is exactly at the center.
        d = sqrt(sumsqr(v) + 1e-12) - obs_radius(j) - cfg.UAV_radius;
        J = J + cfg.mpc.wObs * fmax(0, -d)^2;
        if isfield(cfg.mpc, 'wSafety') && cfg.mpc.wSafety > 0 && isfield(cfg.mpc, 'safetyMargin')
            J = J + cfg.mpc.wSafety * fmax(0, cfg.mpc.safetyMargin - d)^2;
        end
    end
end
opti.minimize(J);

% Control magnitude and slew-rate constraints
opti.subject_to(0                 <= U(1, :) <= cfg.maxSpeed);
opti.subject_to(-cfg.maxPitchRate <= U(2, :) <= cfg.maxPitchRate);
opti.subject_to(-cfg.maxYawRate   <= U(3, :) <= cfg.maxYawRate);

if nargin >= 7 && ~isempty(dwa_box)
    opti.subject_to(dwa_box(1) <= U(1, 1) <= dwa_box(2));
    opti.subject_to(dwa_box(3) <= U(2, 1) <= dwa_box(4));
    opti.subject_to(dwa_box(5) <= U(3, 1) <= dwa_box(6));
end

rate = [cfg.maxAcc; cfg.maxPitchAcc; cfg.maxYawAcc] * dt;
opti.subject_to(-rate <= U(:, 1) - UPREV <= rate);
for k = 2:N
    opti.subject_to(-rate <= U(:, k) - U(:, k - 1) <= rate);
end

opti.solver('ipopt', struct('print_time', 0, ...
    'ipopt', struct('print_level', 0, 'max_iter', 300, 'tol', 1e-6)));

opti.set_value(X0, state);
opti.set_value(GOAL, goal);
if isfield(cfg, 'routeStart'), opti.set_value(START, cfg.routeStart); else, opti.set_value(START, state(1:3)); end

if nargin >= 8 && ~isempty(u_exec)
    u_last = u_exec(:);
elseif nargin >= 6 && isfield(prev, 'u_first')
    u_last = prev.u_first(:);
else
    u_last = zeros(3, 1);
end
opti.set_value(UPREV, u_last);

if nargin >= 6 && isfield(prev, 'X') && isfield(prev, 'U') ...
        && all(size(prev.X) == [6, N+1]) && all(size(prev.U) == [3, N])
    X0_init = prev.X;
    U0_init = prev.U;
else
    X0_init = zeros(6, N + 1);
    for k = 1:N + 1
        frac = (k - 1) / N;
        X0_init(1:3, k) = state(1:3) + frac * (goal - state(1:3));
        X0_init(4:6, k) = [0; 0; 1];
    end
    U0_init = zeros(3, N);
end
opti.set_initial(X, X0_init);
opti.set_initial(U, U0_init);

try
    sol = opti.solve();
    X_val = full(sol.value(X));
    U_val = full(sol.value(U));
    cost_val = full(sol.value(J));
    result.exitflag = 1;
catch e
    warning('MPC_UAV_dynamic solve failed: %s', e.message);
    X_val = X0_init;
    U_val = U0_init;
    cost_val = NaN;
    result.exitflag = 0;
end

result.traj    = X_val';
result.ctrl    = U_val';
result.u_first = U_val(:, 1);
result.cost    = cost_val;
result.X       = X_val;
result.U       = U_val;
end
