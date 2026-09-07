function samples = sampleIntelligent3D(v_range, wt_range, wp_range, u_mpc, tau, cfg)
% sampleIntelligent3D - 基于 MPC 信任度的智能采样 (论文式10~12)
%
% 传统 DWA 用均匀网格采样; 这里根据信任度 tau 自适应采样:
%   Nsample = Nbase * (1 + alpha * exp(-beta * tau))
%   引导区域 Vg = {u : |u - u_MPC| <= rGuide} 采样 Ng = Nsample*tau 个点,
%   探索区域 Ve 采样 Ne = Nsample - Ng 个点。
% tau 高 -> 少采样、集中在 MPC 引导附近; tau 低 -> 多采样、扩大搜索。

c   = cfg.coupling;
Nsample = round(c.Nbase * (1 + c.alpha * exp(-c.beta * tau)));
Ng = round(Nsample * tau);
Ne = Nsample - Ng;

samples = zeros(Ng + Ne, 3);
idx = 0;

% 引导区域采样: 在 u_MPC 附近按半径 rGuide 随机撒点, 再裁剪到动态窗口内
for i = 1:Ng
    v  = u_mpc(1) + (2*rand - 1) * c.rGuide;
    wt = u_mpc(2) + (2*rand - 1) * c.rGuide;
    wp = u_mpc(3) + (2*rand - 1) * c.rGuide;
    v  = min(max(v,  v_range(1)),  v_range(2));
    wt = min(max(wt, wt_range(1)), wt_range(2));
    wp = min(max(wp, wp_range(1)), wp_range(2));
    idx = idx + 1;
    samples(idx, :) = [v, wt, wp];
end

% 探索区域采样: 在整个动态窗口内均匀随机
for i = 1:Ne
    v  = v_range(1)  + rand * (v_range(2)  - v_range(1));
    wt = wt_range(1) + rand * (wt_range(2) - wt_range(1));
    wp = wp_range(1) + rand * (wp_range(2) - wp_range(1));
    idx = idx + 1;
    samples(idx, :) = [v, wt, wp];
end

% 始终把 MPC 引导量本身放进候选集, 保证至少有一个高信任候选
u_mpc_clip = [min(max(u_mpc(1), v_range(1)), v_range(2));
              min(max(u_mpc(2), wt_range(1)), wt_range(2));
              min(max(u_mpc(3), wp_range(1)), wp_range(2))];
samples = [u_mpc_clip'; samples];
end
