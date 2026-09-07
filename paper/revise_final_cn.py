from pathlib import Path
from copy import deepcopy
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn


ROOT = Path(__file__).resolve().parents[2]
PAPER_DIR = ROOT / "LSTM_MPC_DWA" / "paper"
RESULTS_DIR = ROOT / "LSTM_MPC_DWA" / "results"
SOURCE = PAPER_DIR / "EI_paper_final_CN.docx"
OUTPUT = PAPER_DIR / "EI_paper_final_CN_revised.docx"


BLACK = RGBColor(0, 0, 0)
EMU_PER_INCH = 914400


def set_run_black(run, font_name=None, size=None, bold=None, italic=None):
    run.font.color.rgb = BLACK
    if font_name:
        run.font.name = font_name
        rpr = run._element.get_or_add_rPr()
        rfonts = rpr.rFonts
        if rfonts is None:
            rfonts = OxmlElement("w:rFonts")
            rpr.insert(0, rfonts)
        for key in ("ascii", "hAnsi", "eastAsia", "cs"):
            rfonts.set(qn(f"w:{key}"), font_name)
    if size is not None:
        run.font.size = Pt(size)
    if bold is not None:
        run.bold = bold
    if italic is not None:
        run.italic = italic


def set_paragraph_text(paragraph, text, *, size=9.5, align=None, bold=False, italic=False):
    paragraph.clear()
    if align is not None:
        paragraph.alignment = align
    run = paragraph.add_run(text)
    set_run_black(run, "SimSun", size, bold, italic)
    paragraph.paragraph_format.space_after = Pt(3)
    return paragraph


def insert_text_before(anchor, text, *, size=9.5, align=None, bold=False, italic=False):
    p = anchor.insert_paragraph_before()
    return set_paragraph_text(p, text, size=size, align=align, bold=bold, italic=italic)


def insert_text_before_table(table, text, *, size=8.5, align=WD_ALIGN_PARAGRAPH.CENTER, bold=True, italic=False):
    p = doc.add_paragraph()
    table._tbl.addprevious(p._p)
    return set_paragraph_text(p, text, size=size, align=align, bold=bold, italic=italic)


def set_cell_text(cell, text, *, size=7.5, bold=False, align=WD_ALIGN_PARAGRAPH.CENTER):
    cell.text = ""
    p = cell.paragraphs[0]
    p.alignment = align
    p.paragraph_format.space_after = Pt(0)
    p.paragraph_format.space_before = Pt(0)
    run = p.add_run(str(text))
    set_run_black(run, "SimSun", size, bold, False)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER


def set_cell_shading(cell, fill="FFFFFF"):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.first_child_found_in("w:shd")
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), fill)


def set_table_borders(table):
    tbl_pr = table._tbl.tblPr
    borders = tbl_pr.first_child_found_in("w:tblBorders")
    if borders is None:
        borders = OxmlElement("w:tblBorders")
        tbl_pr.append(borders)
    for edge in ("top", "bottom", "insideH"):
        tag = f"w:{edge}"
        el = borders.find(qn(tag))
        if el is None:
            el = OxmlElement(tag)
            borders.append(el)
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), "6")
        el.set(qn("w:space"), "0")
        el.set(qn("w:color"), "000000")
    for edge in ("left", "right", "insideV"):
        tag = f"w:{edge}"
        el = borders.find(qn(tag))
        if el is None:
            el = OxmlElement(tag)
            borders.append(el)
        el.set(qn("w:val"), "nil")


def set_row_no_split(row, repeat_header=False):
    tr_pr = row._tr.get_or_add_trPr()
    tr_pr.append(OxmlElement("w:cantSplit"))
    if repeat_header:
        header = OxmlElement("w:tblHeader")
        header.set(qn("w:val"), "true")
        tr_pr.append(header)


def set_table_widths(table, widths_in):
    table.autofit = False
    for row in table.rows:
        for cell, width in zip(row.cells, widths_in):
            cell.width = Inches(width)
            tc_pr = cell._tc.get_or_add_tcPr()
            tc_w = tc_pr.first_child_found_in("w:tcW")
            if tc_w is None:
                tc_w = OxmlElement("w:tcW")
                tc_pr.append(tc_w)
            tc_w.set(qn("w:w"), str(round(width * 1440)))
            tc_w.set(qn("w:type"), "dxa")


