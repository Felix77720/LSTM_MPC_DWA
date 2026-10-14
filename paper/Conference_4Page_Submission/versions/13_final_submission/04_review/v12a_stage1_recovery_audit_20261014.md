# V12a Stage-1 recovery audit note — 2026-10-14

## Audit status

Recovery execution completed on 2026-10-14. The guarded preflight matched the frozen runtime inventory and provenance, opened and validated all 4,320 existing MAT checkpoints, and verified exact 6 × 5 × 48 × 3 filename-key coverage. Four local workers then independently re-opened and revalidated the same records before aggregation. The runner and worker contain no simulation, retry, RNG, or new-episode path; `newEpisodeRecordCount=0` and `newEpisodeRecordsCreated=false` are recorded in the separate recovery manifest. No historical/raw checkpoint was modified.

During preflight, MATLAB Check Code and execution exposed three defects in the newly written recovery utility: invalid escaped quote syntax, a runtime-dependency inventory return-arity mismatch, and row/column implicit expansion in the exact-coverage assertion. After those were corrected, MATLAB's parallel transparency rules rejected `which` inside `spmd`; worker resolution was changed to a direct helper self-report using `mfilename` and a per-worker SHA-256 check. Each failure occurred before derived output creation; the final recovery passed. The original frozen runner and the 4,320 checkpoint MAT files remained unchanged.

Post-run verification found all eight files listed in `pooled_calibration_artifact_sha256.csv` with matching SHA-256 values (0 mismatches), the named Stage-1 manifest sidecar matched, and the Stage-2 preflight returned `Ready=1`. The pooled CSV contains 4,320 rows. The selected development vector was candidate `smoothness`, `[0.15, 0.15, 0.15, 0.55]`, with pooled safe-goal score 0.8042; this development score is not a held-out superiority claim. Stage 1's per-method development scores were `[0.8958, 0.7431, 0.8194, 0.8958, 0.6667]` for shared LSTM, CV-coupled MPC-DWA, LSTM-to-MPC-only, LSTM-to-DWA-only, and reconstructed latest-position hold, respectively.

| Independent audit field | Static value |
|---|---|
| Recovery mode | Load, validate, then aggregate existing checkpoints only |
| Expected episode key count | 4,320 |
| New/simulated episode records | 0 |
| Frozen runner modified | No |
| Existing checkpoint or raw data modified | No |
| MATLAB / pool / simulation / aggregate execution | Check Code + 4-worker read-only validation and aggregate; no simulator invoked |

The runtime recovery manifest separately records `newEpisodeRecordCount=0` and `newEpisodeRecordsCreated=false`; those audit fields are not added to, or covered by, the preserved provenance signature.

## Code and frozen-runner SHA-256

Hashes below were computed read-only after the final static patch. The recovery entry and worker are dedicated files; their names match their MATLAB function names.

| File | SHA-256 |
|---|---|
| `scripts/run_v12a_pooled_weight_development.m` (frozen runner) | `e0a19a2495ef7067d6d98953640d737b4bd21bf94613aa9ff52e044118a2419b` |
| `scripts/recover_v12a_pooled_weight_development.m` (recovery entry; MATLAB syntax, return-arity, row-orientation and worker-identity fixes after Check Code/preflight) | `f28be64e9cc29b581e7224ed883ae43b08475bd2b66fcd482ab198554f0e7034` |
| `scripts/recover_existing_pooled_episode.m` (read-only worker; direct per-worker identity self-check) | `573d3273e3cd4b1460b27290f3073f41d7b7d5d5cc4b102c5852187c38b0fa6c` |

## Frozen runtime dependency snapshot

The following are current-workspace source-file SHA-256 values. They are a static snapshot, not a claim that the saved checkpoint provenance has already been opened or matched. At recovery time the entry point independently recomputes the complete source inventory, baseline MATLAB source inventory, and recursive CasADi tree and aborts on any mismatch with the checkpoint manifest before pool creation.

