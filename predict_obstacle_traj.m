function pred = predict_obstacle_traj(hist, method, cfg, net)
% predict_obstacle_traj - Unified interface for obstacle trajectory prediction.
%
% Inputs:
%   hist   - obstacle history with >= 1 row and 7 columns
%            [x,y,z,vx,vy,vz,psi]; the last row is the current state.
%   method - 'static' | 'cv' | 'kalman' | 'lstm'.
%   cfg    - configuration struct.
%   net    - trained LSTM network (required only for method 'lstm').
% Output:
%   pred - N_pred x 3 future absolute positions.

N_pred = cfg.dyn.N_pred;
dt     = cfg.dyn.dt;

switch lower(method)
    case 'static'
        cur = hist(end, 1:3);
        pred = repmat(cur, N_pred, 1);

    case 'cv'
        cur = hist(end, 1:3);
        if size(hist, 1) >= 2
            v = (hist(end, 1:3) - hist(end - 1, 1:3)) / dt;
        else
            v = [0, 0, 0];
        end
        pred = cur + (1:N_pred)' * v * dt;

    case 'kalman'
        pred = kalman_predict(hist, N_pred, dt);

    case 'lstm'
        pred = lstm_predict(hist, N_pred, cfg, net);

    otherwise
        error('未知预测方法: %s', method);
end
end

function pred = lstm_predict(hist, N_pred, cfg, net)
% lstm_predict - Predict future positions with the trained LSTM network.
% Inputs: obstacle history, prediction length, config, trained net.
% Output pred: N_pred x 3 future absolute positions.
T_hist = cfg.dyn.T_hist;

if size(hist, 1) >= T_hist
    win = hist(end - T_hist + 1 : end, :);
else
    pad = repmat(hist(1, :), T_hist - size(hist, 1), 1);
    win = [pad; hist];
end

F  = features_from_traj(win);              % 8 x T_hist
Fn = (F - cfg.dyn.muX) ./ cfg.dyn.sigX;

out = predict(net, Fn);                    % (3*N_pred) x 1
if iscell(out)
    out = out{1};
end
out = out(:);                              % enforce a (3*N_pred) x 1 column vector
dY = out .* repmat(cfg.dyn.sigY, N_pred, 1) + repmat(cfg.dyn.muY, N_pred, 1);
dY = reshape(dY, 3, N_pred)';              % N_pred x 3

pred = hist(end, 1:3) + dY;
end

function pred = kalman_predict(hist, N_pred, dt)
% kalman_predict - Predict future positions with a constant-velocity Kalman filter.
% Inputs: obstacle history, prediction length, step size.
% Output pred: N_pred x 3 future absolute positions.
cur = hist(end, 1:3);
if size(hist, 1) < 2
    pred = repmat(cur, N_pred, 1);
    return;
end

v0 = (hist(end, 1:3) - hist(end - 1, 1:3)) / dt;
x  = [hist(end, 1:3)'; v0'];              % [x,y,z,vx,vy,vz]
P  = eye(6);
F  = [eye(3), dt * eye(3); zeros(3), eye(3)];
H  = [eye(3), zeros(3)];
Q  = diag([1e-4, 1e-4, 1e-4, 0.05, 0.05, 0.05]);
R  = 0.05^2 * eye(3);

for i = 2:size(hist, 1)
    x = F * x;
    P = F * P * F' + Q;
    z = hist(i, 1:3)';
    S = H * P * H' + R;
    K = P * H' / S;
    x = x + K * (z - H * x);
    P = (eye(6) - K * H) * P;
end

pred = zeros(N_pred, 3);
xk = x;
for k = 1:N_pred
    xk = F * xk;
    pred(k, :) = (H * xk)';
end
end
