"""Render the 3-s integrated-controller comparison from frozen CSV summaries."""
from __future__ import annotations

import csv
import json
import re
import sys
from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np

SCRIPT_DIR = Path(__file__).resolve().parent
REVISION = SCRIPT_DIR.parent
PROJECT = SCRIPT_DIR.parents[4]
FIGURE_SKILL_SCRIPTS = PROJECT.parent / ".agents" / "skills" / "nature-figure" / "scripts"
sys.path.insert(0, str(FIGURE_SKILL_SCRIPTS))
from audit_panel_alignment import require_matplotlib_panel_alignment

SOURCE = REVISION / "03_supplementary" / "integrated_3s_figure_source.csv"
FIGURES = REVISION / "02_source" / "figures"
QA = REVISION / "qa"
STEM = "integrated_3s_outcomes_main"

ORDER = ["static", "cv", "lstm_mpc_cv_dwa", "cv_mpc_lstm_dwa", "lstm"]
SHORT_LABELS = {
    "static": "Position hold",
    "cv": "Coupled CV",
    "lstm_mpc_cv_dwa": "LSTM to MPC",
    "cv_mpc_lstm_dwa": "LSTM to DWA",
    "lstm": "Shared LSTM",
}
COLORS = {
    "static": "#9AA0A6",
    "cv": "#8DA0CB",
    "lstm_mpc_cv_dwa": "#C7B9D9",
    "cv_mpc_lstm_dwa": "#D9A0AE",
    "lstm": "#4B2E83",
}

mpl.rcParams.update({
    "font.family": "sans-serif",
    "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans", "sans-serif"],
    "font.size": 7.4,
    "axes.labelsize": 7.3,
    "axes.titlesize": 7.6,
    "xtick.labelsize": 6.8,
    "ytick.labelsize": 6.8,
    "axes.linewidth": 0.65,
    "axes.spines.top": False,
    "axes.spines.right": False,
    "legend.frameon": False,
    "pdf.fonttype": 42,
    "ps.fonttype": 42,
    "svg.fonttype": "none",
    "savefig.facecolor": "white",
})


def read_rows() -> list[dict[str, str]]:
    with SOURCE.open("r", encoding="utf-8-sig", newline="") as stream:
        rows = list(csv.DictReader(stream))
    by_key = {row["method_key"]: row for row in rows}
    if set(by_key) != set(ORDER) or len(rows) != len(ORDER):
        raise ValueError("The integrated 3-s figure source must contain each expected method once.")
    for key, row in by_key.items():
        if int(row["episodes"]) != 300:
            raise ValueError(f"Unexpected episode count for {key}.")
        rate = float(row["safe_arrival_rate"])
        count = int(row["safe_arrivals"])
        if not np.isclose(rate, count / 300.0, atol=1e-12, rtol=0):
            raise ValueError(f"Arrival count and rate disagree for {key}.")
    return [by_key[key] for key in ORDER]


