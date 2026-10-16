"""Render the matched five-controller outcome and five-controller route figures.

The script only visualizes saved experiment records. It does not simulate,
filter, relabel, or alter trial outcomes.
"""

from __future__ import annotations

import csv
from pathlib import Path
import sys

import matplotlib as mpl
mpl.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

SCRIPT_DIR = Path(__file__).resolve().parent
REVISION = SCRIPT_DIR.parent
FIGURES = REVISION / "02_source" / "figures"
QA = REVISION / "qa"
PROJECT = SCRIPT_DIR.parents[4]
NATURE_FIGURE_SCRIPTS = PROJECT.parent / ".agents" / "skills" / "nature-figure" / "scripts"
sys.path.insert(0, str(NATURE_FIGURE_SCRIPTS))
from audit_panel_alignment import require_matplotlib_panel_alignment  # noqa: E402

INK = "#263746"
GRID = "#DCE2E6"
COLORS = {
    "static": "#6F7780",
    "standalone_dwa_lstm": "#D55E00",
    "standalone_mpc_lstm": "#0072B2",
    "lstm_dwa_only": "#009E73",
    "lstm": "#CC79A7",
}
LABELS = {
    # Canonical export labels. Legacy source files may carry the older label;
    # manuscript-facing wording lives in SHORT and ROUTE_PANEL_TITLES.
    "static": "Reconstructed MPC-DWA (latest-position hold)",
    "standalone_dwa_lstm": "Standalone DWA + LSTM",
    "standalone_mpc_lstm": "Standalone MPC + LSTM",
    "lstm_dwa_only": "Integrated: LSTM to DWA only",
    "lstm": "Integrated: Shared LSTM",
}
SHORT = {
    "static": "Reconstructed MPC–DWA\nlatest-position hold",
    "standalone_dwa_lstm": "Standalone DWA\n+ LSTM",
    "standalone_mpc_lstm": "Standalone MPC\n+ LSTM",
    "lstm_dwa_only": "Integrated MPC–DWA\nDWA-only LSTM",
    "lstm": "Integrated MPC–DWA\nshared LSTM",
}
CONTRAST_LABELS = {
    **LABELS,
    "static": "Reconstructed MPC-DWA",
}
SUMMARY_ORDER = [
    "static",
    "standalone_dwa_lstm",
    "standalone_mpc_lstm",
    "lstm_dwa_only",
    "lstm",
]
ROUTE_ORDER = ["static", "standalone_dwa_lstm", "standalone_mpc_lstm",
               "lstm_dwa_only", "lstm"]
ROUTE_LABELS = {
    "static": "Reconstructed MPC-DWA (latest-position hold)",
    "standalone_dwa_lstm": "Standalone DWA + LSTM",
    "standalone_mpc_lstm": "Standalone MPC + LSTM",
    "lstm_dwa_only": "Integrated: LSTM to DWA only",
    "lstm": "Integrated: Shared LSTM",
}
ROUTE_PANEL_TITLES = {
    "static": "Reconstructed MPC–DWA\nlatest-position hold",
    "standalone_dwa_lstm": "Standalone DWA + LSTM",
    "standalone_mpc_lstm": "Standalone MPC + LSTM",
    "lstm_dwa_only": "Integrated MPC–DWA\nLSTM forecast to DWA only",
    "lstm": "Integrated MPC–DWA\nShared LSTM forecast",
}
RESULTS_PANEL_LABELS = {
    "static": "MPC–DWA (latest pos.)",
    "standalone_dwa_lstm": "DWA + LSTM",
    "standalone_mpc_lstm": "MPC + LSTM",
    "lstm_dwa_only": "Integrated (DWA-only)",
    "lstm": "Integrated (shared)",
}

