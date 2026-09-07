function [net, info, protocol] = train_lstm_predictor(X, Y, cfg, groupId, splitInfo)
% train_lstm_predictor - Normalize data and train the LSTM trajectory predictor.
%
% Inputs:
%   X   - 1 x N cell array of raw input feature windows.
%   Y   - (3*N_pred) x N raw displacement targets.
%   cfg - config struct; cfg.dyn.muX/sigX/muY/sigY must already be filled.
%   groupId, splitInfo - optional trajectory-level split metadata returned by
%                        generate_training_data.
% Output:
%   net - trained LSTM network.

N_pred = cfg.dyn.N_pred;
muX = cfg.dyn.muX; sigX = cfg.dyn.sigX;
muY = cfg.dyn.muY; sigY = cfg.dyn.sigY;
if nargin < 4 || isempty(groupId)
    groupId = 1:numel(X);
end

if nargin < 5 || isempty(splitInfo)
    if nargin >= 4 && ~isempty(groupId)
        groups = unique(groupId, 'stable');
        nTrain = max(1, min(numel(groups) - 1, floor(0.8 * numel(groups))));
        splitInfo = struct('trainMask', ismember(groupId, groups(1:nTrain)), ...
            'validationMask', ismember(groupId, groups(nTrain + 1:end)));
    else
        n = numel(X); nTrain = max(1, min(n - 1, floor(0.8 * n)));
        splitInfo = struct('trainMask', [true(1, nTrain), false(1, n - nTrain)], ...
            'validationMask', [false(1, nTrain), true(1, n - nTrain)]);
    end
end

