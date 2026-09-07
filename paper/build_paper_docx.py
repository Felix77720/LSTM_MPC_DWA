"""Build an IEEE-style two-column EI conference paper draft (.docx).

Reads the multi-seed results CSVs produced by run_multiseed.m and writes a
Word document with the standard IEEE conference layout: full-width title and
abstract, then a continuous two-column body.
"""

import os
import pandas as pd

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


HERE = os.path.dirname(os.path.abspath(__file__))
RESULTS = os.path.normpath(os.path.join(HERE, "..", "results"))
OUT = os.path.join(HERE, "EI_paper_draft.docx")

TITLE = "LSTM Prediction-Enhanced Coupled MPC-DWA Dynamic Obstacle Avoidance for a UAV"


def read_csv(path):
    for enc in ("utf-8", "utf-8-sig", "gbk", "latin-1"):
        try:
            return pd.read_csv(path, encoding=enc)
        except (UnicodeDecodeError, UnicodeError):
            continue
    return pd.read_csv(path, encoding="utf-8", errors="replace")


def set_page(section):
    section.page_width = Inches(8.5)
    section.page_height = Inches(11.0)
    section.top_margin = Inches(0.75)
    section.bottom_margin = Inches(1.0)
    section.left_margin = Inches(0.625)
    section.right_margin = Inches(0.625)
    section.header_distance = Inches(0.4)
    section.footer_distance = Inches(0.4)


def set_columns(section, num, space_inches=0.25):
    sectPr = section._sectPr
    cols = sectPr.find(qn("w:cols"))
    if cols is None:
        cols = OxmlElement("w:cols")
        sectPr.append(cols)
    cols.set(qn("w:num"), str(num))
    cols.set(qn("w:space"), str(int(space_inches * 1440)))


def add_run(p, text, size=10, bold=False, italic=False, caps=False):
    r = p.add_run(text)
    r.font.size = Pt(size)
    r.bold = bold
    r.italic = italic
    if caps:
        r.font.all_caps = True
    return r


def set_open_table_borders(table, header_rows=1):
    """Booktabs-style table: top/mid/bottom rules, no vertical rules."""
    n_rows = len(table.rows)
    n_cols = len(table.columns)
    for ri, row in enumerate(table.rows):
        for ci, cell in enumerate(row.cells):
            tcPr = cell._tc.get_or_add_tcPr()
            borders = tcPr.find(qn("w:tcBorders"))
            if borders is None:
                borders = OxmlElement("w:tcBorders")
                tcPr.append(borders)
            for tag in ("top", "left", "bottom", "right"):
                el = borders.find(qn("w:" + tag))
                if el is None:
                    el = OxmlElement("w:" + tag)
                    borders.append(el)
                el.set(qn("w:val"), "none")
                el.set(qn("w:sz"), "0")
                el.set(qn("w:space"), "0")
                el.set(qn("w:color"), "auto")

    def rule(row, side, sz):
        for cell in row.cells:
            tcPr = cell._tc.get_or_add_tcPr()
            borders = tcPr.find(qn("w:tcBorders"))
            el = borders.find(qn("w:" + side))
            el.set(qn("w:val"), "single")
            el.set(qn("w:sz"), str(sz))
            el.set(qn("w:space"), "0")
            el.set(qn("w:color"), "000000")

    rule(table.rows[0], "top", 12)
    if header_rows > 0:
        rule(table.rows[header_rows - 1], "bottom", 8)
    rule(table.rows[n_rows - 1], "bottom", 12)


