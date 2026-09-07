function traj = generate_obstacle_trajectory(kind, p, T, dt, rng_seed)
% generate_obstacle_trajectory - Generate one dynamic obstacle trajectory
% independently of the ego vehicle.
%
% Inputs:
%   kind     - maneuver type: 'straight' | 'turn' | 'helix' | 'hover_go' |
%              'zigzag' | 'waypoints' | 'accel' | 'sine_speed'.
%   p        - maneuver parameter struct (required fields depend on kind).
%   T        - total number of time steps.
%   dt       - time step size.
%   rng_seed - random seed used when the maneuver has randomized behavior.
% Output:
%   traj - T x 7 matrix [x, y, z, vx, vy, vz, psi].

if nargin < 5 || isempty(rng_seed)
    rng_seed = 'default';
end
if isnumeric(rng_seed)
    rng(rng_seed);
end

x = p.x0; y = p.y0; z = p.z0; psi = p.psi0;
traj = zeros(T, 7);
wp_idx = 1;   % used only for 'waypoints'

for k = 1:T
    t = (k - 1) * dt;
    switch kind
        case 'straight'
            v  = p.v; om = 0; vz = p.vz;
        case 'turn'
            v  = p.v; om = p.omega; vz = p.vz;
        case 'helix'
            v  = p.v; om = p.omega; vz = p.vz;
        case 'hover_go'
            if t < p.T_hover
                v = 0; om = 0; vz = 0;
            else
                v = p.v; om = p.omega; vz = p.vz;
            end
        case 'zigzag'
            v  = p.v;
            om = p.omega_amp * sin(2 * pi * p.freq * t);
            vz = p.vz;
        case 'waypoints'
            [v, om, vz, wp_idx] = waypoint_control([x; y; z; psi], p, wp_idx);
        case 'accel'
            v  = clamp(p.v + p.a * t, p.vmin, p.vmax);
            om = p.omega;
            vz = p.vz;
        case 'sine_speed'
            v  = p.v * (1 + p.vamp * sin(2 * pi * p.vfreq * t));
            om = p.omega;
            vz = p.vz;
        otherwise
            error('Unknown maneuver type: %s', kind);
    end

    vx = v * cos(psi);
    vy = v * sin(psi);
    traj(k, :) = [x, y, z, vx, vy, vz, psi];

    x   = x   + vx * dt;
    y   = y   + vy * dt;
    z   = z   + vz * dt;
    psi = psi + om * dt;
end
end

function [v, om, vz, wp_idx] = waypoint_control(state, p, wp_idx)
% waypoint_control - Apply proportional steering and altitude control for
% smooth nonlinear waypoint-following.
% Inputs: current state, waypoint parameter struct p, and current waypoint index.
% Outputs: speed v, turn rate om, vertical speed vz, updated waypoint index.
wp = p.waypoints;
nw = size(wp, 1);

if wp_idx < nw && norm(state(1:3) - wp(wp_idx, :)') < p.wp_tol
    wp_idx = wp_idx + 1;
end

target = wp(wp_idx, :)';
des_psi  = atan2(target(2) - state(2), target(1) - state(1));
head_err = wrapToPi(des_psi - state(4));
om       = clamp(p.Kp_psi * head_err, -p.om_max, p.om_max);
vz       = clamp(p.Kp_z * (target(3) - state(3)), -p.vz_max, p.vz_max);
v        = p.v;
end

function y = clamp(x, lo, hi)
    % clamp - Clip x to the interval [lo, hi].
    % Inputs: x, lo, hi. Output y: clipped value.
    y = max(lo, min(hi, x));
end