def insert_scenario_table_before(anchor):
    rows = [
        ("场景", "方法", "成功/3", "碰撞步数", "最小净空/m"),
        ("S1", "static", "3/3", "0.00", "1.511"),
        ("S1", "cv", "3/3", "0.00", "1.986"),
        ("S1", "lstm", "3/3", "0.00", "2.129"),
        ("S2", "static", "1/3", "5.00", "0.024"),
        ("S2", "cv", "3/3", "0.00", "0.646"),
        ("S2", "lstm", "3/3", "0.00", "1.237"),
        ("S3", "static", "3/3", "0.00", "0.365"),
        ("S3", "cv", "1/3", "1.67", "−0.003"),
        ("S3", "lstm", "3/3", "0.00", "0.239"),
        ("S4", "static", "0/3", "3.00", "−0.040"),
        ("S4", "cv", "0/3", "36.00", "−1.029"),
        ("S4", "lstm", "3/3", "0.00", "0.189"),
    ]
    table = doc.add_table(rows=len(rows), cols=5)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    for ri, row in enumerate(rows):
        set_row_no_split(table.rows[ri], repeat_header=(ri == 0))
        for ci, value in enumerate(row):
            set_cell_text(table.cell(ri, ci), value, size=7.5, bold=(ri == 0))
    set_table_widths(table, [0.40, 0.62, 0.62, 0.78, 0.78])
    set_table_borders(table)
    anchor._p.addprevious(table._tbl)
    return table


