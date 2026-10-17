"""Generate the main-text pseudocode and protocol-separated outcome figure.

All plotted counts are read from existing supplementary outcome tables. This
script does not run or alter simulations.
"""

from __future__ import annotations

import argparse
import csv
import json
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
    """Render the main-text algorithm as a modular, stepwise flow diagram."""
    FIGURES.mkdir(parents=True, exist_ok=True)
    QA.mkdir(parents=True, exist_ok=True)
    width, height = 3.48, 2.75
    fig, ax = plt.subplots(figsize=(width, height), dpi=300)
    fig.subplots_adjust(left=0, right=1, bottom=0, top=1)
    ax.set_xlim(0, width)
    ax.set_ylim(0, height)
    ax.set_axis_off()

    def module(x: float, y: float, w: float, h: float, title: str,
               lines: tuple[str, ...], accent: str, *, body_size: float = 6.7) -> None:
        ax.add_patch(FancyBboxPatch(
            (x, y), w, h, boxstyle="round,pad=0.018,rounding_size=0.045",
            linewidth=0.65, edgecolor=accent, facecolor="white", zorder=2,
        ))
        ax.add_patch(FancyBboxPatch(
            (x + 0.008, y + h - 0.19), w - 0.016, 0.182,
            boxstyle="round,pad=0.006,rounding_size=0.035",
            linewidth=0, edgecolor="none", facecolor=accent, alpha=0.10, zorder=2,
        ))
        ax.text(x + 0.085, y + h - 0.095, title, ha="left", va="center",
                fontsize=7.3, fontweight="bold", color=accent, zorder=3)
        body_y = y + h - 0.26
        for index, line in enumerate(lines):
            ax.text(x + 0.085, body_y - index * 0.105, line,
                    ha="left", va="center", fontsize=body_size,
                    color=INK, zorder=3)

    # Step 1 fans one causal forecast into two distinct planner modules.
    module(0.10, 2.30, 3.28, 0.42, "1  OBSERVE → FORECAST",
           ("10 observations → LSTM → 30 positions (3 s)",
            "The time-aligned forecast feeds both MPC and DWA."), SHARED)
    module(0.10, 1.25, 1.54, 0.80, "2a  MPC | route optimizer",
           ("30-step forecast enters cost.",
            "Shift guide; compute trust.",
            "Return route and command."), "#4B729D")
    module(1.84, 1.25, 1.54, 0.80, "2b  DWA | action selector",
           ("Use forecast and MPC guide.",
            "Split guided/exploration samples.",
            "Roll out, screen, score."), "#A86C20")
    module(0.10, 0.60, 3.28, 0.45, "3  COUPLE + RE-SOLVE",
           ("Passing DWA controls bound MPC's first input.",
            "Recentered commands replace it only if re-screening passes."), "#4B729D")
    module(0.10, 0.07, 3.28, 0.40, "4  EXECUTE + REPEAT",
           ("Apply screened action for 0.1 s; then repeat.",
            "If no emergency action passes, stop."), "#425466")

    arrow = dict(arrowstyle="-|>", color="#758692", lw=0.75, mutation_scale=7)
    ax.annotate("", xy=(0.86, 2.05), xytext=(0.86, 2.30), arrowprops=arrow, zorder=1)
    ax.annotate("", xy=(2.61, 2.05), xytext=(2.61, 2.30), arrowprops=arrow, zorder=1)
    ax.annotate("", xy=(0.87, 1.05), xytext=(0.87, 1.25), arrowprops=arrow, zorder=1)
    ax.annotate("", xy=(2.61, 1.05), xytext=(2.61, 1.25), arrowprops=arrow, zorder=1)
    ax.annotate("", xy=(1.74, 0.47), xytext=(1.74, 0.60), arrowprops=arrow, zorder=1)

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
    fig.savefig(stem.with_suffix(".svg"), facecolor="white")
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
        generate_pseudocode()
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
        ("MPC-DWA: DWA-only LSTM", "Integrated: LSTM to DWA only"),
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
        ("LSTM to MPC only", "MPC-DWA (LSTM to MPC only)"),
        ("LSTM to DWA only", "MPC-DWA (LSTM to DWA only)"),
        ("Shared LSTM", "MPC-DWA (shared LSTM)"),
        ("Latest-position hold", "MPC-DWA (latest-position hold)"),
    ]
    seven = {row["method"]: row for row in seven_rows}
    if set(key for _, key in seven_order) != set(seven):
        raise ValueError("Seven-arm display mapping does not match source rows.")

    # Panel contract: compare controller rates within each frozen protocol;
    # never combine the arms into one cross-protocol ranking.
    fig, axes = plt.subplots(2, 1, figsize=(3.42, 3.25), sharex=True)
    fig.subplots_adjust(left=0.39, right=0.98, bottom=0.105, top=0.91, hspace=0.58)
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
        ax.set_xlim(0, 108)
        ax.set_xticks([0, 25, 50, 75, 100])
        ax.set_title(title, loc="left", color=INK, fontweight="bold", pad=3)
        ax.grid(False, axis="x")
        ax.tick_params(axis="both", length=1.8, width=0.5, pad=1.0, colors=BODY)
        for yi, rate in zip(y, rates):
            if rate <= 5.0:
                label_x, label_ha = rate + 2.0, "left"
            else:
                label_x, label_ha = rate - 2.5, "right"
            ax.text(label_x, yi, f"{rate:.1f}%", va="center", ha=label_ha,
                    color=INK, fontsize=5.5, clip_on=True, zorder=5)
        ax.text(-0.18, 1.02, letter, transform=ax.transAxes, ha="left", va="bottom",
                fontsize=7.2, fontweight="bold", color=INK)
    axes[0].set_xlabel("")
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
    fig.savefig(stem.with_suffix(".svg"), facecolor="white")
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
        "uncertainty": "Point estimates only. Matched scene-cluster intervals are reported in text/SI; they are not arm-wise intervals.",
        "simulations_rerun": False,
        "outcome_alignment": alignment,
        "pseudocode_alignment": pseudocode_alignment,
    }
    (QA / "main_manuscript_figures_provenance.json").write_text(
        json.dumps(audit, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("Generated the main-text pseudocode and protocol-separated outcome plot from existing records.")


if __name__ == "__main__":
    main()
