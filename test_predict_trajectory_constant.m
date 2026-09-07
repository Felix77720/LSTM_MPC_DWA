function test_predict_trajectory_constant()
% Compare vectorized propagation with the reference Euler implementation.
here=fileparts(mfilename('fullpath')); addpath(here); baseline=resolve_baseline(here); addpath(baseline); cfg=config_LSTM(); rng(7); maxerr=0;
for q=1:10
    s=randn(6,1); u=randn(3,1); u(1)=abs(u(1)); n=ceil(cfg.predictTime/cfg.dt); ref=zeros(n,6); x=s;
    for k=1:n, x=UAV_model(x,u,cfg.dt,cfg); ref(k,:)=x'; end
    got=predict_trajectory_constant(s,u,cfg); maxerr=max(maxerr,max(abs(got(:)-ref(:))));
end
assert(maxerr<1e-10); fprintf('constant trajectory regression passed, maxerr=%.3g\n',maxerr);
end
