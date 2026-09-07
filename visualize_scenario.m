function visualize_scenario(scenario, methods, trajs, cfg, outdir)
% visualize_scenario - Plot ego trajectories from several methods together
% with the true obstacle trajectories of one scenario.
%
% Inputs:
%   scenario - scenario struct with name, start, goal, and
%              obstacles(j).traj (T x 7).
%   methods  - 1 x K cell of method keys ('static'/'cv'/'kalman'/'lstm').
%   trajs    - 1 x K cell of ego trajectories (K x 6).
%   cfg      - configuration struct.
%   outdir   - output directory for the PNG (defaults to results/).

if nargin < 5 || isempty(outdir)
    outdir = fullfile(fileparts(mfilename('fullpath')), 'results');
end
if ~exist(outdir, 'dir'), mkdir(outdir); end

colors = containers.Map({'static', 'cv', 'kalman', 'lstm'}, ...
    {[0.80 0.20 0.20], [0.15 0.55 0.15], [0.20 0.40 0.85], [0.92 0.55 0.10]});
labels = containers.Map({'static', 'cv', 'kalman', 'lstm'}, ...
    {'MPC-DWA 静态', 'MPC-DWA 匀速外推', 'MPC-DWA 卡尔曼', '本文 LSTM'});

f = figure('Name', scenario.name, 'Position', [80 80 900 680], 'Color', 'w');
hold on; grid on; axis equal; view(45, 25);
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k', ...
    'GridColor', [0.6 0.6 0.6]);
xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
xlim(cfg.arenaSize(1, :)); ylim(cfg.arenaSize(2, :)); zlim(cfg.arenaSize(3, :));
title(scenario.name, 'Interpreter', 'none', 'Color', 'k');

% True obstacle trajectories (black dashed)
for j = 1:numel(scenario.obstacles)
    tr = scenario.obstacles(j).traj(:, 1:3);
    h_obs(j) = plot3(tr(:, 1), tr(:, 2), tr(:, 3), 'k--', 'LineWidth', 1.6); %#ok<AGROW>
    plot3(tr(1, 1), tr(1, 2), tr(1, 3), 'k^', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
    plot3(tr(end, 1), tr(end, 2), tr(end, 3), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
end

% Ego trajectories
h_m = gobjects(1, numel(methods));
for i = 1:numel(methods)
    tr = trajs{i}(:, 1:3);
    key = lower(methods{i});
    if isKey(colors, key), c = colors(key); else, c = [0.45 0.15 0.70]; end
    h_m(i) = plot3(tr(:, 1), tr(:, 2), tr(:, 3), '-', 'Color', c, 'LineWidth', 2);
end

plot3(scenario.start(1), scenario.start(2), scenario.start(3), ...
    'go', 'MarkerFaceColor', 'g', 'MarkerSize', 9);
plot3(scenario.goal(1), scenario.goal(2), scenario.goal(3), ...
    'r*', 'MarkerSize', 13);

% Nominal straight start-goal route, shown so route adjustments are visible.
h_nom = plot3([scenario.start(1) scenario.goal(1)], ...
              [scenario.start(2) scenario.goal(2)], ...
              [scenario.start(3) scenario.goal(3)], ':', ...
              'Color', [0.55 0.55 0.55], 'LineWidth', 1.2);

lgd = [h_obs(1), h_nom, h_m];
lgd_txt = [{'障碍真实轨迹'}, {'标称直线航线'}, ...
           cellfun(@method_text, methods, 'UniformOutput', false)];
lh = legend(lgd, lgd_txt, 'Location', 'best');
set(lh, 'TextColor', 'k', 'Color', 'w', 'EdgeColor', [0.45 0.45 0.45]);
set(findall(f, 'Type', 'text'), 'Color', 'k');

saveas(f, fullfile(outdir, [scenario.name '.png']));
close(f);
end

function s = method_text(m)
key = lower(m);
if isKey(containers.Map({'static','cv','kalman','lstm'}, {1,2,3,4}), key)
    names = containers.Map({'static','cv','kalman','lstm'}, {'MPC-DWA 静态','MPC-DWA 匀速外推','MPC-DWA 卡尔曼','本文 LSTM'});
    s = names(key);
else
    s = m;
end
end
