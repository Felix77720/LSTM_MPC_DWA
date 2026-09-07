"""Build the evidence-backed Chinese manuscript DOCX from EI_paper_final_CN.md.

The markdown file is the prose source of truth. Numeric tables are copied from
the checked result CSVs before this builder is run; the builder intentionally
does not invent or recompute statistical claims.
"""
from pathlib import Path
import re

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Mm, Pt, RGBColor


HERE = Path(__file__).resolve().parent
SOURCE = HERE / "EI_paper_final_CN.md"
OUT = HERE / "EI_paper_final_CN.docx"
RESULTS = HERE.parent / "results"
FIG_SCENARIO = RESULTS / "S4 六障碍密集走廊压缩.png"
FIG_PRED = RESULTS / "S4 六障碍密集走廊压缩_pred.png"


def set_cell_shading(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_text(cell, text, bold=False, size=8.5, color=None):
    cell.text = ""
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(0)
    run = p.add_run(str(text))
    run.bold = bold
    run.font.name = "Times New Roman"
    run._element.rPr.rFonts.set(qn("w:ascii"), "Times New Roman")
    run._element.rPr.rFonts.set(qn("w:hAnsi"), "Times New Roman")
    run._element.rPr.rFonts.set(qn("w:eastAsia"), "SimSun")
    run.font.size = Pt(size)
    if color:
        run.font.color.rgb = RGBColor(*color)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER


def add_page_number(paragraph):
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = paragraph.add_run()
    fld = OxmlElement("w:fldSimple")
    fld.set(qn("w:instr"), "PAGE")
    run._r.append(fld)


def set_section_columns(section, columns=1, gap_mm=6.5):
    """Set Word section columns using the same geometry as the EI-style TeX profile."""
    sect_pr = section._sectPr
    cols = sect_pr.find(qn("w:cols"))
    if cols is None:
        cols = OxmlElement("w:cols")
        sect_pr.append(cols)
    cols.set(qn("w:num"), str(columns))
    cols.set(qn("w:space"), str(int(gap_mm * 56.6929)) if columns > 1 else "0")


def configure_section(section, columns=1):
    section.page_width = Mm(210)
    section.page_height = Mm(297)
    section.top_margin = Mm(18)
    section.bottom_margin = Mm(18)
    section.left_margin = Mm(16.5)
    section.right_margin = Mm(16.5)
    set_section_columns(section, columns)


def latex_display_to_text(text):
    def read_group(value, start):
        if start >= len(value) or value[start] != "{":
            return None, start
        depth = 0
        body = []
        for pos in range(start, len(value)):
            char = value[pos]
            if char == "{":
                depth += 1
                if depth > 1:
                    body.append(char)
            elif char == "}":
                depth -= 1
                if depth == 0:
                    return "".join(body), pos + 1
                body.append(char)
            else:
                body.append(char)
        return None, start

    def replace_frac(value):
        out = []
        pos = 0
        while pos < len(value):
            if value.startswith("\\frac", pos):
                cursor = pos + len("\\frac")
                while cursor < len(value) and value[cursor].isspace():
                    cursor += 1
                numerator, cursor_after_num = read_group(value, cursor)
                if numerator is not None:
                    cursor = cursor_after_num
                    while cursor < len(value) and value[cursor].isspace():
                        cursor += 1
                    denominator, cursor_after_den = read_group(value, cursor)
                    if denominator is not None:
                        out.append("[" + replace_frac(numerator) + "]/[" + replace_frac(denominator) + "]")
                        pos = cursor_after_den
                        continue
            out.append(value[pos])
            pos += 1
        return "".join(out)

    text = text.replace("\\[", "").replace("\\]", "")
    text = text.replace("\\begin{aligned}", "").replace("\\end{aligned}", "")
    text = replace_frac(text)
    text = re.sub(r"\\(?:mathbf|mathsf|mathbb)\s*\{([^{}]*)\}", r"\1", text)
    text = re.sub(r"\\(?:mathbf|mathsf|mathbb)\s*([A-Za-z])", r"\1", text)
    text = text.replace("\\|", "||")
    text = text.replace("\\left", "").replace("\\right", "")
    text = text.replace("&", "")
    text = text.replace("\\tau", "τ").replace("\\theta", "θ")
    text = text.replace("\\psi", "ψ").replace("\\omega", "ω")
    text = text.replace("\\cos", "cos").replace("\\sin", "sin")
    text = text.replace("\\max", "max").replace("\\min", "min")
    text = text.replace("\\,", " ")
    text = text.replace("\\mathsf{T}", "T")
    text = text.replace("\\pm", "±")
    text = text.replace("\\in", "∈").replace("\\leq", "≤").replace("\\geq", "≥")
    text = text.replace("\\alpha", "α").replace("\\beta", "β")
    text = text.replace("\\sigma", "σ").replace("\\omega", "ω")
    text = text.replace("\\sum", "∑")
    text = text.replace("\\quad", " ").replace("\\qquad", " ")
    text = text.replace("\\times", "×").replace("\\cdot", "·").replace("\\land", "∧")
    text = text.replace("\\\\", " ; ")
    text = re.sub(r"\\(?:operatorname|mathrm|text)\s*\{([^{}]*)\}", r"\1", text)
    text = re.sub(r"\\(?:operatorname|mathrm|text)\s+([A-Za-z]+)", r"\1", text)
    text = re.sub(r"\\hat\s*\{?([A-Za-z])\}?", r"\1̂", text)
    sub_map = str.maketrans({
        "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄",
        "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉",
        "+": "₊", "-": "₋", "=": "₌", "t": "ₜ", "j": "ⱼ",
        "k": "ₖ", "n": "ₙ", "p": "ₚ", "r": "ᵣ", "s": "ₛ",
        "v": "ᵥ", "x": "ₓ", "a": "ₐ", "e": "ₑ", "i": "ᵢ",
        "m": "ₘ", "u": "ᵤ",
    })
    sup_map = str.maketrans({
        "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
        "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹",
        "+": "⁺", "-": "⁻", "=": "⁼", "T": "ᵀ",
    })
    def subscript(value):
        return value.translate(sub_map)
    def superscript(value):
        return value.translate(sup_map)
    text = re.sub(r"_\{([^{}]+)\}", lambda m: subscript(m.group(1)), text)
    text = re.sub(r"_([A-Za-z0-9])", lambda m: subscript(m.group(1)), text)
    text = re.sub(r"\^\{([^{}]+)\}", lambda m: superscript(m.group(1)), text)
    text = re.sub(r"\^([A-Za-z0-9])", lambda m: superscript(m.group(1)), text)
    text = text.replace("\\", " ")
    text = re.sub(r"\{([^{}]*)\}", r"\1", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def clean_inline(text):
    """Remove markdown/LaTeX wrappers that should not appear in the DOCX."""
    code_tokens = []
    math_tokens = []
    def protect_code(match):
        code_tokens.append(match.group(1))
        return f"§§CODETOKEN{len(code_tokens) - 1}§§"
    def protect_math(match):
        math_tokens.append(latex_display_to_text(match.group(1)))
        return f"§§MATHTOKEN{len(math_tokens) - 1}§§"
    text = re.sub(r"`([^`]+)`", protect_code, text)
    text = re.sub(r"\$([^$]+)\$", protect_math, text)
    text = re.sub(r"\*\*(.*?)\*\*", r"\1", text)
    text = text.replace("`", "").replace("$", "")
    if "\\" in text:
        text = latex_display_to_text(text)
    for i, value in enumerate(math_tokens):
        text = text.replace(f"§§MATHTOKEN{i}§§", value)
    for i, value in enumerate(code_tokens):
        text = text.replace(f"§§CODETOKEN{i}§§", value)
    return text


def parse_markdown(path):
    lines = path.read_text(encoding="utf-8").splitlines()
    blocks = []
    i = 0
    while i < len(lines):
        line = lines[i].rstrip()
        if not line.strip() or line.strip() == "---":
            i += 1
            continue
        image_match = re.match(r"^!\[(.*?)\]\((.*?)\)\s*$", line)
        if image_match:
            blocks.append(("figure", (image_match.group(1).strip(), image_match.group(2).strip())))
            i += 1
            continue
        if line.startswith("|"):
            table = []
            while i < len(lines) and lines[i].lstrip().startswith("|"):
                row = [x.strip() for x in lines[i].strip().strip("|").split("|")]
                if not all(set(x) <= set("-: ") for x in row):
                    table.append(row)
                i += 1
            if table:
                blocks.append(("table", table))
            continue
        if line.startswith("\\["):
            eq = [line]
            i += 1
            while i < len(lines) and "\\]" not in lines[i]:
                eq.append(lines[i])
                i += 1
            if i < len(lines):
                eq.append(lines[i])
                i += 1
            blocks.append(("equation", latex_display_to_text(" ".join(eq))))
            continue
        if line.startswith("#"):
            level = len(line) - len(line.lstrip("#"))
            blocks.append((f"h{min(level, 3)}", line[level:].strip()))
        elif re.match(r"^\d+\.\s+", line):
            blocks.append(("number", re.sub(r"^\d+\.\s+", "", line)))
        elif line.startswith("- "):
            blocks.append(("bullet", line[2:].strip()))
        else:
            blocks.append(("paragraph", line))
        i += 1
    return blocks


def add_paragraph(doc, text, kind="paragraph"):
    if kind == "bullet":
        p = doc.add_paragraph(style="List Bullet")
    elif kind == "number":
        p = doc.add_paragraph(style="List Number")
    else:
        p = doc.add_paragraph()
    p.paragraph_format.line_spacing = 1.02 if kind.startswith("front_") else 1.04
    p.paragraph_format.space_after = Pt(3 if kind.startswith("front_") else 2.5)
    if kind in {"paragraph", "front_para"}:
        p.paragraph_format.first_line_indent = Pt(14 if kind == "paragraph" else 0)
        p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    if kind == "front_meta":
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.first_line_indent = Pt(0)
        p.paragraph_format.space_after = Pt(1)
    if kind == "front_label":
        p.paragraph_format.first_line_indent = Pt(0)
        p.paragraph_format.space_before = Pt(3)
        p.paragraph_format.space_after = Pt(1)
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    if kind == "front_keyword":
        p.paragraph_format.first_line_indent = Pt(0)
        p.paragraph_format.space_after = Pt(2)
        p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    if kind == "data_note":
        p.paragraph_format.first_line_indent = Pt(0)
        p.paragraph_format.line_spacing = 1.0
        p.paragraph_format.space_after = Pt(1)
        p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    if kind == "table_caption":
        p.paragraph_format.first_line_indent = Pt(0)
        p.paragraph_format.space_before = Pt(5)
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.keep_with_next = True
    if kind == "equation":
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.first_line_indent = Pt(0)
        p.paragraph_format.space_before = Pt(4)
        p.paragraph_format.space_after = Pt(6)
    if kind == "equation":
        # Native OMML keeps equations editable in Word and importable by
        # MathType, instead of flattening them into italic plain text.
        omath_para = OxmlElement("m:oMathPara")
        omath = OxmlElement("m:oMath")
        math_run = OxmlElement("m:r")
        math_text = OxmlElement("m:t")
        math_text.set(qn("xml:space"), "preserve")
        math_text.text = text
        math_run.append(math_text)
        omath.append(math_run)
        omath_para.append(omath)
        p._p.append(omath_para)
    else:
        run = p.add_run(text)
        run.font.name = "Times New Roman"
        run._element.rPr.rFonts.set(qn("w:ascii"), "Times New Roman")
        run._element.rPr.rFonts.set(qn("w:hAnsi"), "Times New Roman")
        run._element.rPr.rFonts.set(qn("w:eastAsia"), "SimSun")
        if kind == "data_note":
            run.font.size = Pt(8.2)
        else:
            run.font.size = Pt(9.2 if kind.startswith("front_") else 9.5)
        if kind == "table_caption":
            run.bold = True
        if kind == "front_label":
            run.bold = True
    return p


def add_table(doc, rows, columns=1):
    cols = max(len(r) for r in rows)
    table = doc.add_table(rows=1, cols=cols)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    table.autofit = False
    for j in range(cols):
        set_cell_text(table.rows[0].cells[j], clean_inline(rows[0][j] if j < len(rows[0]) else ""), True, 7.9 if columns == 1 else 7.4, (0, 0, 0))
        set_cell_shading(table.rows[0].cells[j], "FFFFFF")
    for row in rows[1:]:
        cells = table.add_row().cells
        for j in range(cols):
            set_cell_text(cells[j], clean_inline(row[j] if j < len(row) else ""), False, 7.7 if columns == 1 else 7.4)
            set_cell_shading(cells[j], "FFFFFF")
    for row_index, row in enumerate(table.rows):
        tr_pr = row._tr.get_or_add_trPr()
        cant_split = OxmlElement("w:cantSplit")
        tr_pr.append(cant_split)
        if row_index == 0:
            header_repeat = OxmlElement("w:tblHeader")
            header_repeat.set(qn("w:val"), "true")
            tr_pr.append(header_repeat)
        for cell in row.cells:
            table_width_in = (177.0 / 25.4) if columns == 1 else ((177.0 - 6.5) / 2 / 25.4)
            cell.width = Inches(table_width_in / cols)
    doc.add_paragraph().paragraph_format.space_after = Pt(1)
    return table


def add_figure(doc, path, caption, width=6.2):
    if not path.exists():
        return
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(6)
    p.paragraph_format.keep_together = True
    p.add_run().add_picture(str(path), width=Inches(width))
    cap = doc.add_paragraph(caption)
    cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    cap.paragraph_format.keep_with_previous = True
    cap.paragraph_format.space_after = Pt(8)
    cap.runs[0].font.size = Pt(9)
    cap.runs[0].italic = True
    cap.runs[0].font.name = "SimSun"
    cap.runs[0]._element.rPr.rFonts.set(qn("w:ascii"), "Times New Roman")
    cap.runs[0]._element.rPr.rFonts.set(qn("w:hAnsi"), "Times New Roman")
    cap.runs[0]._element.rPr.rFonts.set(qn("w:eastAsia"), "SimSun")


def build():
    doc = Document()
    doc.core_properties.comments = ""
    sec = doc.sections[0]
    configure_section(sec, 1)

    normal = doc.styles["Normal"]
    normal.font.name = "Times New Roman"
    normal._element.rPr.rFonts.set(qn("w:ascii"), "Times New Roman")
    normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Times New Roman")
    normal._element.rPr.rFonts.set(qn("w:eastAsia"), "SimSun")
    normal.font.size = Pt(9.5)
    normal.paragraph_format.line_spacing = 1.04
    normal.paragraph_format.space_after = Pt(2.5)

    for name, size, color in [("Heading 1", 12, (0, 0, 0)), ("Heading 2", 10.5, (0, 0, 0)), ("Heading 3", 9.5, (0, 0, 0))]:
        style = doc.styles[name]
        style.font.name = "SimSun"
        style._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
        style._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
        style._element.rPr.rFonts.set(qn("w:eastAsia"), "SimSun")
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = RGBColor(*color)
        style.paragraph_format.space_before = Pt(6 if name == "Heading 1" else 4)
        style.paragraph_format.space_after = Pt(2)

    header = sec.header.paragraphs[0]
    header.text = ""
    add_page_number(sec.footer.paragraphs[0])

    blocks = parse_markdown(SOURCE)
    first_title = True
    front_matter = True
    in_two_columns = False
    layout_columns = 1
    wide_table = False

    for index, (kind, text) in enumerate(blocks):
        next_block = blocks[index + 1] if index + 1 < len(blocks) else None
        if kind == "h1" and first_title:
            p = doc.add_paragraph()
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.paragraph_format.space_after = Pt(5)
            r = p.add_run(text)
            r.bold = True
            r.font.name = "SimSun"
            r._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
            r._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
            r._element.rPr.rFonts.set(qn("w:eastAsia"), "SimSun")
            r.font.size = Pt(17)
            r.font.color.rgb = RGBColor(0, 0, 0)
            first_title = False
        elif kind == "h1":
            doc.add_heading(text, level=1)
        elif kind == "h2":
            if front_matter and text in {"摘要", "English Abstract"}:
                add_paragraph(doc, text, "front_label")
            else:
                if text.startswith("1 ") and not in_two_columns:
                    sec = doc.add_section(WD_SECTION.CONTINUOUS)
                    configure_section(sec, 2)
                    in_two_columns = True
                    layout_columns = 2
                    front_matter = False
                doc.add_heading(text, level=2)
        elif kind == "h3":
            doc.add_heading(text, level=3)
        elif kind == "table":
            add_table(doc, text, columns=layout_columns)
            if wide_table:
                sec = doc.add_section(WD_SECTION.CONTINUOUS)
                configure_section(sec, 2)
                layout_columns = 2
                wide_table = False
        elif kind == "figure":
            caption, rel_path = text
            fig_path = (SOURCE.parent / rel_path.replace("%20", " ")).resolve()
            if in_two_columns and "S4" in rel_path and "_pred" in rel_path:
                break_paragraph = doc.add_paragraph()
                break_paragraph.add_run().add_break(WD_BREAK.COLUMN)
            wide_figure = in_two_columns and "lstm_detour_evidence" in rel_path
            if wide_figure and not wide_table:
                sec = doc.add_section(WD_SECTION.CONTINUOUS)
                configure_section(sec, 1)
                layout_columns = 1
                wide_table = True
            fig_width = 6.65 if not in_two_columns or wide_figure else 3.25
            add_figure(doc, fig_path, clean_inline(caption), width=fig_width)
            if wide_figure:
                sec = doc.add_section(WD_SECTION.CONTINUOUS)
                configure_section(sec, 2)
                layout_columns = 2
                wide_table = False
        else:
            text = clean_inline(text)
            if front_matter:
                if text.startswith(("作者：", "单位：", "English title:", "Authors:", "Affiliations:")):
                    kind = "front_meta"
                elif text.startswith(("关键词：", "**关键词：", "Keywords:")):
                    kind = "front_keyword"
                else:
                    kind = "front_para"
            if text.startswith("表 "):
                kind = "table_caption"
                next_rows = next_block[1] if next_block and next_block[0] == "table" else []
                is_wide = bool(next_rows and len(next_rows[0]) >= 5)
                if in_two_columns and is_wide and not wide_table:
                    sec = doc.add_section(WD_SECTION.CONTINUOUS)
                    configure_section(sec, 1)
                    layout_columns = 1
                    wide_table = True
            elif text.startswith("本文数值来自"):
                kind = "data_note"
            add_paragraph(doc, text, kind)

    for section in doc.sections[1:]:
        section.header.is_linked_to_previous = True
        section.footer.is_linked_to_previous = True

    doc.save(OUT)
    print(f"WROTE {OUT}")


if __name__ == "__main__":
    build()
