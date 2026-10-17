"""Render the preselected seven-arm v12a route example from saved records only.

The six forecast/controller arms are shown with the static latest-position
reconstruction. Routes use only their saved UAV states and stop at their saved
terminal points; no route is smoothed, resampled, interpolated, or extended.
"""
from __future__ import annotations

import csv
import json
import re
import sys
from pathlib import Path

import matplotlib as mpl
mpl.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

SCRIPT_DIR = Path(__file__).resolve().parent
REVISION = SCRIPT_DIR.parent
PROJECT = SCRIPT_DIR.parents[4]
FIGURE_SKILL_SCRIPTS = PROJECT.parent / ".agents" / "skills" / "nature-figure" / "scripts"
sys.path.insert(0, str(FIGURE_SKILL_SCRIPTS))
from audit_panel_alignment import require_matplotlib_panel_alignment

RUN_DIR = REVISION / "qa" / "route_example_scene72_seed2"
FIGURES = REVISION / "02_source" / "figures"
QA = REVISION / "qa"

METHODS = [
    ("standalone_dwa_cv", "Standalone DWA-CV", "#E69F00", "-"),
    ("standalone_mpc_cv", "Standalone MPC-CV", "#0072B2", "--"),
    ("cv", "Coupled MPC-DWA-CV", "#009E73", "-."),
    ("lstm_mpc_cv_dwa", "MPC-DWA (LSTM to MPC only)", "#CC79A7", ":"),
    ("cv_mpc_lstm_dwa", "MPC-DWA (LSTM to DWA only)", "#D55E00", (0, (6, 2, 1, 2))),
    ("lstm", "MPC-DWA (shared LSTM)", "#332288", (0, (3, 1, 1, 1))),
    ("static", "MPC-DWA: position hold", "#6F7780", (0, (1, 1))),
]
METHOD_MARKERS = {
    "standalone_dwa_cv": "o",
    "standalone_mpc_cv": "s",
    "cv": "^",
    "lstm_mpc_cv_dwa": "D",
    "cv_mpc_lstm_dwa": "v",
    "lstm": "P",
    "static": "X",
}
STATUS_METHOD_LABELS = {
    "standalone_dwa_cv": "Standalone DWA (CV)",
    "standalone_mpc_cv": "Standalone MPC (CV)",
    "cv": "Coupled MPC-DWA (CV)",
    "lstm_mpc_cv_dwa": "MPC-DWA (LSTM to MPC only)",
    "cv_mpc_lstm_dwa": "MPC-DWA (LSTM to DWA only)",
    "lstm": "MPC-DWA (shared LSTM)",
    "static": "Reconstructed MPC-DWA (latest-position hold)",
}

# route_status.csv stores TerminalXYZ_m to six decimal places. The tolerance
# covers that serialization rounding while remaining well below a micrometre.
STATUS_TERMINAL_DECIMALS = 6
STATUS_TERMINAL_TOLERANCE_M = 5.1e-7
START_TOLERANCE_M = 1e-8

mpl.rcParams.update({
    "font.family": "sans-serif",
    "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
    "font.size": 7.0,
    "axes.titlesize": 7.4,
    "axes.labelsize": 6.8,
    "xtick.labelsize": 6.0,
    "ytick.labelsize": 6.0,
    "legend.fontsize": 6.0,
    "pdf.fonttype": 42,
    "ps.fonttype": 42,
    "svg.fonttype": "none",
    "savefig.facecolor": "white",
})


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def parse_bool(value: str, field: str, method_key: str) -> bool:
    normalized = value.strip().lower()
    if normalized in {"true", "1"}:
        return True
    if normalized in {"false", "0"}:
        return False
    raise ValueError(f"Invalid {field} value for {method_key}: {value!r}.")


def normalize_label(value: str) -> str:
    """Compare display en dashes with ASCII-safe CSV labels consistently."""
    return " ".join(value.replace("–", "-").replace("—", "-").split())