mpl.rcParams.update({
    "font.family": "sans-serif",
    "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
    "font.size": 6.4,
    "axes.titlesize": 7.0,
    "axes.labelsize": 6.1,
    "xtick.labelsize": 5.8,
    "ytick.labelsize": 5.8,
    "pdf.fonttype": 42,
    "ps.fonttype": 42,
    "svg.fonttype": "none",
    "axes.spines.top": False,
    "axes.spines.right": False,
    "savefig.facecolor": "white",
})


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def require_unique(rows: list[dict[str, str]], fields: tuple[str, ...], label: str) -> None:
    values = [tuple(row[field] for field in fields) for row in rows]
    if len(values) != len(set(values)):
        raise ValueError(f"{label} contains duplicate keys for {fields}.")


def save_all(fig: plt.Figure, stem: str, figures_dir: Path = FIGURES,
             qa_dir: Path = QA) -> None:
    figures_dir.mkdir(parents=True, exist_ok=True)
    qa_dir.mkdir(parents=True, exist_ok=True)
    fig.savefig(figures_dir / f"{stem}.pdf", facecolor="white")
    fig.savefig(figures_dir / f"{stem}.svg", facecolor="white")
    fig.savefig(figures_dir / f"{stem}.png", dpi=450, facecolor="white")
    fig.savefig(figures_dir / f"{stem}.tiff", dpi=600, facecolor="white",
                pil_kwargs={"compression": "tiff_lzw"})
    fig.savefig(qa_dir / f"{stem}_qa.png", dpi=600, facecolor="white")
    plt.close(fig)


