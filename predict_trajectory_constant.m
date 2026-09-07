function traj = predict_trajectory_constant(state, ctrl, cfg)
n = ceil(cfg.predictTime / cfg.dt); k=(0:n-1)'; a=1-cfg.dt/cfg.tau;
v=ctrl(1)+(state(6)-ctrl(1))*a.^k; th=state(4)+k*ctrl(2)*cfg.dt; ps=state(5)+k*ctrl(3)*cfg.dt;
xyz=state(1:3)' + cfg.dt*cumsum([v.*cos(th).*cos(ps),v.*cos(th).*sin(ps),v.*sin(th)],1);
traj=zeros(n,6); traj(:,1:3)=xyz; traj(:,4)=state(4)+(k+1)*ctrl(2)*cfg.dt; traj(:,5)=state(5)+(k+1)*ctrl(3)*cfg.dt; traj(:,6)=ctrl(1)+(state(6)-ctrl(1))*a.^(k+1);
end
