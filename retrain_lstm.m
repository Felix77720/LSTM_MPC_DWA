% retrain_lstm - Generate training data from the current maneuver set and
% train a fresh LSTM predictor, then save it to results/lstm_predictor.mat.

clear; close all; clc;

here = fileparts(mfilename('fullpath'));
addpath(here);
baseline = resolve_baseline(here);
casadi = fullfile(baseline, 'third_party', 'casadi-3.8.0-windows64-matlab2018b');
addpath(here, baseline, casadi);

cfg = config_LSTM();
rng(cfg.dyn.trainingSeed);

[X, Y, muX, sigX, muY, sigY, groupId, splitInfo] = generate_training_data(cfg);
cfg.dyn.muX = muX; cfg.dyn.sigX = sigX;
cfg.dyn.muY = muY; cfg.dyn.sigY = sigY;

fprintf('Training LSTM predictor...\n');
[net, trainingInfo, trainingProtocol] = train_lstm_predictor(X, Y, cfg, groupId, splitInfo);

outfile = fullfile(here, 'results', 'lstm_predictor.mat');
save(outfile, 'net', 'muX', 'sigX', 'muY', 'sigY', 'trainingInfo', ...
    'trainingProtocol', 'splitInfo', '-v7.3');
fprintf('Saved retrained predictor to %s\n', outfile);