def make_results_figure(run_dir: Path) -> None:
    run_rows = read_csv(run_dir / "five_method_run_audit.csv")
    summary_rows = read_csv(run_dir / "five_method_summary.csv")
    absolute_rows = read_csv(run_dir / "five_method_absolute_bootstrap.csv")
    contrast_rows = read_csv(run_dir / "five_method_paired_bootstrap.csv")
    key_for_label = {label: key for key, label in LABELS.items()}
    expected_labels = {LABELS[key] for key in SUMMARY_ORDER}
    if len(summary_rows) != len(SUMMARY_ORDER) or {row["Method"] for row in summary_rows} != expected_labels:
        raise ValueError("The five-method summary has duplicate, missing or unknown labels.")
    require_unique(summary_rows, ("Method",), "Five-method summary")
    require_unique(absolute_rows, ("MethodKey",), "Five-method absolute bootstrap")
    require_unique(contrast_rows, ("Contrast", "Metric"), "Five-method paired bootstrap")
    require_unique(run_rows, ("SceneIndex", "SamplingSeed", "MethodKey"), "Five-method run audit")
    summaries = {key_for_label[row["Method"]]: row for row in summary_rows}
    absolute = {row["MethodKey"]: row for row in absolute_rows}
    if set(summaries) != set(SUMMARY_ORDER) or len(run_rows) != 7500:
        raise ValueError("The summary does not contain exactly the five declared controllers.")
    if any(sum(row["MethodKey"] == key for row in run_rows) != 1500 for key in SUMMARY_ORDER):
        raise ValueError("Each controller must contain 1,500 complete matched runs.")
    expected_pairs = {(scene, seed) for scene in range(1, 501) for seed in (1, 2, 3)}
    scenario_seed_by_scene: dict[int, str] = {}
    for key in SUMMARY_ORDER:
        subset = [row for row in run_rows if row["MethodKey"] == key]
        pairs = {(int(float(row["SceneIndex"])), int(float(row["SamplingSeed"])))
                 for row in subset}
        if pairs != expected_pairs:
            raise ValueError(f"{key} is not a complete 500-scene by three-seed arm.")
        for row in subset:
            if row["Method"] != LABELS[key]:
                raise ValueError(f"Method label does not match {key} in the run audit.")
            scene = int(float(row["SceneIndex"]))
            prior = scenario_seed_by_scene.setdefault(scene, row["ScenarioSeed"])
            if prior != row["ScenarioSeed"]:
                raise ValueError(f"ScenarioSeed differs across methods for scene {scene}.")
    if set(absolute) != set(SUMMARY_ORDER) or any(int(row["Runs"]) != 1500 for row in absolute.values()):
        raise ValueError("Absolute intervals must cover all five matched 1,500-run arms.")
    expected_comparators = {key for key in SUMMARY_ORDER if key != "lstm"}
    expected_contrasts = {
        (f"{LABELS['lstm']} minus {CONTRAST_LABELS[key]}", metric)
        for key in expected_comparators
        for metric in ("SafeGoalArrival_pp", "SweptCollision_pp", "SweptClearance_m",
                       "PathLength_m", "MedianPlanningStep_ms")
    }
    actual_contrasts = {(row["Contrast"], row["Metric"]) for row in contrast_rows}
    if actual_contrasts != expected_contrasts:
        raise ValueError("Paired-bootstrap rows do not contain exactly the expected five metrics for each comparator.")
    contrasts = {}
    for key in (item for item in SUMMARY_ORDER if item != "lstm"):
        expected = f"{LABELS['lstm']} minus {CONTRAST_LABELS[key]}"
        rows = [row for row in contrast_rows
                if row["Contrast"] == expected and row["Metric"] == "SafeGoalArrival_pp"]
        if len(rows) != 1:
            raise ValueError(f"Missing unique paired success contrast: {expected}")
        contrasts[key] = rows[0]

    QA.mkdir(parents=True, exist_ok=True)
    with (QA / "five_method_results_figure_source.csv").open(
            "w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(["MethodKey", "Method", "Runs", "SafeGoalArrivals",
                         "SafeGoalArrival_pct", "ClusterCI95_lower_pct",
                         "ClusterCI95_upper_pct", "SweptCollisionRuns", "InfeasibleStops"])
        for key in SUMMARY_ORDER:
            interval = absolute[key]
            row = summaries[key]
            writer.writerow([key, LABELS[key], row["Runs"], row["SafeGoalArrivals"],
                             interval["SafeGoalArrival_pct"], interval["CI95_Lower"],
                             interval["CI95_Upper"],
                             row["SweptCollisionRuns"], row["InfeasibleStops"]])
    with (QA / "five_method_paired_figure_source.csv").open(
            "w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(["ComparatorKey", "Comparator", "Metric", "MeanDifference",
                         "CI95_lower", "CI95_upper", "BootstrapReplicates", "Interpretation"])
        for key in (item for item in SUMMARY_ORDER if item != "lstm"):
            row = contrasts[key]
            writer.writerow([key, LABELS[key], row["Metric"], row["MeanDifference"],
                             row["CI95_Lower"], row["CI95_Upper"],
                             row["BootstrapReplicates"], row["Interpretation"]])

    fig, ax = plt.subplots(figsize=(3.50, 1.90))
    y = np.arange(len(SUMMARY_ORDER))
    for yi, key in zip(y, SUMMARY_ORDER):
        interval = absolute[key]
        mean = float(interval["SafeGoalArrival_pct"])
        lo = float(interval["CI95_Lower"])
        hi = float(interval["CI95_Upper"])
        color = COLORS[key]
        ax.errorbar(mean, yi, xerr=[[mean-lo], [hi-mean]], fmt="o", ms=3.5,
                    color=color, ecolor=color, elinewidth=1.1, capsize=2.0,
                    capthick=0.65, mec="white", mew=0.45, zorder=3)
        label_x = hi + 2.2 if hi < 87 else lo - 2.2
        align = "left" if hi < 87 else "right"
        ax.text(label_x, yi, f"{mean:.1f}%", va="center", ha=align,
                color=INK, fontsize=5.6, fontweight="bold")
    ax.set_yticks(y, [SHORT[key] for key in SUMMARY_ORDER])
    ax.invert_yaxis()
    ax.set_xlim(0, 100)
    ax.set_xticks([0, 20, 40, 60, 80, 100])
    ax.set_ylim(len(SUMMARY_ORDER)-0.50, -0.50)
    ax.set_xlabel("Collision-free goal arrival (%)", labelpad=1.0)
    ax.tick_params(length=2, width=0.55, pad=2.0)
    for tick in ax.get_yticklabels():
        tick.set_color(INK)
        tick.set_fontweight("bold")
        # Keep the two-line controller names visually distinct at final size
        # and prevent glyph boxes from touching in PDF collision audits.
        tick.set_linespacing(1.22)

    fig.subplots_adjust(left=0.36, right=0.98, top=0.97, bottom=0.24)
    fig.canvas.draw()
    require_matplotlib_panel_alignment(
        fig, json_out=FIGURES / "results_summary_alignment.json",
        overlay_svg=FIGURES / "results_summary_alignment.svg",
        tolerance_pt=1.5, gutter_tolerance_pt=1.5,
        require_panel_labels=True, strict=True)
    save_all(fig, "results_summary")


