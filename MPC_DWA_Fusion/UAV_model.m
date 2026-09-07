function state_next = UAV_model(state, control, dt, params)

    x = state(1); y = state(2); z = state(3);
    theta = state(4); psi = state(5); v = state(6);

    v_c = control(1);
    omega_theta = control(2);
    omega_psi   = control(3);

    % 位置运动学: 速度分解到 xyz 三个方向
    dx = v * cos(theta) * cos(psi);
    dy = v * cos(theta) * sin(psi);
    dz = v * sin(theta);

    % 姿态运动学: 角速度直接积分
    dtheta = omega_theta;
    dpsi   = omega_psi;

    % 速度一阶惯性响应: 实际速度平滑逼近指令速度
    dv = (v_c - v) / params.tau;

    state_next = state + [dx; dy; dz; dtheta; dpsi; dv] * dt;
end