def add_table(doc, caption, headers, rows, font_size=8, col_widths=None):
    cap = doc.add_paragraph()
    cap.paragraph_format.space_before = Pt(6)
    cap.paragraph_format.space_after = Pt(2)
    cap.paragraph_format.keep_with_next = True
    add_run(cap, caption, size=font_size)

    table = doc.add_table(rows=0, cols=len(headers))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False

    hdr = table.add_row()
    for i, text in enumerate(headers):
        cell = hdr.cells[i]
        cell.text = ""
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        add_run(p, str(text), size=font_size, bold=True)

    for row in rows:
        tr = table.add_row()
        for i, val in enumerate(row):
            cell = tr.cells[i]
            cell.text = ""
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER if i > 0 else WD_ALIGN_PARAGRAPH.LEFT
            add_run(p, str(val), size=font_size)

    if col_widths:
        for i, w in enumerate(col_widths):
            for row in table.rows:
                row.cells[i].width = Inches(w)
    set_open_table_borders(table, header_rows=1)

    spacer = doc.add_paragraph()
    spacer.paragraph_format.space_after = Pt(2)
    return table


def add_heading(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.keep_with_next = True
    add_run(p, text, size=10, bold=True)
    return p


def add_subheading(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(5)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.keep_with_next = True
    add_run(p, text, size=10, bold=True, italic=True)
    return p


def add_body(doc, text, size=10):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    add_run(p, text, size=size)
    return p


def load_summary():
    path = os.path.join(RESULTS, "multiseed_summary.csv")
    if os.path.exists(path):
        return read_csv(path)
    return None


def load_comparison():
    path = os.path.join(RESULTS, "multiseed_comparison.csv")
    if os.path.exists(path):
        return read_csv(path)
    return None


def fmt(x, nd=2):
    if x is None or pd.isna(x):
        return "-"
    return f"{float(x):.{nd}f}"


def build_document():
    doc = Document()
    style = doc.styles["Normal"]
    style.font.name = "Times New Roman"
    style.font.size = Pt(10)
    rpr = style.element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.append(rfonts)
    rfonts.set(qn("w:ascii"), "Times New Roman")
    rfonts.set(qn("w:hAnsi"), "Times New Roman")
    rfonts.set(qn("w:eastAsia"), "Times New Roman")

    # ----- Full-width title / authors / abstract section -----
    sec1 = doc.sections[0]
    set_page(sec1)
    set_columns(sec1, 1)

    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    title.paragraph_format.space_after = Pt(4)
    add_run(title, TITLE, size=24, bold=True)

    authors = doc.add_paragraph()
    authors.alignment = WD_ALIGN_PARAGRAPH.CENTER
    authors.paragraph_format.space_after = Pt(2)
    add_run(authors, "Author One, Author Two, and Author Three", size=11)

    affil = doc.add_paragraph()
    affil.alignment = WD_ALIGN_PARAGRAPH.CENTER
    affil.paragraph_format.space_after = Pt(6)
    add_run(affil, "Department / Institution, City, Country  |  email@example.com", size=9)

    abstract = doc.add_paragraph()
    abstract.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    abstract.paragraph_format.space_after = Pt(5)
    add_run(abstract, "Abstract\u2014", size=9, bold=True)
    add_run(
        abstract,
        "This paper presents an LSTM prediction-enhanced motion planner for "
        "three-dimensional UAV dynamic obstacle avoidance, built on a bidirectionally "
        "coupled model predictive control (MPC) planning layer and dynamic window "
        "approach (DWA) execution layer. A long short-term memory network, trained "
        "with the MATLAB Deep Learning Toolbox, forecasts each dynamic obstacle's "
        "future three-dimensional trajectory over a 3 s horizon from a 1 s history. "
        "Predicted positions are injected into the MPC layer as time-varying soft "
        "collision constraints and into the DWA layer as a prediction-window minimum "
        "distance term. Training uses 300 independent random obstacle trajectories "
        "yielding 3600 windows. Four simulated scenarios of increasing difficulty "
        "compare the proposed method against static obstacle freezing and "
        "constant-velocity extrapolation. Across three random seeds, the LSTM-enhanced "
        "method is the only method to succeed in every trial, while the "
        "constant-velocity baseline yields the lowest average and final displacement "
        "errors on these fixed scenarios. All results are simulation-only and CPU-only.",
        size=9,
    )

    terms = doc.add_paragraph()
    terms.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    terms.paragraph_format.space_after = Pt(4)
    add_run(terms, "Index Terms\u2014", size=9, bold=True, italic=True)
    add_run(
        terms,
        "Dynamic obstacle avoidance, model predictive control, dynamic window "
        "approach, long short-term memory, trajectory prediction, unmanned aerial vehicle.",
        size=9,
    )

    # ----- Continuous two-column body -----
    sec2 = doc.add_section(WD_SECTION.CONTINUOUS)
    set_page(sec2)
    set_columns(sec2, 2, space_inches=0.25)

    add_heading(doc, "I. Introduction")
    add_body(
        doc,
        "Safe navigation in three-dimensional space is central to operating an "
        "unmanned aerial vehicle (UAV) among other moving vehicles. A practical motion "
        "planner must reach a goal while keeping clearance from obstacles whose future "
        "motion is only partially predictable. A plan based on the latest measurement "
        "can become invalid before it is executed when obstacles turn, stop, or maneuver.",
    )
    add_body(
        doc,
        "This work builds on a baseline in which an MPC planning layer and a DWA "
        "execution layer are bidirectionally coupled. The MPC layer produces a "
        "receding-horizon reference plan, and the DWA layer searches locally executable "
        "candidate controls and returns feasible execution information to the planner. "
        "This combines the look-ahead of optimization with the fast feasibility checks "
        "of a reactive executor. The implementation is written in MATLAB and uses "
        "CasADi with the IPOPT solver.",
    )
    add_body(
        doc,
        "The contribution of this paper is a long short-term memory (LSTM) prediction "
        "module that forecasts the future three-dimensional trajectory of each dynamic "
        "obstacle over a 3 s horizon from a 1 s history. The predicted positions are "
        "used in two places. First, they become time-varying soft collision constraints "
        "in the MPC layer, so the planner sees a different obstacle position at every "
        "future step instead of one frozen position. Second, they become a "
        "prediction-window minimum-distance term in the DWA layer, so each candidate "
        "trajectory is evaluated over the predicted obstacle window rather than only at "
        "the current obstacle position. Four simulated scenarios of increasing "
        "difficulty compare the method against a static baseline that freezes each "
        "obstacle and a constant-velocity baseline that extrapolates motion.",
    )

    add_heading(doc, "II. Related Work")
    add_body(
        doc,
        "Hierarchical planning architectures in which a mid-horizon optimizer and a "
        "local reactive planner cooperate are widely used for ground robots and UAVs "
        "[1]-[3]. MPC provides dynamics-aware look-ahead and constraint handling, while "
        "DWA tests candidate controls by short-horizon propagation and enforces braking "
        "feasibility [4]. Hybrid formulations exchange reference trajectories, feasible "
        "control sets, or tracking feedback between the two layers [1], [4].",
    )
    add_body(
        doc,
        "For dynamic environments, a model of future obstacle motion is required. "
        "Static freezing is simple but unsafe for fast obstacles, and constant-velocity "
        "extrapolation fails when obstacles turn, stop, or hover before maneuvering "
        "[5]. Learning-based sequence models, including LSTM networks, have been "
        "applied to trajectory prediction for pedestrians, vehicles, and robots [5], "
        "[6], and have been coupled to planning and control [6], [7]. This paper "
        "differs in the integration pattern: one LSTM predictor is trained offline in "
        "MATLAB, and its forecasts are injected into both the MPC planner and the DWA "
        "executor through time-varying obstacle data. Static and constant-velocity "
        "baselines make the value of learned prediction explicit.",
    )

    add_heading(doc, "III. Method")

    add_subheading(doc, "A. UAV Dynamics")
    add_body(
        doc,
        "Time is discretized with step index t. The ego UAV follows a first-order "
        "unicycle-like model whose state includes three-dimensional position, pitch and "
        "yaw angles, and speed. The commanded speed follows the actual speed through a "
        "first-order response, while pitch and yaw rates integrate directly. The "
        "control input is the commanded speed and the pitch and yaw rates.",
    )

    add_subheading(doc, "B. Coupled MPC-DWA Baseline")
    add_body(
        doc,
        "At each control cycle, the MPC layer solves a finite-horizon optimal control "
        "problem over N steps with a cost that penalizes distance to the goal, control "
        "magnitude, and control variation. The solution gives a reference trajectory and "
        "a first-step command. The DWA layer then constructs the dynamic window of "
        "controls reachable from the current state, samples candidates near the MPC "
        "command with an additional exploration region, and propagates each candidate "
        "through a short ego trajectory. Each candidate is checked against a braking "
        "feasibility condition and scored by goal progress, agreement with the MPC "
        "reference, speed, and obstacle clearance. The best executable candidate is "
        "applied to the simulated ego model. Feasible DWA controls are summarized into "
        "a constraint box for the next MPC solve, and the executed control and state "
        "warm-start the next optimization, closing the bidirectional coupling.",
    )

    add_subheading(doc, "C. LSTM Trajectory Predictor")
    add_body(
        doc,
        "The predictor is an LSTM network trained and evaluated with the MATLAB Deep "
        "Learning Toolbox. For each obstacle at time t, the network receives a 1 s "
        "kinematic history containing position, velocity, and a continuous "
        "representation of heading, and outputs the predicted three-dimensional "
        "position sequence over the following 3 s. The same network is applied "
        "independently to each obstacle. Training data come from 300 independent random "
        "obstacle trajectories, from which 3600 input-output windows are extracted; the "
        "training trajectories are generated separately from the four fixed evaluation "
        "scenarios.",
    )

    add_subheading(doc, "D. Time-Varying Constraint Injection")
    add_body(
        doc,
        "Let P(t+k|t) be the predicted position of obstacle j at future step k, and "
        "let p(t+k|t) be the planned ego position. The signed clearance is "
        "g = norm(p - P) - r_j - r_e, where r_j is the obstacle radius and r_e is the "
        "ego safety radius. The MPC obstacle cost is a weighted sum of "
        "max(0, -g)^2 over the first H_inj prediction steps and all obstacles. Because "
        "the predicted position changes with k, the constraint is time varying. The "
        "formulation is soft, so predicted violations are penalized instead of making "
        "the whole optimization infeasible. The injection horizon H_inj can be shorter "
        "than the full MPC horizon; it is varied in the ablation study.",
    )
    add_body(
        doc,
        "In the DWA layer, the obstacle score of a candidate trajectory is based on the "
        "minimum signed clearance between that trajectory and all predicted obstacle "
        "positions over the available prediction window. Taking the minimum over both "
        "time and obstacles gives the executor a forward-looking safety signal "
        "consistent with the MPC layer, instead of scoring only against the current "
        "obstacle position.",
    )

    add_subheading(doc, "E. Baselines")
    add_body(
        doc,
        "Two non-learning baselines populate the same obstacle-position interface. The "
        "static baseline holds every obstacle at its latest measured position. The "
        "constant-velocity baseline extrapolates each obstacle with its latest measured "
        "velocity. All other parts of the control loop, including DWA sampling "
        "randomness and MPC solver settings, are identical across methods in a given "
        "comparison.",
    )

    add_heading(doc, "IV. Experiments")

    add_subheading(doc, "A. Setup")
    add_body(
        doc,
        "All experiments are closed-loop simulations in MATLAB using CasADi and "
        "IPOPT. The LSTM predictor runs with the Deep Learning Toolbox. All computation "
        "is CPU-only, and no real-time hardware or embedded execution is considered. "
        "Training uses 300 independent trajectories; evaluation uses four fixed "
        "scenarios excluded from training. The prediction history is 1 s and the "
        "prediction horizon is 3 s.",
    )

    add_subheading(doc, "B. Scenarios and Metrics")
    add_table(
        doc,
        "Table I. Evaluation scenarios in increasing order of difficulty.",
        ["Scenario", "Obstacle set and motion"],
        [
            ["S1: Straight crossing", "One obstacle crosses the nominal route with straight motion."],
            ["S2: Line and turn", "Two obstacles approach from opposite sides; one turns."],
            ["S3: Three crossings", "Straight, turning, and hover-then-maneuver obstacles cross near the route."],
            ["S4: Mixed nonlinear", "Two zigzag obstacles and one hover-then-maneuver obstacle."],
        ],
        font_size=8,
        col_widths=[1.1, 2.7],
    )
    add_body(
        doc,
        "A run succeeds when the ego UAV reaches the goal within tolerance and "
        "experiences zero collisions. Recorded metrics are success rate, collision "
        "count, minimum signed clearance, path length, tracking RMSE against the "
        "start-to-goal line, per-step solve time, and prediction average displacement "
        "error (ADE) and final displacement error (FDE).",
    )

    summary = load_summary()
    comparison = load_comparison()

    add_subheading(doc, "C. Comparison Results")
    if summary is not None and comparison is not None:
        method_rows = {}
        for _, row in summary.iterrows():
            method_rows[row["Method"]] = row

        # Per-scenario success over three seeds.
        scen_map = {}
        if "Scenario" in comparison.columns:
            for _, row in comparison.iterrows():
                name = str(row["Scenario"])
                key = name.strip()[:2].upper()
                if key not in ("S1", "S2", "S3", "S4"):
                    key = name.strip().split()[0][:2].upper()
                scen_map.setdefault(key, {})
                scen_map[key].setdefault(str(row["Method"]), [0, 0])
                scen_map[key][str(row["Method"])][0] += 1
                scen_map[key][str(row["Method"])][1] += int(row["Success"])

        scen_labels = {
            "S1": "S1: Straight crossing",
            "S2": "S2: Line and turn",
            "S3": "S3: Three crossings",
            "S4": "S4: Mixed nonlinear",
        }
        methods = ["static", "cv", "lstm"]
        scen_rows = []
        for key in ("S1", "S2", "S3", "S4"):
            row = [scen_labels.get(key, key)]
            for m in methods:
                trials, succ = scen_map.get(key, {}).get(m, [0, 0])
                row.append(f"{succ}/{trials}")
            scen_rows.append(row)

        add_table(
            doc,
            "Table II. Per-scenario success over three random seeds.",
            ["Scenario", "Static", "Const-vel", "LSTM"],
            scen_rows,
            font_size=8,
            col_widths=[1.55, 0.75, 0.75, 0.75],
        )

        agg_rows = []
        labels = {"static": "Static", "cv": "Const-vel", "lstm": "LSTM"}
        for m in methods:
            r = method_rows.get(m)
            if r is None:
                continue
            trials = int(r["Trials"])
            succ = int(r["SuccessCount"])
            agg_rows.append(
                [
                    labels[m],
                    f"{succ}/{trials}",
                    f"{fmt(r['MeanCollisions'],1)}\u00b1{fmt(r['StdCollisions'],1)}",
                    f"{fmt(r['MeanMinSafeDist_m'])}\u00b1{fmt(r['StdMinSafeDist_m'])}",
                    f"{fmt(r['MeanADE_m'])}\u00b1{fmt(r['StdADE_m'])}",
                    f"{fmt(r['MeanFDE_m'])}\u00b1{fmt(r['StdFDE_m'])}",
                    f"{fmt(r['MedianStepTime_ms'],0)}",
                ]
            )
        add_table(
            doc,
            "Table III. Aggregate comparison over three seeds (mean \u00b1 std; "
            "step time is the median).",
            ["Method", "Success", "Coll.", "Min. clear. (m)", "ADE (m)", "FDE (m)", "Step (ms)"],
            agg_rows,
            font_size=8,
            col_widths=[0.85, 0.6, 0.7, 0.95, 0.95, 0.95, 0.7],
        )
        add_body(
            doc,
            "Across three seeds, the LSTM method completes every scenario in every "
            "trial (12/12), the constant-velocity baseline succeeds in 11/12 trials, "
            "and the static baseline in 6/12. The static baseline has the largest "
            "prediction error because it assumes no motion. On these fixed scenarios "
            "the constant-velocity baseline has the lowest mean ADE and FDE, so the "
            "LSTM success advantage is attributed to the integrated time-varying "
            "injection rather than to lower raw forecast error.",
        )
    else:
        add_body(
            doc,
            "Multi-seed result files were not available at build time; see "
            "results/analysis.md for the single-seed comparison.",
        )

    add_subheading(doc, "D. Ablation on Injection Horizon")
    add_body(
        doc,
        "The number of injected prediction steps H_inj controls how much of the "
        "predicted obstacle window is used by the avoidance layers. The logged "
        "single-seed ablation shows that increasing H_inj from 10 to 20 steps improves "
        "success and minimum clearance, while a further increase to 30 steps raises "
        "clearance but does not preserve the success-rate gain. This trade-off is "
        "single-seed and therefore qualitative: longer look-ahead improves clearance "
        "but places weight on more distant predictions where forecast error and "
        "feasibility issues accumulate. A multi-seed ablation is left as future work.",
    )

    add_subheading(doc, "E. Discussion")
    add_body(
        doc,
        "The results support two conclusions. First, injecting a learned trajectory "
        "forecast into both planning layers yields the most reliable closed-loop "
        "avoidance: the LSTM-enhanced method succeeds in all 12 trials, while the "
        "constant-velocity and static baselines succeed in 11 and 6, respectively. "
        "Second, the reliability gain is not explained by raw forecast accuracy, "
        "because the constant-velocity baseline has the lowest ADE and FDE on these "
        "fixed scenarios; the benefit therefore comes from how the predicted window is "
        "used by the MPC and DWA layers. The earlier single-seed log that suggested a "
        "lower LSTM prediction error did not reproduce across seeds, underscoring the "
        "need for multi-seed reporting. The main limitations are simulation-only "
        "evaluation, CPU-only execution, and the absence of sensor noise, delays, or "
        "flight validation. Minimum clearance and ADE/FDE are the more informative "
        "primary metrics, while success remains a coarse binary summary.",
    )

    add_heading(doc, "V. Conclusion")
    add_body(
        doc,
        "This paper presented an LSTM prediction-enhanced coupled MPC-DWA framework "
        "for three-dimensional UAV dynamic obstacle avoidance. A single LSTM predictor "
        "forecasts each dynamic obstacle's trajectory over a 3 s horizon from a 1 s "
        "history, and the forecast is injected as time-varying soft collision "
        "constraints in the MPC layer and as a prediction-window minimum-distance term "
        "in the DWA layer. In a three-seed simulation study over four increasingly "
        "difficult scenarios, the proposed method succeeded in every trial, "
        "outperforming the constant-velocity and static baselines in avoidance "
        "reliability; the constant-velocity baseline remained the most accurate raw "
        "predictor on these fixed scenarios. Future work should add multi-seed "
        "ablation, noisy and partial obstacle observations, and real-time hardware "
        "evaluation.",
    )

    add_heading(doc, "References")
    add_body(
        doc,
        "References are placeholders pending author verification.",
        size=9,
    )
    for i in range(1, 8):
        p = doc.add_paragraph()
        p.paragraph_format.space_after = Pt(1)
        add_run(p, f"[{i}] [PLACEHOLDER: verify real reference]", size=9)

    doc.save(OUT)
    print("Wrote", OUT)
    if summary is not None:
        print("Multi-seed summary columns:", list(summary.columns))
        print(summary.to_string(index=False))


if __name__ == "__main__":
    build_document()
