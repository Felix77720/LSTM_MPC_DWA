function generate_route_comparison()
% Compatibility wrapper for the current split-scene and 3D route figures.
% The figures are drawn by the manuscript's selected Python/matplotlib backend.
scriptDir = fileparts(mfilename('fullpath'));
revisionRoot = fileparts(scriptDir);
pythonExe = fullfile(revisionRoot, '.nature-figure-venv', 'Scripts', 'python.exe');
pythonScript = fullfile(scriptDir, 'generate_scenario_paths.py');
if ~isfile(pythonExe)
    error('Figure environment not found. Run the Python generator from the revision folder.');
end
if ~isfile(pythonScript)
    error('Split-figure generator not found: %s', pythonScript);
end
[status, output] = system(sprintf('"%s" "%s"', pythonExe, pythonScript));
fprintf('%s', output);
if status ~= 0
    error('Split figure generation failed with exit code %d.', status);
end
end
