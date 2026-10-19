$ErrorActionPreference = 'Stop'

# v13 final-package builder. This script is deliberately allowlist-only:
# it never sweeps the project root for .m files and never copies _local_archive.
# Stage 2 was not completed/verified; only its protocol and audit documents are
# included. The current finite evaluation is 100 scenes x 3 seeds x 7 methods.
# The 500-scene shared-vs-DWA-only contrast is an existing paired subset of
# the historical 7,500-run benchmark, not an additional experiment.

function Assert-RequiredFile {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required v13 package input is missing: $Path"
    }
}

function Assert-RequiredDirectory {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Required v13 package directory is missing: $Path"
    }
}

function Assert-NonEmptyFile {
    param([Parameter(Mandatory)][string]$Path)
    Assert-RequiredFile -Path $Path
    if ((Get-Item -LiteralPath $Path).Length -le 0) {
        throw "Required v13 package input is empty: $Path"
    }
}

function Assert-CsvRecordCount {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][int]$ExpectedCount,
        [Parameter(Mandatory)][string]$Description
    )
    Assert-RequiredFile -Path $Path
    $records = @(Import-Csv -LiteralPath $Path)
    if ($records.Count -ne $ExpectedCount) {
        throw "$Description is incomplete: expected $ExpectedCount records; found $($records.Count) in $Path."
    }
}

function Assert-PathWithin {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Purpose
    )
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
    if (-not $fullPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing $Purpose outside the intended root: $fullPath"
    }
}

function Copy-RequiredFile {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$DestinationRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )
    Assert-RequiredFile -Path $Source
    $destination = [System.IO.Path]::GetFullPath((Join-Path $DestinationRoot $RelativePath))
    Assert-PathWithin -Path $destination -Root $DestinationRoot -Purpose 'copy'
    $destinationDirectory = Split-Path -Parent $destination
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    Copy-Item -LiteralPath $Source -Destination $destination -Force
}

function Assert-Unlocked {
    param([Parameter(Mandatory)][string]$LockPath, [Parameter(Mandatory)][string]$StageName)
    if (Test-Path -LiteralPath $LockPath) {
        throw "$StageName still has an active-run lock; package build is refused: $LockPath"
    }
}

function Assert-EmptyErrorDirectory {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$StageName)
    Assert-RequiredDirectory -Path $Path
    $errorFiles = @(Get-ChildItem -LiteralPath $Path -File -Recurse -Force)
    if ($errorFiles.Count -ne 0) {
        throw "$StageName has $($errorFiles.Count) retained error file(s); package build is refused."
    }
}

function Get-ValidatedStage1ErrorFiles {
    param([Parameter(Mandatory)][string]$Path)
    Assert-RequiredDirectory -Path $Path
    $entries = @(Get-ChildItem -LiteralPath $Path -Force)
    if (@($entries | Where-Object { $_.PSIsContainer }).Count -ne 0) {
        throw "Stage 1 error directory contains an unexpected subdirectory: $Path"
    }
    $allowedPattern = '^candidate_\d{2}_(lstm|cv|lstm_mpc_cv_dwa|cv_mpc_lstm_dwa|static)_scene_\d{3}_scenario_\d{8}_seed_\d{2}\.txt$'
    foreach ($entry in $entries) {
        if ($entry.Extension -ne '.txt' -or $entry.Name -notmatch $allowedPattern) {
            throw "Stage 1 error-log path is outside the frozen job-key allowlist: $($entry.FullName)"
        }
    }
    # Retained retry/error history is preserved, not silently discarded. The
    # complete final artifacts above gate that the run eventually finalized.
    return @($entries | Sort-Object Name)
}

function Copy-AllowlistedVendorTree {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$DestinationRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )
    Assert-RequiredDirectory -Path $Source
    Assert-PathWithin -Path $Source -Root $ProjectRoot -Purpose 'vendor dependency copy'
    $destination = [System.IO.Path]::GetFullPath((Join-Path $DestinationRoot $RelativePath))
    Assert-PathWithin -Path $destination -Root $DestinationRoot -Purpose 'vendor dependency copy'
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    $sourcePrefix = [System.IO.Path]::GetFullPath($Source).TrimEnd('\') + '\'
    foreach ($file in Get-ChildItem -LiteralPath $Source -File -Recurse -Force) {
        $fullSource = [System.IO.Path]::GetFullPath($file.FullName)
        if (-not $fullSource.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to copy vendor file outside its fixed dependency tree: $fullSource"
        }
        $relativeFile = $fullSource.Substring($sourcePrefix.Length)
        Copy-RequiredFile -Source $fullSource -DestinationRoot $destination -RelativePath $relativeFile
    }
}

function Assert-ExactNameSet {
    param(
        [Parameter(Mandatory)][string[]]$Expected,
        [Parameter(Mandatory)][string[]]$Actual,
        [Parameter(Mandatory)][string]$Description
    )
    $expectedSorted = @($Expected | Sort-Object -Unique)
    $actualSorted = @($Actual | Sort-Object -Unique)
    if ($expectedSorted.Count -ne $Expected.Count -or
        $actualSorted.Count -ne $Actual.Count -or
        (Compare-Object -ReferenceObject $expectedSorted -DifferenceObject $actualSorted).Count -ne 0) {
        throw "$Description does not match its exact frozen path allowlist. Expected $($Expected.Count) distinct paths; found $($Actual.Count)."
    }
}

function Assert-HeldoutCheckpointPathCoverage {
    param(
        [Parameter(Mandatory)][string]$EpisodeRoot,
        [Parameter(Mandatory)][int]$ExpectedScenes,
        [Parameter(Mandatory)][string]$StageName
    )
    Assert-RequiredDirectory -Path $EpisodeRoot
    $methods = @(
        'standalone_dwa_cv', 'standalone_mpc_cv', 'cv',
        'lstm_mpc_cv_dwa', 'cv_mpc_lstm_dwa', 'lstm', 'static'
    )
    $expectedKeys = [System.Collections.Generic.List[string]]::new()
    for ($scene = 1; $scene -le $ExpectedScenes; $scene++) {
        for ($seed = 1; $seed -le 3; $seed++) {
            foreach ($method in $methods) {
                $expectedKeys.Add(('scene_{0:D3}_seed_{1:D2}_{2}' -f $scene, $seed, $method))
            }
        }
    }
    $episodeEntries = @(Get-ChildItem -LiteralPath $EpisodeRoot -Force)
    $episodeRootFiles = @($episodeEntries | Where-Object { -not $_.PSIsContainer })
    if ($episodeRootFiles.Count -ne 0) {
        throw "$StageName episode root contains files outside the key-directory allowlist: $($episodeRootFiles[0].FullName)"
    }
    $keyDirectories = @($episodeEntries | Where-Object { $_.PSIsContainer })
    Assert-ExactNameSet -Expected $expectedKeys.ToArray() `
        -Actual @($keyDirectories | ForEach-Object Name) `
        -Description "$StageName scene/seed/method key directories"
    foreach ($keyDirectory in $keyDirectories) {
        $children = @(Get-ChildItem -LiteralPath $keyDirectory.FullName -Force)
        $unexpected = @($children | Where-Object {
            if ($_.PSIsContainer) {
                $_.Name -notmatch '^(attempt_\d{4}|orphaned_attempt_[A-Za-z0-9_]+)$'
            } else {
                $true
            }
        })
        if ($unexpected.Count -ne 0) {
            throw "$StageName key contains a path outside the checkpoint/quarantine allowlist: $($unexpected[0].FullName)"
        }
        $attempts = @($children | Where-Object { $_.PSIsContainer -and $_.Name -match '^attempt_\d{4}$' } |
            Sort-Object Name)
        if ($attempts.Count -eq 0) {
            throw "$StageName key has no committed attempt directory: $($keyDirectory.FullName)"
        }
        foreach ($attempt in $attempts) {
            $attemptEntries = @(Get-ChildItem -LiteralPath $attempt.FullName -Force)
            if (@($attemptEntries | Where-Object { $_.PSIsContainer }).Count -ne 0 -or
                @($attemptEntries | Where-Object { $_.Name -notin @('checkpoint.mat','checkpoint.sha256') }).Count -ne 0 -or
                $attemptEntries.Count -ne 2 -or
                @($attemptEntries | Where-Object { $_.Name -eq 'checkpoint.mat' }).Count -ne 1 -or
                @($attemptEntries | Where-Object { $_.Name -eq 'checkpoint.sha256' }).Count -ne 1) {
                throw "$StageName attempt contains files outside the checkpoint allowlist: $($attempt.FullName)"
            }
            Assert-RequiredFile -Path (Join-Path $attempt.FullName 'checkpoint.mat')
            Assert-RequiredFile -Path (Join-Path $attempt.FullName 'checkpoint.sha256')
        }
        $temporaryAttempts = @(Get-ChildItem -LiteralPath $keyDirectory.FullName -Directory -Force |
            Where-Object { $_.Name -like 'tmp_attempt_*' })
        if ($temporaryAttempts.Count -ne 0) {
            throw "$StageName key contains an uncommitted temporary attempt: $($keyDirectory.FullName)"
        }
    }
}

