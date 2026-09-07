function run_supplemental_experiments(mode)
% run_supplemental_experiments - Reproducible supplemental pilot/full runs.
% mode: 'quick' (one representative seed), 'pilot', or 'full'.
if nargin < 1, mode = 'quick'; end
mode = lower(mode);
here = fileparts(mfilename('fullpath')); addpath(here); baseline = resolve_baseline(here);
addpath(here, baseline, fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b'));
cfg = config_LSTM(); outdir = fullfile(here, 'results', 'supplemental');
cfg.maxSteps = 700; cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;
if ~exist(outdir, 'dir'), mkdir(outdir); end
runid = datestr(now, 'yyyymmdd_HHMMSS'); outdir = fullfile(outdir, [mode '_' runid]); mkdir(outdir);
netfile = fullfile(here, 'results', 'lstm_predictor.mat');
if ~exist(netfile, 'file'), error('需要先运行 run_experiments 生成 LSTM 模型'); end
S = load(netfile, 'net', 'muX', 'sigX', 'muY', 'sigY'); net = S.net;
cfg.dyn.muX=S.muX; cfg.dyn.sigX=S.sigX; cfg.dyn.muY=S.muY; cfg.dyn.sigY=S.sigY;
noobs = struct('name','N0 无障碍对照','start',[1 1 1]','goal',[18 18 8]','obstacles',struct('traj',{},'radius',{}));
repeat = generate_repeat_scenario(cfg); evals = generate_eval_scenarios(cfg);
switch mode
    case 'quick', seeds=0; jobs={struct('s',noobs,'m','lstm','h',30,'w',3),struct('s',repeat,'m','lstm','h',30,'w',0),struct('s',repeat,'m','lstm','h',30,'w',3)};
    case 'pilot', seeds=0; jobs={struct('s',noobs,'m','lstm','h',30,'w',3),struct('s',repeat,'m','lstm','h',30,'w',0),struct('s',repeat,'m','static','h',30,'w',3),struct('s',repeat,'m','cv','h',30,'w',3),struct('s',repeat,'m','kalman','h',30,'w',3),struct('s',repeat,'m','lstm','h',30,'w',3),struct('s',repeat,'m','lstm_mpc_only','h',30,'w',3),struct('s',repeat,'m','lstm_dwa_only','h',30,'w',3),struct('s',repeat,'m','lstm','h',10,'w',3),struct('s',repeat,'m','lstm','h',20,'w',3)};
    case 'full'
        seeds=0:2; jobs={struct('s',noobs,'m','lstm','h',30,'w',3)}; for si=1:4, for m={'static','cv','kalman','lstm'}, jobs{end+1}=struct('s',evals(si),'m',m{1},'h',30,'w',3); end, end
        jobs{end+1}=struct('s',repeat,'m','lstm','h',30,'w',0); for m={'static','cv','lstm','lstm_mpc_only','lstm_dwa_only'}, jobs{end+1}=struct('s',repeat,'m',m{1},'h',30,'w',3); end
        jobs{end+1}=struct('s',repeat,'m','lstm','h',10,'w',3); jobs{end+1}=struct('s',repeat,'m','lstm','h',20,'w',3);
    otherwise, error('mode must be quick, pilot, or full');
end
rows = {};
all_res = {};
model_sha = file_sha256(netfile);
for seed = seeds
    for ji=1:numel(jobs)
                job=jobs{ji}; h=job.h; scen=job.s; meth=job.m; cfg.dyn.injectHorizon=min(h,cfg.dyn.N_pred); cfg.mpc.wRoute=job.w;
                fprintf('supplemental %s seed %d job %d/%d: %s %s H%d\n',mode,seed,ji,numel(jobs),scen.name,meth,h);
                rng(10000 + seed); res = simulate_dynamic(scen, meth, net, cfg);
                all_res{end+1} = res; %#ok<AGROW>
                [detour_events, ~] = count_detour_events(res.horizontalOffset);
                p95 = prctile(res.stepTimes,95); rows(end+1,:) = {seed, scen.name, meth, h, job.w, model_sha, res.steps, res.success, ...
                    res.failureType, res.collisions, res.collisionEvents, detour_events, res.minClearance, res.pathLength, ...
                    res.trackRMSE, res.meanStepTime, p95, res.meanPredictionTime, res.meanDwaTime, ...
                    res.meanMpcTime, res.meanPlantMetricTime, res.ADE, res.FDE, res.finalDist, res.solveFailures, res.fallbackSteps}; %#ok<AGROW>
                trial = fullfile(outdir, sprintf('seed%03d_job%03d_%s_H%d.mat', seed, ji, meth, h));
                save(trial, 'res', 'cfg', 'seed', 'h', 'model_sha');
                t=res.time(2:end); t=t(:); assert(numel(t)==numel(res.horizontalOffset) && numel(t)==numel(res.stepClearance));
                TT=table(t,res.horizontalOffset(:),res.verticalOffset(:),res.stepClearance(:),res.nearestObstacle(:), ...
                    res.stepTimes(:),res.predictionTimes(:),res.dwaTimes(:),res.mpcTimes(:),res.plantMetricTimes(:), ...
                    'VariableNames',{'Time','HorizontalOffset','VerticalOffset','Clearance','NearestObstacle', ...
                    'StepTime','PredictionTime','DwaTime','MpcTime','PlantMetricTime'});
                writetable(TT,[trial(1:end-4) '_trajectory.csv']);
                Tnow=cell2table(rows, 'VariableNames', {'Seed','Scenario','Method','Horizon','RouteWeight','ModelSHA256','Steps','Success','FailureType','Collisions','CollisionEvents','DetourEvents','MinClearance','PathLength','TrackRMSE','MeanStepTime','P95StepTime','MeanPredictionTime','MeanDwaTime','MeanMpcTime','MeanPlantMetricTime','ADE','FDE','FinalDist','SolveFailures','FallbackSteps'});
                writetable(Tnow, fullfile(outdir, 'metrics.csv'));
    end
end
T = cell2table(rows, 'VariableNames', {'Seed','Scenario','Method','Horizon','RouteWeight','ModelSHA256','Steps','Success','FailureType','Collisions','CollisionEvents','DetourEvents','MinClearance','PathLength','TrackRMSE','MeanStepTime','P95StepTime','MeanPredictionTime','MeanDwaTime','MeanMpcTime','MeanPlantMetricTime','ADE','FDE','FinalDist','SolveFailures','FallbackSteps'});
writetable(T, fullfile(outdir, 'metrics.csv')); save(fullfile(outdir, 'supplemental.mat'), 'T', 'all_res', 'cfg', 'seeds', 'jobs');
fprintf('Supplemental %s complete: %s\n', mode, outdir);
end

function h = file_sha256(path)
md = java.security.MessageDigest.getInstance('SHA-256'); fid=fopen(path,'r'); bytes=fread(fid,Inf,'*uint8'); fclose(fid);
md.update(bytes); digest = typecast(md.digest(),'uint8'); h=lower(reshape(dec2hex(digest)',1,[]));
end
