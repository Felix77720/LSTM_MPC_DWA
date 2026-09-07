function w = dynamicWeights(tau, cfg)
% dynamicWeights - 基于信任度 tau 的自适应评价权重 (论文式22~25)
%
% 返回 w = [w_pos, w_heading, w_vel, w_obs], 已归一化使其和为 1。
% 高信任度 -> 位置/航向/速度跟踪权重升高、避障权重降低 (更相信 MPC 引导);
% 低信任度 -> 避障权重升高 (回归保守的局部避障)。

c = cfg.coupling;

sig = 1 / (1 + exp(-c.sigmoidK * (tau - c.sigmoidX0)));   % sigmoid(0..1)

w_pos = c.wPosRange(1)  + (c.wPosRange(2)  - c.wPosRange(1))  * sig;
w_head= c.wHeadRange(1) + (c.wHeadRange(2) - c.wHeadRange(1)) * sig;
w_vel = c.wVelBase * (1 + sig);
w_obs = sig * c.wObsRange(1) + (1 - sig) * c.wObsRange(2);

total = w_pos + w_head + w_vel + w_obs;
w = [w_pos, w_head, w_vel, w_obs] / total;
end
