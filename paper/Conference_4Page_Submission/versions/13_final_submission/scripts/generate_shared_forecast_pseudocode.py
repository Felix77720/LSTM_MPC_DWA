"""Render a compact pseudocode overview of the implemented MPC-DWA cycle."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import matplotlib as mpl
mpl.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

SCRIPT_DIR = Path(__file__).resolve().parent
REVISION = SCRIPT_DIR.parent
PROJECT = SCRIPT_DIR.parents[4]
FIGURE_SKILL_SCRIPTS = PROJECT.parent / ".agents" / "skills" / "nature-figure" / "scripts"
sys.path.insert(0, str(FIGURE_SKILL_SCRIPTS))
from audit_panel_alignment import require_matplotlib_panel_alignment

FIGURES = REVISION / "02_source" / "figures"
QA = REVISION / "qa"
STEM = "shared_forecast_pseudocode_algorithm_s1"

mpl.rcParams.update({
    "font.family": "sans-serif",
    "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans", "sans-serif"],
    "font.size": 7.0,
    "svg.fonttype": "none",
    "pdf.fonttype": 42,
    "ps.fonttype": 42,
    "savefig.facecolor": "white",
})


def main() -> None:
    FIGURES.mkdir(parents=True, exist_ok=True)
    QA.mkdir(parents=True, exist_ok=True)
    width, height = 7.05, 3.50
    fig, ax = plt.subplots(figsize=(7.05, 3.50), dpi=300)
    fig.subplots_adjust(left=0, right=1, bottom=0, top=1)
    ax.set_xlim(0, width)
    ax.set_ylim(0, height)
    ax.set_axis_off()

    panel = FancyBboxPatch(
        (0.06, 0.08), width - 0.12, height - 0.16,
        boxstyle="round,pad=0.018,rounding_size=0.045",
        linewidth=0.8, edgecolor="#AAB6C2", facecolor="#FBFCFD", zorder=0,
    )
    ax.add_patch(panel)
    ax.text(0.24, 3.18, "Algorithm S1 | Shared-forecast MPC-DWA cycle",
            ha="left", va="center", fontsize=10.0, fontweight="bold",
            color="#26374A")
    ax.text(0.24, 2.96,
            "Input: current UAV state, latest 10 obstacle observations, previous MPC solution",
            ha="left", va="center", fontsize=7.5, color="#3D4A57")

    code = [
        ("for each 0.1-s update:", "#26374A", "bold", 0),
        ("1  Predict 30 future obstacle positions from the latest 10 observations with LSTM.", "#25877C", "normal", 1),
        ("2  Share this time-indexed forecast with MPC and DWA.", "#25877C", "normal", 1),
        ("3  Initialize/shift MPC guide; update trust from safety, progress, tracking and smoothness.", "#4B729D", "normal", 1),
        ("4  Split guided/exploratory DWA samples using trust/MPC guidance; rank by score.", "#C47A27", "normal", 1),
        ("5  Roll out candidates over the same 30-step forecast.", "#C47A27", "normal", 1),
        ("6  Retain clearance >0.25 m, corridor and braking passes; score survivors.", "#C47A27", "normal", 1),
        ("7  Choose the top safe DWA action/envelope; otherwise screen emergency actions.", "#C47A27", "normal", 1),
        ("8  If none passes, stop; otherwise re-screen the selected emergency action.", "#B95043", "normal", 1),
        ("9  Re-solve MPC on the same forecast: DWA envelope normally; physical bounds in recovery.", "#4B729D", "normal", 1),
        ("10 Apply screened DWA/emergency action for 0.1 s; update state/history and repeat.", "#26374A", "normal", 1),
    ]
    y0, dy = 2.68, 0.215
    for index, (line, color, weight, indent) in enumerate(code):
        ax.text(0.27 + 0.22 * indent, y0 - index * dy, line,
                ha="left", va="center", fontsize=7.7,
                fontfamily="DejaVu Sans Mono", fontweight=weight,
                color=color, clip_on=True)

    ax.text(0.24, 0.24,
            "Output: checked next action and updated MPC guide, or a fail-closed stop",
            ha="left", va="center", fontsize=7.5, color="#3D4A57")

    alignment = require_matplotlib_panel_alignment(
        fig,
        json_out=QA / f"{STEM}.alignment.json",
        overlay_svg=QA / f"{STEM}.alignment.svg",
        tolerance_pt=1.5,
        gutter_tolerance_pt=1.5,
        strict=True,
    )
    svg_path = FIGURES / f"{STEM}.svg"
    fig.savefig(svg_path, facecolor="white")
    svg_path.write_bytes(re.sub(rb"[ \t]+(?=\r?$)", b"", svg_path.read_bytes(), flags=re.MULTILINE))
    fig.savefig(FIGURES / f"{STEM}.pdf", facecolor="white")
    fig.savefig(FIGURES / f"{STEM}.png", facecolor="white", dpi=600)
    fig.savefig(FIGURES / f"{STEM}.tiff", facecolor="white", dpi=600,
                pil_kwargs={"compression": "tiff_lzw"})
    plt.close(fig)

    audit = {
        "source": "supplementary_methods.tex, S1.1-S1.4",
        "purpose": "pseudocode overview of the implemented shared-forecast loop",
        "input": "current UAV state, latest ten obstacle observations, previous MPC solution",
        "forecast": "one causal 30-step LSTM forecast shared by MPC and DWA",
        "trust_update": "safety, goal progress, route tracking and control smoothness guide DWA sampling",
        "control_period_s": 0.1,
        "normal_clearance_gate_m": 0.25,
        "normal_branch": "DWA screening and envelope; MPC re-solve uses the envelope",
        "recovery_branch": "emergency candidates are re-screened; stop if none passes",
        "recovery_mpc_bounds": "physical input bounds",
        "output": "screened DWA/emergency action and updated MPC guide, or fail-closed stop",
        "new_simulation_or_route_data": False,
        "exports": [f"{STEM}.pdf", f"{STEM}.svg", f"{STEM}.png", f"{STEM}.tiff"],
        "panel_alignment": alignment,
    }
    (QA / f"{STEM}.json").write_text(
        json.dumps(audit, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Rendered {STEM} from the existing implemented cycle.")


if __name__ == "__main__":
    main()
