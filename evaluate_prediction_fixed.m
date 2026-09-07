function T = evaluate_prediction_fixed()
% Evaluate static/CV/Kalman/LSTM on identical history and future windows.
here=fileparts(mfilename('fullpath')); addpath(here); baseline=resolve_baseline(here); addpath(baseline); cfg=config_LSTM(); S=load(fullfile(here,'results','lstm_predictor.mat'),'net','muX','sigX','muY','sigY');
cfg.dyn.muX=S.muX; cfg.dyn.sigX=S.sigX; cfg.dyn.muY=S.muY; cfg.dyn.sigY=S.sigY; net=S.net;
sc=generate_eval_scenarios(cfg); methods={'static','cv','kalman','lstm'}; rows={}; out=fullfile(here,'results','prediction_fixed'); if ~exist(out,'dir'),mkdir(out);end
for si=1:numel(sc), for j=1:numel(sc(si).obstacles), for step=10:10:min(200,cfg.maxSteps)
    fut=sc(si).obstacles(j).traj(step+1:step+cfg.dyn.N_pred,1:3); hist=sc(si).obstacles(j).traj(1:step,:);
    for mi=1:numel(methods), p=predict_obstacle_traj(hist,methods{mi},cfg,net); e=sqrt(sum((p-fut).^2,2)); rows(end+1,:)={sc(si).name,j,step,methods{mi},mean(e),e(end)}; end
end,end,end
T=cell2table(rows,'VariableNames',{'Scenario','Obstacle','HistoryStep','Method','ADE','FDE'}); writetable(T,fullfile(out,'fixed_window_summary.csv')); G=groupsummary(T,{'Scenario','Method'},'mean',{'ADE','FDE'}); writetable(G,fullfile(out,'fixed_window_group_summary.csv')); save(fullfile(out,'fixed_window_summary.mat'),'T','G','cfg');
end
