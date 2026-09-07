function postprocess_prediction_fixed()
% Aggregate an existing fixed-window CSV; does not rerun prediction.
here=fileparts(mfilename('fullpath')); addpath(here); baseline=resolve_baseline(here); addpath(baseline);
cfg=config_LSTM(); inFile=fullfile(here,'results','prediction_fixed','fixed_window_summary.csv'); outDir=fileparts(inFile);
T=readtable(inFile); G=groupsummary(T,{'Scenario','Method'},'mean',{'ADE','FDE'});
writetable(G,fullfile(outDir,'fixed_window_group_summary.csv'));
windowSteps=10:10:min(200,cfg.maxSteps); save(fullfile(outDir,'fixed_window_metadata.mat'),'T','G','cfg','windowSteps','inFile');
fprintf('Wrote %s and metadata without rerunning prediction.\n',outDir);
end
