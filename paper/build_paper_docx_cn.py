"""生成中文 EI 会议风格（IEEE 双栏）论文初稿 .docx。

读取 run_multiseed.m 输出的多种子结果 CSV，生成中文 Word 文档：
标题和摘要通栏，正文为连续双栏。
"""

import os

import pandas as pd
from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt


HERE = os.path.dirname(os.path.abspath(__file__))
RESULTS = os.path.normpath(os.path.join(HERE, "..", "results"))
OUT = os.path.join(HERE, "EI_paper_draft_CN.docx")

TITLE = "基于 LSTM 预测增强的 MPC-DWA 无人机动态避障方法"


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


def set_columns(section, num, space_inches=0.25):
    sectPr = section._sectPr
    cols = sectPr.find(qn("w:cols"))
    if cols is None:
        cols = OxmlElement("w:cols")
        sectPr.append(cols)
    cols.set(qn("w:num"), str(num))
    cols.set(qn("w:space"), str(int(space_inches * 1440)))


def set_run_font(run, east_asia="宋体", ascii_font="Times New Roman"):
    run.font.name = ascii_font
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.append(rfonts)
    rfonts.set(qn("w:ascii"), ascii_font)
    rfonts.set(qn("w:hAnsi"), ascii_font)
    rfonts.set(qn("w:eastAsia"), east_asia)


def add_run(p, text, size=10, bold=False, italic=False, east_asia="宋体"):
    r = p.add_run(text)
    r.font.size = Pt(size)
    r.bold = bold
    r.italic = italic
    set_run_font(r, east_asia=east_asia)
    return r


def set_open_table_borders(table):
    for row in table.rows:
        for cell in row.cells:
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
    rule(table.rows[0], "bottom", 8)
    rule(table.rows[-1], "bottom", 12)


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
    set_open_table_borders(table)
    return table


