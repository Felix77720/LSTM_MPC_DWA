# Final route-illustration amendment — 2026-10-16

This note documents a post hoc change to the illustrative route shown in the main paper. It does not amend an experimental arm, rerun a simulation, or change any numerical result.

## Reason and selection

The author requested that the route comparison make the proposed method's outcome easy to see, preferably using a matched case in which only the proposed shared-LSTM MPC–DWA reaches the goal. The original figure contract had prospectively fixed scene 1, sampling seed 1, before the exploratory run. To answer the new presentation request, the saved outcomes for all 300 matched scene–seed sets in the completed 100-scene evaluation were screened once using the explicit rule: shared LSTM has a collision-free goal arrival, and each of the other six methods has `GoalArrival = 0`.

Exactly one set met that rule: scene 79, sampling seed 2. The selected records show one shared-LSTM safe arrival, one baseline run with swept contact, and five collision-free non-arrivals. The selection is therefore an outcome-selected illustration and is labelled post hoc in the main caption, bilingual reader, and supplement. It is not population evidence and is not used to support an aggregate or superiority claim. All aggregate comparisons continue to use the complete evaluation as reported in the tables and results text.

## Path integrity and visual limitation

The figure uses every saved XYZ state for all seven methods through the recorded terminal state. It does not smooth, curve-fit, resample, interpolate, omit, or extend a route. Small state markers are placed only on saved samples to make the short paths easier to follow; the collision-run endpoint below the nominal workspace floor is retained in the plot limits. Start, goal, and terminal symbols are reduced so that they obscure fewer route segments. The scenario schematic remains a separate figure; obstacle geometry is not overlaid on the route comparison.

Several comparator runs stopped after only 1.6–3.4 seconds and consequently have short, nearly straight recorded paths. This is a property of the saved simulation outcomes, not a plotting choice. No different case satisfies the stated “only shared LSTM reaches” criterion in the 300 matched sets. The original prospectively fixed scene-1/seed-1 route export and prior figure are retained in the source results and the audit backup; the new illustration does not replace or discard that evidence.

## Reproducibility

The saved route CSVs, start/goal coordinates, status table, and selection audit are under `qa/route_example_scene79_seed2/`. `scripts/export_v13_route_example_from_heldout.m` re-derives and verifies this export from the existing raw outcome table, trajectory archive, and scenario bank; it does not call a simulator. `scripts/generate_seven_method_route_figure.py` generates the PDF, SVG, PNG, TIFF and endpoint audit from these saved positions. The source map, bilingual captions, SI description, package allowlist, and checksums are updated with this amendment.

## Final visibility and PDF check

The final visual pass increased route stroke and saved-state marker size, changed the start marker to neutral charcoal so it cannot be mistaken for the green coupled-CV method, and removed pane fills while retaining the 3D grid. These are display-only changes. All trajectory CSV values, coordinates, sampling times, terminal positions, statuses and aggregate outcomes remain unchanged. Because the unique-arrival rule yields only one case, the five short comparator traces cannot be replaced by more curved routes without relaxing the requested outcome criterion. The coupled-CV and LSTM-to-MPC traces stop within centimetres of one another, so they necessarily overlap in a shared-coordinate plot; no artificial spatial separation was applied.

After this edit, the figure-source validator reported 21 PASS, 0 WARN and 0 FAIL; the PDF glyph-size floor was 7 pt; the rendered collision audit found 0 FAIL and 0 WARN. The canonical in-place build produced a four-page Letter main paper and an 18-page Letter supplement. All four main pages and SI pages 17–18 were freshly rendered and inspected; no clipping, overlap, missing caption or formula collision was observed. Full results, including the standalone MPC-CV advantage in the separate exploratory comparison, remain in the manuscript tables and are not inferred from this selected example.
