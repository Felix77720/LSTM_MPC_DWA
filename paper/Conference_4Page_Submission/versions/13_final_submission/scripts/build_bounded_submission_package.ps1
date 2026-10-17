[CmdletBinding()]
param([switch]$ReplaceExisting)

$ErrorActionPreference = 'Stop'
$revisionRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $revisionRoot '..\..\..\..'))
$supplementRoot = Join-Path $revisionRoot '03_supplementary'
$zipPath = Join-Path $supplementRoot 'reproducibility_package_v13.zip'
$zipHashPath = "$zipPath.sha256"
$script:copiedPackagePaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

function Assert-Within {
    param([string]$Path, [string]$Root, [string]$Purpose)
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
    if (-not $fullPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing $Purpose outside the intended directory: $fullPath"
    }
}

function Add-File {
    param([string]$RelativeSource, [string]$PackagePath)
    $packageKey = $PackagePath.Replace('\', '/')
    if (-not $script:copiedPackagePaths.Add($packageKey)) { return }
    $source = [System.IO.Path]::GetFullPath((Join-Path $revisionRoot $RelativeSource))
    Assert-Within -Path $source -Root $revisionRoot -Purpose 'source read'
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Required package input missing: $RelativeSource" }
    $destination = [System.IO.Path]::GetFullPath((Join-Path $stageRoot (Join-Path 'LSTM_MPC_DWA' $PackagePath)))
    Assert-Within -Path $destination -Root $stageRoot -Purpose 'package copy'
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination
}

function Add-TreeByExtension {
    param([string]$RelativeSource, [string]$PackagePath, [string[]]$Extensions)
    $sourceRoot = [System.IO.Path]::GetFullPath((Join-Path $revisionRoot $RelativeSource))
    Assert-Within -Path $sourceRoot -Root $revisionRoot -Purpose 'source tree read'
    if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) { throw "Required package directory missing: $RelativeSource" }
    $prefix = $sourceRoot.TrimEnd('\') + '\'
    foreach ($item in Get-ChildItem -LiteralPath $sourceRoot -File -Recurse -Force) {
        if ($Extensions -notcontains $item.Extension.ToLowerInvariant()) { continue }
        $fullItem = [System.IO.Path]::GetFullPath($item.FullName)
        Assert-Within -Path $fullItem -Root $sourceRoot -Purpose 'source tree copy'
        $local = $fullItem.Substring($prefix.Length)
        $targetRelative = Join-Path $PackagePath $local
        Add-File -RelativeSource (Join-Path $RelativeSource $local) -PackagePath $targetRelative
    }
}

if ((Test-Path -LiteralPath $zipPath) -and -not $ReplaceExisting) {
    throw "Archive already exists; rerun with -ReplaceExisting to preserve it under a timestamped backup: $zipPath"
}

$stageRoot = Join-Path $revisionRoot (Join-Path 'tmp' ('bounded_package_' + [guid]::NewGuid().ToString('N')))
$null = New-Item -ItemType Directory -Path $stageRoot
$pendingZip = Join-Path $supplementRoot ('reproducibility_package_v13.pending_' + [guid]::NewGuid().ToString('N') + '.zip')
$previousZipPath = $null
$previousZipHashPath = $null

try {
    # Main source and figures used by the four-page paper.
    foreach ($file in @(
        'README.md',
        '02_source/main.tex', '02_source/main.pdf', '02_source/references.bib',
        '02_source/IEEEtran.cls', '02_source/IEEEtran.bst',
        '02_source/figures/scenario_schematic.pdf', '02_source/figures/route_comparison.pdf',
        '02_source/figures/algorithm_main_pseudocode.pdf',
        '02_source/figures/algorithm_main_pseudocode.svg',
        '02_source/figures/algorithm_main_pseudocode.png',
        '02_source/figures/algorithm_main_pseudocode.tiff',
        '02_source/figures/seven_method_outcomes_main.pdf',
        '02_source/figures/seven_method_outcomes_main.svg',
        '02_source/figures/seven_method_outcomes_main.png',
        '02_source/figures/seven_method_outcomes_main.tiff',
        '02_source/figures/route_comparison_seven_method_scene72_seed2_singlecol.pdf',
        '02_source/figures/route_comparison_seven_method_scene72_seed2_singlecol.svg',
        '02_source/figures/route_comparison_seven_method_scene72_seed2_singlecol.png',
        '02_source/figures/route_comparison_seven_method_scene72_seed2_singlecol.tiff',
        'scripts/generate_main_manuscript_figures.py',
        'qa/main_result_figure_contract.md',
        'qa/route_example_scene72_seed2/selection_audit.json',
        'qa/route_example_scene72_seed2/start_goal.csv',
        'qa/route_example_scene72_seed2/route_status.csv',
        'qa/route_example_scene72_seed2/trajectory_standalone_dwa_cv.csv',
        'qa/route_example_scene72_seed2/trajectory_standalone_mpc_cv.csv',
        'qa/route_example_scene72_seed2/trajectory_cv.csv',
        'qa/route_example_scene72_seed2/trajectory_lstm_mpc_cv_dwa.csv',
        'qa/route_example_scene72_seed2/trajectory_cv_mpc_lstm_dwa.csv',
        'qa/route_example_scene72_seed2/trajectory_lstm.csv',
        'qa/route_example_scene72_seed2/trajectory_static.csv',
        'qa/seven_method_route_endpoint_audit_scene72_seed2.json',
        'qa/seven_method_figure_collision_audit_scene72_seed2.json',
        'qa/route_comparison_seven_method_scene72_seed2_singlecol.json',
        'qa/route_comparison_seven_method_scene72_seed2_singlecol.alignment.json',
        'qa/route_comparison_seven_method_scene72_seed2_singlecol.collision-audit.json',
        'qa/route_comparison_seven_method_scene72_seed2_si.collision-audit.json',
        'qa/algorithm_main_pseudocode.alignment.json',
        '04_review/v13_final_submission_audit_20261017.md',
        '02_source/figures/route_comparison_five_method_scene404_seed2.pdf',
        '02_source/figures/route_comparison_five_method_scene404_seed2.svg',
        '02_source/figures/route_comparison_five_method_scene404_seed2.png',
        '02_source/figures/route_comparison_five_method_scene404_seed2.tiff',
        '02_source/figures/route_comparison_seven_method_scene72_seed2.pdf',
        '02_source/figures/route_comparison_seven_method_scene72_seed2.svg',
        '02_source/figures/route_comparison_seven_method_scene72_seed2.png',
        '02_source/figures/route_comparison_seven_method_scene72_seed2.tiff',
        '02_source/figures/route_comparison_seven_method_scene72_seed2.svg',
        '02_source/figures/route_comparison_seven_method_scene72_seed2.png',
        '02_source/figures/route_comparison_seven_method_scene72_seed2.tiff',
        '02_source/figures/shared_forecast_pseudocode_algorithm_s1.pdf',
        '02_source/figures/shared_forecast_pseudocode_algorithm_s1.svg',
        '02_source/figures/shared_forecast_pseudocode_algorithm_s1.png',
        '02_source/figures/shared_forecast_pseudocode_algorithm_s1.tiff',
        'scripts/generate_seven_method_route_figure.py',
        'scripts/generate_shared_forecast_pseudocode.py',
        'qa/five_method_route_data/scene.csv', 'qa/five_method_route_data/routes.csv',
        'qa/five_method_route_data/route_status.csv', 'qa/five_method_route_data/obstacle_tracks.csv',
        'qa/candidate_scene288_seed2/scene.csv', 'qa/candidate_scene288_seed2/routes.csv',
        'qa/candidate_scene288_seed2/route_status.csv', 'qa/candidate_scene288_seed2/obstacle_tracks.csv',
        'qa/candidate_scene288_seed3/scene.csv', 'qa/candidate_scene288_seed3/routes.csv',
        'qa/candidate_scene288_seed3/route_status.csv', 'qa/candidate_scene288_seed3/obstacle_tracks.csv',
        'qa/figure_collisions_main_routes.json', 'qa/figure_collisions_supp_routes.json',
        '03_bilingual/paper.md', '03_bilingual/source_map.json',
        '03_bilingual/translation_notes.md', '03_bilingual/supplementary_table_guide.md',
        '03_bilingual/assets/Fig1_scenario.png', '03_bilingual/assets/route_comparison.svg',
        '03_supplementary/supplementary_methods.tex', '03_supplementary/supplementary_methods.pdf',
        '04_review/v13_final_submission_audit_20261014.md',
        '04_review/v13_final_submission_audit_20261016_final.md',
        '04_review/v13_route_illustration_amendment_20261016.md',
        'scripts/generate_four_method_figures.py', 'scripts/compile_final.ps1',
        '04_review/reference_verification_20261014.md',
        '04_review/v12a_stage1_recovery_audit_20261014.md',
        '04_review/original_mpc_dwa_baseline_protocol.md',
        'scripts/build_bounded_submission_package.ps1',
        'scripts/sync_bilingual_source_map.py', 'scripts/test_sync_bilingual_source_map.py',
        'scripts/run_v12a_pooled_weight_development.m',
        'scripts/recover_v12a_pooled_weight_development.m',
        'scripts/recover_existing_pooled_episode.m',
        'scripts/simulate_dynamic_v12a_timed.m',
        'scripts/simulate_standalone_controller_v12a_timed.m',
        'scripts/merge_five_method_fair_results.py',
        'scripts/analyze_standalone_controller_fair_rerun.m',
        'scripts/run_standalone_controller_fair_rerun.m',
        'scripts/export_five_method_historical_route_data.m',
        'scripts/generate_route_comparison.m',
        'scripts/generate_scenario_schematic.py'
    )) { Add-File -RelativeSource $file -PackagePath $file }

    # Supplementary data, protocols, historical assets, and the recovered Stage-1 artifacts.
    Add-TreeByExtension -RelativeSource '03_supplementary' -PackagePath '03_supplementary' -Extensions @('.csv', '.md', '.mat', '.sha256')
    Add-TreeByExtension -RelativeSource '03_supplementary/figures' -PackagePath '03_supplementary/figures' -Extensions @('.pdf', '.svg', '.png', '.tif', '.tiff')
    Add-TreeByExtension -RelativeSource '03_supplementary/historical_36run_records' -PackagePath '03_supplementary/historical_36run_records' -Extensions @('.csv', '.md', '.mat')
    Add-TreeByExtension -RelativeSource '03_supplementary/historical_48scene' -PackagePath '03_supplementary/historical_48scene' -Extensions @('.csv', '.md', '.mat')
    Add-TreeByExtension -RelativeSource '03_supplementary/stage1_development' -PackagePath '03_supplementary/stage1_development' -Extensions @('.csv', '.md', '.mat', '.sha256')

    $packageRoot = Join-Path $stageRoot 'LSTM_MPC_DWA'
    $paths = @(Get-ChildItem -LiteralPath $packageRoot -File -Recurse | Sort-Object FullName | ForEach-Object {
        $_.FullName.Substring($packageRoot.Length).TrimStart('\').Replace('\', '/')
    }) + @('PACKAGE_CONTENTS.txt', 'SHA256SUMS.txt')
    [System.IO.File]::WriteAllLines((Join-Path $packageRoot 'PACKAGE_CONTENTS.txt'), [string[]]$paths, [System.Text.Encoding]::UTF8)
    $hashLines = foreach ($file in Get-ChildItem -LiteralPath $packageRoot -File -Recurse | Sort-Object FullName) {
        $relative = $file.FullName.Substring($packageRoot.Length).TrimStart('\').Replace('\', '/')
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $relative"
    }
    $hashLines = @('SHA256SUMS.txt is excluded from its own checksum list; the external ZIP sidecar hashes the complete archive.') + @($hashLines)
    [System.IO.File]::WriteAllLines((Join-Path $packageRoot 'SHA256SUMS.txt'), [string[]]$hashLines, [System.Text.Encoding]::ASCII)

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::Open($pendingZip, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        $stagePrefix = [System.IO.Path]::GetFullPath($stageRoot).TrimEnd('\') + '\'
        foreach ($file in Get-ChildItem -LiteralPath $stageRoot -File -Recurse | Sort-Object FullName) {
            $full = [System.IO.Path]::GetFullPath($file.FullName)
            Assert-Within -Path $full -Root $stageRoot -Purpose 'archive input'
            $entry = $full.Substring($stagePrefix.Length).Replace('\', '/')
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $full, $entry, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    } finally { $archive.Dispose() }

    $check = [System.IO.Compression.ZipFile]::OpenRead($pendingZip)
    try {
        foreach ($required in @(
            'LSTM_MPC_DWA/02_source/main.pdf',
            'LSTM_MPC_DWA/02_source/main.tex',
            'LSTM_MPC_DWA/02_source/figures/route_comparison.pdf',
            'LSTM_MPC_DWA/02_source/figures/algorithm_main_pseudocode.pdf',
            'LSTM_MPC_DWA/02_source/figures/algorithm_main_pseudocode.svg',
            'LSTM_MPC_DWA/02_source/figures/algorithm_main_pseudocode.png',
            'LSTM_MPC_DWA/02_source/figures/algorithm_main_pseudocode.tiff',
            'LSTM_MPC_DWA/02_source/figures/seven_method_outcomes_main.pdf',
            'LSTM_MPC_DWA/02_source/figures/seven_method_outcomes_main.svg',
            'LSTM_MPC_DWA/02_source/figures/seven_method_outcomes_main.png',
            'LSTM_MPC_DWA/02_source/figures/seven_method_outcomes_main.tiff',
            'LSTM_MPC_DWA/02_source/figures/route_comparison_seven_method_scene72_seed2_singlecol.pdf',
            'LSTM_MPC_DWA/02_source/figures/route_comparison_seven_method_scene72_seed2.pdf',
            'LSTM_MPC_DWA/02_source/figures/route_comparison_five_method_scene404_seed2.pdf',
            'LSTM_MPC_DWA/03_supplementary/supplementary_methods.pdf',
            'LSTM_MPC_DWA/03_supplementary/stage1_development/pooled_development_raw.csv',
            'LSTM_MPC_DWA/03_supplementary/stage1_development/pooled_episode_sha256.csv',
            'LSTM_MPC_DWA/03_bilingual/paper.md',
            'LSTM_MPC_DWA/qa/route_comparison_seven_method_scene72_seed2_singlecol.json',
            'LSTM_MPC_DWA/qa/route_comparison_seven_method_scene72_seed2_singlecol.alignment.json',
            'LSTM_MPC_DWA/qa/route_comparison_seven_method_scene72_seed2_singlecol.collision-audit.json',
            'LSTM_MPC_DWA/qa/route_comparison_seven_method_scene72_seed2_si.collision-audit.json',
            'LSTM_MPC_DWA/qa/algorithm_main_pseudocode.alignment.json',
            'LSTM_MPC_DWA/04_review/v13_final_submission_audit_20261017.md',
            'LSTM_MPC_DWA/04_review/v13_final_submission_audit_20261014.md',
            'LSTM_MPC_DWA/SHA256SUMS.txt', 'LSTM_MPC_DWA/PACKAGE_CONTENTS.txt'
        )) { if (-not $check.GetEntry($required)) { throw "Required archive entry missing: $required" } }
        foreach ($entry in $check.Entries) {
            $stream = $entry.Open()
            try { $buffer = New-Object byte[] 65536; while ($stream.Read($buffer, 0, $buffer.Length) -gt 0) {} }
            finally { $stream.Dispose() }
        }
        $entryCount = $check.Entries.Count
    } finally { $check.Dispose() }

    if ((Test-Path -LiteralPath $zipPath) -or (Test-Path -LiteralPath $zipHashPath)) {
        if (-not $ReplaceExisting) { throw "Existing release artifact appeared during package build: $zipPath" }
        $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $previousZipPath = "$zipPath.previous_$stamp"
        $previousZipHashPath = "$zipHashPath.previous_$stamp"
        if (Test-Path -LiteralPath $zipPath) { Move-Item -LiteralPath $zipPath -Destination $previousZipPath }
        if (Test-Path -LiteralPath $zipHashPath) { Move-Item -LiteralPath $zipHashPath -Destination $previousZipHashPath }
    }
    Move-Item -LiteralPath $pendingZip -Destination $zipPath
    $zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    [System.IO.File]::WriteAllText($zipHashPath, "$zipHash  reproducibility_package_v13.zip`n", [System.Text.Encoding]::ASCII)
    $verifiedZipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $verifiedSidecar = (Get-Content -LiteralPath $zipHashPath -Raw).Trim()
    if ($verifiedZipHash -ne $zipHash -or
        -not $verifiedSidecar.StartsWith($zipHash, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'The replacement compact archive or SHA-256 sidecar failed post-move verification.'
    }
    foreach ($generatedBackup in @($previousZipPath, $previousZipHashPath)) {
        if ($generatedBackup -and (Test-Path -LiteralPath $generatedBackup -PathType Leaf)) {
            Assert-Within -Path $generatedBackup -Root $supplementRoot -Purpose 'verified generated-backup cleanup'
            Remove-Item -LiteralPath $generatedBackup -Force
        }
    }
    Write-Output "Created: $zipPath"
    Write-Output "SHA-256: $zipHash"
    Write-Output "ZIP entries: $entryCount"
    Write-Output "Size (MB): $([Math]::Round((Get-Item -LiteralPath $zipPath).Length / 1MB, 2))"
}
finally {
    if (Test-Path -LiteralPath $stageRoot -PathType Container) {
        Assert-Within -Path $stageRoot -Root (Join-Path $revisionRoot 'tmp') -Purpose 'temporary staging cleanup'
        Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
    if (Test-Path -LiteralPath $pendingZip -PathType Leaf) { Remove-Item -LiteralPath $pendingZip -Force }
}