def insert_parameter_table_before(anchor):
    rows = [
        ("参数", "设置", "作用"),
        ("仿真步长 dt", "0.1 s", "闭环更新周期"),
        ("MPC / 预测时域 N,Np", "30 步 / 3 s", "共同时间范围"),
        ("历史长度 Th", "10 步 / 1 s", "LSTM 输入窗口"),
        ("LSTM", "64 单元，dropout=0.1", "序列编码器"),
        ("训练", "Adam，100 epoch，batch=128，lr=1e-3", "预测器优化设置"),
        ("DWA 采样", "Nbase=300，rguide=0.35，alpha=1，beta=3", "候选控制生成"),
        ("安全参数", "re=0.3 m，ds=0.35 m，dreject=0.05 m", "净空约束与候选拒绝"),
        ("回线软代价", "wroute=3", "抑制绕行后的永久侧向偏移"),
        ("求解器", "CasADi + IPOPT，max_iter=300，tol=1e-6", "MPC 数值求解"),
    ]
    table = doc.add_table(rows=len(rows), cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    for ri, row in enumerate(rows):
        set_row_no_split(table.rows[ri], repeat_header=(ri == 0))
        for ci, value in enumerate(row):
            set_cell_text(table.cell(ri, ci), value, size=6.6, bold=(ri == 0))
    set_table_widths(table, [1.22, 2.55, 2.43])
    set_table_borders(table)
    anchor._p.addprevious(table._tbl)
    return table


def update_main_results_table(table):
    rows = [
        ("方法", "运行数", "成功率\n(95% CI)", "碰撞步数\n均值±SD", "碰撞事件\n均值", "最小净空/m\n均值±SD", "ADE/m\n均值±SD", "FDE/m\n均值±SD", "步时/ms\n均值±SD"),
        ("static", "12", "58.3%\n(32.0–80.7%)", "2.00±3.07", "0.417", "0.465±0.657", "2.342±0.161", "4.458±0.311", "104.16±26.80"),
        ("cv", "12", "58.3%\n(32.0–80.7%)", "9.42±16.06", "0.667", "0.400±1.142", "0.532±0.181", "1.277±0.443", "100.63±25.80"),
        ("lstm", "12", "100.0%\n(75.7–100.0%)", "0.00±0.00", "0.000", "0.949±0.835", "0.553±0.112", "1.311±0.240", "106.29±27.75"),
    ]
    for ri, row in enumerate(rows):
        set_row_no_split(table.rows[ri], repeat_header=(ri == 0))
        for ci, value in enumerate(row):
            set_cell_text(table.cell(ri, ci), value, size=6.0, bold=(ri == 0))
    set_table_widths(table, [0.40, 0.43, 0.78, 0.75, 0.62, 0.88, 0.75, 0.75, 0.84])
    set_table_borders(table)


def set_inline_width(paragraph, width_in):
    drawing = paragraph._p.find(qn("w:r"))
    if drawing is None:
        return
    inline = paragraph._p.find(".//" + qn("wp:inline"))
    if inline is None:
        return
    extent = inline.find(qn("wp:extent"))
    if extent is None:
        return
    old_cx = int(extent.get("cx"))
    old_cy = int(extent.get("cy"))
    new_cx = round(width_in * EMU_PER_INCH)
    new_cy = round(new_cx * old_cy / old_cx)
    extent.set("cx", str(new_cx))
    extent.set("cy", str(new_cy))
    xfrm_ext = inline.find(".//" + qn("a:xfrm") + "/" + qn("a:ext"))
    if xfrm_ext is not None:
        xfrm_ext.set("cx", str(new_cx))
        xfrm_ext.set("cy", str(new_cy))


def insert_picture_before(anchor, image_path, alt_text, width_in=3.03):
    p = anchor.insert_paragraph_before()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(3)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.keep_with_next = True
    run = p.add_run()
    run.add_picture(str(image_path), width=Inches(width_in))
    inline = p._p.find(".//" + qn("wp:inline"))
    if inline is not None:
        doc_pr = inline.find(qn("wp:docPr"))
        if doc_pr is not None:
            doc_pr.set("descr", alt_text)
            doc_pr.set("title", alt_text)
    return p


def delete_paragraph(paragraph):
    paragraph._element.getparent().remove(paragraph._element)


def all_paragraphs_in_document(document):
    yield from document.paragraphs
    for table in document.tables:
        for row in table.rows:
            for cell in row.cells:
                yield from cell.paragraphs
    for section in document.sections:
        yield from section.header.paragraphs
        yield from section.footer.paragraphs


doc = Document(str(SOURCE))

# Update the evidence-bound narrative without changing unsupported numbers.
replacements = {
    "进一步的路线约束、MPC/DWA 单层注入及预测时域消融表明，两层时序注入与 3 s 预测时域共同构成主要闭环收益。":
        "单种子路线约束、MPC/DWA 单层注入及预测时域消融提示，两层时序注入和 3 s 预测时域有助于提高闭环净空；该机制性结果仍需多种子验证。",
    "本文的主要结论限定为：在本文的仿真动力学、固定场景和干净观测条件下，LSTM 预测增强的双层 MPC-DWA 注入显著改善了闭环安全结果；该结论不等同于 LSTM 在每一个预测误差或非理想传感器条件下都优于基线。":
        "本文的主要结论限定为：在本文的仿真动力学、固定场景和干净观测条件下，LSTM 预测增强的双层 MPC-DWA 注入改善了闭环安全指标；该结论不等同于 LSTM 在每一个预测误差或非理想传感器条件下都优于基线。",
    "MPC-DWA 分层规划将全局或中期的模型预测与短时可执行控制联系起来，适合处理无人机的速度、角速度和动力学约束。经典 DWA 通过动态窗口和短时轨迹评分保证控制候选具有可执行性；MPC 则通过滚动优化生成面向目标的参考序列。已有无人机规划工作通常关注静态环境或采用固定障碍模型，难以覆盖动态障碍的未来不确定性。":
        "MPC-DWA 分层规划将全局或中期的模型预测与短时可执行控制联系起来，适合处理无人机的速度、角速度和动力学约束[1,3]。经典 DWA 通过动态窗口和短时轨迹评分保证控制候选具有可执行性；MPC 则通过滚动优化生成面向目标的参考序列[6]。已有无人机规划工作通常关注静态环境或采用固定障碍模型，难以覆盖动态障碍的未来不确定性。",
    "动态障碍预测可使用静态冻结、匀速模型、滤波器或学习型序列模型。静态冻结计算代价低但对运动障碍物缺乏时序信息；匀速外推在直线运动下有效，却不能描述加速、转弯、变速和航点切换。LSTM 能从历史序列中提取局部运动模式，但预测准确性只有在其结果以正确时间索引进入规划器时才可能转化为闭环收益。本文不把预测器独立看作完整避障方法，而是研究其与 MPC-DWA 双层执行链的一致耦合。":
        "动态障碍预测可使用静态冻结、匀速模型、滤波器或学习型序列模型[2,4,5]。静态冻结计算代价低但对运动障碍物缺乏时序信息；匀速外推在直线运动下有效，却不能描述加速、转弯、变速和航点切换。LSTM 能从历史序列中提取局部运动模式，但预测准确性只有在其结果以正确时间索引进入规划器时才可能转化为闭环收益。本文不把预测器独立看作完整避障方法，而是研究其与 MPC-DWA 双层执行链的一致耦合。",
    "图 1 给出 S4 单种子轨迹：LSTM 轨迹绕开多次重叠机动并到达目标，cv 轨迹在密集走廊中发生多次接触。图 2 给出同一场景在中段时刻的障碍历史和未来预测，展示 LSTM 对转弯/变速轨迹的前瞻差异。":
        "图 1–图 4 展示了四个固定场景下的三维闭环轨迹。S1 中三种方法均成功到达目标；S2 中静态冻结出现碰撞，而 cv 与 LSTM 保持成功；S3 中 cv 出现碰撞，LSTM 与静态冻结成功；S4 的密集走廊最具挑战性，LSTM 仍保持正净空并成功到达目标。图 5 进一步给出 S4 中段时刻的障碍历史与未来预测，展示不同预测接口在转弯和变速轨迹上的差异。",
    "闭环 ADE/FDE 与固定窗口结果应分开解释。主闭环运行中，cv 的平均 ADE/FDE 略低于 LSTM，这是因为闭环状态、终止时刻和控制器反馈会改变采样到的历史窗口；但 cv 的较低预测误差没有转化为 S3/S4 的无碰撞闭环行为。该对照说明避障能力由预测、时间同步、MPC 安全代价和 DWA 候选筛选共同决定，而不是由单一 ADE/FDE 排名决定。":
        "闭环 ADE/FDE 与固定窗口结果应分开解释。主闭环运行中，cv 的平均 ADE/FDE 略低于 LSTM，这是因为闭环状态、终止时刻和控制器反馈会改变采样到的历史窗口；但 cv 的较低预测误差没有转化为 S3/S4 的无碰撞闭环行为。该对照说明避障能力由预测、时间同步、MPC 安全代价和 DWA 候选筛选共同决定，而不是由单一 ADE/FDE 排名决定。",
    "本文仍存在三个边界。第一，障碍轨迹来自固定合成生成器，尚未覆盖真实传感器遮挡、检测漏检、障碍物交互和多智能体博弈；因此不能直接外推到真实飞行。第二，主实验使用干净观测，压力实验表明延迟和噪声会显著削弱 LSTM 闭环性能。第三，平均每步计算时间约 100–106 ms，尚未满足严格 10 Hz 以外的实时裕度，且当前缓存 MPC 仍需在更高频硬件上验证。下一步应使用带传感器噪声、漏检和时间延迟的训练数据重新训练预测器，并在真实或硬件在环平台上检验安全约束与计算预算。":
        "本文仍存在三个边界。第一，障碍轨迹来自固定合成生成器，尚未覆盖真实传感器遮挡、检测漏检、障碍物交互和多智能体博弈；因此不能直接外推到真实飞行。第二，主实验使用干净观测，压力实验表明延迟和噪声会显著削弱 LSTM 闭环性能。第三，主实验平均每步计算时间约为 100–106 ms，当前结果尚未证明系统可稳定满足 10 Hz 实时预算；压力测试中步时进一步升至约 223–238 ms。下一步应使用带传感器噪声、漏检和时间延迟的训练数据重新训练预测器，并在真实或硬件在环平台上检验安全约束与计算预算。",
    "加入 5 cm 位置噪声和 1 个采样周期延迟后，因果平滑与延迟补偿使 LSTM 的碰撞程度优于匀速外推，但仍未超过静态方法，说明当前证据支持的是干净观测和中等动态机动条件下的闭环优势，而不是对任意传感器延迟的普适鲁棒性。":
        "加入 5 cm 位置噪声和 1 个采样周期延迟，并为每次运行预先生成一条由三种方法共享的带噪观测流，从而保证不同方法面对完全相同的时序输入。LSTM 在 3 次压力运行中成功 1/3，平均碰撞步数为 29.67，低于 cv 的 31.00 但未超过 static 的 2.33，说明当前证据支持的是干净观测和中等动态机动条件下的闭环优势，而不是对任意传感器延迟的普适鲁棒性。",
    "输出为未来 N_p=30 步的三维位移增量，覆盖 3 s。预测绝对位置由当前历史末端位置加位移增量得到。训练数据由 300 条独立生成的随机轨迹构成，包含直线、转弯、加速、悬停后机动、正弦变速、之字形和航点跟随等运动模式，共提取约 3,600 个输入—输出窗口。训练轨迹与 S1–S4 固定评估轨迹分离。":
        "输出为未来 N_p=30 步的三维位移增量，覆盖 3 s。预测绝对位置由当前历史末端位置加位移增量得到。训练数据由 300 条独立生成的随机轨迹构成，包含直线、转弯、加速、悬停后机动、正弦变速、之字形和航点跟随等运动模式，共提取 3,600 个输入—输出窗口。训练轨迹与 S1–S4 固定评估轨迹分离。网络结构为 8 维序列输入、64 单元 LSTM（仅输出末时刻）、0.1 dropout、64 单元全连接 ReLU 层和 90 维回归输出；训练采用 Adam 优化器，学习率为 1e-3，批大小为 128，共训练 100 个 epoch。输入特征按维度标准化，输出位移按坐标轴标准化。当前训练脚本没有独立验证集、早停或基于验证集的模型选择，因此 300 条轨迹是训练样本而非独立的验证样本。",
    "观测存在噪声和延迟时，闭环额外采用一个因果位置平滑窗口和延迟补偿：平滑只使用当前及过去样本，并保留最新观测位置；对延迟历史产生的预测则丢弃已落后的前 d 步并以预测末端速度补齐尾部。三种方法在压力测试中使用相同观测预处理和匹配随机种子。":
        "观测存在噪声和延迟时，闭环额外采用一个因果位置平滑窗口和延迟补偿：平滑只使用当前及过去样本，并保留最新观测位置；对延迟历史产生的预测则丢弃已落后的前 d 步并以预测末端速度补齐尾部。带噪声的完整观测流在每次闭环运行开始时只生成一次，并由 MPC 与 DWA 的所有预测调用共享；三种方法在压力测试中使用相同观测流和匹配随机种子。",
    "其中 r_j 为障碍物半径，r_e=0.3 m 为无人机半径。预测位置严格对应规划状态的 X(:,k+1)。MPC 障碍代价为":
        "其中 r_j 为障碍物半径，r_e=0.3 m 为无人机半径。为明确闭环时间索引，本文将规划时刻记为 t，并用 p_(t+k|t) 与 o_hat_(j,t+k|t) 表示第 k 步的规划位置和障碍预测位置；代码中的预测第 k 行严格对应规划状态的 X(:,k+1)。MPC 障碍代价为",
    "闭环指标包括成功率、碰撞时间步数、碰撞事件数、真实最小净空、路径长度、到标称航线的三维跟踪 RMSE、DWA 回退步数和每步计算时间。主实验的独立重复单位是匹配的“场景—随机种子—方法”闭环运行；不对同一运行内的时间步进行伪重复显著性检验。表中均值和标准差仅作描述性汇总，不报告没有预先定义且无法由当前运行支持的 P 值。":
        "闭环指标包括成功率、碰撞时间步数、碰撞事件数、真实最小净空、路径长度、到标称航线的三维跟踪 RMSE、DWA 回退步数和每步计算时间。主实验的独立重复单位是匹配的“场景—随机种子—方法”闭环运行；不对同一运行内的时间步进行伪重复显著性检验。表 3 报告运行级均值±标准差；成功率同时给出基于 12 次运行的 95% Wilson 区间。均值、标准差和区间均为描述性统计，不报告没有预先定义且无法由当前运行支持的 P 值。",
    "另外，在 S4 中加入标准差 0.05 m 的位置观测噪声和 1 步延迟，并对三种方法各运行 3 个匹配种子。该压力实验用于界定感知非理想条件下的边界，而非与干净观测主实验混合。":
        "另外，在 S4 中加入标准差 0.05 m 的位置观测噪声和 1 步延迟，并对三种方法各运行 3 个匹配种子。每次运行只生成一次完整带噪观测流，之后由所有预测调用复用；该压力实验用于界定感知非理想条件下的边界，而非与干净观测主实验混合。",
    "LSTM 在 12 次闭环运行中全部到达且无碰撞。static 和 cv 均有 5 次未成功；cv 的平均碰撞步数最高，主要集中于 S3 和 S4 的非线性密集走廊。按场景汇总，LSTM 在 S1–S4 分别为 3/3、3/3、3/3 和 3/3 成功；cv 分别为 3/3、3/3、1/3 和 0/3；static 分别为 3/3、1/3、3/3 和 0/3。LSTM 的平均真实最小净空高于两种基线，且 S4 中仍保持正净空，而 cv 的 S4 平均净空为 −1.029 m。":
        "LSTM 在 12 次闭环运行中全部到达且无碰撞；其成功率的 95% Wilson 区间为 75.7–100.0%，表明样本量仍不足以支持无条件的成功率外推。static 和 cv 均有 5 次未成功；cv 的平均碰撞步数最高，且标准差较大，说明少数密集场景运行对汇总结果影响明显。按场景汇总，LSTM 在 S1–S4 分别为 3/3、3/3、3/3 和 3/3 成功；cv 分别为 3/3、3/3、1/3 和 0/3；static 分别为 3/3、1/3、3/3 和 0/3。LSTM 的平均真实最小净空高于两种基线，但运行级标准差也较大；S4 中 LSTM 平均保持正净空，而 cv 的 S4 平均净空为 −1.029 m。",
    "在 S4 中加入 0.05 m 位置噪声和 1 个采样周期延迟后，加入因果平滑和延迟补偿的 LSTM 在 3 次运行中的成功数为 0/3，平均碰撞步数为 18.33，平均真实最小净空为 −0.513 m；cv 为 0/3、30.33 步和 −1.025 m；static 为 2/3、0.33 步和 0.074 m。因而 LSTM 在该压力条件下较 cv 明显更好，但没有超过 static。该结果是方法的明确边界：当前网络主要由干净历史训练，简单的在线平滑和延迟补偿可以减轻但不能消除感知分布偏移。":
        "在 S4 中加入 0.05 m 位置噪声和 1 个采样周期延迟，并为每次运行预先生成一条由三种方法共享的带噪观测流，从而保证不同方法面对完全相同的时序输入。LSTM 在 3 次运行中的成功数为 1/3，平均碰撞步数为 29.67，平均真实最小净空为 −0.448±0.971 m；cv 为 0/3、31.00 步和 −1.004±0.023 m；static 为 2/3、2.33 步和 −0.052±0.116 m。LSTM 的平均碰撞步数略低于 cv，但成功率和平均净空均未超过 static，因此不能将其表述为对该感知压力的整体鲁棒优势。三种方法的平均步时分别为 129.93、127.22 和 131.73 ms；逐运行 P95 步时范围分别为 160.69–161.61、148.87–154.62 和 160.93–162.19 ms。",
    "本文的主要证据链是：LSTM 在固定窗口上改善了非线性障碍轨迹预测；当同一预测被正确对齐并同时送入 MPC 和 DWA 时，S1–S4 的闭环成功率从 58.3% 提高到 100%，碰撞步数降为 0，且平均真实最小净空提高。cv 的案例说明，较低的平均预测误差并不必然产生更安全的闭环，因为密集走廊中的少量系统性时间误差可能被 MPC 和 DWA 的滚动执行放大。":
        "本文的主要证据链是：LSTM 在固定窗口上改善了非线性障碍轨迹预测；当同一预测被正确对齐并同时送入 MPC 和 DWA 时，S1–S4 的 12 次闭环运行全部成功且无碰撞，运行级平均真实最小净空为 0.949±0.835 m，高于两种基线。与此同时，成功率的 95% Wilson 区间为 75.7–100.0%，因此这一结果应理解为本文 12 次运行内的描述性证据，而不是对任意场景的成功率估计。cv 的案例说明，较低的平均预测误差并不必然产生更安全的闭环，因为密集走廊中的少量系统性时间误差可能被 MPC 和 DWA 的滚动执行放大。",
    "本文仍存在三个边界。第一，障碍轨迹来自固定合成生成器，尚未覆盖真实传感器遮挡、检测漏检、障碍物交互和多智能体博弈；因此不能直接外推到真实飞行。第二，主实验使用干净观测，压力实验表明延迟和噪声会显著削弱 LSTM 闭环性能。第三，平均每步计算时间约 100–106 ms，尚未满足严格 10 Hz 以外的实时裕度，且当前缓存 MPC 仍需在更高频硬件上验证。下一步应使用带传感器噪声、漏检和时间延迟的训练数据重新训练预测器，并在真实或硬件在环平台上检验安全约束与计算预算。":
        "本文仍存在四个边界。第一，障碍轨迹来自固定合成生成器，尚未覆盖真实传感器遮挡、检测漏检、障碍物交互和多智能体博弈；因此不能直接外推到真实飞行。第二，当前 LSTM 训练没有独立验证集或早停，模型选择不确定性尚未量化；固定评估场景与训练轨迹分离只能支持场景级外部检验，不能替代独立模型选择。第三，主实验使用干净观测，固定观测流压力实验表明延迟和噪声会显著削弱 LSTM 闭环性能，且其成功率未超过 static。第四，主实验平均每步计算时间约为 100–106 ms，当前结果尚未证明系统可稳定满足 10 Hz 实时预算；压力测试中逐运行 P95 步时约为 149–162 ms。下一步应使用带传感器噪声、漏检和时间延迟的训练数据重新训练预测器，并在真实或硬件在环平台上检验安全约束与计算预算。",
    "本文提出了一个将 LSTM 障碍物轨迹预测同时注入 MPC 和 DWA 的三维无人机动态避障方法，并通过固定窗口、3 种子闭环对照、结构消融和感知压力测试构成证据闭环。在本文设置的干净观测仿真中，LSTM-MPC-DWA 达到 12/12 成功、0 碰撞步，明显优于 static 和 cv 的 7/12 成功；固定窗口预测也在所有 S1–S4 分组中优于 cv。与此同时，噪声—延迟压力测试显示该优势并非无条件成立。因而本文支持的结论是：正确时间对齐的 LSTM 预测能够在中等复杂度动态障碍场景中显著增强 MPC-DWA 的闭环避障，而感知分布偏移和实时部署仍是需要进一步解决的关键问题。":
        "本文提出了一个将 LSTM 障碍物轨迹预测同时注入 MPC 和 DWA 的三维无人机动态避障方法，并通过固定窗口、3 种子闭环对照、结构消融和感知压力测试构成证据闭环。在本文设置的干净观测仿真中，LSTM-MPC-DWA 达到 12/12 成功、0 碰撞步；static 和 cv 均为 7/12 成功，且运行级不确定性已在表 3 中给出。固定窗口预测也在所有 S1–S4 分组中优于 cv。与此同时，固定观测流的噪声—延迟压力测试显示该优势并非无条件成立。因而本文支持的结论是：正确时间对齐的 LSTM 预测能够在本文的中等复杂度动态障碍仿真中改善 MPC-DWA 的闭环避障，而感知分布偏移、独立验证和实时部署仍是需要进一步解决的关键问题。",
}
for p in list(doc.paragraphs):
    for old_text, new_text in replacements.items():
        if old_text in p.text:
            p.text = p.text.replace(old_text, new_text)

# Keep the main closed-loop table aligned with the run-level statistical audit.
prediction_table = doc.tables[0]
main_results_table = doc.tables[1]
insert_text_before_table(prediction_table, "表 2  固定历史—未来窗口预测误差", size=8.5)
insert_text_before_table(main_results_table, "表 3  三种子闭环运行汇总（均值±标准差）", size=8.5)
update_main_results_table(main_results_table)

# Add the implementation and reproducibility parameters before the experiment section.
experiment_heading = next(p for p in doc.paragraphs if p.text == "4 实验设计")
insert_text_before(experiment_heading, "3.4 实现与复现参数", size=11.5, align=WD_ALIGN_PARAGRAPH.LEFT, bold=True)
insert_text_before(
    experiment_heading,
    "所有方法使用相同的无人机动力学、场景轨迹、MPC 代价和 DWA 动态窗口；仅障碍物未来轨迹接口不同。MPC 使用 CasADi 接口调用 IPOPT，最大迭代次数为 300、容差为 1e-6。DWA 基础采样数为 300，并按信任度自适应增加；引导采样比例为 0.35，探索强度参数为 3。",
    size=8.8,
)
insert_text_before(experiment_heading, "表 1  主要实现与复现参数", size=8.5, align=WD_ALIGN_PARAGRAPH.CENTER, bold=True)
insert_parameter_table_before(experiment_heading)

# Keep the main multi-seed table together with its heading instead of leaving
# only the table header at the bottom of the preceding page.
main_results_heading = next(p for p in doc.paragraphs if p.text == "5.2 多种子闭环比较")
main_page_break = main_results_heading.insert_paragraph_before()
main_page_break.add_run().add_break(WD_BREAK.PAGE)

# Improve the mathematical notation paragraph while retaining the source model.
for p in doc.paragraphs:
    if p.text == "J_obs= sum_k,j w_obsmax(0,-d_j,k)^2 +w_smax(0,d_s-d_j,k)^2,":
        p.text = "J_obs=Σ_k,j [w_obs max(0,−d_j,k)^2 + w_s max(0,d_s−d_j,k)^2]."

# Caption renumbering after inserting S1–S3 before the existing S4 figures.
for p in doc.paragraphs:
    if p.text.startswith("图 1｜S4 六障碍密集走廊"):
        p.text = p.text.replace("图 1｜", "图 4  ", 1)
    elif p.text.startswith("图 2｜S4 中段时刻"):
        p.text = p.text.replace("图 2｜", "图 5  ", 1)

# Locate the existing S4 trajectory and prediction image paragraphs before insertion.
old_fig = next(p for p in doc.paragraphs if "rId11" in p._p.xml)
old_pred = next(p for p in doc.paragraphs if "rId12" in p._p.xml)
set_inline_width(old_fig, 5.60)
set_inline_width(old_pred, 3.03)

# Insert the scene-level summary table and a focused interpretation before the figures.
table_caption = insert_text_before(old_fig, "表 4  三种子闭环运行的场景级汇总（均值）", size=8.5, align=WD_ALIGN_PARAGRAPH.CENTER, bold=True)
insert_scenario_table_before(old_fig)
insert_text_before(
    old_fig,
    "表中碰撞步数为一次闭环运行中发生碰撞的时间步数，最小净空为带符号净空；负值表示几何安全边界被穿越。S1–S4 分别对应双障碍轻度交叉、四障碍走廊交错、五障碍非线性走廊压缩和六障碍密集走廊压缩。",
    size=8.2,
    align=WD_ALIGN_PARAGRAPH.LEFT,
)
page_break = table_caption.insert_paragraph_before()
page_break.add_run().add_break(WD_BREAK.PAGE)

figures = [
    (RESULTS_DIR / "S1 双障碍轻度交叉.png", "图 1  S1 双障碍轻度交叉场景的三维闭环轨迹。黑色虚线为障碍物真实轨迹，灰色点线为标称直线航线，红色、绿色和橙色分别表示静态冻结、匀速外推和本文 LSTM。"),
    (RESULTS_DIR / "S2 四障碍走廊交错.png", "图 2  S2 四障碍走廊交错场景的三维闭环轨迹。图例和线型含义同图 1。"),
    (RESULTS_DIR / "S3 五障碍非线性走廊压缩.png", "图 3  S3 五障碍非线性走廊压缩场景的三维闭环轨迹。图例和线型含义同图 1。"),
]
insert_text_before(old_fig, "图 1–图 4 的轨迹图与表 4 的场景级统计相互补充：轨迹图用于显示绕障方向和空间偏移，表 4 用于区分到达、碰撞和净空三类结果。", size=8.8)
for image_path, caption in figures:
    insert_picture_before(old_fig, image_path, caption, width_in=5.60)
    insert_text_before(old_fig, caption, size=7.8, align=WD_ALIGN_PARAGRAPH.CENTER, italic=True)

# Replace the internal audit appendix with a concise, publication-appropriate reproducibility note.
for p in list(doc.paragraphs):
    if p.text == "结果分配与统计审计记录" or p.text.startswith(("核心结果：", "必要支持：", "机制诊断：", "鲁棒性边界：", "统计单位：", "数据与复现说明：")):
        delete_paragraph(p)
refs_heading = next(p for p in doc.paragraphs if p.text == "参考文献")
insert_text_before(refs_heading, "数据与复现说明", size=11.5, align=WD_ALIGN_PARAGRAPH.LEFT, bold=True)
insert_text_before(
    refs_heading,
    "本文数值来自固定窗口预测、三种子闭环比较、结构消融和噪声—延迟压力测试的逐运行记录。固定窗口存在时间重叠，不作为独立重复；闭环运行以场景—随机种子—方法为独立单位。主实验模型文件 results/lstm_predictor.mat 的 SHA-256 为 660d8698419de646af07f597193568b056236a12e8c8085ba9af6f49e29c5a49；固定观测流压力测试目录为 results/robustness/noise005_delay1_20260905_141201，其中 robustness_comparison.csv 保存 9 次逐运行结果和 P95 步时。本次运行未记录独立硬件型号，因此计算时间只用于同一环境内比较，不用于宣称实时部署。正式投稿时应提供可访问的代码、模型和逐运行数据归档链接，并补充作者、单位、硬件环境及参考文献 [1] 的正式书目信息。",
    size=9.2,
)

# Correct and complete the references that are supported by the local verification record.
reference_updates = {
    "[1] 常绪成等. 基于 MPC-DWA 策略的无人机路径规划算法研究. 电光与控制, 2026.":
        "[1] 常绪成，等. 基于 MPC-DWA 策略的无人机路径规划算法研究. 电光与控制，2026（网络首发；原文链接待作者补充）.",
    "[2] 滕菲等. 北京航空航天大学学报, 2025. DOI: 10.13700/j.bh.1001-5965.2025.0084.":
        "[2] 滕菲，王迎春，姚永辉，张坤. 基于深度强化学习的无人机动态避障规划. 北京航空航天大学学报，2025（网络优先）. DOI: 10.13700/j.bh.1001-5965.2025.0084.",
    "[3] 史培龙等. 长安大学学报（自然科学版）, 2024. DOI: 10.19721/j.cnki.1671-8879.2024.04.015.":
        "[3] 史培龙，等. Dynamic obstacle avoidance control of intelligent vehicle on large curvature roads considering trajectory prediction. 长安大学学报（自然科学版），2024（4）：161–174. DOI: 10.19721/j.cnki.1671-8879.2024.04.015.",
    "[4] Hahn. Actuators, 2025. DOI: 10.3390/act14050207.":
        "[4] Hahn B. Enhancing obstacle avoidance in dynamic window approach via dynamic obstacle behavior prediction. Actuators，2025，14（5）：207. DOI: 10.3390/act14050207.",
    "[5] Yu and Zhang. Ocean Engineering, 2026. DOI: 10.1016/j.oceaneng.2026.124503.":
        "[5] Yu H，Zhang Z. Dynamic obstacle avoidance algorithm for UUV based on physics prior LSTM network model and dynamic window approach. Ocean Engineering，2026，124503. DOI: 10.1016/j.oceaneng.2026.124503.",
    "[6] Li. AIITA, 2026. DOI: 10.1109/aiita69518.2026.11567135.":
        "[6] Ögren P，Leonard N E. A convergent dynamic window approach to obstacle avoidance. IEEE Transactions on Robotics，2005，21（2）：188–195. DOI: 10.1109/TRO.2004.838008.",
    "[7] Ögren and Leonard. IEEE Transactions on Robotics, 2005.": None,
}
for p in doc.paragraphs:
    if p.text in reference_updates:
        new_text = reference_updates[p.text]
        if new_text is None:
            delete_paragraph(p)
        else:
            p.text = new_text

# Set a clean metadata surface and force all document text to black.
cp = doc.core_properties
cp.title = "基于 LSTM 预测增强的 MPC-DWA 无人机动态避障方法"
cp.author = ""
cp.last_modified_by = ""
cp.comments = ""
cp.subject = "无人机动态障碍避障与轨迹预测"
cp.keywords = "无人机; MPC; DWA; LSTM; 动态避障"

for style in doc.styles:
    if hasattr(style, "font"):
        style.font.color.rgb = BLACK

for table in doc.tables:
    for row in table.rows:
        for cell in row.cells:
            set_cell_shading(cell)

for p in all_paragraphs_in_document(doc):
    for run in p.runs:
        set_run_black(run)

# Keep heading hierarchy while making the headings and captions uniformly black.
for p in doc.paragraphs:
    if p.style.name.startswith("Heading"):
        for run in p.runs:
            set_run_black(run, "SimSun")

doc.save(str(OUTPUT))
print(OUTPUT)