| Dependency path relative to `LSTM_MPC_DWA/` | SHA-256 |
|---|---|
| `config_LSTM.m` | `e6eb255398690fa982462ef53b36dc8ba754e6b613382e33505373fdb0aaaead` |
| `computeTrust_dynamic.m` | `9222503e990a74381b1971f672f071715704262ba72a563e219353e8b6f5c230` |
| `features_from_traj.m` | `8d79b15c783dbcdcacd0b7690fc436e837860cf61cafb91c11359b82da492de9` |
| `generate_obstacle_trajectory.m` | `d4dee66e330ff5cf0ce31315aab0ff511484827a9ab8dfcf25db32faffdac294` |
| `MPC_UAV_dynamic_cached.m` | `aa48c14f931d9913351945a9aa67ff8e179cba6b66ee7c0b06fc78e32f4edcdc` |
| `predict_obstacle_traj.m` | `2b75774e7817c50f446d0bc1470f40c5dc207d02c1417adc5fdf8bd5a13366e1` |
| `prepare_observation_stream.m` | `24410b121b2a34a28a09614fc9ac6af3164057af68091055e7ef1eae92175ce8` |
| `paper/Conference_4Page_Submission/versions/13_final_submission/scripts/run_v12a_pooled_weight_development.m` | `e0a19a2495ef7067d6d98953640d737b4bd21bf94613aa9ff52e044118a2419b` |
| `paper/Conference_4Page_Submission/versions/13_final_submission/scripts/simulate_dynamic_v12a_timed.m` | `4d6452f0d3f682c8aca06d9b4d39da2f9bc91a862ef014323290dab9d2049e5f` |
| `paper/Conference_4Page_Submission/versions/13_final_submission/scripts/simulate_standalone_controller_v12a_timed.m` | `aff149fda4e9df9e1b7be3768eca0a9accb1d362daffd84828d948f06dd0e2a9` |
| `MPC_DWA_Fusion/computeTrust.m` | `fa9c45055cbb04ff0ee16b9bcd53580fb4b794e193f06b120cb67d13b3ecdf8a` |
| `MPC_DWA_Fusion/config_UAV.m` | `29abaddd36ad56c151b957e6796d487d275774fe46a70c73dd400d47d3a2d9f2` |
| `MPC_DWA_Fusion/dynamicWeights.m` | `6c79a893c550c148d77eb2a7f33142c74c80809ed2692d68047c35a93f122f37` |
| `MPC_DWA_Fusion/MPC_DWA_main.m` | `2455a2e9a69c5ae4021028f503b2f5eb9e43843fdaaf1a3eb61c99f4bed0cd6d` |
| `MPC_DWA_Fusion/MPC_UAV.m` | `7464dea13c4d1338b859480008ac55f43a5a5a94d780367e61afae15a678712b` |
| `MPC_DWA_Fusion/referenceScores3D.m` | `53e7f8d21c5dd3947b6662fffc80758d57b108e4cd2547210a5d207561ef4c06` |
| `MPC_DWA_Fusion/sampleIntelligent3D.m` | `9aee8b6066f278c43c5b0b44a54609af3df063b03e0ba0cb894199e3217a78b4` |
| `MPC_DWA_Fusion/test_MPC.m` | `bfda6819c540d8c81515447b9782a822e4315205a8f67ecca2dcc3ba71d2fc5e` |
| `MPC_DWA_Fusion/UAV_DWA_3D.m` | `dd2bd2fcc9d7253e9ad0b9f2cd3b1d073b22fd0b43a8f3621d875fd0c4fdb2fc` |
| `MPC_DWA_Fusion/UAV_dynamics_sym.m` | `771e3bbcc1d3bdcea19bb68aaaec37e5e40a6bc9fe0927214c26e9fac5add92c` |
| `MPC_DWA_Fusion/UAV_model.m` | `b2029e64b3e8472c688353865624447f455998ef8478e0083f6ba6cc77c3dca0` |

Recursive CasADi dependency snapshot: `MPC_DWA_Fusion/third_party/casadi-3.8.0-windows64-matlab2018b`, 2,744 files, tree SHA-256 `60e6815aec37854de80a912101c3e306ad97266e6b6ea7063d519fcd408c6fde`. The current 21-source-plus-CasADi runtime inventory snapshot SHA-256 is `c50b2b9f297adc3f55686e55b6ab84e70b87783359a103c37e6d405272b49074`; it must equal the saved manifest's runtime inventory digest during preflight or recovery stops.

## Safety gates and static behavior

Before creating a pool or writing any output, the recovery entry checks the frozen inputs and dependency hashes, recomputes the provenance signature and saved original worker-path audit, verifies the expected 4,320-key design, validates every checkpoint through the guarded helper, compares file and route hashes, enforces complete status and exact row labels/terminal classifications, verifies exact key coverage, and rejects locks or any existing final output. The complete-manifest inventory is also revalidated when present.

The helper checks that its resolved absolute path and SHA-256 match the recovery entry's expected values, checks the checkpoint basename and `.mat` extension, hashes before and after load, then only loads and validates the existing `jobEnvelope`. It recomputes path length and swept minimum clearance from the stored trajectory and fixed obstacle tracks, then checks the row metrics, labels, terminal fields, and classification flags against those values. It contains no simulator invocation, retry loop, RNG operation, or checkpoint write. The entry explicitly adds the helper directory to workers, checks every worker's resolved absolute helper path and hash, and the `parfor` body calls this guarded helper directly; results are re-hashed against pre-pool values before aggregation. All file SHA reads use binary mode (`'rb'`); text hashes use `uint8(char(text))`.

## Manifest/signature boundary

The finalization copies the original manifest struct and changes only completion metadata: `status`, `completedUTC`, `episodeRecordCount`, `unresolvedFailureCount`, `episodeInventory`, and `episodeInventorySHA256`. The existing `provenance` struct and `provenanceSignature` are preserved unchanged. The named manifest sidecar hashes the finalized original manifest MAT file, `selection.manifestSHA256` points to that hash, and `pooled_development_bundle.mat` carries the exact same finalized manifest struct. Recovery-specific fields are kept in a separate recovery manifest and do not replace or mutate the provenance signature.
