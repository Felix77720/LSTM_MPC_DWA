function visualize_prediction(scenario, net, cfg, step, outdir)
% visualize_prediction - Compare static, constant-velocity, Kalman, and LSTM
% predictions with the true future obstacle path at one time step.
%
% Inputs:
%   scenario - scenario struct with obstacle trajectories.
%   net      - trained LSTM network.
%   cfg      - configuration struct.
%   step     - time step whose history is used for prediction.
%   outdir   - output directory for the PNG (defaults to results/).

if nargin < 5 || isempty(outdir)
    outdir = fullfile(fileparts(mfilename('fullpath')), 'results');
end
if ~exist(outdir, 'dir'), mkdir(outdir); end

N_pred = cfg.dyn.N_pred;
M = numel(scenario.obstacles);
methods = {'static', 'cv', 'kalman', 'lstm'};
colors  = {[0.80 0.20 0.20], [0.15 0.55 0.15], [0.20 0.40 0.85], [0.92 0.55 0.10]};

f = figure('Name', [scenario.name ' 预测对比'], 'Position', [120 120 900 320 * M], 'Color', 'w');
for j = 1:M
    hist = scenario.obstacles(j).traj(1:step, :);
    true_fut = scenario.obstacles(j).traj(step + 1 : step + N_pred, 1:3);

    subplot(M, 1, j); hold on; grid on;
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.6 0.6 0.6]);
    xlabel('X (m)'); ylabel('Y (m)');
    title(sprintf('%s | 障碍 %d | step=%d', scenario.name, j, step), 'Interpreter', 'none');

    plot(true_fut(:, 1), true_fut(:, 2), 'k-', 'LineWidth', 2.5);
    for mi = 1:numel(methods)
        pr = predict_obstacle_traj(hist, methods{mi}, cfg, net);
        plot(pr(:, 1), pr(:, 2), '-', 'Color', colors{mi}, 'LineWidth', 1.4);
    end
    lh = legend({'真实', '静态', '匀速外推', 'Kalman', 'LSTM'}, 'Location', 'best');
    set(lh, 'TextColor', 'k', 'Color', 'w', 'EdgeColor', [0.45 0.45 0.45]);
end
set(findall(f, 'Type', 'text'), 'Color', 'k');
saveas(f, fullfile(outdir, [scenario.name '_pred.png']));
close(f);
end
