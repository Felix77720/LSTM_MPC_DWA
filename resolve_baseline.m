function baseline = resolve_baseline(here)
% resolve_baseline - Locate the bundled MPC-DWA baseline.
% Prefer the self-contained repository layout, while retaining compatibility
% with the original workspace layout where the baseline was a sibling folder.

localBaseline = fullfile(here, 'MPC_DWA_Fusion');
parentBaseline = fullfile(fileparts(here), 'MPC_DWA_Fusion');

if exist(localBaseline, 'dir')
    baseline = localBaseline;
elseif exist(parentBaseline, 'dir')
    baseline = parentBaseline;
else
    error(['MPC_DWA_Fusion was not found. Expected it inside the LSTM_MPC_DWA ', ...
        'folder or alongside it.']);
end
end