def main() -> None:
    rows = read_rows()
    FIGURES.mkdir(parents=True, exist_ok=True)
    QA.mkdir(parents=True, exist_ok=True)

    fig, (ax_rate, ax_delta) = plt.subplots(
        2, 1, figsize=(3.42, 3.05), gridspec_kw={"height_ratios": [1.15, 1.0]},
        constrained_layout=False,
    )
    fig.subplots_adjust(left=0.34, right=0.96, top=0.94, bottom=0.12, hspace=0.66)

    y = np.arange(len(rows))[::-1]
    rates = np.array([float(row["safe_arrival_rate"]) * 100 for row in rows])
    lows = np.array([float(row["absolute_ci_low"]) * 100 for row in rows])
    highs = np.array([float(row["absolute_ci_high"]) * 100 for row in rows])
    xerr = np.vstack([rates - lows, highs - rates])
    colors = [COLORS[row["method_key"]] for row in rows]
    for index, row in enumerate(rows):
        key = row["method_key"]
        ax_rate.errorbar(
            rates[index], y[index],
            xerr=np.array([[xerr[0, index]], [xerr[1, index]]]),
            fmt="o", markersize=4.7 if key == "lstm" else 4.0,
            markerfacecolor=COLORS[key], markeredgecolor="white",
            markeredgewidth=0.55, ecolor=COLORS[key], elinewidth=1.35,
            capsize=2.2, capthick=1.0, zorder=4,
        )
        label_dy = -0.58
        ax_rate.text(
            rates[index], y[index] + label_dy, f"{rates[index]:.1f}",
            va="center", ha="center", fontsize=6.8,
            color="#2D2242" if key == "lstm" else "#4D5358",
            fontweight="bold" if key == "lstm" else "normal",
        )
    ax_rate.set_yticks(y, [SHORT_LABELS[row["method_key"]] for row in rows])
    ax_rate.set_ylim(-0.90, 4.25)
    ax_rate.set_xlim(44, 88)
    ax_rate.set_xticks([50, 60, 70, 80])
    ax_rate.set_xlabel("Collision-free arrival (%)")
    ax_rate.set_title("Safe-arrival rate", loc="left", pad=3.0)
    ax_rate.grid(axis="x", color="#D9DDE2", linewidth=0.45, alpha=0.75)
    ax_rate.tick_params(axis="y", length=0, pad=2)
    ax_rate.text(-0.30, 1.025, "a", transform=ax_rate.transAxes,
                 fontsize=8.2, fontweight="bold", va="bottom", ha="left")

    comparator_rows = rows[:-1]
    y2 = np.arange(len(comparator_rows))[::-1]
    diffs = np.array([float(row["shared_minus_comparator_pp"]) for row in comparator_rows])
    dlows = np.array([float(row["simultaneous_ci_low_pp"]) for row in comparator_rows])
    dhighs = np.array([float(row["simultaneous_ci_high_pp"]) for row in comparator_rows])
    derr = np.vstack([diffs - dlows, dhighs - diffs])
    ax_delta.axvline(0, color="#6F7780", linestyle="--", linewidth=0.8, zorder=1)
    for index, row in enumerate(comparator_rows):
        key = row["method_key"]
        significant = dlows[index] > 0 or dhighs[index] < 0
        color = "#4B2E83" if significant else "#9B8DB7"
        ax_delta.errorbar(
            diffs[index], y2[index],
            xerr=np.array([[derr[0, index]], [derr[1, index]]]),
            fmt="o", markersize=4.4, markerfacecolor=color,
            markeredgecolor="white", markeredgewidth=0.55,
            ecolor=color, elinewidth=1.35, capsize=2.2, capthick=1.0, zorder=4,
        )
        label_x = diffs[index] if significant else dhighs[index] + 0.65
        label_y = y2[index] - 0.36 if significant else y2[index]
        ax_delta.text(
            label_x, label_y, f"{diffs[index]:+.1f}",
            va="center", ha="center" if significant else "left", fontsize=6.7,
            color="#2D2242" if significant else "#555B61",
            fontweight="bold" if significant else "normal",
        )
    ax_delta.set_yticks(y2, [SHORT_LABELS[row["method_key"]] for row in comparator_rows])
    ax_delta.set_xlim(-13, 35)
    ax_delta.set_xticks([-10, 0, 10, 20, 30])
    ax_delta.set_xlabel("Shared minus comparator (pp)")
    ax_delta.set_title("Shared LSTM minus comparator", loc="left", pad=3.0)
    ax_delta.grid(axis="x", color="#D9DDE2", linewidth=0.45, alpha=0.75)
    ax_delta.tick_params(axis="y", length=0, pad=2)
    ax_delta.text(-0.30, 1.025, "b", transform=ax_delta.transAxes,
                  fontsize=8.2, fontweight="bold", va="bottom", ha="left")

    alignment = require_matplotlib_panel_alignment(
        fig,
        json_out=QA / f"{STEM}.alignment.json",
        overlay_svg=QA / f"{STEM}.alignment.svg",
        tolerance_pt=1.5,
        gutter_tolerance_pt=1.5,
        require_panel_labels=True,
        strict=True,
        column_groups=[["a", "b"]],
        panel_ids={ax_rate: "a", ax_delta: "b"},
    )

    pdf_path = FIGURES / f"{STEM}.pdf"
    svg_path = FIGURES / f"{STEM}.svg"
    fig.savefig(pdf_path, facecolor="white")
    fig.savefig(svg_path, facecolor="white")
    svg_path.write_bytes(re.sub(rb"[ \t]+(?=\r?$)", b"", svg_path.read_bytes(), flags=re.MULTILINE))
    fig.savefig(FIGURES / f"{STEM}.png", facecolor="white", dpi=600)
    fig.savefig(
        FIGURES / f"{STEM}.tiff", facecolor="white", dpi=600,
        pil_kwargs={"compression": "tiff_lzw"},
    )
    plt.close(fig)

    (QA / f"{STEM}.json").write_text(
        json.dumps({
            "core_conclusion": (
                "Within the 3-s integrated MPC-DWA comparison, shared LSTM improves "
                "safe arrival over position hold. Differences from coupled CV and "
                "one-layer LSTM injection remain uncertain."
            ),
            "source": SOURCE.relative_to(PROJECT).as_posix(),
            "episodes_per_method": 300,
            "independent_unit": "scene; three matched seeds averaged within scene",
            "absolute_intervals": "scene-bootstrap percentile 95% intervals",
            "paired_intervals": "simultaneous max-|t| 95% scene-cluster intervals",
            "alignment": alignment,
            "exports": [f"{STEM}.{ext}" for ext in ("pdf", "svg", "png", "tiff")],
        }, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Saved {pdf_path}")


if __name__ == "__main__":
    main()
