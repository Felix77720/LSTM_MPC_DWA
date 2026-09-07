function cfg = config_LSTM()
% config_LSTM - Return MPC-DWA and LSTM settings for dynamic obstacle avoidance.
% Extends the baseline config_UAV.m, which must be on the MATLAB path.
%
% Output:
%   cfg - configuration struct initialized from baseline config_UAV.

cfg = config_UAV();

% ---- Dynamic obstacle and LSTM prediction parameters ----
cfg.dyn = struct();
cfg.dyn.dt          = cfg.dt;        % simulation/prediction step [s]
cfg.dyn.numFeatures = 8;             % [x,y,z,vx,vy,vz,cos(psi),sin(psi)]
cfg.dyn.T_hist      = 10;            % input history length in steps (1.0 s at dt=0.1)
cfg.dyn.N_pred      = cfg.mpc.N;     % output length in steps (default matches MPC horizon, 3.0 s)
cfg.dyn.injectHorizon = cfg.mpc.N;   % look-ahead steps injected into MPC/DWA (ablation setting)

% LSTM network and training
cfg.dyn.hidden      = 96;
cfg.dyn.dropout     = 0.2;
cfg.dyn.epochs      = 180;
cfg.dyn.miniBatch   = 128;
cfg.dyn.learnRate   = 0.001;
cfg.dyn.l2          = 1e-4;
cfg.dyn.gradientThreshold = 1.0;
cfg.dyn.validationPatience = 12;
cfg.dyn.validationFrequency = 50;
cfg.dyn.trainTrajectories = 800;     % independent trajectories, split by trajectory
cfg.dyn.windowsPerTrajectory = 16;
cfg.dyn.trainFraction = 0.80;
cfg.dyn.noiseAugmentStd = 0.03;      % position noise used in training histories [m]
cfg.dyn.noiseAugmentCopies = 1;      % clean + one noisy view per training window
cfg.dyn.delayAugmentSteps = 1;       % add one-step delayed history windows
cfg.dyn.validationNoiseStd = 0.03;   % held-out validation stress view [m]
cfg.dyn.validationNoiseAugmentCopies = 1;
cfg.dyn.trainingSeed = 20260905;
cfg.dyn.randomEvalScenarios = 12;
cfg.dyn.randomEvalSeeds = 1:3;

% Observation noise (0 by default for clean ADE/FDE comparisons)
cfg.dyn.obsNoise    = 0.0;
cfg.dyn.obsDelaySteps = 0; % delayed observation steps used by prediction only
cfg.dyn.obsSmoothingSteps = 3; % causal position smoothing window for noisy observations
cfg.dyn.delayCompensation = true; % align delayed forecasts to the current control time

% Normalization statistics (backfilled during training)
cfg.dyn.muX = [];  cfg.dyn.sigX = [];
cfg.dyn.muY = [];  cfg.dyn.sigY = [];

% Extra trajectory length margin for dynamic obstacles
cfg.dyn.T_obs = cfg.maxSteps + cfg.dyn.N_pred + cfg.dyn.T_hist + 10;
cfg.mpc.wRoute = 0; % shared 3-D return-to-line soft cost; 0 preserves legacy behavior
cfg.mpc.wSafety = 12000; % penalty for predicted clearance below the safety margin
cfg.mpc.safetyMargin = 0.35; % soft clearance margin beyond geometric contact [m]
cfg.coupling.dReject = 0.25; % reject DWA candidates below the robust clearance margin [m]

% Flight corridor constraints for closed-loop evaluation.  These prevent a
% collision-free but physically implausible vertical escape from being
% counted as a successful horizontal detour.
cfg.flight.zMin = 0.5;
cfg.flight.zMax = 9.5;
cfg.flight.zRouteBand = 3.0;
cfg.coupling.wVertical = 0.25; % prefer horizontal detours when safety is comparable
end