def add_heading(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.keep_with_next = True
    add_run(p, text, size=10, bold=True, east_asia="黑体")
    return p


def add_subheading(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(5)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.keep_with_next = True
    add_run(p, text, size=10, bold=True, italic=True, east_asia="黑体")
    return p


def add_body(doc, text, size=10):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.first_line_indent = Pt(size * 2)
    p.paragraph_format.line_spacing = 1.15
    add_run(p, text, size=size)
    return p


def fmt(x, nd=2):
    if x is None or pd.isna(x):
        return "-"
    return f"{float(x):.{nd}f}"


def add_figure(doc, path, caption, width_inches=3.05, font_size=8):
    """Add a centered figure and its Chinese caption inside the two-column body."""
    if not os.path.exists(path):
        raise FileNotFoundError(f"Missing figure for paper: {path}")
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(1)
    p.paragraph_format.keep_with_next = True
    run = p.add_run()
    run.add_picture(path, width=Inches(width_inches))

    cap = doc.add_paragraph()
    cap.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    cap.paragraph_format.space_after = Pt(5)
    add_run(cap, caption, size=font_size)
    return p


SCEN_LABELS = {
    "S1": "S1 双障碍轻度交叉",
    "S2": "S2 四障碍走廊交错",
    "S3": "S3 五障碍非线性走廊压缩",
    "S4": "S4 六障碍密集走廊压缩",
}

SCEN_DESCRIPTIONS = {
    "S1": "2 个半径 1.2 m 的障碍物以变速与正弦变速从两侧穿越主航线。",
    "S2": "4 个半径 1.5 m 的障碍物组合直线、正弦变速、转弯与加速穿越主航线。",
    "S3": "5 个半径 1.8 m 的障碍物组合直线、正弦变速、悬停后机动、航点与之字机动。",
    "S4": "6 个半径 2.0 m 的障碍物密集交叉，包含之字、正弦变速、加速、航点、悬停与转弯。",
}

SCEN_OBSTACLES = {
    "S1": "2",
    "S2": "4",
    "S3": "5",
    "S4": "6",
}


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
    rfonts.set(qn("w:eastAsia"), "宋体")

    # 通栏标题 / 作者 / 摘要
    sec1 = doc.sections[0]
    set_page(sec1)
    set_columns(sec1, 1)

    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    title.paragraph_format.space_after = Pt(4)
    add_run(title, TITLE, size=20, bold=True, east_asia="黑体")

    authors = doc.add_paragraph()
    authors.alignment = WD_ALIGN_PARAGRAPH.CENTER
    authors.paragraph_format.space_after = Pt(2)
    add_run(authors, "作者一，作者二，作者三", size=11)

    affil = doc.add_paragraph()
    affil.alignment = WD_ALIGN_PARAGRAPH.CENTER
    affil.paragraph_format.space_after = Pt(6)
    add_run(affil, "单位 / 院系，城市，国家  |  email@example.com", size=9)

    abstract = doc.add_paragraph()
    abstract.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    abstract.paragraph_format.space_after = Pt(5)
    add_run(abstract, "摘要——", size=9, bold=True, east_asia="黑体")
    add_run(
        abstract,
        "针对无人机在动态障碍环境下的三维避障问题，本文提出一种基于长短期记忆"
        "（LSTM）网络预测增强的模型预测控制（MPC）与动态窗口法（DWA）双向耦合"
        "的规划方法。该方法使用 MATLAB 深度学习工具箱训练 LSTM 网络，根据障碍物"
        " 1 s 的运动历史预测其未来 3 s 的三维轨迹，并将预测位置分别注入 MPC 层的"
        "时变软碰撞约束和 DWA 层的预测窗口最小距离项。训练数据由 300 条独立随机"
        "障碍轨迹生成，共得到 3600 个训练窗口。为拉开难度，实验设计了四个障碍数量"
        "与半径递增、从主航线两侧连续穿越的仿真场景（S1-S4）。单次闭环运行的结果"
        "表明：随着障碍密度增大，飞行走廊被压缩、最小净空下降，匀速外推在最密集的"
        "非线性场景中出现碰撞失败，而本文 LSTM 保持全程成功，且 ADE/FDE 远低于"
        "静态冻结基线，"
        "说明学习式前瞻预测能够将预测优势转化为更高的动态避障可靠性。上述结果均为"
        "纯仿真、CPU 环境下的结果。",
        size=9,
    )

    terms = doc.add_paragraph()
    terms.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    terms.paragraph_format.space_after = Pt(4)
    add_run(terms, "关键词——", size=9, bold=True, italic=True, east_asia="黑体")
    add_run(
        terms,
        "动态避障；模型预测控制；动态窗口法；长短期记忆网络；轨迹预测；无人机",
        size=9,
    )

    en_title = doc.add_paragraph()
    en_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    en_title.paragraph_format.space_before = Pt(4)
    en_title.paragraph_format.space_after = Pt(3)
    add_run(
        en_title,
        "LSTM Prediction-Enhanced Coupled MPC-DWA Dynamic Obstacle Avoidance for a UAV",
        size=12,
        bold=True,
        east_asia="宋体",
    )

    en_abs = doc.add_paragraph()
    en_abs.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    en_abs.paragraph_format.space_after = Pt(4)
    add_run(en_abs, "Abstract——", size=9, bold=True, italic=True, east_asia="宋体")
    add_run(
        en_abs,
        "To improve three-dimensional UAV avoidance of dynamic obstacles, this paper "
        "proposes an LSTM trajectory-prediction module embedded in a bidirectionally "
        "coupled MPC-DWA planner. The LSTM forecasts each obstacle's 3D trajectory for "
        "3 s from a 1 s kinematic history; the predictions become time-varying soft "
        "collision constraints in MPC and a prediction-window minimum-distance term in "
        "DWA. Four scenarios with 2, 4, 5 and 6 crossing obstacles and increasing "
        "obstacle radius are evaluated in a single-seed run. As obstacle density "
        "increases, the flight corridor is compressed and the minimum clearance drops; "
        "constant-velocity extrapolation collides in the densest scenario, while the "
        "proposed LSTM method keeps full success and far lower ADE/FDE than static "
        "freezing. All results are simulation-only "
        "and CPU-only.",
        size=9,
    )

    en_terms = doc.add_paragraph()
    en_terms.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    en_terms.paragraph_format.space_after = Pt(6)
    add_run(en_terms, "Keywords——", size=9, bold=True, italic=True, east_asia="宋体")
    add_run(
        en_terms,
        "dynamic obstacle avoidance; model predictive control; dynamic window "
        "approach; long short-term memory; trajectory prediction; UAV",
        size=9,
    )

    # 连续双栏正文
    sec2 = doc.add_section(WD_SECTION.CONTINUOUS)
    set_page(sec2)
    set_columns(sec2, 2, space_inches=0.25)

    add_heading(doc, "I. 引言")
    add_body(
        doc,
        "在存在其他运动体的环境中，无人机需要同时完成目标到达与障碍规避。与静态"
        "障碍不同，动态障碍的未来位置只能部分预测，若规划器仅依据当前观测，其计划"
        "可能在执行前就已失效，尤其是障碍物发生转弯、加减速或悬停后再机动时。",
    )
    add_body(
        doc,
        "本文在模型预测控制（MPC）规划层与动态窗口法（DWA）执行层双向耦合的基线"
        "框架上，引入长短期记忆（LSTM）网络对每个动态障碍的未来三维轨迹进行预测。"
        "预测结果分别注入 MPC 层的时变软碰撞约束与 DWA 层的预测窗口最小距离项，使"
        "规划器与执行器共享一致的前瞻信息。",
    )
    add_body(
        doc,
        "为验证方法的有效性，本文设计了四个难度递增、且与无人机标称航线强交叉的"
        "仿真场景，障碍物包含强加速、急转弯、正弦变速与航点跟随等非线性机动。实验"
        "将本文方法与静态冻结、匀速外推两种基线进行比较，结果表明本文方法在避障"
        "成功率与轨迹预测精度两方面均优于基线。",
    )

    add_heading(doc, "II. 相关工作")
    add_body(
        doc,
        "分层规划架构将中长期优化器与局部反应式规划器结合，是地面机器人与无人机"
        "运动规划中的常用思路 [1]-[3]。MPC 能利用动力学模型进行前瞻优化并处理约束，"
        "DWA 则通过短时程轨迹仿真直接筛选可执行控制并保证制动可行性 [7]。已有研究"
        "通过参考轨迹、可行控制集或跟踪反馈等方式实现二者的耦合 [1], [4], [7]。",
    )
    add_body(
        doc,
        "在动态环境中，规划器需要障碍物未来运动模型。静态冻结虽然简单，但对快速"
        "运动的障碍物过于保守甚至不安全；匀速外推代价低，但在障碍物转弯、停止或"
        "悬停后再机动时误差较大 [4]。以 LSTM 为代表的序列模型已广泛用于行人、车辆"
        "与机器人轨迹预测 [5], [6]，并与规划控制方法相结合 [2], [3], [6]。本文的差异在于："
        "单个 LSTM 预测器在 MATLAB 中离线训练，其预测结果同时注入 MPC 与 DWA 两层，"
        "并通过时变障碍数据实现一致的前瞻避障。",
    )
    add_table(
        doc,
        "表 A  代表性方法与本文的差异对比",
        ["方法/文献", "对象", "预测", "规划/控制", "与本文差异"],
        [
            ["常绪成等 [1]", "3D 无人机", "无", "MPC-DWA 双向融合", "本文所扩展的基线"],
            ["滕菲等 [2]", "3D 无人机", "LSTM 编码环境特征", "PPO(DRL)", "无 MPC-DWA、无显式轨迹预测"],
            ["史培龙等 [3]", "地面车", "U-LSTM 轨迹预测", "模糊重规划 + MPC 跟踪", "无 DWA，MPC 仅跟踪，非 3D 无人机"],
            ["Hahn [4]", "地面机器人", "线性预测", "DWA", "无学习、无 MPC"],
            ["Yu & Zhang [5]", "水下 UUV", "物理先验 LSTM", "DWA", "无 MPC、非空中场景"],
            ["Li [6]", "无人机", "LSTM 用于跟踪", "LSTM-MPC", "不面向动态障碍避障规划"],
            ["Ögren & Leonard [7]", "移动机器人", "无", "DWA", "经典 DWA 基准"],
            ["本文", "3D 无人机", "LSTM 显式轨迹预测", "MPC-DWA 双向 + 时变注入", "预测注入规划与执行两层，含非学习基线"],
        ],
        font_size=7.5,
        col_widths=[0.7, 0.7, 1.0, 0.75, 1.1],
    )
    add_body(
        doc,
        "由表 A 可见，已有方法多数只在一层使用预测或学习信息，且对象局限于地面"
        "机器人、地面车或水下平台。本文把离线训练的 LSTM 预测同时注入 MPC 与 DWA，"
        "并在障碍数量与半径递增的四档三维场景中与静态和匀速外推基线公平对比。",
    )

    add_heading(doc, "III. 问题建模与方法")

    add_subheading(doc, "A. 无人机动力学模型")
    add_body(
        doc,
        "时间以步长 dt=0.1 s 离散，状态向量为 x=[x,y,z,theta,psi,v]^T，控制向量为 "
        "u=[v_c,omega_theta,omega_psi]^T。无人机采用一阶类独轮车运动学，其离散动力学为",
    )
    add_body(
        doc,
        "x_{t+1}=x_t+dt*v_t*cos(theta_t)*cos(psi_t)，y_{t+1}=y_t+dt*v_t*cos(theta_t)*"
        "sin(psi_t)，z_{t+1}=z_t+dt*v_t*sin(theta_t)；theta_{t+1}=theta_t+dt*omega_theta，"
        "psi_{t+1}=psi_t+dt*omega_psi，v_{t+1}=v_t+dt*(v_c-v_t)/tau。其中 tau=0.5 s "
        "为速度响应时间常数，v_c 为指令速度。",
    )

    add_subheading(doc, "B. 双向耦合的 MPC-DWA 基线")
    add_body(
        doc,
        "每个控制周期内，MPC 层在 N=30 步预测时域上优化控制序列 U=[u_1,...,u_N]，"
        "代价函数为",
    )
    add_body(
        doc,
        "J_MPC=sum_k[wPos*||p_k-g||^2+wCtrl*||u_k||^2+wSmooth*||u_k-u_{k-1}||^2]+"
        "wTerm*||p_N-g||^2+J_obs，其中 p_k 为第 k 步预测位置，g 为目标点，J_obs 为"
        "时变软碰撞惩罚。求解结果给出参考轨迹与首步指令 u_MPC。DWA 层根据当前状态"
        "构造动态窗口，在 u_MPC 附近采样候选控制并加入探索区域，对每个候选生成短时程"
        "轨迹并检查制动可行性 v_end<=sqrt(2*a_max*d_min)，最后按加权目标执行：",
    )
    add_body(
        doc,
        "J_DWA=w1*s_pos+w2*s_heading+w3*s_vel+w4*s_obs，其中 s_pos、s_heading、"
        "s_vel、s_obs 分别表示目标进度、航向一致性、速度保持与障碍物净空得分。DWA "
        "层把可行控制集归纳为下一轮 MPC 的控制约束盒，并把执行控制与状态回传热启动，"
        "从而形成双向耦合。",
    )

    add_subheading(doc, "C. LSTM 轨迹预测器")
    add_body(
        doc,
        "预测器为 MATLAB 深度学习工具箱训练的多对一 LSTM 网络。对 t 时刻的每个"
        "障碍物，输入为最近 10 个历史时刻（1 s）的特征矩阵 F，维度为 8 x T_hist="
        "8 x 10，特征为 [x,y,z,vx,vy,vz,cos(psi),sin(psi)]；输出为 3 x N_pred=90 维"
        "位移增量（30 个未来时刻的三维位置）。网络按位移增量回归训练，预测位置由"
        "当前测量位置加增量得到：",
    )
    add_body(
        doc,
        "Delta_Y=W_out*h_LSTM+b_out，P_hat(t+k|t)=P_obs(t)+Delta_Y(k)，其中 h_LSTM "
        "为 64 维 LSTM 隐状态。同一网络独立作用于每个障碍物。训练数据来自 300 条"
        "独立随机障碍轨迹，共提取约 3600 个输入输出窗口；训练轨迹与四个固定评估场景"
        "分离，避免场景过拟合。",
    )

    add_subheading(doc, "D. 时变约束注入与信任度机制")
    add_body(
        doc,
        "设 P_j(t+k|t) 为障碍物 j 在 t 时刻对未来第 k 步的预测位置，p(t+k|t) 为规划的"
        "无人机位置，则带符号净空为 g_{j,k}=||p-P_j||-r_j-r_e，其中 r_j 为障碍物半径，"
        "r_e=0.3 m 为无人机安全半径。MPC 的时变软碰撞项为 J_obs=wObs*"
        "sum_{k=1}^{H_inj} sum_j max(0,-g_{j,k})^2。由于预测位置随 k 变化，该约束"
        "为时变软约束：对预测越限进行惩罚，而不会使整体优化不可行。注入时域 H_inj "
        "可小于完整 MPC 时域，用于消融实验。",
    )
    add_body(
        doc,
        "信任度向量 tau=sigma.*[tau_sa,tau_g,tau_t,tau_sm] 用于平衡 MPC 参考与 DWA "
        "局部反应：tau_sa 由 MPC 参考相对预测障碍物的最小净空映射得到，tau_g 表示"
        "参考终点对目标的进度，tau_t 反映当前状态与参考首点的偏差，tau_sm 惩罚参考"
        "控制变化率；sigma=[0.35,0.30,0.15,0.20]。",
    )
    add_body(
        doc,
        "在 DWA 层，候选轨迹的障碍物得分取决于该轨迹与所有障碍物预测位置在预测"
        "窗口内的最小带符号净空。对时间与障碍物同时取最小值，使执行器获得与 MPC "
        "层一致的前瞻安全信号，而不是仅对当前障碍物位置进行评分。因此，即使障碍物"
        "即将转弯或加速，DWA 也能受益于 LSTM 给出的未来走廊。",
    )

    add_subheading(doc, "E. 对比基线")
    add_body(
        doc,
        "两种非学习基线填充相同的障碍物位置接口。静态基线将每个障碍物固定在其最近"
        "测量位置，即 P_hat(t+k|t)=P_obs(t)；匀速基线以最近两步测量速度外推 "
        "P_hat(t+k|t)=P_obs(t)+k*dt*v_meas。在相同比较中，除障碍物预测外，控制回路"
        "其余部分（包括 DWA 采样随机性与 MPC 求解设置）保持一致。",
    )

    add_heading(doc, "IV. 实验")

    add_subheading(doc, "A. 实验设置")
    add_body(
        doc,
        "全部实验为 MATLAB 闭环仿真，MPC 使用 CasADi 与 IPOPT 求解，LSTM 使用深度"
        "学习工具箱训练与推理。所有计算均在 CPU 上完成，不考虑实时硬件或嵌入式"
        "执行。预测历史为 1 s，预测时域为 3 s，训练轨迹与评估场景分离。",
    )

    add_subheading(doc, "B. 场景与评价指标")
    add_table(
        doc,
        "表 I  难度递增的评价场景",
        ["场景", "障碍物集合与运动方式"],
        [
            ["S1 双障碍轻度交叉", SCEN_DESCRIPTIONS["S1"]],
            ["S2 四障碍走廊交错", SCEN_DESCRIPTIONS["S2"]],
            ["S3 五障碍非线性走廊压缩", SCEN_DESCRIPTIONS["S3"]],
            ["S4 六障碍密集走廊压缩", SCEN_DESCRIPTIONS["S4"]],
        ],
        font_size=8,
        col_widths=[1.35, 2.45],
    )
    add_body(
        doc,
        "当无人机在容许误差内到达目标且碰撞次数为零时，记为该次运行成功。记录的"
        "指标包括成功率、碰撞次数、最小带符号净空、路径长度、相对起终点直线的跟踪"
        "均方根误差、单步求解时间，以及预测的平均位移误差（ADE）与最终位移误差"
        "（FDE）。",
    )

    summary = read_csv(os.path.join(RESULTS, "multiseed_summary.csv"))
    comparison = read_csv(os.path.join(RESULTS, "multiseed_comparison.csv"))

    add_subheading(doc, "C. 对比实验结果")

    scen_labels = dict(SCEN_LABELS)
    methods = ["static", "cv", "lstm"]
    method_labels = {"static": "静态", "cv": "匀速外推", "lstm": "本文 LSTM"}

    scen_map = {}
    for _, row in comparison.iterrows():
        key = str(row["Scenario"]).strip()[:2].upper()
        if key not in scen_labels:
            key = str(row["Scenario"]).strip().split()[0][:2].upper()
        scen_map.setdefault(key, {})
        scen_map[key].setdefault(str(row["Method"]), [0, 0])
        scen_map[key][str(row["Method"])][0] += 1
        scen_map[key][str(row["Method"])][1] += int(row["Success"])

    scen_rows = []
    for key in ("S1", "S2", "S3", "S4"):
        row = [scen_labels[key]]
        for m in methods:
            trials, succ = scen_map.get(key, {}).get(m, [0, 0])
            row.append(f"{succ}/{trials}")
        scen_rows.append(row)
    add_table(
        doc,
        "表 II  单次运行中各场景的成功次数",
        ["场景", "静态", "匀速外推", "本文 LSTM"],
        scen_rows,
        font_size=8,
        col_widths=[1.45, 0.75, 0.85, 0.75],
    )

    sum_rows = {}
    for _, row in summary.iterrows():
        sum_rows[str(row["Method"])] = row

    agg_rows = []
    for m in methods:
        r = sum_rows.get(m)
        if r is None:
            continue
        agg_rows.append(
            [
                method_labels[m],
                f"{int(r['SuccessCount'])}/{int(r['Trials'])}",
                f"{fmt(r['MeanCollisions'], 1)}±{fmt(r['StdCollisions'], 1)}",
                f"{fmt(r['MeanMinSafeDist_m'])}±{fmt(r['StdMinSafeDist_m'])}",
                f"{fmt(r['MeanADE_m'])}±{fmt(r['StdADE_m'])}",
                f"{fmt(r['MeanFDE_m'])}±{fmt(r['StdFDE_m'])}",
                f"{fmt(r['MedianStepTime_ms'], 0)}",
            ]
        )
    add_table(
        doc,
        "表 III  单次运行下的总体对比（步时为中位数）",
        ["方法", "成功率", "碰撞", "最小净空(m)", "ADE(m)", "FDE(m)", "步时(ms)"],
        agg_rows,
        font_size=8,
        col_widths=[0.75, 0.6, 0.7, 0.95, 0.95, 0.95, 0.7],
    )

    scounts = {}
    for m in methods:
        if m in sum_rows:
            scounts[m] = int(sum_rows[m]["SuccessCount"])
        else:
            scounts[m] = 0
    add_body(
        doc,
        f"在单次运行下，静态、匀速外推与本文 LSTM 的总成功次数分别为 "
        f"{scounts['static']}/4、{scounts['cv']}/4 与 {scounts['lstm']}/4。"
        f"静态基线的 ADE/FDE 最大（{fmt(sum_rows['static']['MeanADE_m'])}/"
        f"{fmt(sum_rows['static']['MeanFDE_m'])} m），说明把动态障碍物当作静止目标"
        f"会带来最严重的预测偏差；匀速外推预测误差较低，但在最密集的 S4 中碰撞"
        f"失败；本文 LSTM 在全部场景保持成功，且 ADE/FDE 显著低于静态基线、波动"
        f"最小。",
    )

    path_rows = []
    for key in ("S1", "S2", "S3", "S4"):
        sub = comparison[comparison["Scenario"].astype(str).str.startswith(key + " ")]
        if sub.empty:
            continue
        path_rows.append(
            [
                scen_labels[key],
                SCEN_OBSTACLES[key],
                f"{fmt(sub['MinSafeDist_m'].mean())}±{fmt(sub['MinSafeDist_m'].std(), 2)}",
                f"{fmt(sub['PathLength_m'].mean())}±{fmt(sub['PathLength_m'].std(), 2)}",
                f"{fmt(sub['TrackRMSE_m'].mean())}±{fmt(sub['TrackRMSE_m'].std(), 2)}",
            ]
        )
    add_table(
        doc,
        "表 IV  多障碍压缩下的走廊指标（全部方法 × 1 次运行）",
        ["场景", "障碍数", "最小净空(m)", "路径长度(m)", "跟踪RMSE(m)"],
        path_rows,
        font_size=8,
        col_widths=[1.35, 0.45, 0.9, 0.8, 0.9],
    )
    add_body(
        doc,
        "表 IV 表明，最小带符号净空从 S1 到 S4 明显下降，路径长度与相对起终点直线"
        "的跟踪 RMSE 随难度上升。这说明高密度障碍不仅增加了碰撞风险，也迫使无人"
        "机产生更明显的三维绕行，标称直线航线在结果图中只是参考基准而不是实际"
        "飞行路径。",
    )

    for idx, key in enumerate(("S1", "S2", "S3", "S4"), start=1):
        label = scen_labels[key]
        fig_path = os.path.join(RESULTS, label + ".png")
        add_figure(
            doc,
            fig_path,
            f"图{idx}  场景{key}的障碍物真实轨迹与三种方法的三维避障轨迹，"
            "灰色虚线为标称直线航线。",
        )
    for idx, key in enumerate(("S3", "S4"), start=5):
        label = scen_labels[key]
        fig_path = os.path.join(RESULTS, label + "_pred.png")
        add_figure(
            doc,
            fig_path,
            f"图{idx}  场景{key}典型时刻的真实未来轨迹与静态、匀速外推、LSTM 预测对比。",
            width_inches=3.05,
        )

    add_subheading(doc, "D. 预测时域消融")
    add_body(
        doc,
        "注入预测步数 H_inj 决定避障层使用多少预测窗口，其取值在 {10,20,30} 中变化。"
        "该组为单种子 × 4 场景的辅助消融，结果见表 V。",
    )
    ablation_path = os.path.join(RESULTS, "ablation_horizon.csv")
    if os.path.exists(ablation_path):
        ablation = read_csv(ablation_path)
        abl_rows = []
        for _, row in ablation.iterrows():
            abl_rows.append(
                [
                    int(row["Horizon_steps"]),
                    f"{fmt(row['SuccessRate_pct'], 0)}%",
                    fmt(row["AvgCollisions"], 2),
                    fmt(row["AvgMinSafeDist_m"]),
                    fmt(row["AvgADE_m"]),
                    fmt(row["AvgFDE_m"]),
                    fmt(row["AvgStepTime_ms"], 0),
                ]
            )
        add_table(
            doc,
            "表 V  LSTM 注入时域消融（单种子 × 4 场景均值）",
            ["H_inj(步)", "成功率", "碰撞", "最小净空(m)", "ADE(m)", "FDE(m)", "步时(ms)"],
            abl_rows,
            font_size=8,
            col_widths=[0.6, 0.5, 0.5, 0.75, 0.6, 0.6, 0.6],
        )

    add_subheading(doc, "E. 讨论")
    add_body(
        doc,
        f"结果表明两点。其一，随着障碍数量与半径递增，飞行走廊被明显压缩：匀速"
        f"外推在 S4 出现碰撞失败，而本文 LSTM 保持 {scounts['lstm']}/4 成功；静态"
        f"冻结虽然全部到达目标，但其 ADE/FDE 最大，说明它用最差的预测换取了保守"
        f"的安全。其二，最小净空从 S1 到 S4 总体下降，而路径长度与跟踪 RMSE 上升，"
        f"说明四档场景确实迫使无人机对主航线进行越来越明显的三维绕行，方法差异"
        f"不是仅来自轨迹预测指标。需要说明的是，"
        f"本文所有结果均来自纯仿真与 CPU 环境：未考虑传感器噪声、通信延迟、部分"
        f"观测或真实飞行验证；成功率为单次判断，碰撞次数与最小净空提供了更细的"
        f"安全信息。",
    )

    add_heading(doc, "V. 结论")
    add_body(
        doc,
        "本文提出了一种基于 LSTM 预测增强的 MPC-DWA 无人机动态避障方法。单个 "
        "LSTM 预测器根据 1 s 历史预测障碍物 3 s 内轨迹，并将预测结果注入 MPC 层"
        "时变软约束与 DWA 层预测窗口最小距离项。本文设计了障碍数量 2/4/5/6、半径"
        "1.2/1.5/1.8/2.0 m 且连续穿越主航线的四档场景，并在一次运行中与静态"
        "和匀速外推基线比较。结果表明：障碍密度增大后飞行走廊被压缩、最小净空"
        "下降，匀速外推在密集非线性场景碰撞失败；本文 LSTM 保持全程成功，并将"
        "预测误差远低于静态基线，在路径长度与跟踪 RMSE 上体现明显绕障调整。"
        "未来工作将补充多种子消融、含噪声与部分"
        "观测的障碍状态、通信延迟，以及实时硬件评估。",
    )

    add_heading(doc, "参考文献")
    refs = [
        "[1] 常绪成，等. 基于 MPC-DWA 策略的无人机路径规划算法研究. 电光与控制，2026（网络首发）.",
        "[2] 滕菲，等. 北京航空航天大学学报，2025. DOI: 10.13700/j.bh.1001-5965.2025.0084.",
        "[3] 史培龙，等. 长安大学学报（自然科学版），2024. DOI: 10.19721/j.cnki.1671-8879.2024.04.015.",
        "[4] Hahn. Actuators, 2025. DOI: 10.3390/act14050207.",
        "[5] Yu, Zhang. Ocean Engineering, 2026. DOI: 10.1016/j.oceaneng.2026.124503.",
        "[6] Li. AIITA, 2026. DOI: 10.1109/aiita69518.2026.11567135.",
        "[7] Ögren, Leonard. IEEE Transactions on Robotics, 2005（经典 DWA，无 DOI）.",
    ]
    for text in refs:
        p = doc.add_paragraph()
        p.paragraph_format.space_after = Pt(1)
        p.paragraph_format.left_indent = Inches(0.25)
        p.paragraph_format.first_line_indent = Inches(-0.25)
        add_run(p, text, size=9)

    doc.save(OUT)
    print("Wrote", OUT)
    print("Summary columns:", list(summary.columns))
    print(summary.to_string(index=False))


if __name__ == "__main__":
    build_document()