def clip_track_to_workspace(points: list[np.ndarray]) -> list[list[np.ndarray]]:
    """Clip saved piecewise-linear obstacle tracks to the plotted 3D volume."""
    lower = np.array([0.0, 0.0, 0.0])
    upper = np.array([20.0, 20.0, 10.0])
    pieces: list[list[np.ndarray]] = []
    current: list[np.ndarray] = []

    def finish() -> None:
        nonlocal current
        if len(current) >= 2:
            pieces.append(current)
        current = []

    for start, end in zip(points[:-1], points[1:]):
        direction = end - start
        enter, leave = 0.0, 1.0
        visible = True
        for axis in range(3):
            if abs(direction[axis]) < 1e-12:
                if start[axis] < lower[axis] or start[axis] > upper[axis]:
                    visible = False
                    break
                continue
            first = (lower[axis] - start[axis]) / direction[axis]
            last = (upper[axis] - start[axis]) / direction[axis]
            enter = max(enter, min(first, last))
            leave = min(leave, max(first, last))
            if enter > leave:
                visible = False
                break
        if not visible:
            finish()
            continue
        clipped_start = start + enter * direction
        clipped_end = start + leave * direction
        if current and np.allclose(current[-1], clipped_start, rtol=0, atol=1e-9):
            current.append(clipped_end)
        else:
            finish()
            current = [clipped_start, clipped_end]
    finish()
    return pieces


