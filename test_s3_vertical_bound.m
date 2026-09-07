function test_s3_vertical_bound()
% test_s3_vertical_bound - Regression check against vertical escape maneuvers.
S = load(fullfile(fileparts(mfilename('fullpath')), 'results', 's3_optimized', ...
    'seed001_lstm.mat'), 'res');
max_vertical_offset = max(abs(S.res.verticalOffset(:)));
fprintf('S3 LSTM seed=1 maxAbsVerticalOffset=%.3f m\n', max_vertical_offset);
assert(max_vertical_offset <= 1.5, ...
    'S3 vertical-bound regression failed: max abs vertical offset is %.3f m.', ...
    max_vertical_offset);
fprintf('S3_VERTICAL_BOUND_PASS maxAbsVerticalOffset=%.3f\n', max_vertical_offset);
end