trainMask = logical(splitInfo.trainMask(:)');
valMask = logical(splitInfo.validationMask(:)');
assert(numel(trainMask) == numel(X) && numel(valMask) == numel(X), ...
    'Training/validation split must cover every sequence.');
assert(any(trainMask) && any(valMask), 'Training and validation sets must be non-empty.');

XTrainRaw = X(trainMask);
YTrainRaw = Y(:, trainMask);
XValRaw = X(valMask);
YValRaw = Y(:, valMask);

% Add noisy histories only as input views.  Targets remain clean future
% trajectories, so the network learns to denoise without target leakage.
[XTrainRaw, YTrainRaw] = augment_noisy_histories(XTrainRaw, YTrainRaw, cfg, 'train');
% The validation split is trajectory-disjoint.  Adding one stress view makes
% early stopping sensitive to the same perturbation family used at test time,
% while keeping clean validation windows in the selection criterion.
[XValRaw, YValRaw] = augment_noisy_histories(XValRaw, YValRaw, cfg, 'validation');

Xn = cellfun(@(c) (c - muX) ./ sigX, XTrainRaw, 'UniformOutput', false);
Xn = Xn(:);                          % sequences must be an observations x 1 cell
Xvn = cellfun(@(c) (c - muX) ./ sigX, XValRaw, 'UniformOutput', false);
Xvn = Xvn(:);

Yn = normalize_targets(YTrainRaw, muY, sigY, N_pred);
Yvn = normalize_targets(YValRaw, muY, sigY, N_pred);
fprintf('LSTM protocol shapes: train sequences=%d, train responses=%d; validation sequences=%d, validation responses=%d\n', ...
    numel(Xn), size(Yn, 1), numel(Xvn), size(Yvn, 1));
assert(numel(Xn) == size(Yn, 1), 'Training predictor/response count mismatch.');
assert(numel(Xvn) == size(Yvn, 1), 'Validation predictor/response count mismatch.');

layers = build_lstm_network(cfg);
if isfield(cfg.dyn, 'trainingSeed')
    rng(cfg.dyn.trainingSeed);
end
valFrequency = getfield_or_local(cfg.dyn, 'validationFrequency', 50);
options = trainingOptions('adam', ...
    'MaxEpochs',        cfg.dyn.epochs, ...
    'MiniBatchSize',    cfg.dyn.miniBatch, ...
    'InitialLearnRate', cfg.dyn.learnRate, ...
    'L2Regularization', getfield_or_local(cfg.dyn, 'l2', 1e-4), ...
    'GradientThreshold', getfield_or_local(cfg.dyn, 'gradientThreshold', 1), ...
    'Shuffle',          'every-epoch', ...
    'ValidationData',   {Xvn, Yvn}, ...
    'ValidationFrequency', valFrequency, ...
    'ValidationPatience', getfield_or_local(cfg.dyn, 'validationPatience', 12), ...
    'OutputNetwork',    'best-validation-loss', ...
    'Plots',            'none', ...
    'Verbose',          0, ...
    'VerboseFrequency', 10);

[net, info] = trainNetwork(Xn, Yn, layers, options);
protocol = struct('trainWindows', numel(XTrainRaw), ...
    'validationWindows', numel(XValRaw), ...
    'trainTrajectories', numel(unique(groupId(trainMask))), ...
    'validationTrajectories', numel(unique(groupId(valMask))), ...
    'noiseAugmentStd_m', getfield_or_local(cfg.dyn, 'noiseAugmentStd', 0), ...
    'noiseAugmentCopies', getfield_or_local(cfg.dyn, 'noiseAugmentCopies', 0), ...
    'delayAugmentSteps', getfield_or_local(cfg.dyn, 'delayAugmentSteps', 0), ...
    'validationNoiseStd_m', getfield_or_local(cfg.dyn, 'validationNoiseStd', 0), ...
    'bestValidationModel', 'best-validation-loss', ...
    'trainingSeed', getfield_or_local(cfg.dyn, 'trainingSeed', NaN));
end

function Yn = normalize_targets(Y, muY, sigY, N_pred)
Yr = reshape(Y, 3, N_pred, []);
Yr = (Yr - muY) ./ sigY;
Yn = reshape(Yr, 3 * N_pred, [])';
end

function [Xout, Yout] = augment_noisy_histories(Xin, Yin, cfg, mode)
if nargin < 4, mode = 'train'; end
if strcmpi(mode, 'validation')
    copies = getfield_or_local(cfg.dyn, 'validationNoiseAugmentCopies', 0);
    noiseStd = getfield_or_local(cfg.dyn, 'validationNoiseStd', 0);
else
    copies = getfield_or_local(cfg.dyn, 'noiseAugmentCopies', 0);
    noiseStd = getfield_or_local(cfg.dyn, 'noiseAugmentStd', 0);
end
Xout = Xin(:);
Yout = Yin;
fprintf('Augment %s input: X=%d Y=%dx%d copies=%d noise=%.3f\n', ...
    mode, numel(Xout), size(Yout, 1), size(Yout, 2), copies, noiseStd);
if copies <= 0 || noiseStd <= 0
    return;
end
Yout = [Yout, zeros(size(Yin, 1), numel(Xin) * copies)];
dt = cfg.dyn.dt;
for copy = 1:copies
    for i = 1:numel(Xin)
        seq = Xin{i};
        noisy = seq;
        noisy(1:3, :) = seq(1:3, :) + noiseStd * randn(3, size(seq, 2));
        if size(seq, 2) >= 2
            v = [seq(4:6, 1), diff(noisy(1:3, :), 1, 2) / dt];
            noisy(4:6, :) = v;
        end
        % The predictor returns an offset from the last observed position.
        % When the history is noisy, express the clean future relative to
        % the noisy last position; otherwise the network is trained with a
        % systematic absolute-position offset at inference time.
        Xout{end + 1} = noisy; %#ok<AGROW>
        yNoisy = reshape(Yin(:, i), 3, []);
        yNoisy = yNoisy + seq(1:3, end) - noisy(1:3, end);
        Yout(:, numel(Xin) + (copy - 1) * numel(Xin) + i) = yNoisy(:);
    end
end
fprintf('Augment %s output: X=%d Y=%dx%d\n', mode, numel(Xout), size(Yout, 1), size(Yout, 2));
end

function v = getfield_or_local(s, name, default)
if isfield(s, name), v = s.(name); else, v = default; end
end