$revisionRoot = Split-Path -Parent $PSScriptRoot
if ((Split-Path -Leaf $revisionRoot) -ne '13_final_submission') {
    throw "This package builder is scoped to 13_final_submission, found: $revisionRoot"
}
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $revisionRoot '..\..\..\..'))
$resultsRoot = Join-Path $projectRoot 'results'
$supplementRoot = Join-Path $revisionRoot '03_supplementary'
$revisionPackagePath = 'paper\Conference_4Page_Submission\versions\13_final_submission'
$revisionZipPath = $revisionPackagePath.Replace('\', '/')
$projectDocumentRoot = Join-Path $projectRoot 'paper'
$projectDocumentAllowlist = @('DOCUMENT_INDEX.md')
$stage1PackageRelativePath = 'results\v12a_pooled_weight_development_inclusive_dev48_20261012'
$stage1ArchivePath = $stage1PackageRelativePath.Replace('\', '/')
$heldoutPackageRelativePath = 'results\v13_seven_method_100scene_exploratory_20261015'
$heldoutArchivePath = $heldoutPackageRelativePath.Replace('\', '/')

# Frozen development and current finite-evaluation locations.
$stage1Root = Join-Path $resultsRoot 'v12a_pooled_weight_development_inclusive_dev48_20261012'
$heldoutRoot = Join-Path $resultsRoot 'v13_seven_method_100scene_exploratory_20261015'

# Check all active-run locks before checking artifacts. This makes an
# in-progress development or held-out run a hard refusal, with no staging or
# output writes. An archived stale-lock file is retained as audit history.
Assert-Unlocked -LockPath (Join-Path $stage1Root '.pooled_development_lock') -StageName 'Stage 1 pooled-weight calibration'
Assert-Unlocked -LockPath (Join-Path $heldoutRoot '.heldout_runner_lock') -StageName '100-scene seven-method evaluation'

# Stage 1: only path names/counts are examined; no episode MAT is opened here.
$stage1Files = @(
    'pooled_development_manifest.mat', 'pooled_development_manifest.sha256',
    'pooled_development_recovery_manifest.mat', 'pooled_development_recovery_manifest.sha256',
    'pooled_episode_sha256.csv', 'pooled_episode_sha256.csv.sha256',
    'pooled_calibration_artifact_sha256.csv', 'pooled_development_raw.csv',
    'pooled_candidate_method_scores.csv', 'pooled_candidate_scores.csv',
    'pooled_endpoint_reclassification.csv', 'pooled_weight_selection.mat',
    'pooled_development_bundle.mat'
)
foreach ($name in $stage1Files) { Assert-RequiredFile -Path (Join-Path $stage1Root $name) }
Assert-CsvRecordCount -Path (Join-Path $stage1Root 'pooled_episode_sha256.csv') `
    -ExpectedCount 4320 -Description 'Stage 1 per-episode SHA index'
$stage1ErrorFiles = Get-ValidatedStage1ErrorFiles -Path (Join-Path $stage1Root 'errors')

# Stage 2 was interrupted and has no verified selection. It is intentionally
# excluded from results packaging; only its protocol/audit documents in
# 04_review are copied below. No Stage-2 MAT/CSV output is required or copied.

# Current finite evaluation: path-only checkpoint coverage and exact output
# allowlists. Per-episode MAT files are validated by path only and are never
# copied into this package.
$heldoutFiles = @(
    'heldout_scenario_bank.mat', 'heldout_scenario_bank.sha256',
    'heldout_execution_manifest.mat', 'heldout_execution_manifest.sha256',
    'scenario_manifest.csv', 'heldout_raw.csv', 'heldout_trajectories.mat',
    'heldout_run_manifest.mat', 'heldout_run_manifest.sha256',
    'heldout_package_manifest.json', 'heldout_package_manifest.sha256',
    'output_hash_manifest.csv', 'heldout_failed_keys_latest.txt',
    'heldout_invocation_log.csv'
)
foreach ($name in $heldoutFiles) { Assert-RequiredFile -Path (Join-Path $heldoutRoot $name) }
Assert-CsvRecordCount -Path (Join-Path $heldoutRoot 'scenario_manifest.csv') `
    -ExpectedCount 100 -Description '100-scene manifest'
Assert-CsvRecordCount -Path (Join-Path $heldoutRoot 'heldout_raw.csv') `
    -ExpectedCount 2100 -Description '2,100-episode raw result table'
foreach ($failureArtifact in @('heldout_failures.csv', 'heldout_failures.mat')) {
    if (Test-Path -LiteralPath (Join-Path $heldoutRoot $failureArtifact)) {
        throw "Held-out failure artifact is present; independent resolution is required before packaging: $failureArtifact"
    }
}
Assert-HeldoutCheckpointPathCoverage -EpisodeRoot (Join-Path $heldoutRoot 'episodes') `
    -ExpectedScenes 100 -StageName '100-scene evaluation'
$failedKeysText = (Get-Content -LiteralPath (Join-Path $heldoutRoot 'heldout_failed_keys_latest.txt') -Raw).Trim()
if ($failedKeysText -ne 'No currently failed episode keys.') {
    throw "100-scene evaluation still reports failed episode keys; resolve before packaging: $failedKeysText"
}
$heldoutAnalysisFiles = @(
    'seven_method_summary.csv', 'six_paired_max_t_contrasts.csv',
    'heldout_analysis.mat', 'analysis_hash_manifest.csv'
)
foreach ($name in $heldoutAnalysisFiles) {
    Assert-RequiredFile -Path (Join-Path (Join-Path $heldoutRoot 'analysis') $name)
}
Assert-CsvRecordCount -Path (Join-Path (Join-Path $heldoutRoot 'analysis') 'seven_method_summary.csv') `
    -ExpectedCount 7 -Description 'Seven-method summary'
Assert-CsvRecordCount -Path (Join-Path (Join-Path $heldoutRoot 'analysis') 'six_paired_max_t_contrasts.csv') `
    -ExpectedCount 6 -Description 'Six paired contrasts'
$heldoutRouteFiles = @('start_goal.csv', 'obstacle_tracks.csv', 'route_status.csv', 'route_example_raw.mat')
foreach ($name in $heldoutRouteFiles) {
    Assert-RequiredFile -Path (Join-Path (Join-Path $heldoutRoot 'route_example') $name)
}
Assert-CsvRecordCount -Path (Join-Path (Join-Path $heldoutRoot 'route_example') 'route_status.csv') `
    -ExpectedCount 7 -Description 'Scene-1/seed-1 route status table'
foreach ($method in @('standalone_dwa_cv', 'standalone_mpc_cv', 'cv', `
    'lstm_mpc_cv_dwa', 'cv_mpc_lstm_dwa', 'lstm', 'static')) {
    Assert-NonEmptyFile -Path (Join-Path (Join-Path $heldoutRoot 'route_example') "trajectory_$method.csv")
}

# Files below are the explicit deliverable/source/data allowlist. These paths
# were checked against the current main/SI TeX figure references, bilingual
# Markdown image links, Stage-1 selection provenance, and held-out runner hash
# inventory. No guessed filenames or entire-folder copies are permitted.
$confirmedFigureAllowlist = @(
    '02_source\figures\scenario_schematic.pdf',
    '02_source\figures\route_comparison.pdf',
    '02_source\figures\algorithm_main_pseudocode.pdf',
    '02_source\figures\algorithm_main_pseudocode.svg',
    '02_source\figures\algorithm_main_pseudocode.png',
    '02_source\figures\algorithm_main_pseudocode.tiff',
    '02_source\figures\integrated_3s_outcomes_main.pdf',
    '02_source\figures\integrated_3s_outcomes_main.svg',
    '02_source\figures\integrated_3s_outcomes_main.png',
    '02_source\figures\integrated_3s_outcomes_main.tiff',
    '02_source\figures\route_comparison_integrated_five_method_scene72_seed2_singlecol.pdf',
    '02_source\figures\route_comparison_integrated_five_method_scene72_seed2_singlecol.svg',
    '02_source\figures\route_comparison_integrated_five_method_scene72_seed2_singlecol.png',
    '02_source\figures\route_comparison_integrated_five_method_scene72_seed2_singlecol.tiff',
    '02_source\figures\route_comparison_seven_method_scene72_seed2.pdf',
    '02_source\figures\route_comparison_seven_method_scene72_seed2.svg',
    '02_source\figures\route_comparison_seven_method_scene72_seed2.png',
    '02_source\figures\route_comparison_seven_method_scene72_seed2.tiff',
    '02_source\figures\route_comparison_five_method_scene404_seed2.pdf',
    '02_source\figures\route_comparison_five_method_scene404_seed2.svg',
    '02_source\figures\route_comparison_five_method_scene404_seed2.png',
    '02_source\figures\route_comparison_five_method_scene404_seed2.tiff',
    '02_source\figures\shared_forecast_pseudocode_algorithm_s1.pdf',
    '02_source\figures\shared_forecast_pseudocode_algorithm_s1.svg',
    '02_source\figures\shared_forecast_pseudocode_algorithm_s1.png',
    '02_source\figures\shared_forecast_pseudocode_algorithm_s1.tiff',
    '03_supplementary\figures\route_comparison_seven_method_scene72_seed2.pdf',
    '03_supplementary\figures\route_comparison_seven_method_scene72_seed2.svg',
    '03_supplementary\figures\route_comparison_seven_method_scene72_seed2.png',
    '03_supplementary\figures\route_comparison_seven_method_scene72_seed2.tiff',
    '03_supplementary\figures\shared_forecast_pseudocode_algorithm_s1.pdf',
    '03_supplementary\figures\shared_forecast_pseudocode_algorithm_s1.svg',
    '03_supplementary\figures\shared_forecast_pseudocode_algorithm_s1.png',
    '03_supplementary\figures\shared_forecast_pseudocode_algorithm_s1.tiff',
    '03_supplementary\figures\historical_36run_results.pdf',
    '03_supplementary\figures\historical_48scene_baselines.pdf',
    '03_supplementary\figures\historical_scene2_four_controller_routes.pdf',
    '03_supplementary\figures\route_comparison.pdf'
)
$confirmedBilingualAssetAllowlist = @(
    '03_bilingual\paper.md',
    '03_bilingual\source_map.json',
    '03_bilingual\supplementary_table_guide.md',
    '03_bilingual\translation_notes.md',
    '03_bilingual\assets\Fig1_scenario.png',
    '03_bilingual\assets\Fig2_planning_cycle.svg',
    '03_bilingual\assets\route_comparison.svg'
)
$frozenModelSourceRelativePath = '_local_archive\results\lstm_predictor.mat'
$frozenModelSourcePath = Join-Path $projectRoot $frozenModelSourceRelativePath
# Exact model digest recorded by selection.provenance in the frozen Stage-1
# pooled_weight_selection.mat; the builder verifies the source file before copy.
$frozenModelSourceSHA256 = '61d84f53263b9ed568c15a3a0fa2dc2fb04d7b1b4e4f669ae38effc4e3e3c25d'
$assetAllowlistConfirmed = $true
$baselineSourceAllowlistConfirmed = $true

if (-not $assetAllowlistConfirmed -or $confirmedFigureAllowlist.Count -eq 0) {
    throw 'Unresolved allowlist gate: enumerate all manuscript/SI figure paths and confirm every referenced asset before packaging.'
}
if (-not $baselineSourceAllowlistConfirmed) {
    throw 'Unresolved source gate: enumerate and explicitly allowlist all direct MPC_DWA_Fusion .m files hashed by the held-out runner.'
}
if ([string]::IsNullOrWhiteSpace($frozenModelSourcePath) -or
    $frozenModelSourcePath -match '^TODO') {
    throw 'Unresolved model gate: set the exact model file path recorded by the frozen Stage-1 provenance.'
}
if (-not [System.IO.Path]::IsPathRooted($frozenModelSourcePath)) {
    throw 'The frozen model source must be an explicit absolute path.'
}
Assert-PathWithin -Path $frozenModelSourcePath -Root $projectRoot -Purpose 'frozen model copy'
if ($confirmedBilingualAssetAllowlist.Count -eq 0) {
    throw 'Unresolved bilingual gate: include 03_bilingual/paper.md and enumerate any exact linked assets.'
}

$revisionRequiredFiles = @(
    'README.md',
    '02_source\main.pdf', '02_source\main.tex', '02_source\references.bib',
    '04_review\v13_final_submission_audit_20261020.md',
    '04_review\publication_assessment_v13_20261017.md',
    'scripts\generate_main_manuscript_figures.py',
    'scripts\generate_integrated_3s_results_figure.py',
    'qa\main_result_figure_contract.md',
    'qa\seven_method_route_endpoint_audit_scene72_seed2.json',
    'qa\seven_method_figure_collision_audit_scene72_seed2.json',
    'qa\route_comparison_integrated_five_method_scene72_seed2_singlecol.json',
    'qa\route_comparison_integrated_five_method_scene72_seed2_singlecol.alignment.json',
    'qa\route_comparison_integrated_five_method_scene72_seed2_singlecol.collision-audit.json',
    'qa\route_comparison_seven_method_scene72_seed2_si.collision-audit.json',
    'qa\algorithm_main_pseudocode.alignment.json',
    'qa\algorithm_main_pseudocode.collision-audit.json',
    'qa\integrated_3s_outcomes_main.json',
    'qa\integrated_3s_outcomes_main.alignment.json',
    'qa\integrated_3s_outcomes_main.collision-audit.json',
    'qa\route_example_scene72_seed2\selection_audit.json',
    'qa\route_example_scene72_seed2\start_goal.csv',
    'qa\route_example_scene72_seed2\route_status.csv',
    'qa\route_example_scene72_seed2\trajectory_standalone_dwa_cv.csv',
    'qa\route_example_scene72_seed2\trajectory_standalone_mpc_cv.csv',
    'qa\route_example_scene72_seed2\trajectory_cv.csv',
    'qa\route_example_scene72_seed2\trajectory_lstm_mpc_cv_dwa.csv',
    'qa\route_example_scene72_seed2\trajectory_cv_mpc_lstm_dwa.csv',
    'qa\route_example_scene72_seed2\trajectory_lstm.csv',
    'qa\route_example_scene72_seed2\trajectory_static.csv',
    '03_supplementary\seven_method_outcomes_figure_source.csv',
    '03_supplementary\integrated_3s_figure_source.csv',
    '02_source\IEEEtran.cls', '02_source\IEEEtran.bst',
    '02_source\figures\route_comparison_seven_method.pdf',
    '02_source\figures\route_comparison_seven_method.svg',
    '02_source\figures\route_comparison_seven_method.png',
    '02_source\figures\route_comparison_seven_method.tiff',
    '02_source\figures\route_comparison_seven_method_scene72_seed2.pdf',
    '02_source\figures\route_comparison_seven_method_scene72_seed2.svg',
    '02_source\figures\route_comparison_seven_method_scene72_seed2.png',
    '02_source\figures\route_comparison_seven_method_scene72_seed2.tiff',
    '03_supplementary\figures\shared_forecast_pseudocode_algorithm_s1.pdf',
    '03_supplementary\figures\shared_forecast_pseudocode_algorithm_s1.svg',
    '03_supplementary\figures\shared_forecast_pseudocode_algorithm_s1.png',
    '03_supplementary\figures\shared_forecast_pseudocode_algorithm_s1.tiff',
    '02_source\figures\route_comparison_seven_method_scene79_seed2.pdf',
    '02_source\figures\route_comparison_seven_method_scene79_seed2.svg',
    '02_source\figures\route_comparison_seven_method_scene79_seed2.png',
    '02_source\figures\route_comparison_seven_method_scene79_seed2.tiff',
    '02_source\figures\route_comparison_five_method_scene404_seed2.pdf',
    '02_source\figures\route_comparison_five_method_scene404_seed2.svg',
    '02_source\figures\route_comparison_five_method_scene404_seed2.png',
    '02_source\figures\route_comparison_five_method_scene404_seed2.tiff',
    'qa\five_method_route_data\scene.csv',
    'qa\five_method_route_data\routes.csv',
    'qa\five_method_route_data\route_status.csv',
    'qa\five_method_route_data\obstacle_tracks.csv',
    'qa\candidate_scene288_seed2\scene.csv',
    'qa\candidate_scene288_seed2\routes.csv',
    'qa\candidate_scene288_seed2\route_status.csv',
    'qa\candidate_scene288_seed2\obstacle_tracks.csv',
    'qa\candidate_scene288_seed3\scene.csv',
    'qa\candidate_scene288_seed3\routes.csv',
    'qa\candidate_scene288_seed3\route_status.csv',
    'qa\candidate_scene288_seed3\obstacle_tracks.csv',
    'qa\figure_collisions_main_routes.json',
    'qa\figure_collisions_supp_routes.json',
    '03_supplementary\figures\route_comparison_seven_method_scene72_seed2.pdf',
    '03_supplementary\figures\route_comparison_seven_method_scene72_seed2.svg',
    '03_supplementary\figures\route_comparison_seven_method_scene72_seed2.png',
    '03_supplementary\figures\route_comparison_seven_method_scene72_seed2.tiff',
    '03_supplementary\README.md', '03_supplementary\supplementary_methods.tex',
    '03_supplementary\supplementary_methods.pdf',
    '03_supplementary\confirmatory_raw.csv',
    '03_supplementary\confirmatory_method_summary.csv',
    '03_supplementary\confirmatory_cluster_bootstrap.csv',
    '03_supplementary\confirmatory_scene_cluster_means.csv',
    '03_supplementary\confirmatory_run_audit.csv',
    '03_supplementary\scenario_manifest.csv',
    '03_supplementary\scene_generation_specification.md',
    '03_supplementary\paired_scene_outcome_counts.csv',
    '03_supplementary\confirmatory_experiment_protocol.md',
    '03_supplementary\confirmatory_protocol_clarification.md',
    '03_supplementary\five_method_run_audit.csv',
    '03_supplementary\five_method_summary.csv',
    '03_supplementary\five_method_paired_bootstrap.csv',
    '03_supplementary\five_method_absolute_bootstrap.csv',
    '03_supplementary\five_method_terminal_outcomes.csv',
    '03_supplementary\figures\route_comparison_seven_method.pdf',
    '03_supplementary\shared_lstm_random12_revised.csv',
    '04_review\final_submission_audit.md', '04_review\reference_verification.md',
    '04_review\formula_symbol_audit.md', '04_review\command_template_compliance.md',
    '04_review\seven_method_figure_contract_v12a.md',
    '04_review\v12a_result_figure_contract.md',
    '04_review\v12a_multidimensional_claim_contract.md',
    '04_review\pooled_weight_selection_protocol_v12a.md',
    '04_review\redesigned_comparison_protocol.md',
    '04_review\protocol_amendment_endpoint_inclusive_20261012.md',
    '04_review\redesigned_protocol_v12a_amendment.md',
    '04_review\v12a_calibration_quarantine_20261011.md',
    '04_review\trust_scale_parameter_calibration_v13.md',
    '04_review\seven_method_heldout_protocol_v13.md',
    '04_review\seven_method_100scene_exploratory_amendment_20261015.md',
    '04_review\v13_final_submission_audit_20261015.md',
    '04_review\v13_final_submission_audit_20261016_addendum.md',
    '04_review\v13_final_submission_audit_20261016_forecast_update.md',
    '04_review\v13_final_submission_audit_20261016_final.md',
    '04_review\v13_route_illustration_amendment_20261016.md',
    '04_review\shared_vs_dwaonly_confirmatory_protocol.md',
    '04_review\reference_verification_v13.md',
    'qa\seven_method_route_endpoint_audit.json',
    'qa\seven_method_figure_collision_audit.json',
    'qa\seven_method_route_endpoint_audit_scene72_seed2.json',
    'qa\seven_method_figure_collision_audit_scene72_seed2.json',
    'qa\seven_method_route_endpoint_audit_scene79_seed2.json',
    'qa\seven_method_figure_collision_audit_scene79_seed2.json',
    'qa\route_example_scene72_seed2\selection_audit.json',
    'qa\route_example_scene72_seed2\start_goal.csv',
    'qa\route_example_scene72_seed2\route_status.csv',
    'qa\route_example_scene72_seed2\trajectory_standalone_dwa_cv.csv',
    'qa\route_example_scene72_seed2\trajectory_standalone_mpc_cv.csv',
    'qa\route_example_scene72_seed2\trajectory_cv.csv',
    'qa\route_example_scene72_seed2\trajectory_lstm_mpc_cv_dwa.csv',
    'qa\route_example_scene72_seed2\trajectory_cv_mpc_lstm_dwa.csv',
    'qa\route_example_scene72_seed2\trajectory_lstm.csv',
    'qa\route_example_scene72_seed2\trajectory_static.csv',
    'qa\route_example_scene79_seed2\selection_audit.json',
    'qa\route_example_scene79_seed2\start_goal.csv',
    'qa\route_example_scene79_seed2\route_status.csv',
    'qa\route_example_scene79_seed2\trajectory_standalone_dwa_cv.csv',
    'qa\route_example_scene79_seed2\trajectory_standalone_mpc_cv.csv',
    'qa\route_example_scene79_seed2\trajectory_cv.csv',
    'qa\route_example_scene79_seed2\trajectory_lstm_mpc_cv_dwa.csv',
    'qa\route_example_scene79_seed2\trajectory_cv_mpc_lstm_dwa.csv',
    'qa\route_example_scene79_seed2\trajectory_lstm.csv',
    'qa\route_example_scene79_seed2\trajectory_static.csv',
    'qa\historical_scene2_route_endpoint_audit.json',
    'qa\confirmatory_route_figure_data\obstacle_tracks.csv',
    'qa\confirmatory_route_figure_data\route_cv.csv',
    'qa\confirmatory_route_figure_data\route_kalman.csv',
    'qa\confirmatory_route_figure_data\route_lstm_dwa_only.csv',
    'qa\confirmatory_route_figure_data\route_lstm_mpc_only.csv',
    'qa\confirmatory_route_figure_data\route_lstm.csv',
    'qa\confirmatory_route_figure_data\route_static.csv',
    'qa\confirmatory_route_figure_data\route_status.csv',
    'qa\confirmatory_route_figure_data\start_goal.csv'
)
$scriptAllowlist = @(
    'analyze_v12a_seven_method_heldout.m', 'analyze_v13_snapshot_compatible.m',
    'analyze_v13_trust_scale_parameter_calibration.m',
    'build_reproducibility_package.ps1', 'compile_final.ps1',
    'generate_algorithm_flow.py',
    'generate_four_method_figures.py', 'generate_scenario_schematic.py', 'generate_seven_method_route_figure.py',
    'generate_seven_method_route_figure_compat.py',
    'generate_shared_forecast_pseudocode.py',
    'export_confirmatory_route_data.m',
    'recompute_confirmatory_outcomes.m',
    'generate_v12a_heldout_scenarios.m', 'run_v12_redesigned.m',
    'run_v12a_pooled_weight_development.m',
    'run_v13_trust_scale_parameter_calibration.m',
    'run_v12a_seven_method_heldout.m', 'simulate_dynamic_v12a_timed.m',
    'simulate_standalone_controller_v12a_timed.m',
    'sha256_sidecar_matches.m', 'sync_bilingual_source_map.py',
    'export_v13_route_example_from_heldout.m'
)
$projectSourceAllowlist = @(
    'computeTrust_dynamic.m', 'config_LSTM.m', 'features_from_traj.m',
    'generate_obstacle_trajectory.m', 'generate_random_eval_scenarios.m',
    'MPC_UAV_dynamic_cached.m', 'predict_obstacle_traj.m',
    'predict_trajectory_constant.m', 'prepare_observation_stream.m',
    'simulate_dynamic.m', 'simulate_standalone_controller.m'
)
$fusionSourceAllowlist = @(
    'computeTrust.m', 'config_UAV.m', 'dynamicWeights.m', 'MPC_DWA_main.m',
    'MPC_UAV.m', 'referenceScores3D.m', 'sampleIntelligent3D.m',
    'test_MPC.m', 'UAV_DWA_3D.m', 'UAV_dynamics_sym.m', 'UAV_model.m'
)
$referenceBundleAllowlist = @(
    'confirmatory_revision\confirmatory_48scenes_20261005_050804\experiment_bundle.mat',
    'reviewer_layer_ablation\random12_20261002_030232\layer_ablation_bundle.mat',
    'standalone_controller_revision\fair_rerun\smoke\smoke_scene001_seed01_20261010_183121\experiment_bundle.mat'
)
$omittedLargeReferenceBundles = @(
    'confirmatory_revision\shared_vs_dwaonly_h1s_mpc3s_500scenes_20261005_164515\experiment_bundle.mat',
    'original_baseline_revision\original_mpc_dwa_static_500scenes_20261009_212117\experiment_bundle.mat',
    'standalone_controller_revision\fair_rerun\standalone_dwa_mpc_500scenes_20261010_183340\experiment_bundle.mat',
    'standalone_controller_revision\standalone_dwa_mpc_500scenes_20261007_234711\experiment_bundle.mat',
    'standalone_controller_revision\standalone_dwa_mpc_swept_500scenes_20261008_132820\experiment_bundle.mat'
)
$optionalReferenceBundle = 'v12_redesigned_test_500scenes_20261017\experiment_bundle.mat'
$presentOptionalReferenceBundles = @()
if (Test-Path -LiteralPath (Join-Path $resultsRoot $optionalReferenceBundle) -PathType Leaf) {
    $presentOptionalReferenceBundles = @($optionalReferenceBundle)
}
$stage1SourceFiles = @(
    'confirmatory_revision\confirmatory_48scenes_20261005_050804\experiment_bundle.mat',
    'confirmatory_revision\confirmatory_48scenes_20261005_050804\confirmatory_raw.csv',
    'confirmatory_revision\confirmatory_48scenes_20261005_050804\scenario_manifest.csv',
    'confirmatory_revision\confirmatory_48scenes_20261005_050804\confirmatory_run_audit.csv',
    'confirmatory_revision\confirmatory_48scenes_20261005_050804\scene002_seed01_static.mat',
    'confirmatory_revision\confirmatory_48scenes_20261005_050804\scene002_seed01_cv.mat',
    'confirmatory_revision\confirmatory_48scenes_20261005_050804\scene002_seed01_kalman.mat',
    'confirmatory_revision\confirmatory_48scenes_20261005_050804\scene002_seed01_lstm_mpc_only.mat',
    'confirmatory_revision\confirmatory_48scenes_20261005_050804\scene002_seed01_lstm_dwa_only.mat',
    'confirmatory_revision\confirmatory_48scenes_20261005_050804\scene002_seed01_lstm.mat',
    'v12_trust_weight_tuning_dev48_20261006\tuning_bundle.mat'
)
$frozenParentProtocolRelativePath = 'paper\Conference_4Page_Submission\versions\13_final_submission\04_review\frozen_parent_redesigned_comparison_protocol_v12.md'
$deliveryRelativePaths = @(
    'README.md',
    '02_source/main.pdf', '02_source/main.tex', '02_source/references.bib',
    '04_review/v13_final_submission_audit_20261020.md',
    '04_review/publication_assessment_v13_20261017.md',
    'scripts/generate_main_manuscript_figures.py',
    'scripts/generate_integrated_3s_results_figure.py',
    'qa/main_result_figure_contract.md',
    'qa/seven_method_route_endpoint_audit_scene72_seed2.json',
    'qa/seven_method_figure_collision_audit_scene72_seed2.json',
    '03_supplementary/seven_method_outcomes_figure_source.csv',
    '03_supplementary/integrated_3s_figure_source.csv',
    '02_source/figures/algorithm_main_pseudocode.pdf',
    '02_source/figures/algorithm_main_pseudocode.svg',
    '02_source/figures/algorithm_main_pseudocode.png',
    '02_source/figures/algorithm_main_pseudocode.tiff',
    '02_source/figures/integrated_3s_outcomes_main.pdf',
    '02_source/figures/integrated_3s_outcomes_main.svg',
    '02_source/figures/integrated_3s_outcomes_main.png',
    '02_source/figures/integrated_3s_outcomes_main.tiff',
    '02_source/figures/route_comparison_integrated_five_method_scene72_seed2_singlecol.pdf',
    '02_source/figures/route_comparison_integrated_five_method_scene72_seed2_singlecol.svg',
    '02_source/figures/route_comparison_integrated_five_method_scene72_seed2_singlecol.png',
    '02_source/figures/route_comparison_integrated_five_method_scene72_seed2_singlecol.tiff',
    'qa/route_comparison_integrated_five_method_scene72_seed2_singlecol.json',
    'qa/route_comparison_integrated_five_method_scene72_seed2_singlecol.alignment.json',
    'qa/route_comparison_integrated_five_method_scene72_seed2_singlecol.collision-audit.json',
    'qa/route_comparison_seven_method_scene72_seed2_si.collision-audit.json',
    'qa/algorithm_main_pseudocode.alignment.json',
    'qa/algorithm_main_pseudocode.collision-audit.json',
    'qa/integrated_3s_outcomes_main.json',
    'qa/integrated_3s_outcomes_main.alignment.json',
    'qa/integrated_3s_outcomes_main.collision-audit.json',
    '02_source/figures/route_comparison_seven_method_scene72_seed2.pdf',
    '02_source/figures/route_comparison_seven_method_scene72_seed2.svg',
    '02_source/figures/route_comparison_seven_method_scene72_seed2.png',
    '02_source/figures/route_comparison_seven_method_scene72_seed2.tiff',
    '02_source/IEEEtran.cls', '02_source/IEEEtran.bst',
    'scripts/generate_seven_method_route_figure.py',
    'scripts/generate_shared_forecast_pseudocode.py',
    '02_source/figures/route_comparison_seven_method.pdf',
    '02_source/figures/route_comparison_seven_method.svg',
    '02_source/figures/route_comparison_seven_method.png',
    '02_source/figures/route_comparison_seven_method.tiff',
    '02_source/figures/route_comparison_seven_method_scene72_seed2.pdf',
    '02_source/figures/route_comparison_seven_method_scene72_seed2.svg',
    '02_source/figures/route_comparison_seven_method_scene72_seed2.png',
    '02_source/figures/route_comparison_seven_method_scene72_seed2.tiff',
    '02_source/figures/route_comparison_seven_method.svg',
    '02_source/figures/route_comparison_seven_method.png',
    '02_source/figures/route_comparison_seven_method.tiff',
    '02_source/figures/route_comparison_seven_method_scene79_seed2.pdf',
    '02_source/figures/route_comparison_seven_method_scene79_seed2.svg',
    '02_source/figures/route_comparison_seven_method_scene79_seed2.png',
    '02_source/figures/route_comparison_seven_method_scene79_seed2.tiff',
    '02_source/figures/route_comparison_five_method_scene404_seed2.pdf',
    '02_source/figures/route_comparison_five_method_scene404_seed2.svg',
    '02_source/figures/route_comparison_five_method_scene404_seed2.png',
    '02_source/figures/route_comparison_five_method_scene404_seed2.tiff',
    'qa/five_method_route_data/scene.csv',
    'qa/five_method_route_data/routes.csv',
    'qa/five_method_route_data/route_status.csv',
    'qa/five_method_route_data/obstacle_tracks.csv',
    'qa/candidate_scene288_seed2/scene.csv',
    'qa/candidate_scene288_seed2/routes.csv',
    'qa/candidate_scene288_seed2/route_status.csv',
    'qa/candidate_scene288_seed2/obstacle_tracks.csv',
    'qa/candidate_scene288_seed3/scene.csv',
    'qa/candidate_scene288_seed3/routes.csv',
    'qa/candidate_scene288_seed3/route_status.csv',
    'qa/candidate_scene288_seed3/obstacle_tracks.csv',
    'qa/figure_collisions_main_routes.json',
    'qa/figure_collisions_supp_routes.json',
    '03_supplementary/figures/route_comparison_seven_method_scene72_seed2.pdf',
    '03_supplementary/figures/route_comparison_seven_method_scene72_seed2.svg',
    '03_supplementary/figures/route_comparison_seven_method_scene72_seed2.png',
    '03_supplementary/figures/route_comparison_seven_method_scene72_seed2.tiff',
    'qa/seven_method_route_endpoint_audit.json',
    'qa/seven_method_figure_collision_audit.json',
    'qa/seven_method_route_endpoint_audit_scene72_seed2.json',
    'qa/seven_method_figure_collision_audit_scene72_seed2.json',
    'qa/seven_method_route_endpoint_audit_scene79_seed2.json',
    'qa/seven_method_figure_collision_audit_scene79_seed2.json',
    'scripts/generate_seven_method_route_figure.py',
    'scripts/generate_four_method_figures.py',
    'scripts/compile_final.ps1',
    'scripts/build_reproducibility_package.ps1',
    'scripts/export_v13_route_example_from_heldout.m',
    'qa/route_example_scene79_seed2/selection_audit.json',
    'qa/route_example_scene79_seed2/start_goal.csv',
    'qa/route_example_scene79_seed2/route_status.csv',
    'qa/route_example_scene79_seed2/trajectory_standalone_dwa_cv.csv',
    'qa/route_example_scene79_seed2/trajectory_standalone_mpc_cv.csv',
    'qa/route_example_scene79_seed2/trajectory_cv.csv',
    'qa/route_example_scene79_seed2/trajectory_lstm_mpc_cv_dwa.csv',
    'qa/route_example_scene79_seed2/trajectory_cv_mpc_lstm_dwa.csv',
    'qa/route_example_scene79_seed2/trajectory_lstm.csv',
    'qa/route_example_scene79_seed2/trajectory_static.csv',
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
    '03_supplementary/README.md', '03_supplementary/supplementary_methods.pdf',
    '03_supplementary/supplementary_methods.tex',
    '03_supplementary/confirmatory_raw.csv',
    '03_supplementary/confirmatory_method_summary.csv',
    '03_supplementary/confirmatory_cluster_bootstrap.csv',
    '03_supplementary/confirmatory_scene_cluster_means.csv',
    '03_supplementary/confirmatory_run_audit.csv',
    '03_supplementary/scenario_manifest.csv',
    '03_supplementary/scene_generation_specification.md',
    '03_supplementary/paired_scene_outcome_counts.csv',
    '03_supplementary/confirmatory_experiment_protocol.md',
    '03_supplementary/confirmatory_protocol_clarification.md',
    '03_supplementary/five_method_run_audit.csv',
    '03_supplementary/five_method_summary.csv',
    '03_supplementary/five_method_paired_bootstrap.csv',
    '03_supplementary/five_method_absolute_bootstrap.csv',
    '03_supplementary/five_method_terminal_outcomes.csv',
    '03_supplementary/figures/route_comparison_seven_method.pdf',
    '03_supplementary/shared_lstm_random12_revised.csv',
    '03_bilingual/source_map.json',
    '03_bilingual/supplementary_table_guide.md',
    '03_bilingual/translation_notes.md',
    '04_review/v13_final_submission_audit_20261015.md',
    '04_review/v13_final_submission_audit_20261016_addendum.md',
    '04_review/v13_final_submission_audit_20261016_forecast_update.md',
    '04_review/v13_final_submission_audit_20261016_final.md',
    '04_review/v13_route_illustration_amendment_20261016.md',
    '04_review/shared_vs_dwaonly_confirmatory_protocol.md',
    '04_review/reference_verification_v13.md',
    '04_review/final_submission_audit.md', '04_review/reference_verification.md',
    '04_review/formula_symbol_audit.md', '04_review/command_template_compliance.md',
    '04_review/v12a_multidimensional_claim_contract.md',
    '04_review/protocol_amendment_endpoint_inclusive_20261012.md',
    '04_review/seven_method_figure_contract_v12a.md',
    '04_review/v12a_result_figure_contract.md',
    '04_review/trust_scale_parameter_calibration_v13.md',
    '04_review/seven_method_heldout_protocol_v13.md',
    '04_review/seven_method_100scene_exploratory_amendment_20261015.md',
    'qa/seven_method_route_endpoint_audit.json',
    'qa/route_example_scene79_seed2/selection_audit.json',
    'qa/route_example_scene79_seed2/start_goal.csv',
    'qa/route_example_scene79_seed2/route_status.csv',
    'qa/route_example_scene79_seed2/trajectory_standalone_dwa_cv.csv',
    'qa/route_example_scene79_seed2/trajectory_standalone_mpc_cv.csv',
    'qa/route_example_scene79_seed2/trajectory_cv.csv',
    'qa/route_example_scene79_seed2/trajectory_lstm_mpc_cv_dwa.csv',
    'qa/route_example_scene79_seed2/trajectory_cv_mpc_lstm_dwa.csv',
    'qa/route_example_scene79_seed2/trajectory_lstm.csv',
    'qa/route_example_scene79_seed2/trajectory_static.csv',
    'qa/historical_scene2_route_endpoint_audit.json',
    'qa/confirmatory_route_figure_data/obstacle_tracks.csv',
    'qa/confirmatory_route_figure_data/route_cv.csv',
    'qa/confirmatory_route_figure_data/route_kalman.csv',
    'qa/confirmatory_route_figure_data/route_lstm_dwa_only.csv',
    'qa/confirmatory_route_figure_data/route_lstm_mpc_only.csv',
    'qa/confirmatory_route_figure_data/route_lstm.csv',
    'qa/confirmatory_route_figure_data/route_static.csv',
    'qa/confirmatory_route_figure_data/route_status.csv',
    'qa/confirmatory_route_figure_data/start_goal.csv'
)

# Confirm every explicitly named artifact before creating a staging directory.
foreach ($relativePath in $revisionRequiredFiles) {
    Assert-RequiredFile -Path (Join-Path $revisionRoot $relativePath)
}
foreach ($name in $projectDocumentAllowlist) {
    Assert-RequiredFile -Path (Join-Path $projectDocumentRoot $name)
}
Assert-CsvRecordCount -Path (Join-Path $supplementRoot 'confirmatory_raw.csv') `
    -ExpectedCount 3000 -Description '500-scene paired contrast raw records'
Assert-CsvRecordCount -Path (Join-Path $supplementRoot 'confirmatory_method_summary.csv') `
    -ExpectedCount 2 -Description '500-scene paired contrast method summary'
Assert-CsvRecordCount -Path (Join-Path $supplementRoot 'confirmatory_run_audit.csv') `
    -ExpectedCount 3000 -Description '500-scene paired contrast run audit'
Assert-CsvRecordCount -Path (Join-Path $supplementRoot 'scenario_manifest.csv') `
    -ExpectedCount 500 -Description 'Historical 500-scene manifest'
Assert-CsvRecordCount -Path (Join-Path $supplementRoot 'five_method_run_audit.csv') `
    -ExpectedCount 7500 -Description 'Historical five-controller run audit'
foreach ($relativePath in $confirmedFigureAllowlist) {
    Assert-RequiredFile -Path (Join-Path $revisionRoot $relativePath)
}
foreach ($relativePath in $confirmedBilingualAssetAllowlist) {
    Assert-RequiredFile -Path (Join-Path $revisionRoot $relativePath)
}
foreach ($name in $scriptAllowlist) {
    Assert-RequiredFile -Path (Join-Path (Join-Path $revisionRoot 'scripts') $name)
}
foreach ($name in $projectSourceAllowlist) {
    Assert-RequiredFile -Path (Join-Path $projectRoot $name)
}
foreach ($name in $fusionSourceAllowlist) {
    Assert-RequiredFile -Path (Join-Path (Join-Path $projectRoot 'MPC_DWA_Fusion') $name)
}
foreach ($relativePath in ($referenceBundleAllowlist + $omittedLargeReferenceBundles + $presentOptionalReferenceBundles + $stage1SourceFiles)) {
    Assert-RequiredFile -Path (Join-Path $resultsRoot $relativePath)
}
Assert-RequiredFile -Path (Join-Path $heldoutRoot 'experiment_bundle.mat')
Assert-RequiredFile -Path (Join-Path $supplementRoot 'reproducibility_package_v13.zip')
Assert-RequiredFile -Path (Join-Path $supplementRoot 'reproducibility_package_v13.zip.sha256')
$legacyArchivePath = Join-Path $supplementRoot 'reproducibility_package_v13.zip'
$legacyArchiveHash = (Get-FileHash -LiteralPath $legacyArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
$legacySidecar = (Get-Content -LiteralPath ($legacyArchivePath + '.sha256') -Raw).Trim()
if (-not $legacySidecar.StartsWith($legacyArchiveHash, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'The preserved legacy v13 archive does not match its SHA-256 sidecar.'
}
Assert-RequiredFile -Path (Join-Path $projectRoot $frozenParentProtocolRelativePath)
Assert-RequiredFile -Path $frozenModelSourcePath
$actualFrozenModelSHA256 = (Get-FileHash -LiteralPath $frozenModelSourcePath `
    -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualFrozenModelSHA256 -ne $frozenModelSourceSHA256) {
    throw "Frozen model SHA-256 differs from Stage-1 provenance: $frozenModelSourcePath"
}

