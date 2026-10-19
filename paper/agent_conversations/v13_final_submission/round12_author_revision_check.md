# Round 12 author revision check

This is the author-side check of the final revision against the three frozen Round 12 reports. The reports themselves are preserved unchanged. No simulation was rerun and no primary outcome was altered during this revision.

| Review item | Revision made | Final status / evidence boundary |
|---|---|---|
| R1-M1, archive absent from the review packet | The supplementary directory contains `reproducibility_package.zip` and its `.sha256` sidecar; the build script includes final manuscript, figures, reader, supplement, protocol clarification and reviewer packet. The README says this is a local companion with no public DOI. | Addressed for the local revision bundle. An external submission must attach the archive or provide a persistent repository location. |
| R1-m1, exact observation-history span | Main text and Supplementary Methods S2/Table S1 state that ten observations sampled every 0.1 s span 0.9 s first-to-last. | Addressed; the experiment and its outcomes are unchanged. |
| R2-M1, novelty and relation to prior work | Introduction now identifies dual-mode DWA, Social-LSTM, learned human forecasts in MPC, uncertainty-aware MPC, and LSTM--DWA for UUVs, then states the UAV forecast-sharing interface and matched ablation precisely. | Addressed at the evidence-supported scope; no broad priority or general-planner claim is made. |
| R2-M2, primary observation model | Main text, Supplementary Methods S4 and `confirmatory_protocol_clarification.md` state current-time simulator observations with zero added noise and zero delay, distinguishing primary runs from training augmentation and the S5 diagnostic. | Addressed from the executed configuration; frozen protocol and outcomes remain unchanged. |
| R2-m1, condition label clarity | Figure 3 identifies “LSTM to DWA only / MPC: latest position” and “Shared LSTM / MPC: 3-s LSTM forecast”; caption states that both conditions use the integrated planner and DWA receives the same forecast. | Addressed. |
| R3-m1, paired versus per-condition intervals | Figure 3(a) labels the whiskers as per-condition scene-cluster intervals; panel (b) contains a separate paired mean-gain and 95% interval callout. The caption states the role of each interval. | Addressed; final-size collision and font audits pass. |
| R2-M2/R3-m2, reproducibility limits | Run records and paired scene outcomes remain supplied separately. The local reproduction archive and matching checksum are included in the revision directory and rebuilt after the manuscript changes. | The archive supports local reconstruction. No public deposit, DOI, real-flight validation, or unseen-family evaluation is claimed. |
| Author request: make primary data easier to read | The main paper uses a two-panel comparison: absolute arrival rates and a three-category matched-scene outcome distribution (72 shared-favored, 404 tied, 24 DWA-only-favored). The paired CI is explicit; the supplementary CSV preserves the exact scene counts, and Table S5 retains run-level outcomes. | The graph supplements rather than replaces the auditable numeric records. |

## Final consistency checks

- The compiled manuscript is four pages; the supplementary methods are eleven pages.
- Four display-equation blocks remain in the manuscript; no inline dollar-delimited formulas remain.
- The primary estimate and denominator remain 936/1,500 (62.4%) versus 836/1,500 (55.7%), paired difference +6.7 percentage points (95% CI +4.2 to +9.2).
- The historical four-method 3D route figure and the problem-scene schematic retain their protected SHA-256 values. CV/Kalman and earlier multi-method results remain separate from the 500-scene primary test.
- The bilingual reader and source map are synchronized to the edited abstract, literature framing, observation span, primary sensor condition, discussion and Figure 3 caption.
- The result supports average goal-arrival performance only within the tested generated simulation distribution. It does not rank the method against standalone MPC or DWA or establish physical-flight safety.