def make_route_figure(route_dir: Path, *, output_dir: Path = FIGURES,
                      qa_dir: Path = QA, single_column: bool = False,
                      stem: str = "route_comparison") -> None:
    route_rows = read_csv(route_dir / "routes.csv")
    obstacle_rows = read_csv(route_dir / "obstacle_tracks.csv")
    status_rows = read_csv(route_dir / "route_status.csv")
    scene_rows = read_csv(route_dir / "scene.csv")
    if len(scene_rows) != 1:
        raise ValueError("The route illustration must use one matched scene.")
    scene = scene_rows[0]
    statuses = {row["MethodKey"]: row for row in status_rows}
    if len(status_rows) != len(ROUTE_ORDER) or set(statuses) != set(ROUTE_ORDER):
        raise ValueError("Route status must contain exactly the five declared route methods.")
    require_unique(status_rows, ("MethodKey",), "Route status")
    require_unique(route_rows, ("MethodKey", "Step"), "Route states")
    if {row["MethodKey"] for row in route_rows} != set(ROUTE_ORDER):
        raise ValueError("Route states must contain exactly the five declared route methods.")
    if (int(float(scene["SceneIndex"])), int(float(scene["SamplingSeed"]))) != (404, 2):
        raise ValueError("The route figure must preserve the declared matched scene 404, seed 2.")
    if len(obstacle_rows) == 0:
        raise ValueError("The matched route illustration requires the saved obstacle tracks.")
    expected_outcomes = {
        "static": (False, True, 224),
        "standalone_dwa_lstm": (False, False, 20),
        "standalone_mpc_lstm": (False, True, 262),
        "lstm_dwa_only": (False, False, 220),
        "lstm": (True, False, 253),
    }
    for key, (success, collision, steps) in expected_outcomes.items():
        row = statuses[key]
        if (str(row["SweptSuccess"]).lower() in {"true", "1"}) != success:
            raise ValueError(f"Unexpected swept-success status for {key}.")
        if (str(row["SweptCollision"]).lower() in {"true", "1"}) != collision:
            raise ValueError(f"Unexpected swept-collision status for {key}.")
        if int(float(row["Steps"])) != steps or row["Method"] != ROUTE_LABELS[key]:
            raise ValueError(f"Unexpected route label or terminal step for {key}.")
        path = [route for route in route_rows if route["MethodKey"] == key]
        if [int(float(route["Step"])) for route in path] != list(range(steps + 1)):
            raise ValueError(f"{key} must contain only its recorded states through step {steps}.")
        for coordinate in ("X_m", "Y_m", "Z_m"):
            terminal_field = f"Terminal{coordinate[0]}_m"
            if not np.isclose(float(path[-1][coordinate]), float(row[terminal_field]),
                              rtol=0, atol=1e-9):
                raise ValueError(f"Last plotted state disagrees with terminal audit for {key}.")
    max_terminal_step = max(int(float(row["Steps"])) for row in status_rows)
    obstacle_ids = sorted({int(row["ObstacleIndex"]) for row in obstacle_rows})
    if len(obstacle_ids) != 3:
        raise ValueError("Scene 404, seed 2 must retain all three obstacle tracks.")
    tracks: dict[int, list[np.ndarray]] = {}
    for obstacle_id in obstacle_ids:
        points = sorted(
            (row for row in obstacle_rows
             if int(row["ObstacleIndex"]) == obstacle_id
             and int(row["Step"]) <= max_terminal_step),
            key=lambda row: int(row["Step"]),
        )
        steps = [int(row["Step"]) for row in points]
        if steps != list(range(max_terminal_step + 1)):
            raise ValueError(
                f"Obstacle {obstacle_id} must have saved states through step {max_terminal_step}."
            )
        tracks[obstacle_id] = [
            np.array([float(row["X_m"]), float(row["Y_m"]), float(row["Z_m"])])
            for row in points
        ]

    if single_column:
        fig = plt.figure(figsize=(3.48, 3.28))
        # Leave a deliberate right gutter for the z-axis title. Matplotlib's
        # 3-D label is placed outside the axes box and was clipped at the
        # single-column trim size in the previous layout.
        ax = fig.add_axes([0.0, 0.29, 0.84, 0.66], projection="3d")
        route_linewidth = 1.15
        route_markers = {
            "static": "P",
            "standalone_dwa_lstm": "o",
            "standalone_mpc_lstm": "s",
            "lstm_dwa_only": "^",
            "lstm": "D",
        }
        route_linestyles = {
            "static": (0, (1.4, 1.1)),
            "standalone_dwa_lstm": "-",
            "standalone_mpc_lstm": "--",
            "lstm_dwa_only": "-.",
            "lstm": (0, (4.0, 1.2, 1.0, 1.2)),
        }
    else:
        fig = plt.figure(figsize=(7.16, 3.72))
        ax = fig.add_axes([0.06, 0.27, 0.88, 0.67], projection="3d")
        route_linewidth = 1.85
        route_markers = {}
        route_linestyles = {}
    # Preserve explicit draw order: route strokes first, then scene anchors,
    # followed by true terminal-state markers for routes that nearly meet.
    ax.computed_zorder = False
    # The common obstacle context is drawn once, from the matched saved
    # scene, and stops at the longest recorded route (step 262).
    for points in tracks.values():
        for piece in clip_track_to_workspace(points):
            ax.plot([p[0] for p in piece], [p[1] for p in piece],
                    [p[2] for p in piece], color="#8795A1", alpha=0.58,
                    linewidth=0.88, linestyle=(0, (2, 2)), zorder=1)

    legend_labels = {
        "static": "MPC-DWA (latest-position\nhold)" if single_column else "Reconstructed MPC–DWA\n(latest-position hold)",
        "standalone_dwa_lstm": "Standalone DWA + LSTM",
        "standalone_mpc_lstm": "Standalone MPC + LSTM",
        "lstm_dwa_only": "MPC-DWA (LSTM to DWA\nonly)" if single_column else "Integrated MPC–DWA\n(LSTM to DWA only)",
        "lstm": "MPC-DWA (shared LSTM)" if single_column else "Integrated MPC–DWA\n(shared LSTM)",
    }
    terminal_states: dict[str, tuple[dict[str, str], bool, bool]] = {}
    for key in ROUTE_ORDER:
        status = statuses[key]
        terminal_step = int(float(status["Steps"]))
        path = sorted(
            (row for row in route_rows
             if row["MethodKey"] == key and int(float(row["Step"])) <= terminal_step),
            key=lambda row: int(float(row["Step"])),
        )
        if not path:
            raise ValueError(f"No recorded route states for {key} through step {terminal_step}.")
        plot_options: dict[str, object] = {
            "color": COLORS[key],
            "linewidth": route_linewidth * (1.22 if single_column and key == "lstm" else 1.0),
            "zorder": 4,
            "label": legend_labels[key],
        }
        if single_column:
            marker_count = min(8, len(path))
            plot_options.update({
                "linestyle": route_linestyles[key],
                "marker": route_markers[key],
                "markevery": np.unique(np.linspace(0, len(path) - 1, marker_count,
                                                    dtype=int)),
                "markersize": 2.2,
                "markerfacecolor": "white",
                "markeredgecolor": COLORS[key],
                "markeredgewidth": 0.55,
            })
        ax.plot([float(row["X_m"]) for row in path],
                [float(row["Y_m"]) for row in path],
                [float(row["Z_m"]) for row in path], **plot_options)
        endpoint = path[-1]
        arrived = str(status["SweptSuccess"]).lower() in {"true", "1"}
        collision = str(status["SweptCollision"]).lower() in {"true", "1"}
        terminal_states[key] = (endpoint, arrived, collision)

    ax.scatter([float(scene["StartX_m"])], [float(scene["StartY_m"])],
               [float(scene["StartZ_m"])], marker="^", s=50,
               color="#18865A", edgecolors="white", linewidths=0.55,
               depthshade=False, zorder=9)
    ax.scatter([float(scene["GoalX_m"])], [float(scene["GoalY_m"])],
               [float(scene["GoalZ_m"])], marker="*", s=82,
               color="#C84C4C", edgecolors="white", linewidths=0.45,
               depthshade=False, zorder=9)
    # Endpoint symbols are plotted last so nearby terminals do not disappear
    # beneath the goal marker. Their coordinates remain the logged states.
    for key in ROUTE_ORDER:
        endpoint, arrived, collision = terminal_states[key]
        marker = "o" if arrived else ("X" if collision else "s")
        marker_color = "#17212B" if collision else COLORS[key]
        if arrived:
            ax.scatter([float(endpoint["X_m"])], [float(endpoint["Y_m"])],
                       [float(endpoint["Z_m"])], marker=marker, s=64,
                       facecolors="none", edgecolors=marker_color,
                       linewidths=1.45, depthshade=False, zorder=20)
            continue
        ax.scatter([float(endpoint["X_m"])], [float(endpoint["Y_m"])],
                   [float(endpoint["Z_m"])], marker=marker, s=38 if collision else 48,
                   color=marker_color, edgecolors="white", linewidths=0.75,
                   depthshade=False, zorder=12)
    # Reassert the true goal marker after near-goal terminal symbols so the
    # target remains visible without moving or bending any recorded route.
    ax.scatter([float(scene["GoalX_m"])], [float(scene["GoalY_m"])],
               [float(scene["GoalZ_m"])], marker="*", s=38,
               color="#C84C4C", edgecolors="white", linewidths=0.4,
               depthshade=False, zorder=30)

    ax.set_xlim(0, 20); ax.set_ylim(0, 20); ax.set_zlim(0, 10)
    ax.set_xticks([0, 5, 10, 15, 20]); ax.set_yticks([0, 5, 10, 15, 20])
    ax.set_zticks([0, 2.5, 5, 7.5, 10])
    axis_fontsize = 6.2 if single_column else 7.0
    tick_fontsize = 5.5 if single_column else 6.0
    ax.set_xlabel("x (m)", labelpad=1.6, fontsize=axis_fontsize)
    ax.set_ylabel("y (m)", labelpad=1.6, fontsize=axis_fontsize)
    ax.set_zlabel("z (m)", labelpad=-3.0 if single_column else 0.8, fontsize=axis_fontsize)
    ax.tick_params(axis="both", which="major", labelsize=tick_fontsize, pad=1.6,
                   length=2.2, width=0.55)
    ax.tick_params(axis="z", which="major", labelsize=5.2 if single_column else 5.8, pad=1.0,
                   length=1.8, width=0.50)
    ax.view_init(elev=25, azim=-57)
    ax.set_box_aspect((2, 2, 1), zoom=1.25)
    ax.grid(True)
    for axis in (ax.xaxis, ax.yaxis, ax.zaxis):
        axis.pane.fill = False
        axis.pane.set_edgecolor("#C5CED4")
        axis.line.set_color("#9CAAB3")
        axis.line.set_linewidth(0.55)
    for axis in (ax.xaxis, ax.yaxis, ax.zaxis):
        axis._axinfo["grid"]["color"] = (0.76, 0.80, 0.83, 0.42)
        axis._axinfo["grid"]["linewidth"] = 0.35

    fig.suptitle(
        f"Recorded 3-D routes - scene {int(scene['SceneIndex'])}, seed {int(scene['SamplingSeed'])}",
        x=0.5, y=0.985, fontsize=7.0 if single_column else 8.0,
        fontweight="bold", color=INK,
    )
    handles, labels = ax.get_legend_handles_labels()
    if single_column:
        fig.legend(handles, labels, loc="lower center", bbox_to_anchor=(0.5, 0.095),
                   ncol=2, frameon=False, fontsize=5.35, handlelength=1.5,
                   columnspacing=0.9, labelspacing=0.18, handletextpad=0.35)
        fig.text(
            0.5, 0.012,
            "Start/goal: triangle/star; arrival: circle; stop: square; X: swept contact; dashed: obstacles",
            ha="center", va="bottom", fontsize=6.0, color=INK,
        )
    else:
        fig.legend(handles, labels, loc="lower center", bbox_to_anchor=(0.5, 0.075),
                   ncol=3, frameon=False, fontsize=5.8, handlelength=2.0,
                   columnspacing=1.5, labelspacing=0.35, handletextpad=0.55)
        fig.text(
            0.5, 0.018,
            "Start: triangle   Goal: star   Arrived: circle   Stopped: square   X: swept collision somewhere on route, not at endpoint   Dashed: obstacle tracks",
            ha="center", va="bottom", fontsize=5.3, color=INK,
        )
    fig.canvas.draw()
    require_matplotlib_panel_alignment(
        fig, json_out=qa_dir / f"{stem}.alignment.json",
        overlay_svg=qa_dir / f"{stem}.alignment.svg",
        tolerance_pt=1.5, gutter_tolerance_pt=1.5,
        require_panel_labels=False, strict=True)
    save_all(fig, stem, output_dir, qa_dir)


def main() -> None:
    if len(sys.argv) == 4 and sys.argv[1] == "--main-route":
        route_dir = Path(sys.argv[2]).resolve()
        output_dir = Path(sys.argv[3]).resolve()
        make_route_figure(
            route_dir, output_dir=output_dir, qa_dir=QA, single_column=True,
            stem="route_comparison_five_method_scene404_seed2")
        print(f"Rendered the saved five-controller route example from {route_dir}")
        return
    if len(sys.argv) != 3:
        raise SystemExit(
            "Usage: generate_four_method_figures.py <completed-run-dir> <route-data-dir>\n"
            "   or: generate_four_method_figures.py --main-route <route-data-dir> <output-figure-dir>")
    run_dir = Path(sys.argv[1]).resolve()
    route_dir = Path(sys.argv[2]).resolve()
    make_results_figure(run_dir)
    make_route_figure(route_dir)
    print(f"Rendered the five-controller aggregate and matched 3-D routes from {run_dir} and {route_dir}")


if __name__ == "__main__":
    main()