$casadiRelativePath = 'MPC_DWA_Fusion\third_party\casadi-3.8.0-windows64-matlab2018b'
$casadiArchiveRelativePath = $casadiRelativePath.Replace('\', '/')
$casadiSource = Join-Path $projectRoot $casadiRelativePath
Assert-RequiredDirectory -Path $casadiSource

# The two Stage-1.4 supplementary citations are direct references in the final
# supplementary text; include the existing originals at their current locations.
$fixedSceneEvidence = Join-Path $resultsRoot 'emergency_revision\fixed_scenes_20261005_030440\fixed_scenes_revised.csv'
Assert-RequiredFile -Path $fixedSceneEvidence

$stageRoot = Join-Path $supplementRoot ('.repro_pack_v13_' + [guid]::NewGuid().ToString('N'))
$packageRoot = Join-Path $stageRoot 'LSTM_MPC_DWA'
$packageRevisionRoot = Join-Path $packageRoot $revisionPackagePath
$zipPath = Join-Path $supplementRoot 'reproducibility_package.zip'
$pendingZip = Join-Path $supplementRoot ('.reproducibility_package_' + [guid]::NewGuid().ToString('N') + '.pending.zip')
$zipHashPath = Join-Path $supplementRoot 'reproducibility_package.zip.sha256'
$deliveryManifestPath = Join-Path $supplementRoot 'final_delivery_SHA256.txt'
$pendingDeliveryManifestPath = Join-Path $supplementRoot ('.final_delivery_SHA256_' + [guid]::NewGuid().ToString('N') + '.pending.txt')
Assert-PathWithin -Path $stageRoot -Root $supplementRoot -Purpose 'package staging'
New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null

try {
    foreach ($relativePath in $revisionRequiredFiles) {
        Copy-RequiredFile -Source (Join-Path $revisionRoot $relativePath) `
            -DestinationRoot $packageRevisionRoot -RelativePath $relativePath
    }
    foreach ($name in $projectDocumentAllowlist) {
        $relativePath = Join-Path 'paper' $name
        Copy-RequiredFile -Source (Join-Path $projectDocumentRoot $name) `
            -DestinationRoot $packageRoot -RelativePath $relativePath
    }
    foreach ($relativePath in $confirmedFigureAllowlist) {
        Copy-RequiredFile -Source (Join-Path $revisionRoot $relativePath) `
            -DestinationRoot $packageRevisionRoot -RelativePath $relativePath
    }
    foreach ($relativePath in $confirmedBilingualAssetAllowlist) {
        Copy-RequiredFile -Source (Join-Path $revisionRoot $relativePath) `
            -DestinationRoot $packageRevisionRoot -RelativePath $relativePath
    }
    foreach ($name in $scriptAllowlist) {
        $relativePath = "scripts\$name"
        Copy-RequiredFile -Source (Join-Path (Join-Path $revisionRoot 'scripts') $name) `
            -DestinationRoot $packageRevisionRoot -RelativePath $relativePath
    }
    foreach ($name in $projectSourceAllowlist) {
        Copy-RequiredFile -Source (Join-Path $projectRoot $name) `
            -DestinationRoot $packageRoot -RelativePath $name
    }
    foreach ($name in $fusionSourceAllowlist) {
        $relativePath = "MPC_DWA_Fusion\$name"
        Copy-RequiredFile -Source (Join-Path (Join-Path $projectRoot 'MPC_DWA_Fusion') $name) `
            -DestinationRoot $packageRoot -RelativePath $relativePath
    }
    Copy-RequiredFile -Source (Join-Path $casadiSource 'README.md') -DestinationRoot $packageRoot `
        -RelativePath (Join-Path $casadiRelativePath 'README.md')
    Copy-RequiredFile -Source $frozenModelSourcePath -DestinationRoot $packageRoot `
        -RelativePath 'models\frozen_lstm_predictor.mat'

    foreach ($relativePath in ($referenceBundleAllowlist + $stage1SourceFiles)) {
        Copy-RequiredFile -Source (Join-Path $resultsRoot $relativePath) `
            -DestinationRoot $packageRoot -RelativePath (Join-Path 'results' $relativePath)
    }
    Copy-RequiredFile -Source (Join-Path $projectRoot $frozenParentProtocolRelativePath) `
        -DestinationRoot $packageRoot -RelativePath $frozenParentProtocolRelativePath
    Copy-RequiredFile -Source $fixedSceneEvidence -DestinationRoot $packageRoot `
        -RelativePath 'results\emergency_revision\fixed_scenes_20261005_030440\fixed_scenes_revised.csv'
    $omittedArtifactInputs = [System.Collections.Generic.List[object]]::new()
    foreach ($relativePath in ($omittedLargeReferenceBundles + $presentOptionalReferenceBundles)) {
        $omittedArtifactInputs.Add([pscustomobject]@{
            SourcePath = Join-Path $resultsRoot $relativePath
            Reason = 'Large historical experiment bundle retained at the original results path; not duplicated in this archive.'
        })
    }
    $omittedArtifactInputs.Add([pscustomobject]@{
        SourcePath = Join-Path $heldoutRoot 'experiment_bundle.mat'
        Reason = 'Combined MAT bundle retained at the original results path; scenario bank, raw outcomes, trajectories and manifests are separately included.'
    })
    $omittedArtifactRows = foreach ($item in $omittedArtifactInputs) {
        $sourceFile = Get-Item -LiteralPath $item.SourcePath
        [pscustomobject]@{
            OriginalRelativePath = $sourceFile.FullName.Substring($projectRoot.Length).TrimStart('\').Replace('\', '/')
            Bytes = $sourceFile.Length
            SHA256 = (Get-FileHash -LiteralPath $sourceFile.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            PackageTreatment = $item.Reason
        }
    }
    $omittedArtifactRows | Export-Csv -LiteralPath (Join-Path $packageRoot 'OMITTED_ARTIFACTS_SHA256.csv') `
        -NoTypeInformation -Encoding UTF8

    $casadiManifestRows = foreach ($file in Get-ChildItem -LiteralPath $casadiSource -File -Recurse -Force | Sort-Object FullName) {
        [pscustomobject]@{
            RelativePath = $file.FullName.Substring($casadiSource.Length).TrimStart('\').Replace('\', '/')
            Bytes = $file.Length
            SHA256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    }
    $casadiManifestRows | Export-Csv -LiteralPath (Join-Path $packageRoot 'CASADI_3.8.0_SHA256.csv') `
        -NoTypeInformation -Encoding UTF8

    $stage1Target = Join-Path $packageRoot $stage1PackageRelativePath
    foreach ($name in $stage1Files) {
        Copy-RequiredFile -Source (Join-Path $stage1Root $name) -DestinationRoot $stage1Target -RelativePath $name
    }
    foreach ($file in $stage1ErrorFiles) {
        Copy-RequiredFile -Source $file.FullName -DestinationRoot $stage1Target `
            -RelativePath (Join-Path 'errors' $file.Name)
    }

    $heldoutTarget = Join-Path $packageRoot $heldoutPackageRelativePath
    foreach ($name in $heldoutFiles) {
        Copy-RequiredFile -Source (Join-Path $heldoutRoot $name) -DestinationRoot $heldoutTarget -RelativePath $name
    }
    foreach ($name in $heldoutAnalysisFiles) {
        Copy-RequiredFile -Source (Join-Path (Join-Path $heldoutRoot 'analysis') $name) `
            -DestinationRoot $heldoutTarget -RelativePath (Join-Path 'analysis' $name)
    }
    foreach ($name in $heldoutRouteFiles) {
        Copy-RequiredFile -Source (Join-Path (Join-Path $heldoutRoot 'route_example') $name) `
            -DestinationRoot $heldoutTarget -RelativePath (Join-Path 'route_example' $name)
    }
    foreach ($method in @('standalone_dwa_cv', 'standalone_mpc_cv', 'cv', `
        'lstm_mpc_cv_dwa', 'cv_mpc_lstm_dwa', 'lstm', 'static')) {
        $name = "trajectory_$method.csv"
        Copy-RequiredFile -Source (Join-Path (Join-Path $heldoutRoot 'route_example') $name) `
            -DestinationRoot $heldoutTarget -RelativePath (Join-Path 'route_example' $name)
    }

    $readme = @(
        '# Reproducibility package', '',
        'This package contains the v13 manuscript, its explicitly allowlisted figures/assets, full bilingual reader, supplementary files, source code, model, and dependency/artifact hash manifests.',
        'The 500-scene shared-LSTM versus DWA-only-LSTM contrast (3,000 paired episodes) is included with its frozen protocol, raw records, run audit, scene-cluster summaries, and bootstrap output. These episodes are a subset of the historical 7,500-run five-controller benchmark, not an additional cohort; the full five-controller run audit and summaries are included for reconciliation.',
        'Stage 1 contains the 4,320-run development summaries, selection/recovery manifests, and per-run SHA-256 index; individual Stage-1 episode MAT files are intentionally not copied.',
        'Stage 2 trust-scale calibration was not completed or verified. Its protocol/audit documents and separately allowlisted source scripts are retained, but no Stage-2 result tables or MAT files are included.',
        'The finite v13 evaluation comprises 100 scenes x 3 seeds x 7 methods (2,100 episodes). It includes run-level outcomes, analysis records, manifests, the scenario bank, full trajectory archive, and the originally fixed scene-1/seed-1 route CSVs. Main-text Figure 4 is the post hoc five-integrated-controller scene-72/seed-2 matched example; only shared LSTM arrives safely in that illustrative case. Supplementary Figure S5 retains all seven methods from the same record in 3-D and XY/XZ/YZ projections; shared LSTM and standalone DWA arrive safely there. The scene-79 exclusive-arrival set remains archived because several comparator paths are too short and nearly straight to inspect clearly. Both figures are descriptive, and exact saved paths plus selection/endpoint audits and record-only exporters are included. Algorithm S1 follows Supplementary Methods S1.4. Individual held-out episode MAT checkpoints and the redundant combined experiment_bundle.mat are not duplicated.',
        'The historical four-controller scene-2 route example includes the exact saved route CSVs, endpoint audit, and the six small source MAT records plus scenario/run audit needed by scripts/export_confirmatory_route_data.m. These files are exported from existing records; rebuilding them does not run simulations.',
        'Large historical experiment bundles and the combined v13 MAT bundle remain unchanged at their original results paths; OMITTED_ARTIFACTS_SHA256.csv records their source paths, sizes and hashes. Compact historical evidence is retained in the supplement. The compact v13 archive is delivered separately beside this full archive rather than redundantly embedded within it.',
        'CasADi 3.8.0 Windows/MATLAB binaries are not duplicated. The expected local path and license note are preserved, and CASADI_3.8.0_SHA256.csv inventories the original dependency files and hashes. A compatible CasADi distribution must be provided separately to rerun optimizations.',
        'Historical result banks, including earlier 7,500-run, 48-scene, CV/Kalman and scene-404 records, remain separately identified and are not pooled with this evaluation. The v13 evidence is simulation-only; it is not real-flight validation.',
        'The compact v13 reproducibility archive and its SHA-256 sidecar are delivered separately beside this full archive; they are not nested to avoid duplicating the same assets.',
        'Run SHA-256 checks from this directory with `sha256sum -c SHA256SUMS.txt` or an equivalent platform tool.',
        'SHA256SUMS.txt covers every packaged file except itself; the adjacent ZIP sidecar covers the archive.',
        'PACKAGE_CONTENTS.txt is the exact inventory of the archive.'
    )
    [System.IO.File]::WriteAllLines((Join-Path $packageRoot 'README_reproducibility.md'), `
        [string[]]$readme, [System.Text.Encoding]::UTF8)

    $packageFiles = @(Get-ChildItem -LiteralPath $packageRoot -File -Recurse -Force | Sort-Object FullName)
    $packageRelativePaths = @($packageFiles | ForEach-Object {
        $_.FullName.Substring($packageRoot.Length).TrimStart('\').Replace('\', '/')
    })
    $inventoryLines = @('Package file inventory:') + $packageRelativePaths + @('PACKAGE_CONTENTS.txt', 'SHA256SUMS.txt')
    [System.IO.File]::WriteAllLines((Join-Path $packageRoot 'PACKAGE_CONTENTS.txt'), `
        [string[]]$inventoryLines, [System.Text.Encoding]::UTF8)

    $hashFiles = @(Get-ChildItem -LiteralPath $packageRoot -File -Recurse -Force |
        Where-Object { $_.Name -ne 'SHA256SUMS.txt' } | Sort-Object FullName)
    $hashLines = foreach ($file in $hashFiles) {
        $relativePath = $file.FullName.Substring($packageRoot.Length).TrimStart('\').Replace('\', '/')
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $relativePath"
    }
    [System.IO.File]::WriteAllLines((Join-Path $packageRoot 'SHA256SUMS.txt'), `
        [string[]]$hashLines, [System.Text.Encoding]::ASCII)

    $expectedArchiveEntries = @(Get-ChildItem -LiteralPath $packageRoot -File -Recurse -Force | ForEach-Object {
        'LSTM_MPC_DWA/' + $_.FullName.Substring($packageRoot.Length).TrimStart('\').Replace('\', '/')
    })

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $resolvedStageRoot = [System.IO.Path]::GetFullPath($stageRoot).TrimEnd('\') + '\'
    $archive = [System.IO.Compression.ZipFile]::Open($pendingZip, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in Get-ChildItem -LiteralPath $stageRoot -File -Recurse -Force | Sort-Object FullName) {
            $resolvedFile = [System.IO.Path]::GetFullPath($file.FullName)
            if (-not $resolvedFile.StartsWith($resolvedStageRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw "Refusing to archive a file outside the staging directory: $resolvedFile"
            }
            $entryName = $resolvedFile.Substring($resolvedStageRoot.Length).Replace('\', '/')
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive, $resolvedFile, $entryName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    }
    finally { $archive.Dispose() }

    $pendingZipBytes = (Get-Item -LiteralPath $pendingZip).Length
    if ($pendingZipBytes -gt (95MB)) {
        throw "The v13 archive is $pendingZipBytes bytes, above the 95 MiB GitHub-ready size guard."
    }

    $zip = [System.IO.Compression.ZipFile]::OpenRead($pendingZip)
    try {
        $requiredEntries = @(
            'LSTM_MPC_DWA/README_reproducibility.md',
            'LSTM_MPC_DWA/SHA256SUMS.txt', 'LSTM_MPC_DWA/PACKAGE_CONTENTS.txt',
            'LSTM_MPC_DWA/OMITTED_ARTIFACTS_SHA256.csv',
            'LSTM_MPC_DWA/paper/DOCUMENT_INDEX.md',
            "LSTM_MPC_DWA/$revisionZipPath/04_review/v13_final_submission_audit_20261020.md",
            "LSTM_MPC_DWA/$revisionZipPath/04_review/reference_verification_v13.md",
            "LSTM_MPC_DWA/$revisionZipPath/qa/historical_scene2_route_endpoint_audit.json",
            "LSTM_MPC_DWA/$revisionZipPath/qa/seven_method_route_endpoint_audit.json",
            "LSTM_MPC_DWA/$revisionZipPath/qa/seven_method_figure_collision_audit.json",
            "LSTM_MPC_DWA/$revisionZipPath/qa/seven_method_route_endpoint_audit_scene72_seed2.json",
            "LSTM_MPC_DWA/$revisionZipPath/qa/seven_method_figure_collision_audit_scene72_seed2.json",
            "LSTM_MPC_DWA/$revisionZipPath/qa/route_comparison_integrated_five_method_scene72_seed2_singlecol.collision-audit.json",
            "LSTM_MPC_DWA/$revisionZipPath/qa/route_comparison_seven_method_scene72_seed2_si.collision-audit.json",
            "LSTM_MPC_DWA/$revisionZipPath/qa/seven_method_route_endpoint_audit_scene79_seed2.json",
            "LSTM_MPC_DWA/$revisionZipPath/qa/seven_method_figure_collision_audit_scene79_seed2.json",
            "LSTM_MPC_DWA/$revisionZipPath/scripts/export_v13_route_example_from_heldout.m",
            "LSTM_MPC_DWA/$revisionZipPath/scripts/generate_seven_method_route_figure.py",
            "LSTM_MPC_DWA/$revisionZipPath/scripts/compile_final.ps1",
            "LSTM_MPC_DWA/$revisionZipPath/scripts/build_reproducibility_package.ps1",
            "LSTM_MPC_DWA/$revisionZipPath/04_review/v13_route_illustration_amendment_20261016.md",
            "LSTM_MPC_DWA/$revisionZipPath/qa/confirmatory_route_figure_data/obstacle_tracks.csv",
            "LSTM_MPC_DWA/$revisionZipPath/qa/confirmatory_route_figure_data/route_cv.csv",
            "LSTM_MPC_DWA/$revisionZipPath/qa/confirmatory_route_figure_data/route_kalman.csv",
            "LSTM_MPC_DWA/$revisionZipPath/qa/confirmatory_route_figure_data/route_lstm_dwa_only.csv",
            "LSTM_MPC_DWA/$revisionZipPath/qa/confirmatory_route_figure_data/route_lstm_mpc_only.csv",
            "LSTM_MPC_DWA/$revisionZipPath/qa/confirmatory_route_figure_data/route_lstm.csv",
            "LSTM_MPC_DWA/$revisionZipPath/qa/confirmatory_route_figure_data/route_static.csv",
            "LSTM_MPC_DWA/$revisionZipPath/qa/confirmatory_route_figure_data/route_status.csv",
            "LSTM_MPC_DWA/$revisionZipPath/qa/confirmatory_route_figure_data/start_goal.csv",
            "LSTM_MPC_DWA/$revisionZipPath/scripts/export_confirmatory_route_data.m",
            'LSTM_MPC_DWA/CASADI_3.8.0_SHA256.csv',
            "LSTM_MPC_DWA/$casadiArchiveRelativePath/README.md",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/main.pdf",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/main.tex",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/algorithm_main_pseudocode.pdf",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/integrated_3s_outcomes_main.pdf",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/route_comparison_integrated_five_method_scene72_seed2_singlecol.pdf",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/route_comparison_seven_method_scene72_seed2.pdf",
            "LSTM_MPC_DWA/$revisionZipPath/04_review/v13_final_submission_audit_20261020.md",
            "LSTM_MPC_DWA/$revisionZipPath/04_review/publication_assessment_v13_20261017.md",
            "LSTM_MPC_DWA/$revisionZipPath/qa/algorithm_main_pseudocode.collision-audit.json",
            "LSTM_MPC_DWA/$revisionZipPath/qa/integrated_3s_outcomes_main.collision-audit.json",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/route_comparison_seven_method.pdf",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/route_comparison_five_method_scene404_seed2.pdf",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/route_comparison_five_method_scene404_seed2.svg",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/route_comparison_five_method_scene404_seed2.png",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/route_comparison_five_method_scene404_seed2.tiff",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/route_comparison_seven_method_scene72_seed2.pdf",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/shared_forecast_pseudocode_algorithm_s1.pdf",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/shared_forecast_pseudocode_algorithm_s1.svg",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/shared_forecast_pseudocode_algorithm_s1.png",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/shared_forecast_pseudocode_algorithm_s1.tiff",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/route_comparison_seven_method_scene79_seed2.pdf",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/route_comparison_seven_method_scene79_seed2.svg",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/route_comparison_seven_method_scene79_seed2.png",
            "LSTM_MPC_DWA/$revisionZipPath/02_source/figures/route_comparison_seven_method_scene79_seed2.tiff",
            "LSTM_MPC_DWA/$revisionZipPath/03_bilingual/paper.md",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/supplementary_methods.pdf",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/supplementary_methods.tex",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/confirmatory_raw.csv",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/confirmatory_method_summary.csv",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/confirmatory_cluster_bootstrap.csv",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/confirmatory_scene_cluster_means.csv",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/confirmatory_run_audit.csv",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/scenario_manifest.csv",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/scene_generation_specification.md",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/paired_scene_outcome_counts.csv",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/confirmatory_experiment_protocol.md",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/five_method_run_audit.csv",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/five_method_summary.csv",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/five_method_paired_bootstrap.csv",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/five_method_absolute_bootstrap.csv",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/five_method_terminal_outcomes.csv",
            "LSTM_MPC_DWA/$revisionZipPath/04_review/v13_final_submission_audit_20261016_forecast_update.md",
            "LSTM_MPC_DWA/$revisionZipPath/04_review/v13_final_submission_audit_20261016_final.md",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/figures/route_comparison_seven_method.pdf",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/figures/route_comparison_seven_method_scene72_seed2.pdf",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/figures/route_comparison_seven_method_scene72_seed2.svg",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/figures/route_comparison_seven_method_scene72_seed2.png",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/figures/route_comparison_seven_method_scene72_seed2.tiff",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/figures/shared_forecast_pseudocode_algorithm_s1.pdf",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/figures/shared_forecast_pseudocode_algorithm_s1.svg",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/figures/shared_forecast_pseudocode_algorithm_s1.png",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/figures/shared_forecast_pseudocode_algorithm_s1.tiff",
            "LSTM_MPC_DWA/$revisionZipPath/scripts/generate_shared_forecast_pseudocode.py",
            "LSTM_MPC_DWA/$revisionZipPath/03_supplementary/shared_lstm_random12_revised.csv",
            "LSTM_MPC_DWA/$revisionZipPath/04_review/seven_method_100scene_exploratory_amendment_20261015.md",
            "LSTM_MPC_DWA/$stage1ArchivePath/pooled_development_recovery_manifest.mat",
            "LSTM_MPC_DWA/$stage1ArchivePath/pooled_episode_sha256.csv",
            "LSTM_MPC_DWA/$heldoutArchivePath/heldout_scenario_bank.mat",
            "LSTM_MPC_DWA/$heldoutArchivePath/heldout_trajectories.mat",
            "LSTM_MPC_DWA/$heldoutArchivePath/heldout_run_manifest.mat",
            "LSTM_MPC_DWA/$heldoutArchivePath/heldout_package_manifest.json",
            "LSTM_MPC_DWA/$heldoutArchivePath/output_hash_manifest.csv",
            "LSTM_MPC_DWA/$heldoutArchivePath/heldout_invocation_log.csv",
            "LSTM_MPC_DWA/$heldoutArchivePath/analysis/seven_method_summary.csv",
            "LSTM_MPC_DWA/$heldoutArchivePath/analysis/six_paired_max_t_contrasts.csv",
            "LSTM_MPC_DWA/$heldoutArchivePath/analysis/heldout_analysis.mat",
            "LSTM_MPC_DWA/$heldoutArchivePath/analysis/analysis_hash_manifest.csv",
            "LSTM_MPC_DWA/$heldoutArchivePath/route_example/start_goal.csv",
            "LSTM_MPC_DWA/$heldoutArchivePath/route_example/obstacle_tracks.csv",
            "LSTM_MPC_DWA/$heldoutArchivePath/route_example/route_status.csv"
        )
        foreach ($relativePath in $referenceBundleAllowlist) {
            $requiredEntries += 'LSTM_MPC_DWA/results/' + $relativePath.Replace('\', '/')
        }
        foreach ($name in @(
            'selection_audit.json', 'start_goal.csv', 'route_status.csv',
            'trajectory_standalone_dwa_cv.csv', 'trajectory_standalone_mpc_cv.csv',
            'trajectory_cv.csv', 'trajectory_lstm_mpc_cv_dwa.csv',
            'trajectory_cv_mpc_lstm_dwa.csv', 'trajectory_lstm.csv', 'trajectory_static.csv'
        )) {
            $requiredEntries += "LSTM_MPC_DWA/$revisionZipPath/qa/route_example_scene79_seed2/$name"
            $requiredEntries += "LSTM_MPC_DWA/$revisionZipPath/qa/route_example_scene72_seed2/$name"
        }
        foreach ($relativePath in ($stage1SourceFiles + $presentOptionalReferenceBundles)) {
            $requiredEntries += 'LSTM_MPC_DWA/results/' + $relativePath.Replace('\', '/')
        }
        $requiredEntries += 'LSTM_MPC_DWA/results/emergency_revision/fixed_scenes_20261005_030440/fixed_scenes_revised.csv'
        foreach ($name in $stage1Files) {
            $requiredEntries += "LSTM_MPC_DWA/$stage1ArchivePath/" + $name.Replace('\', '/')
        }
        foreach ($name in $heldoutFiles) {
            $requiredEntries += "LSTM_MPC_DWA/$heldoutArchivePath/" + $name.Replace('\', '/')
        }
        foreach ($name in $heldoutAnalysisFiles) {
            $requiredEntries += "LSTM_MPC_DWA/$heldoutArchivePath/analysis/" + $name.Replace('\', '/')
        }
        foreach ($name in $heldoutRouteFiles) {
            $requiredEntries += "LSTM_MPC_DWA/$heldoutArchivePath/route_example/" + $name.Replace('\', '/')
        }
        foreach ($method in @('standalone_dwa_cv', 'standalone_mpc_cv', 'cv', `
            'lstm_mpc_cv_dwa', 'cv_mpc_lstm_dwa', 'lstm', 'static')) {
            $requiredEntries += "LSTM_MPC_DWA/$heldoutArchivePath/route_example/trajectory_$method.csv"
        }
        foreach ($entryName in $requiredEntries) {
            if (-not $zip.GetEntry($entryName)) { throw "Required v13 package entry is missing: $entryName" }
        }
        $actualArchiveEntries = @($zip.Entries | ForEach-Object FullName)
        Assert-ExactNameSet -Expected $expectedArchiveEntries -Actual $actualArchiveEntries `
            -Description 'ZIP entry inventory'
        $zipEntryCount = $zip.Entries.Count
    }
    finally { $zip.Dispose() }

    $timestamp = (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N')
    $previousZipPath = Join-Path $supplementRoot "reproducibility_package_previous_$timestamp.zip"
    $previousZipHashPath = Join-Path $supplementRoot "reproducibility_package_previous_$timestamp.zip.sha256"
    $previousDeliveryManifestPath = Join-Path $supplementRoot "final_delivery_SHA256_previous_$timestamp.txt"
    Assert-Unlocked -LockPath (Join-Path $stage1Root '.pooled_development_lock') -StageName 'Stage 1 pooled-weight calibration'
    Assert-Unlocked -LockPath (Join-Path $heldoutRoot '.heldout_runner_lock') -StageName '100-scene seven-method evaluation'
    if (Test-Path -LiteralPath $zipPath) {
        Move-Item -LiteralPath $zipPath -Destination $previousZipPath
    }
    if (Test-Path -LiteralPath $zipHashPath) {
        Move-Item -LiteralPath $zipHashPath -Destination $previousZipHashPath
    }
    Move-Item -LiteralPath $pendingZip -Destination $zipPath
    $zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    [System.IO.File]::WriteAllText($zipHashPath, "$zipHash  reproducibility_package.zip`n", [System.Text.Encoding]::ASCII)

    # Hash top-level deliverables and explicitly confirmed reader assets.
    $deliveryRelativePaths += $confirmedFigureAllowlist | ForEach-Object { $_.Replace('\', '/') }
    $deliveryRelativePaths += $confirmedBilingualAssetAllowlist | ForEach-Object { $_.Replace('\', '/') }
    $deliveryRelativePaths += $projectDocumentAllowlist | ForEach-Object {
        '../../../' + $_
    }
    $deliveryRelativePaths = @($deliveryRelativePaths | Sort-Object -Unique)
    $deliveryManifestLines = @(
        '# Independent SHA-256 manifest for final v13 delivery artifacts.',
        '# Paths are relative to the 13_final_submission directory; this manifest excludes itself.'
    )
    foreach ($relativePath in $deliveryRelativePaths) {
        $normalized = $relativePath.Replace('/', '\')
        $filePath = [System.IO.Path]::GetFullPath((Join-Path $revisionRoot $normalized))
        if ($relativePath -eq '../../../DOCUMENT_INDEX.md') {
            Assert-PathWithin -Path $filePath -Root $projectDocumentRoot -Purpose 'paper index delivery hash'
        }
        else {
            Assert-PathWithin -Path $filePath -Root $revisionRoot -Purpose 'delivery hash'
        }
        Assert-RequiredFile -Path $filePath
        $artifactHash = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash.ToLowerInvariant()
        $deliveryManifestLines += "$artifactHash  $relativePath"
    }
    [System.IO.File]::WriteAllLines($pendingDeliveryManifestPath, `
        [string[]]$deliveryManifestLines, [System.Text.Encoding]::ASCII)
    if (Test-Path -LiteralPath $deliveryManifestPath) {
        Move-Item -LiteralPath $deliveryManifestPath -Destination $previousDeliveryManifestPath
    }
    Move-Item -LiteralPath $pendingDeliveryManifestPath -Destination $deliveryManifestPath

    $finalZipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $finalZipSidecar = (Get-Content -LiteralPath $zipHashPath -Raw).Trim()
    if ($finalZipHash -ne $zipHash -or
        -not $finalZipSidecar.StartsWith($zipHash, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Final archive or its SHA-256 sidecar failed the post-move verification.'
    }
    # Retain rollback files until the replacement archive and external manifest
    # have both been written and checked; then remove only this run's generated
    # duplicate files to avoid accumulating large archives on the system drive.
    foreach ($generatedBackup in @($previousZipPath, $previousZipHashPath, $previousDeliveryManifestPath)) {
        if (Test-Path -LiteralPath $generatedBackup -PathType Leaf) {
            Assert-PathWithin -Path $generatedBackup -Root $supplementRoot -Purpose 'verified generated-backup cleanup'
            Remove-Item -LiteralPath $generatedBackup -Force
        }
    }

    Write-Output "Created v13 reproducibility package: $zipPath"
    Write-Output "Package SHA-256: $zipHash"
    Write-Output "Included entries: $zipEntryCount"
    Write-Output "Independent delivery SHA-256 manifest: $deliveryManifestPath"
}
finally {
    if (Test-Path -LiteralPath $stageRoot -PathType Container) {
        Assert-PathWithin -Path $stageRoot -Root $supplementRoot -Purpose 'temporary staging cleanup'
        Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
    if (Test-Path -LiteralPath $pendingZip -PathType Leaf) { Remove-Item -LiteralPath $pendingZip -Force }
    if (Test-Path -LiteralPath $pendingDeliveryManifestPath -PathType Leaf) {
        Remove-Item -LiteralPath $pendingDeliveryManifestPath -Force
    }
}
