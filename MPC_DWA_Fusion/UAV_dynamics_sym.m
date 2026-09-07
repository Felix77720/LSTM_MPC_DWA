function x_next = UAV_dynamics_sym(x, u, cfg)
% UAV_dynamics_sym - 无人机离散动力学的 CasADi 符号形式
%
% 与 UAV_model.m 逐项对应, 只是 x/u 换成 CasADi 的符号变量 (MX)。
% 这样 CasADi 能自动对动力学求偏导, 用于 IPOPT 的梯度/雅可比计算。
%
% x : 6x1 CasADi 列向量 [x, y, z, theta, psi, v]
% u : 3x1 CasADi 列向量 [v_c, omega_theta, omega_psi]

theta = x(4);
psi   = x(5);
v     = x(6);

v_c          = u(1);
omega_theta  = u(2);
omega_psi    = u(3);

dx = v * cos(theta) * cos(psi);
dy = v * cos(theta) * sin(psi);
dz = v * sin(theta);

x_next = x + cfg.dt * [dx; dy; dz; omega_theta; omega_psi; (v_c - v)/cfg.tau];
end
