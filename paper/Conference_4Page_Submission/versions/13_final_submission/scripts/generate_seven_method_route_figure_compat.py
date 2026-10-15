"""Backward-compatible entry point for the final seven-arm route figure.

The canonical generator is ``generate_seven_method_route_figure.py``. This
legacy filename delegates to it so it cannot overwrite the figure with an
older layout.
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

RUN_DIR = PROJECT / "results" / "v13_seven_method_100scene_exploratory_20261015" / "route_example"
FIGURES = REVISION / "02_source" / "figures"
QA = REVISION / "qa"

METHODS = [
    ("standalone_dwa_cv", "Standalone DWA-CV", "#E69F00", "-"),
    ("standalone_mpc_cv", "Standalone MPC-CV", "#0072B2", "--"),
    ("cv", "Coupled MPC-DWA-CV", "#009E73", "-."),
    ("lstm_mpc_cv_dwa", "MPC-DWA: LSTM to MPC", "#CC79A7", ":"),
    ("cv_mpc_lstm_dwa", "MPC-DWA: LSTM to DWA", "#D55E00", (0, (6, 2, 1, 2))),
    ("lstm", "MPC-DWA: shared LSTM", "#332288", (0, (3, 1, 1, 1))),
    ("static", "MPC-DWA: position hold", "#6F7780", (0, (1, 1))),
]
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
    "axes.titlesize": 7.5,
    "axes.labelsize": 7.0,
    "xtick.labelsize": 7.0,
    "ytick.labelsize": 7.0,
    "legend.fontsize": 7.0,
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


def normalize_svg_whitespace(path: Path) -> None:
    """Keep the editable SVG diff-clean without changing its geometry."""
    svg = path.read_text(encoding="utf-8")
    svg = re.sub(r"[ \t]+(?=\n)", "", svg)
    path.write_text(svg, encoding="utf-8", newline="\n")


def main() -> None:
    if not RUN_DIR.is_dir():
        raise FileNotFoundError(f"Route export directory does not exist: {RUN_DIR}")

    FIGURES.mkdir(parents=True, exist_ok=True)
    QA.mkdir(parents=True, exist_ok=True)
    start_goal = np.loadtxt(RUN_DIR / "start_goal.csv", delimiter=",").reshape(2, 3)
    if not np.isfinite(start_goal).all():
        raise ValueError("Start/goal export contains non-finite coordinates.")
    start = start_goal[0]
    goal = start_goal[1]

    status_list = read_csv(RUN_DIR / "route_status.csv")
    status_rows = {row["MethodKey"]: row for row in status_list}
    method_keys = [key for key, _, _, _ in METHODS]
    if len(status_rows) != len(status_list):
        raise ValueError("route_status.csv contains duplicate method keys.")
    if set(status_rows) != set(method_keys):
        missing = sorted(set(method_keys) - set(status_rows))
        extra = sorted(set(status_rows) - set(method_keys))
        raise ValueError(f"Unexpected route-status keys; missing={missing}, extra={extra}.")

    obstacle_rows = np.loadtxt(RUN_DIR / "obstacle_tracks.csv", delimiter=",")
    if obstacle_rows.ndim == 1:
        obstacle_rows = obstacle_rows[None, :]
    if obstacle_rows.shape[1] < 6 or not np.isfinite(obstacle_rows).all():
        raise ValueError("Obstacle-track export is malformed or non-finite.")
    if (np.any(obstacle_rows[:, 0] < 1)
            or not np.allclose(obstacle_rows[:, 0], np.rint(obstacle_rows[:, 0]))):
        raise ValueError("Obstacle IDs must be positive integers.")

    # Design at final single-column size so labels stay legible in the 4-page
    # manuscript without forcing the path comparison onto a separate page.
    fig = plt.figure(figsize=(3.48, 3.2), constrained_layout=False)
    ax = fig.add_subplot(111, projection="3d")
    ax.view_init(elev=27, azim=-57)
    ax.set_proj_type("ortho")
    ax.set_xlim(0, 20)
    ax.set_ylim(0, 20)
    ax.set_zlim(0, 10)
    ax.set_box_aspect((2, 2, 1))
    ax.set_xlabel("x (m)", labelpad=12)
    ax.set_ylabel("y (m)", labelpad=12)
    ax.set_zlabel("z (m)", labelpad=1)
    # The route illustration is qualitative; omit crowded numeric ticks while
    # retaining the physical axes and units stated in the caption.
    ax.set_xticks([])
    ax.set_yticks([])
    ax.set_zticks([])
    ax.xaxis.pane.set_facecolor((0.96, 0.97, 0.98, 0.45))
    ax.yaxis.pane.set_facecolor((0.96, 0.97, 0.98, 0.45))
    ax.zaxis.pane.set_facecolor((0.98, 0.98, 0.98, 0.25))
    for axis in (ax.xaxis, ax.yaxis, ax.zaxis):
        axis._axinfo["grid"]["color"] = (0.84, 0.86, 0.88, 0.38)
        axis._axinfo["grid"]["linewidth"] = 0.35

    handles = []
    endpoint_audit: list[dict[str, object]] = []
    obstacle_audit: list[dict[str, object]] = []
    for obstacle_id in np.unique(obstacle_rows[:, 0]).astype(int):
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
        trajectory_path = RUN_DIR / f"trajectory_{key}.csv"
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

        ax.plot(xyz[:, 0], xyz[:, 1], xyz[:, 2], color=color,
                linestyle=linestyle, linewidth=1.4, alpha=0.90, zorder=4)
        ax.scatter(*xyz[-1], marker=endpoint_marker,
                   s=38 if safe else 44, linewidths=1.15, color=color,
                   depthshade=False, zorder=8)
        handles.append(plt.Line2D([0], [0], color=color, lw=2.1,
                                  linestyle=linestyle,
                                  label=label))
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

    ax.scatter(*start, marker="^", s=68, color="#009E73", edgecolor="white",
               linewidth=0.8, depthshade=False, zorder=10)
    ax.scatter(*goal, marker="*", s=110, color="#CC3311", edgecolor="white",
               linewidth=0.7, depthshade=False, zorder=10)
    fig.legend(
        handles=handles, loc="lower center", bbox_to_anchor=(0.5, 0.01),
        ncol=2, frameon=False, fontsize=7.0, handlelength=0.5,
        columnspacing=0.5, labelspacing=0.28, handletextpad=1.5)
    # Endpoint markers and obstacle-track line styles are defined in the
    # manuscript caption, so a second legend would repeat text and crowd the plot.
    fig.subplots_adjust(left=0.06, right=0.91, top=0.97, bottom=0.29)

    stem = "route_comparison_seven_method"
    alignment_report = require_matplotlib_panel_alignment(
        fig,
        json_out=QA / f"{stem}.alignment.json",
        overlay_svg=QA / f"{stem}.alignment.svg",
        tolerance_pt=1.5,
        gutter_tolerance_pt=1.5,
        strict=True,
    )
    fig.savefig(FIGURES / f"{stem}.pdf", facecolor="white")
    svg_path = FIGURES / f"{stem}.svg"
    fig.savefig(svg_path, facecolor="white")
    normalize_svg_whitespace(svg_path)
    fig.savefig(FIGURES / f"{stem}.png", facecolor="white", dpi=600)
    fig.savefig(FIGURES / f"{stem}.tiff", facecolor="white", dpi=600)
    plt.close(fig)

    audit = {
        "source": RUN_DIR.relative_to(PROJECT).as_posix(),
        "selection": "scene 1, seed 1, fixed before test outcomes",
        "coordinate_frame": "one shared 3D axis",
        "axes_count": 1,
        "target_canvas_width_in": 3.48,
        "target_canvas_height_in": 3.2,
        "minimum_plot_text_size_pt": 7.0,
        "method_keys": method_keys,
        "trajectory_smoothing": False,
        "trajectory_interpolation_or_resampling": False,
        "trajectory_extension_after_terminal": False,
        "plotted_route_data": "all and only recorded XYZ states from trajectory CSVs",
        "route_distinguishability": "predeclared method-specific color and line style",
        "method_line_styles": {
            key: repr(linestyle) for key, _, _, linestyle in METHODS
        },
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
    (QA / "seven_method_route_endpoint_audit.json").write_text(
        json.dumps(audit, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Saved seven-method 3D route figure and endpoint audit from {RUN_DIR}.")


if __name__ == "__main__":
    from generate_seven_method_route_figure import main as canonical_main
    canonical_main()