def main() -> None:
    run_dir = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else RUN_DIR
    if len(sys.argv) > 2:
        raise SystemExit(
            "Usage: generate_seven_method_route_figure.py [route-export-directory]"
        )
    if not run_dir.is_dir():
        raise FileNotFoundError(f"Route export directory does not exist: {run_dir}")
    selection_path = run_dir / "selection_audit.json"
    if not selection_path.is_file():
        raise FileNotFoundError(f"Selection audit is missing: {selection_path}")
    selection_audit = json.loads(selection_path.read_text(encoding="utf-8"))
    if selection_audit.get("eligible_set_count") != 1:
        raise ValueError("The selected route must be the unique eligible matched set.")
    try:
        selected_scene = int(selection_audit["selected_scene_index"])
        selected_seed = int(selection_audit["sampling_seed"])
    except (KeyError, TypeError, ValueError) as exc:
        raise ValueError("The selection audit lacks an integer scene/seed key.") from exc
    if not 1 <= selected_scene <= 100 or selected_seed not in {1, 2, 3}:
        raise ValueError("The selected scene/seed is outside the frozen 100-scene design.")
    expected_dir = f"route_example_scene{selected_scene}_seed{selected_seed}"
    if run_dir.name != expected_dir:
        raise ValueError(
            f"Selection audit expects {expected_dir}, not route directory {run_dir.name}."
        )

    FIGURES.mkdir(parents=True, exist_ok=True)
    QA.mkdir(parents=True, exist_ok=True)
    start_goal = np.loadtxt(run_dir / "start_goal.csv", delimiter=",").reshape(2, 3)
    if not np.isfinite(start_goal).all():
        raise ValueError("Start/goal export contains non-finite coordinates.")
    start = start_goal[0]
    goal = start_goal[1]

    status_list = read_csv(run_dir / "route_status.csv")
    status_rows = {row["MethodKey"]: row for row in status_list}
    method_keys = [key for key, _, _, _ in METHODS]
    if len(status_rows) != len(status_list):
        raise ValueError("route_status.csv contains duplicate method keys.")
    if set(status_rows) != set(method_keys):
        missing = sorted(set(method_keys) - set(status_rows))
        extra = sorted(set(status_rows) - set(method_keys))
        raise ValueError(f"Unexpected route-status keys; missing={missing}, extra={extra}.")

    obstacle_path = run_dir / "obstacle_tracks.csv"
    obstacle_rows = (np.loadtxt(obstacle_path, delimiter=",")
                     if obstacle_path.is_file() else np.empty((0, 6)))
    if obstacle_rows.size and obstacle_rows.ndim == 1:
        obstacle_rows = obstacle_rows[None, :]
    if obstacle_rows.size and (obstacle_rows.shape[1] < 6
                               or not np.isfinite(obstacle_rows).all()):
        raise ValueError("Obstacle-track export is malformed or non-finite.")
    if obstacle_rows.size and (np.any(obstacle_rows[:, 0] < 1)
            or not np.allclose(obstacle_rows[:, 0], np.rint(obstacle_rows[:, 0]))):
        raise ValueError("Obstacle IDs must be positive integers.")

    # Keep one shared 3-D scene and add orthogonal projections to reveal route
    # separation that a single perspective can hide.
    fig = plt.figure(figsize=(3.42, 3.25), constrained_layout=False)
    grid = fig.add_gridspec(
        2, 2, left=0.09, right=0.985, top=0.94, bottom=0.30,
        wspace=0.32, hspace=0.55)
    ax3d = fig.add_subplot(grid[0, 0], projection="3d")
    ax_xy = fig.add_subplot(grid[0, 1])
    ax_xz = fig.add_subplot(grid[1, 0])
    ax_yz = fig.add_subplot(grid[1, 1])
    axes = (ax3d, ax_xy, ax_xz, ax_yz)
    ax3d.view_init(elev=27, azim=-57)
    ax3d.set_proj_type("ortho")
    ax3d.set_xlim(0, 20)
    ax3d.set_ylim(0, 20)
    # Include the collision-run terminal below z=0 rather than clipping it.
    ax3d.set_zlim(-0.8, 10)
    ax3d.set_box_aspect((2, 2, 1.08))
    ax3d.set_xlabel("x", labelpad=1, fontsize=6.2)
    ax3d.set_ylabel("y", labelpad=1, fontsize=6.2)
    # The adjacent XZ/YZ projections explicitly label z (m); omit this
    # redundant 3-D label so it cannot collide with the neighboring XY y-axis.
    ax3d.set_xticks([0, 10, 20])
    ax3d.set_yticks([0, 10, 20])
    ax3d.set_zticks([0, 5, 10])
    ax3d.tick_params(axis="both", labelsize=5.7, pad=0.5)
    ax3d.zaxis.set_tick_params(labelsize=5.7, pad=0.5)
    for axis in (ax3d.xaxis, ax3d.yaxis, ax3d.zaxis):
        axis.pane.fill = False
        axis._axinfo["grid"]["color"] = (0.80, 0.83, 0.85, 0.60)
        axis._axinfo["grid"]["linewidth"] = 0.45

    projection_specs = (
        (ax_xy, (0, 1), ("x (m)", "y (m)"), "XY plan"),
        (ax_xz, (0, 2), ("x (m)", "z (m)"), "XZ elevation"),
        (ax_yz, (1, 2), ("y (m)", "z (m)"), "YZ elevation"),
    )
    for panel_letter, (axis, coords, labels, title) in zip("bcd", projection_specs):
        axis.set_xlim(0, 20)
        if coords[1] == 2:
            axis.set_ylim(-0.8, 10)
            axis.set_yticks([0, 5, 10])
        else:
            axis.set_ylim(0, 20)
            axis.set_yticks([0, 10, 20])
        axis.set_xlabel(labels[0], labelpad=1.0, fontsize=6.4)
        axis.set_ylabel(labels[1], labelpad=1.0, fontsize=6.4)
        axis.set_xticks([0, 10, 20])
        axis.grid(True, color="#D6DCE1", linewidth=0.45, alpha=0.75)
        axis.tick_params(labelsize=6.0, length=2.0, pad=1.0)
        axis.set_title(title, loc="center", fontsize=6.6, pad=1.2)
        axis.text(0.02, 0.98, panel_letter, transform=axis.transAxes,
                  fontsize=7.0, fontweight="bold", va="top", ha="left")
        for spine in ("top", "right"):
            axis.spines[spine].set_visible(False)
    ax3d.text2D(0.02, 0.98, "a", transform=ax3d.transAxes,
                fontsize=7.0, fontweight="bold", va="top", ha="left")
    ax3d.set_title("3-D perspective", loc="center", fontsize=6.6, pad=1.2)

    handles = []
    endpoint_audit: list[dict[str, object]] = []
    obstacle_audit: list[dict[str, object]] = []
    for obstacle_id in (np.unique(obstacle_rows[:, 0]).astype(int)
                        if obstacle_rows.size else []):
        rows = obstacle_rows[obstacle_rows[:, 0] == obstacle_id]
        times = rows[:, 1]
        radii = rows[:, 5]
        if (len(rows) == 0 or not np.isclose(times[0], 0.0, atol=1e-12)
                or np.any(np.diff(times) <= 0) or np.any(radii <= 0)
                or not np.allclose(radii, radii[0], atol=1e-12, rtol=0)):
            raise ValueError(
                f"Obstacle {obstacle_id} has invalid times or a nonpositive/variable radius.")
        obstacle_audit.append({
            "obstacle_id": int(obstacle_id),
            "radius_m": float(radii[0]),
            "center_track_samples": len(rows),
            "track_start_time_s": float(times[0]),
            "track_end_time_s": float(times[-1]),
            "radius_drawn_in_route_figure": False,
        })

    for key, label, color, linestyle in METHODS:
        trajectory_path = run_dir / f"trajectory_{key}.csv"
        data = np.loadtxt(trajectory_path, delimiter=",")
        if data.ndim == 1:
            data = data[None, :]
        if data.shape[1] < 4:
            raise ValueError(f"Route export for {key} must contain time and XYZ columns.")
        if data.shape[0] == 0 or not np.isfinite(data).all():
            raise ValueError(f"Missing or non-finite recorded route for {key}.")

        route_times = data[:, 0]
        if (not np.isclose(route_times[0], 0.0, atol=1e-12)
                or np.any(np.diff(route_times) <= 0)
                or not np.allclose(np.diff(route_times), 0.1, atol=1e-9, rtol=0)):
            raise ValueError(
                f"Recorded route times for {key} are not the original 0.1-s states.")

        xyz = data[:, 1:4]
        start_delta = xyz[0] - start_goal[0]
        if not np.allclose(xyz[0], start_goal[0], atol=START_TOLERANCE_M, rtol=0):
            raise ValueError(
                f"Route for {key} does not begin at the shared start: "
                f"delta={start_delta.tolist()} m."
            )
        row = status_rows[key]
        expected_label = STATUS_METHOD_LABELS[key]
        if normalize_label(row.get("Method", "")) != normalize_label(expected_label):
            raise ValueError(
                f"Route-status label for {key} differs from the frozen figure label: "
                f"{row.get('Method')!r} != {expected_label!r}.")
        safe = parse_bool(row["SafeGoalArrival"], "SafeGoalArrival", key)
        collision = parse_bool(row["SweptCollision"], "SweptCollision", key)
        if safe and collision:
            raise ValueError(f"SafeGoalArrival conflicts with SweptCollision for {key}.")
        if safe:
            endpoint_category = "collision_free_goal_arrival"
            endpoint_marker = "o"
        elif collision:
            endpoint_category = "swept_collision"
            endpoint_marker = "X"
        else:
            # route_status.csv does not encode stop reason, so this category
            # also includes collision-free maximum-step non-arrivals.
            endpoint_category = "no_collision_goal_not_reached"
            endpoint_marker = "s"
        recorded_steps = int(float(row["Steps"]))
        if float(row["Steps"]) != recorded_steps or len(xyz) != recorded_steps + 1:
            raise ValueError(f"Recorded state count does not match route_status.csv for {key}.")

        try:
            status_terminal = np.array(
                [float(value) for value in row["TerminalXYZ_m"].split(",")], dtype=float)
        except ValueError as exc:
            raise ValueError(f"Invalid TerminalXYZ_m for {key}.") from exc
        if status_terminal.shape != (3,) or not np.isfinite(status_terminal).all():
            raise ValueError(f"TerminalXYZ_m must contain three finite coordinates for {key}.")
        endpoint_delta = xyz[-1] - status_terminal
        if not np.allclose(xyz[-1], status_terminal,
                           atol=STATUS_TERMINAL_TOLERANCE_M, rtol=0):
            raise ValueError(
                f"Plotted terminal point differs from saved status for {key}: "
                f"delta={endpoint_delta.tolist()} m."
            )
        goal_tolerance = float(row["GoalTolerance_m"])
        if not np.isfinite(goal_tolerance) or goal_tolerance <= 0:
            raise ValueError(f"Invalid GoalTolerance_m for {key}.")
        final_goal_distance = float(np.linalg.norm(xyz[-1] - goal))
        if safe != (final_goal_distance <= goal_tolerance and not collision):
            raise ValueError(
                f"Safe-goal status conflicts with the recorded endpoint and "
                f"goal tolerance for {key}: distance={final_goal_distance:.9g} m, "
                f"tolerance={goal_tolerance:.9g} m, collision={collision}."
            )

        # Sparse method-specific markers identify actual saved states, making short terminal paths
        # easier to follow without interpolating or modifying their geometry.
        # A unique marker shape per method also distinguishes overlapping
        # routes in grayscale and where colored traces lie close together.
        state_stride = max(1, int(np.ceil((len(xyz) - 1) / 12)))
        route_marker = METHOD_MARKERS[key]
        shared = key == "lstm"
        line_width = 2.25 if shared else 1.65
        marker_size = 2.6 if shared else 2.3
        ax3d.plot(xyz[:, 0], xyz[:, 1], xyz[:, 2], color=color,
                  linestyle=linestyle, linewidth=line_width, alpha=1.0,
                  marker=route_marker, markersize=marker_size,
                  markerfacecolor="white", markeredgecolor=color,
                  markeredgewidth=0.65, markevery=state_stride, zorder=4)
        for axis, coords in ((ax_xy, (0, 1)), (ax_xz, (0, 2)), (ax_yz, (1, 2))):
            axis.plot(xyz[:, coords[0]], xyz[:, coords[1]], color=color,
                      linestyle=linestyle, linewidth=1.9 if shared else 1.45,
                      marker=route_marker, markersize=marker_size,
                      markerfacecolor="white", markeredgecolor=color,
                      markeredgewidth=0.60, markevery=state_stride, zorder=3)
        for axis, coords in ((ax3d, (0, 1, 2)), (ax_xy, (0, 1)),
                             (ax_xz, (0, 2)), (ax_yz, (1, 2))):
            endpoint = [xyz[-1, i] for i in coords]
            if axis is ax3d:
                axis.scatter(*endpoint, marker=endpoint_marker,
                             s=30 if safe else 31, linewidths=1.0,
                             facecolors="none", edgecolors=color,
                             depthshade=False, zorder=8)
            else:
                axis.scatter(endpoint[0], endpoint[1], marker=endpoint_marker,
                             s=25 if safe else 27, linewidths=0.9,
                             facecolors="none", edgecolors=color, zorder=6)
        display_labels = {
            "standalone_dwa_cv": "DWA-CV",
            "standalone_mpc_cv": "MPC-CV",
            "cv": "Coupled MPC-DWA-CV",
            "lstm_mpc_cv_dwa": "LSTM to MPC only",
            "cv_mpc_lstm_dwa": "LSTM to DWA only",
            "lstm": "Shared LSTM",
            "static": "Latest-position hold",
        }
        handles.append(plt.Line2D([0], [0], color=color, lw=1.8 if shared else 1.5,
                                  linestyle=linestyle, marker=route_marker,
                                  markersize=2.8, markerfacecolor="white",
                                  markeredgecolor=color, markeredgewidth=0.65,
                                  label=display_labels[key]))
        endpoint_audit.append({
            "method_key": key,
            "figure_label": label.replace("\n", " "),
            "route_csv": trajectory_path.name,
            "method_line_style": repr(linestyle),
            "safe_goal_arrival": safe,
            "swept_collision": collision,
            "endpoint_category": endpoint_category,
            "endpoint_marker": endpoint_marker,
            "recorded_steps": recorded_steps,
            "path_states_plotted": len(xyz),
            "terminal_time_s": float(data[-1, 0]),
            "terminal_xyz_m": xyz[-1].tolist(),
            "start_delta_m": start_delta.tolist(),
            "start_verified": True,
            "final_goal_distance_m": final_goal_distance,
            "goal_tolerance_m": goal_tolerance,
            "route_status_terminal_xyz_m": status_terminal.tolist(),
            "terminal_delta_m": endpoint_delta.tolist(),
            "status_terminal_decimal_places": STATUS_TERMINAL_DECIMALS,
            "terminal_match_tolerance_m": STATUS_TERMINAL_TOLERANCE_M,
            "terminal_verified": True,
            "recorded_time_sequence_verified": True,
            "extended_after_terminal": False,
        })

    ax3d.scatter(*start, marker="^", s=40, color="#222222", edgecolor="white",
                 linewidth=0.7, depthshade=False, zorder=10)
    ax3d.scatter(*goal, marker="*", s=74, facecolors="none",
                 edgecolors="#CC3311", linewidth=0.9,
                 depthshade=False, zorder=2)
    for axis, coords in ((ax_xy, (0, 1)), (ax_xz, (0, 2)), (ax_yz, (1, 2))):
        axis.scatter([start[coords[0]]], [start[coords[1]]], marker="^",
                     s=30, color="#222222", edgecolor="white", linewidth=0.55, zorder=8)
        axis.scatter([goal[coords[0]]], [goal[coords[1]]], marker="*", s=58,
                     facecolors="none", edgecolors="#CC3311", linewidth=0.75, zorder=7)
    fig.legend(
        handles=handles, loc="lower center", bbox_to_anchor=(0.5, 0.025),
        ncol=2, frameon=False, fontsize=6.0, handlelength=1.05,
        columnspacing=0.7, labelspacing=0.38, handletextpad=0.35)

    stem = f"route_comparison_seven_method_scene{selected_scene}_seed{selected_seed}"
    alignment_report = require_matplotlib_panel_alignment(
        fig,
        json_out=QA / f"{stem}.alignment.json",
        overlay_svg=QA / f"{stem}.alignment.svg",
        tolerance_pt=1.5,
        gutter_tolerance_pt=1.5,
        require_panel_labels=True,
        strict=True,
        axes=[ax_xy, ax_xz, ax_yz],
        panel_ids={ax_xy: "b", ax_xz: "c", ax_yz: "d"},
        row_groups=[["c", "d"]],
        column_groups=[["b", "d"]],
    )
    fig.savefig(FIGURES / f"{stem}.pdf", facecolor="white")
    svg_path = FIGURES / f"{stem}.svg"
    fig.savefig(svg_path, facecolor="white")
    # Matplotlib emits trailing separators on continuation lines inside SVG
    # path data. They are harmless to render, but create noisy diffs and fail
    # repository whitespace checks; removing them leaves geometry unchanged.
    svg_path.write_bytes(re.sub(rb"[ \t]+(?=\r?$)", b"", svg_path.read_bytes(), flags=re.MULTILINE))
    fig.savefig(FIGURES / f"{stem}.png", facecolor="white", dpi=600)
    fig.savefig(FIGURES / f"{stem}.tiff", facecolor="white", dpi=600,
                pil_kwargs={"compression": "tiff_lzw"})
    plt.close(fig)

    audit = {
        "source": run_dir.relative_to(PROJECT).as_posix(),
        "selection": selection_audit["selection"],
        "selection_rule": selection_audit["selection_rule"],
        "matched_sets_screened": selection_audit["matched_sets_screened"],
        "eligible_set_count": selection_audit["eligible_set_count"],
        "selected_scene_index": selection_audit["selected_scene_index"],
        "sampling_seed": selection_audit["sampling_seed"],
        "selection_mode": selection_audit.get("selection_mode", "unspecified"),
        "route_legibility_summary": selection_audit.get("route_legibility_summary", {}),
        "alignment_exclusion_reason": (
            "The four labelled views have separate coordinate projections; panel alignment "
            "is checked from the common 2x2 GridSpec, with the distinct 3-D axis projection "
            "kept as the hero panel."
        ),
        "scenario_seed": selection_audit["scenario_seed"],
        "coordinate_frame": (
            "one shared 3-D coordinate frame, shown in one perspective and three "
            "orthogonal projections; route coordinates are unchanged"
        ),
        "view_elevation_degrees": 27,
        "view_azimuth_degrees": -57,
        "axes_count": 4,
        "panel_map": {
            "a": "shared 3-D perspective",
            "b": "XY plan projection",
            "c": "XZ elevation projection",
            "d": "YZ elevation projection",
        },
        "target_canvas_width_in": 3.42,
        "target_canvas_height_in": 3.25,
        "minimum_plot_text_size_pt": 5.7,
        "method_keys": method_keys,
        "trajectory_smoothing": False,
        "trajectory_interpolation_or_resampling": False,
        "trajectory_extension_after_terminal": False,
        "plotted_route_data": "all and only recorded XYZ states from trajectory CSVs",
        "route_distinguishability": (
            "same method-specific color, line style and marker shape in all four "
            "views, with sparse markers at actual recorded states; shared LSTM is "
            "slightly emphasized without changing route geometry"
        ),
        "sparse_state_marker_rule": (
            "approximately 12 evenly spaced indices per recorded route; all markers are saved states"
        ),
        "z_axis_limits_m": [-0.8, 10.0],
        "method_line_styles": {
            key: repr(linestyle) for key, _, _, linestyle in METHODS
        },
        "method_marker_shapes": METHOD_MARKERS,
        "obstacle_tracks_included": False,
        "start_goal_included": True,
        "endpoint_markers": {
            "o": "collision-free goal arrival; marker indicates route terminal",
            "X": "route had a swept collision; marker indicates route terminal, not collision location",
            "s": "no collision; goal not reached; marker indicates route terminal (stop reason unavailable in route_status.csv)",
        },
        "obstacle_geometry_shown": (
            "omitted from the route-only overlay for legibility; moving-obstacle "
            "geometry and prescribed paths are shown in the separate Problem Formulation schematic"
        ),
        "obstacles": obstacle_audit,
        "status_terminal_decimal_places": STATUS_TERMINAL_DECIMALS,
        "terminal_match_tolerance_m": STATUS_TERMINAL_TOLERANCE_M,
        "start_match_tolerance_m": START_TOLERANCE_M,
        "exports": [f"{stem}.pdf", f"{stem}.svg", f"{stem}.png", f"{stem}.tiff"],
        "panel_alignment": alignment_report,
        "methods": endpoint_audit,
    }
    endpoint_audit_path = QA / (
        f"seven_method_route_endpoint_audit_scene{selected_scene}_seed{selected_seed}.json"
    )
    endpoint_audit_path.write_text(
        json.dumps(audit, indent=2, ensure_ascii=False), encoding="utf-8")

    # A panoramic single-3-D view is used in the two-column main paper; the
    # four-view figure above remains in the supplement for coordinate detail.
    # The main-paper derivative occupies one two-column float. A shallower
    # canvas keeps the recorded 3-D paths large at print size and removes the
    # unused strip below the perspective projection; the SI still has all
    # four orthogonal views for route separation.
    wide_fig = plt.figure(figsize=(6.95, 3.02), constrained_layout=False)
    ax_wide = wide_fig.add_axes([0.015, 0.02, 0.75, 0.96], projection="3d")
    ax_wide.view_init(elev=25, azim=-56)
    ax_wide.set_proj_type("ortho")
    ax_wide.set_xlim(0, 20)
    ax_wide.set_ylim(0, 20)
    ax_wide.set_zlim(-0.8, 10)
    ax_wide.set_box_aspect((20, 20, 11), zoom=1.12)
    ax_wide.set_xlabel("x (m)", labelpad=3, fontsize=8.0)
    ax_wide.set_ylabel("y (m)", labelpad=3, fontsize=8.0)
    ax_wide.set_zlabel("z (m)", labelpad=2, fontsize=8.0)
    ax_wide.set_xticks([0, 5, 10, 15, 20])
    ax_wide.set_yticks([0, 5, 10, 15, 20])
    ax_wide.set_zticks([0, 2.5, 5, 7.5, 10])
    ax_wide.tick_params(axis="both", labelsize=7.0, pad=1.0, length=2.0)
    ax_wide.zaxis.set_tick_params(labelsize=7.0, pad=1.0, length=2.0)
    for axis in (ax_wide.xaxis, ax_wide.yaxis, ax_wide.zaxis):
        axis.pane.fill = False
        axis._axinfo["grid"]["color"] = (0.80, 0.83, 0.85, 0.62)
        axis._axinfo["grid"]["linewidth"] = 0.55

    audit_by_key = {row["method_key"]: row for row in endpoint_audit}
    wide_handles = []
    for key, label, color, linestyle in METHODS:
        record = audit_by_key[key]
        route = np.loadtxt(run_dir / record["route_csv"], delimiter=",")
        if route.ndim == 1:
            route = route[None, :]
        xyz = route[:, 1:4]
        if (len(xyz) != record["path_states_plotted"]
                or not np.allclose(xyz[-1], record["terminal_xyz_m"],
                                   atol=STATUS_TERMINAL_TOLERANCE_M, rtol=0)):
            raise ValueError(f"Wide-view route does not match endpoint audit for {key}.")
        stride = max(1, int(np.ceil((len(xyz) - 1) / 12)))
        shared = key == "lstm"
        display_labels = {
            "standalone_dwa_cv": "Standalone DWA-CV",
            "standalone_mpc_cv": "Standalone MPC-CV",
            "cv": "Coupled MPC-DWA-CV",
            "lstm_mpc_cv_dwa": "LSTM to MPC only",
            "cv_mpc_lstm_dwa": "LSTM to DWA only",
            "lstm": "Shared LSTM",
            "static": "Latest-position hold",
        }
        line, = ax_wide.plot(
            xyz[:, 0], xyz[:, 1], xyz[:, 2], color=color, linestyle=linestyle,
            linewidth=2.45 if shared else 1.85, alpha=0.98,
            marker=METHOD_MARKERS[key], markersize=3.3 if shared else 2.9,
            markerfacecolor="white", markeredgecolor=color, markeredgewidth=0.75,
            markevery=stride, zorder=5 if shared else 4,
        )
        endpoint_marker = "o" if record["safe_goal_arrival"] else (
            "X" if record["swept_collision"] else "s")
        ax_wide.scatter(*xyz[-1], marker=endpoint_marker, s=38 if endpoint_marker != "X" else 40,
                        linewidths=1.05, facecolors="none", edgecolors=color,
                        depthshade=False, zorder=9)
        line.set_label(display_labels[key])
        wide_handles.append(line)

    ax_wide.scatter(*start, marker="^", s=52, color="#222222", edgecolor="white",
                    linewidth=0.8, depthshade=False, zorder=10)
    ax_wide.scatter(*goal, marker="*", s=92, facecolors="none",
                    edgecolors="#CC3311", linewidth=1.1, depthshade=False, zorder=3)
    wide_fig.legend(
        handles=wide_handles, loc="center left", bbox_to_anchor=(0.755, 0.52),
        ncol=1, frameon=False, fontsize=7.2, handlelength=1.5,
        handletextpad=0.5, labelspacing=0.9,
        title="Controller", title_fontsize=7.5,
    )
    wide_stem = f"route_comparison_seven_method_scene{selected_scene}_seed{selected_seed}_main"
    wide_fig.savefig(FIGURES / f"{wide_stem}.pdf", facecolor="white")
    wide_svg = FIGURES / f"{wide_stem}.svg"
    wide_fig.savefig(wide_svg, facecolor="white")
    wide_svg.write_bytes(re.sub(rb"[ \t]+(?=\r?$)", b"", wide_svg.read_bytes(), flags=re.MULTILINE))
    wide_fig.savefig(FIGURES / f"{wide_stem}.png", facecolor="white", dpi=600)
    wide_fig.savefig(FIGURES / f"{wide_stem}.tiff", facecolor="white", dpi=600,
                     pil_kwargs={"compression": "tiff_lzw"})
    plt.close(wide_fig)
    wide_audit = {
        "source": run_dir.relative_to(PROJECT).as_posix(),
        "selection_scene": selected_scene,
        "sampling_seed": selected_seed,
        "coordinate_frame": "all seven saved XYZ trajectories in one shared 3-D perspective",
        "target_canvas_inches": [6.95, 3.02],
        "route_states": "all and only the original saved states; no smoothing, interpolation, resampling, or extension",
        "endpoint_checks_reused": True,
        "source_endpoint_audit": endpoint_audit_path.name,
        "method_keys": method_keys,
        "method_labels": [handle.get_label() for handle in wide_handles],
        "exports": [f"{wide_stem}.{ext}" for ext in ("pdf", "svg", "png", "tiff")],
        "methods": endpoint_audit,
    }
    (QA / f"{wide_stem}.json").write_text(
        json.dumps(wide_audit, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Saved seven-method 3D route figure and endpoint audit from {run_dir}.")


if __name__ == "__main__":
    main()
