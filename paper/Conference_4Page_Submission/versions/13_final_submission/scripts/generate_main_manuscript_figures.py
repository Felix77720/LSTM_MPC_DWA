"""Generate the main-text pseudocode and protocol-separated outcome figure.

All plotted counts are read from existing supplementary outcome tables. This
script does not run or alter simulations.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import shutil
import sys
from pathlib import Path

import matplotlib as mpl
mpl.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

SCRIPT_DIR = Path(__file__).resolve().parent
REVISION = SCRIPT_DIR.parent
SUPPLEMENT = REVISION / "03_supplementary"
FIGURES = REVISION / "02_source" / "figures"
QA = REVISION / "qa"
PROJECT = SCRIPT_DIR.parents[4]
NATURE_FIGURE_SCRIPTS = PROJECT.parent / ".agents" / "skills" / "nature-figure" / "scripts"
sys.path.insert(0, str(NATURE_FIGURE_SCRIPTS))
from audit_panel_alignment import require_matplotlib_panel_alignment  # noqa: E402

mpl.rcParams.update({
    "font.family": "sans-serif",
    "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans", "sans-serif"],
    "font.size": 5.8,
    "axes.titlesize": 6.4,
    "axes.labelsize": 6.0,
    "xtick.labelsize": 5.5,
    "ytick.labelsize": 5.5,
    "pdf.fonttype": 42,
    "ps.fonttype": 42,
    "svg.fonttype": "none",
    "axes.spines.top": False,
    "axes.spines.right": False,
    "savefig.facecolor": "white",
})

INK = "#253746"
BODY = "#425466"
GRID = "#D9E0E5"
NEUTRAL = "#98A6B2"
SHARED = "#16877D"


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def generate_pseudocode() -> dict:
    """Render the shared-forecast receding-horizon algorithm as modular pseudocode."""
    FIGURES.mkdir(parents=True, exist_ok=True)
    QA.mkdir(parents=True, exist_ok=True)
    width, height = 3.80, 3.40
    fig, ax = plt.subplots(figsize=(width, height), dpi=300)
    fig.subplots_adjust(left=0, right=1, bottom=0, top=1)
    ax.set_xlim(0, width)
    ax.set_ylim(0, height)
    ax.set_axis_off()

    def module(x: float, y: float, w: float, h: float, title: str,
               lines: tuple[str, ...], accent: str, *, body_size: float = 5.55,
               title_size: float = 6.25) -> None:
        ax.add_patch(FancyBboxPatch(
            (x, y), w, h, boxstyle="round,pad=0.012,rounding_size=0.035",
            linewidth=0.60, edgecolor=accent, facecolor="white", zorder=2,
        ))
        ax.add_patch(plt.Rectangle((x, y), 0.045, h, color=accent,
                                   linewidth=0, zorder=2))
        ax.text(x + 0.11, y + h - 0.095, title, ha="left", va="center",
                fontsize=title_size, fontweight="bold", color=accent, zorder=3)
        body_y = y + h - 0.205
        for index, line in enumerate(lines):
            ax.text(x + 0.11, body_y - index * 0.100, line,
                    ha="left", va="center", fontsize=body_size,
                    color=INK, zorder=3)

    ax.text(0.43, 3.33, "SHARED-FORECAST PLANNER  |  UPDATE LOOP",
            ha="left", va="top", fontsize=8.58, fontweight="bold", color=INK)

    # Step 3 separates the route guide from local action screening. The gate
    # below exposes normal and emergency behavior without implying a guarantee.
    module(0.43, 2.88, 3.20, 0.31, "1  OBSERVE + INITIALIZE",
           ("UAV state, goal, latest 10 observations and previous MPC sequence.",),
           "#425466", body_size=6.54, title_size=7.26)
    module(0.43, 2.37, 3.20, 0.42, "2  PREDICT ONCE, SHARE",
           ("Causal LSTM predicts 30 time-aligned obstacle positions (3 s).",
            "Broadcast this same forecast to MPC and DWA."), SHARED,
           body_size=6.54, title_size=7.26)
    module(0.43, 1.55, 1.49, 0.64, "3a  MPC | ROUTE GUIDE",
           ("Optimize the 30-step route",
            "with the shared forecast;",
            "output guide + trust."), "#4B729D", body_size=6.42, title_size=7.14)
    module(2.14, 1.55, 1.49, 0.64, "3b  DWA | ACTION SCREEN",
           ("Sample reachable controls",
            "screen 10 / 30 steps using",
            "forecast + guide; score."), "#A86C20", body_size=6.42, title_size=6.96)

    ax.add_patch(FancyBboxPatch(
        (0.43, 1.29), 3.20, 0.17,
        boxstyle="round,pad=0.008,rounding_size=0.025",
        linewidth=0.55, edgecolor="#526573", facecolor="#EEF2F4", zorder=2,
    ))
    ax.text(2.03, 1.375, "4  GATE: IS THE NORMAL DWA SAFE SET NONEMPTY?",
            ha="center", va="center", fontsize=6.78, fontweight="bold",
            color=INK, zorder=3)
    module(0.43, 0.56, 1.56, 0.65, "YES  |  NORMAL",
           ("Choose top-scored safe action;",
            "bound MPC's first input.",
            "If clear >1 m & cross-track >0.5 m,",
            "recenter; re-screen, else revert."), "#16877D",
           body_size=6.00, title_size=6.90)
    module(2.07, 0.56, 1.56, 0.65, "NO  |  EMERGENCY",
           ("Screen emergency actions;",
            "use one only if it passes.",
            "If none passes, stop."), "#A45B4A",
           body_size=6.18, title_size=6.90)
    module(0.43, 0.08, 3.20, 0.38, "5  RE-SOLVE + EXECUTE",
           ("Re-solve MPC with the safe-set bound when available.",
            "Execute the screened action for 0.1 s; update and repeat."),
           "#425466", body_size=6.36, title_size=7.02)

    arrow = dict(arrowstyle="-|>", color="#71818D", lw=0.65, mutation_scale=6.5)
    ax.annotate("", xy=(2.03, 2.79), xytext=(2.03, 2.88), arrowprops=arrow, zorder=1)
    # Fan the single forecast to both planners.
    ax.annotate("", xy=(2.03, 2.27), xytext=(2.03, 2.37), arrowprops=arrow, zorder=1)
    ax.plot([1.175, 2.885], [2.27, 2.27], color="#71818D", lw=0.55, zorder=1)
    ax.annotate("", xy=(1.175, 2.19), xytext=(1.175, 2.27), arrowprops=arrow, zorder=1)
    ax.annotate("", xy=(2.885, 2.19), xytext=(2.885, 2.27), arrowprops=arrow, zorder=1)
    # The MPC guide is an additional input to DWA.
    ax.annotate("", xy=(2.14, 1.87), xytext=(1.92, 1.87), arrowprops=arrow, zorder=1)
    ax.annotate("", xy=(2.03, 1.46), xytext=(2.03, 1.55), arrowprops=arrow, zorder=1)
    # Gate fans into mutually exclusive normal and emergency branches.
    ax.annotate("", xy=(1.21, 1.21), xytext=(1.21, 1.29), arrowprops=arrow, zorder=1)
    ax.annotate("", xy=(2.85, 1.21), xytext=(2.85, 1.29), arrowprops=arrow, zorder=1)
    # Merge branch outputs before executing exactly one screened action.
    ax.annotate("", xy=(1.21, 0.51), xytext=(1.21, 0.56), arrowprops=arrow, zorder=1)
    ax.annotate("", xy=(2.85, 0.51), xytext=(2.85, 0.56), arrowprops=arrow, zorder=1)
    ax.plot([1.21, 2.85], [0.51, 0.51], color="#71818D", lw=0.55, zorder=1)
    ax.annotate("", xy=(2.03, 0.46), xytext=(2.03, 0.51), arrowprops=arrow, zorder=1)
    # Return arrow marks the receding-horizon loop.
    ax.plot([0.25, 0.25], [0.23, 2.98], color="#98A6B2", lw=0.55, zorder=1)
    ax.plot([0.25, 0.43], [0.23, 0.23], color="#98A6B2", lw=0.55, zorder=1)
    ax.annotate("", xy=(0.43, 2.98), xytext=(0.25, 2.98), arrowprops=arrow, zorder=1)
    ax.text(0.16, 1.60, "repeat every 0.1 s", ha="center", va="center",
            rotation=90, rotation_mode="anchor", fontsize=7.30, color=BODY)

    fig.canvas.draw()
    alignment = require_matplotlib_panel_alignment(
        fig,
        json_out=QA / "algorithm_main_pseudocode.alignment.json",
        overlay_svg=QA / "algorithm_main_pseudocode.alignment.svg",
        tolerance_pt=1.5,
        gutter_tolerance_pt=1.5,
        strict=True,
    )
    stem = FIGURES / "algorithm_main_pseudocode"
    fig.savefig(stem.with_suffix(".pdf"), facecolor="white")
    svg_path = stem.with_suffix(".svg")
    fig.savefig(svg_path, facecolor="white")
    svg_path.write_bytes(re.sub(rb"[ \t]+(?=\r?$)", b"", svg_path.read_bytes(),
                                flags=re.MULTILINE))
    fig.savefig(stem.with_suffix(".png"), dpi=600, facecolor="white")
    fig.savefig(stem.with_suffix(".tiff"), dpi=600, facecolor="white",
                pil_kwargs={"compression": "tiff_lzw"})
    plt.close(fig)
    return alignment


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pseudocode-only", action="store_true",
                        help="Regenerate only the main-text pseudocode assets.")
    args = parser.parse_args()
    if args.pseudocode_only:
        alignment = generate_pseudocode()
        provenance_path = QA / "main_manuscript_figures_provenance.json"
        if provenance_path.is_file():
            provenance = json.loads(provenance_path.read_text(encoding="utf-8"))
            provenance["pseudocode_alignment"] = alignment
            provenance_path.write_text(
                json.dumps(provenance, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )
        print("Generated the main-text pseudocode only.")
        return
    FIGURES.mkdir(parents=True, exist_ok=True)
    QA.mkdir(parents=True, exist_ok=True)

    historic_rows = read_rows(SUPPLEMENT / "five_method_summary.csv")
    historic = {row["Method"]: row for row in historic_rows}
    seven_rows = read_rows(SUPPLEMENT / "seven_method_outcomes_figure_source.csv")
    if len(seven_rows) != 7 or any(int(row["runs"]) != 300 for row in seven_rows):
        raise ValueError("Expected the seven existing arms with 300 runs each.")

    historic_order = [
        ("MPC-DWA: position hold", "Reconstructed MPC-DWA (latest-position hold)"),
        ("MPC-DWA: LSTM to DWA", "Integrated: LSTM to DWA only"),
        ("MPC-DWA: shared LSTM", "Integrated: Shared LSTM"),
        ("Standalone DWA + LSTM", "Standalone DWA + LSTM"),
        ("Standalone MPC + LSTM", "Standalone MPC + LSTM"),
    ]
    if len(historic) != 5:
        raise ValueError(f"Expected five historical benchmark arms, found {len(historic)}.")

    seven_order = [
        ("Standalone DWA-CV", "Standalone DWA-CV"),
        ("Standalone MPC-CV", "Standalone MPC-CV"),
        ("Coupled MPC-DWA-CV", "Coupled MPC-DWA-CV"),
        ("Coupled: LSTM to MPC", "MPC-DWA (LSTM to MPC only)"),
        ("Coupled: LSTM to DWA", "MPC-DWA (LSTM to DWA only)"),
        ("Coupled: shared LSTM", "MPC-DWA (shared LSTM)"),
        ("Coupled: position hold", "MPC-DWA (latest-position hold)"),
    ]
    seven = {row["method"]: row for row in seven_rows}
    if set(key for _, key in seven_order) != set(seven):
        raise ValueError("Seven-arm display mapping does not match source rows.")

    # Panel contract: compare controller rates within each frozen protocol;
    # never combine the arms into one cross-protocol ranking.
    fig, axes = plt.subplots(2, 1, figsize=(3.48, 3.45), sharex=True)
    fig.subplots_adjust(left=0.39, right=0.83, bottom=0.12, top=0.88, hspace=0.78)
    panels = [
        (axes[0], "a", "Frozen 500-scene benchmark", historic_order, historic, True),
        (axes[1], "b", "Separate 100-scene exploration", seven_order, seven, False),
    ]
    for ax, letter, title, order, rows, is_historic in panels:
        names = [name for name, _ in order]
        rates: list[float] = []
        for _, key in order:
            row = rows[key]
            if is_historic:
                if int(row["Runs"]) != 1500:
                    raise ValueError(f"Unexpected historical denominator for {key}.")
                rates.append(float(row["SafeGoalArrival_pct"]))
            else:
                rates.append(100.0 * int(row["arrivals"]) / int(row["runs"]))
        y = list(range(len(order)))
        colors = [SHARED if "shared lstm" in name.lower() else NEUTRAL
                  for name in names]
        ax.barh(y, rates, height=0.64, color=colors, edgecolor="white", linewidth=0.45, zorder=3)
        ax.set_yticks(y, names)
        ax.invert_yaxis()
        ax.set_xlim(0, 100)
        ax.set_xticks([0, 25, 50, 75, 100])
        ax.set_title(title, loc="left", color=INK, fontweight="bold", pad=3)
        ax.grid(False, axis="x")
        ax.tick_params(axis="both", length=1.8, width=0.5, pad=1.0, colors=BODY,
                       labelsize=5.1)
        for yi, rate in zip(y, rates):
            if rate <= 5.0:
                label_x, label_ha = rate + 2.0, "left"
            else:
                label_x, label_ha = rate - 2.5, "right"
            ax.text(label_x, yi, f"{rate:.1f}%", va="center", ha=label_ha,
                    color=INK, fontsize=5.2, clip_on=True, zorder=5)
            row = rows[order[yi][1]]
            contacts = int(row["SweptCollisionRuns"]) if is_historic else int(row["swept_contacts"])
            ax.text(1.035, yi, f"{contacts}", transform=ax.get_yaxis_transform(),
                    va="center", ha="left", color=INK, fontsize=5.2, clip_on=False)
        ax.text(-0.18, 1.02, letter, transform=ax.transAxes, ha="left", va="bottom",
                fontsize=7.2, fontweight="bold", color=INK)
        ax.text(1.035, 1.02, "Swept\ncontacts", transform=ax.transAxes,
                ha="left", va="bottom", fontsize=5.0, color=BODY, clip_on=False)
        effect = ("Δ shared−DWA-only: +6.7 pp [4.2, 9.2]"
                  if is_historic else
                  "Δ shared−DWA-only: −1.0 pp [−4.8, 2.8]")
        ax.text(0.00, 1.17, effect, transform=ax.transAxes, ha="left", va="bottom",
                fontsize=5.05, color=BODY, clip_on=False)
    axes[0].set_xlabel("")
    axes[1].set_xlabel("Collision-free goal arrival (%)", color=BODY, labelpad=2)
    fig.canvas.draw()
    alignment = require_matplotlib_panel_alignment(
        fig,
        json_out=QA / "seven_method_outcomes_main.alignment.json",
        overlay_svg=QA / "seven_method_outcomes_main.alignment.svg",
        tolerance_pt=1.5,
        gutter_tolerance_pt=1.5,
        require_panel_labels=True,
        strict=True,
    )
    if alignment.get("verdict") != "PASS":
        raise RuntimeError(f"Outcome-figure alignment did not pass: {alignment.get('verdict')}")
    stem = FIGURES / "seven_method_outcomes_main"
    fig.savefig(stem.with_suffix(".pdf"), facecolor="white")
    svg_path = stem.with_suffix(".svg")
    fig.savefig(svg_path, facecolor="white")
    svg_path.write_bytes(re.sub(rb"[ \t]+(?=\r?$)", b"", svg_path.read_bytes(), flags=re.MULTILINE))
    fig.savefig(stem.with_suffix(".png"), dpi=600, facecolor="white")
    fig.savefig(stem.with_suffix(".tiff"), dpi=600, facecolor="white",
                pil_kwargs={"compression": "tiff_lzw"})
    plt.close(fig)

    pseudocode_alignment = generate_pseudocode()

    audit = {
        "historical_panel_source": "03_supplementary/five_method_summary.csv",
        "exploratory_panel_source": "03_supplementary/seven_method_outcomes_figure_source.csv",
        "figure_claim": "Forecast sharing improves on DWA-only input in the frozen 1-s benchmark but is not the highest-rate controller in either separate protocol.",
        "protocols_are_separate": True,
        "source_rows_used": {"historical_arms": len(historic_order), "exploratory_arms": len(seven_rows)},
        "excluded_rows": 0,
        "uncertainty": "Bars are point estimates; paired shared-minus-DWA-only intervals are shown directly above the panels (panel b uses a simultaneous max-|t| interval).",
        "contact_counts": "Swept-contact counts are shown in a row-aligned column and read from the source outcome CSVs.",
        "simulations_rerun": False,
        "outcome_alignment": alignment,
        "pseudocode_alignment": pseudocode_alignment,
    }
    (QA / "main_manuscript_figures_provenance.json").write_text(
        json.dumps(audit, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("Generated the main-text pseudocode and protocol-separated outcome plot from existing records.")


if __name__ == "__main__":
    main()
