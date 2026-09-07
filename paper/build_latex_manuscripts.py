from __future__ import annotations

import re
import os
from pathlib import Path
from urllib.parse import unquote


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PAPER_DIR = PROJECT_ROOT / "paper"


def escape_text(text: str) -> str:
    """Escape LaTeX characters in ordinary text."""
    replacements = {
        "\\": r"\textbackslash{}",
        "&": r"\&",
        "%": r"\%",
        "$": r"\$",
        "#": r"\#",
        "_": r"\_",
        "{": r"\{",
        "}": r"\}",
        "~": r"\textasciitilde{}",
        "^": r"\textasciicircum{}",
    }
    return "".join(replacements.get(char, char) for char in text)


def render_inline(text: str) -> str:
    """Convert the inline Markdown used by the manuscripts to LaTeX."""
    protected: list[str] = []

    def protect(value: str) -> str:
        marker = f"\x00{len(protected)}\x00"
        protected.append(value)
        return marker

    def protect_pattern(value: str, pattern: str, formatter) -> str:
        return re.sub(pattern, lambda match: protect(formatter(match)), value)

    text = protect_pattern(text, r"\$[^$\n]+\$", lambda match: match.group(0))
    text = protect_pattern(text, r"\\\([^\n]*?\\\)", lambda match: match.group(0))
    text = protect_pattern(
        text,
        r"`[^`]+`",
        lambda match: r"\texttt{" + escape_text(match.group(0)[1:-1]) + "}",
    )

    def render_link(match: re.Match[str]) -> str:
        label = render_inline(match.group(1))
        target = match.group(2).replace("#", r"\#")
        return rf"\href{{{target}}}{{{label}}}"

    text = protect_pattern(text, r"\[([^\]]+)\]\(([^)]+)\)", render_link)
    text = protect_pattern(
        text,
        r"<((?:https?://|doi:)[^>]+)>",
        lambda match: rf"\url{{{match.group(1)}}}",
    )

    def render_bare_url(match: re.Match[str]) -> str:
        full_match = match.group(0)
        target = full_match.rstrip(".,;:")
        suffix = full_match[len(target) :]
        return rf"\url{{{target}}}{suffix}"

    text = protect_pattern(text, r"(?<![\w/])https?://[^\s]+", render_bare_url)
    text = protect_pattern(
        text,
        r"\*\*([^*]+)\*\*",
        lambda match: r"\textbf{" + render_inline(match.group(1)) + "}",
    )
    text = protect_pattern(
        text,
        r"(?<!\*)\*([^*]+)\*(?!\*)",
        lambda match: r"\emph{" + render_inline(match.group(1)) + "}",
    )

    rendered = escape_text(text)
    for index, value in enumerate(protected):
        rendered = rendered.replace(f"\x00{index}\x00", value)
    return rendered


def strip_heading_number(title: str) -> str:
    return re.sub(r"^\d+(?:\.\d+)?\s+", "", title.strip())


def caption_text(line: str) -> str | None:
    match = re.match(r"^(?:表\s*\d+|Table\s+\d+)\s*[\.:：]?\s*(.*)$", line.strip())
    return match.group(1).strip() if match else None


def split_table_row(line: str) -> list[str]:
    parts = line.strip().split("|")
    if parts and parts[0].strip() == "":
        parts = parts[1:]
    if parts and parts[-1].strip() == "":
        parts = parts[:-1]
    return [part.strip() for part in parts]


def is_table_separator(line: str) -> bool:
    cells = split_table_row(line)
    return bool(cells) and all(re.fullmatch(r":?-{3,}:?", cell.replace(" ", "")) for cell in cells)


def is_image(line: str) -> bool:
    return bool(re.match(r"^!\[[^]]*\]\([^)]+\)$", line.strip()))


def is_ordered_item(line: str) -> bool:
    return bool(re.match(r"^\d+\.\s+", line.strip()))


def figure_caption(alt: str) -> str:
    return re.sub(r"^(?:图|Fig\.?)[ ]*\d+[ ]*[｜|\.:：]?\s*", "", alt.strip())


class ManuscriptConverter:
    def __init__(self, source: Path, destination: Path, *, title: str, chinese: bool, twocolumn: bool):
        self.source = source
        self.destination = destination
        self.title = title
        self.chinese = chinese
        self.twocolumn = twocolumn
        self.table_index = 0
        self.figure_index = 0
        self.pending_caption: str | None = None
        self.in_abstract = False
        self.in_references = False
        self.abstract_prefix_pending = False

    def preamble(self) -> str:
        if self.chinese:
            document_class = (
                r"\documentclass[10pt,a4paper,twocolumn]{ctexart}"
                if self.twocolumn
                else r"\documentclass[11pt,a4paper]{ctexart}"
            )
            geometry = (
                r"\usepackage[left=1.65cm,right=1.65cm,top=1.8cm,bottom=1.8cm]{geometry}"
                if self.twocolumn
                else r"\usepackage[left=2.4cm,right=2.4cm,top=2.2cm,bottom=2.2cm]{geometry}"
            )
        else:
            document_class = r"\documentclass[10pt,a4paper]{article}"
            geometry = r"\usepackage[left=2.2cm,right=2.2cm,top=2.0cm,bottom=2.0cm]{geometry}"

        columnsep = r"\setlength{\columnsep}{0.65cm}" if self.twocolumn else ""
        unicode_font = r"\usepackage{fontspec}" if not self.chinese else ""
        return "\n".join(
            line
            for line in [
                document_class,
                geometry,
                unicode_font,
                r"\setCJKmainfont{SimSun}" if self.chinese else "",
                r"\setCJKsansfont{SimSun}" if self.chinese else "",
                r"\usepackage{amsmath,amssymb}",
                r"\usepackage{booktabs}",
                r"\usepackage{graphicx}",
                r"\usepackage{tabularx}",
                r"\usepackage{array}",
                r"\usepackage{caption}",
                r"\usepackage{enumitem}",
                r"\usepackage[hidelinks]{hyperref}",
                r"\newcolumntype{Y}{>{\raggedright\arraybackslash}X}",
                r"\captionsetup{font=small,labelfont=bf,labelsep=space}",
                r"\setlength{\parindent}{2em}",
                r"\setlength{\parskip}{0pt}",
                r"\setlength{\tabcolsep}{3pt}",
                r"\emergencystretch=3em",
                columnsep,
                "",
                rf"\title{{{render_inline(self.title)}}}",
                r"\author{}",
                r"\date{}",
                "",
                r"\begin{document}",
                r"\maketitle",
                "",
            ]
            if line != ""
        )

    def close_abstract(self, output: list[str]) -> None:
        if self.in_abstract:
            output.append(r"\end{abstract}")
            output.append("")
            self.in_abstract = False

    def heading(self, level: int, title: str, output: list[str]) -> None:
        self.close_abstract(output)
        if self.in_references:
            output.append(r"\end{thebibliography}")
            output.append("")
            self.in_references = False

        normalized = title.strip()
        lower = normalized.lower()
        if lower in {"摘要", "abstract"}:
            output.append(r"\begin{abstract}")
            if normalized == "摘要":
                output.append(r"\noindent\textbf{摘要：}")
            else:
                output.append(r"\noindent\textbf{Abstract. }")
            output.append("")
            self.in_abstract = True
            return
        if "english abstract" in lower:
            output.append(r"\begin{abstract}")
            output.append(r"\noindent\textbf{Abstract. }")
            output.append("")
            self.in_abstract = True
            return
        if normalized in {"参考文献", "References"}:
            command = r"\section*{参考文献}" if normalized == "参考文献" else r"\section*{References}"
            output.extend([command, r"\begin{thebibliography}{99}"])
            self.in_references = True
            return

        title_text = strip_heading_number(normalized)
        command = r"\section" if level == 2 else r"\subsection"
        output.append(f"{command}{{{render_inline(title_text)}}}")
        output.append("")

    def keyword_line(self, line: str, output: list[str]) -> bool:
        match = re.match(r"^\*\*(关键词|Keywords)：?\*\*\s*(.*)$", line.strip())
        if not match:
            return False
        label = "关键词" if match.group(1) == "关键词" else "Keywords"
        output.append(rf"\noindent\textbf{{{label}：}} {render_inline(match.group(2))}")
        output.append("")
        return True

    def table(self, lines: list[str], output: list[str]) -> None:
        rows = [split_table_row(line) for line in lines if not is_table_separator(line)]
        if not rows:
            return
        self.table_index += 1
        count = len(rows[0])
        rows = [row + [""] * (count - len(row)) for row in rows]
        rows = [row[:count] for row in rows]
        environment = "table*" if self.twocolumn else "table"
        width = r"\textwidth" if self.twocolumn else r"\linewidth"
        caption = self.pending_caption or ""
        self.pending_caption = None
        output.extend(
            [
                rf"\begin{{{environment}}}[t]",
                r"\centering",
                r"\small",
                rf"\caption{{{render_inline(caption)}}}",
                rf"\label{{tab:table-{self.table_index}}}",
                rf"\begin{{tabularx}}{{{width}}}{{{'Y' * count}}}",
                r"\toprule",
            ]
        )
        output.append(" & ".join(render_inline(cell) for cell in rows[0]) + r" \\")
        output.append(r"\midrule")
        for row in rows[1:]:
            output.append(" & ".join(render_inline(cell) for cell in row) + r" \\")
        output.extend(
            [
                r"\bottomrule",
                r"\end{tabularx}",
                rf"\end{{{environment}}}",
                "",
            ]
        )

    def image(self, line: str, output: list[str]) -> None:
        match = re.match(r"^!\[([^]]*)\]\(([^)]+)\)$", line.strip())
        if not match:
            return
        alt = match.group(1).strip()
        path = unquote(match.group(2).strip()).replace("\\", "/")
        image_path = (self.source.parent / path).resolve()
        if not image_path.exists():
            raise FileNotFoundError(f"Figure referenced by {self.source.name} does not exist: {image_path}")
        include_path = Path(os.path.relpath(image_path, self.destination.parent)).as_posix()
        self.figure_index += 1
        environment = "figure*" if self.twocolumn else "figure"
        width = r"0.98\textwidth" if self.twocolumn else r"0.98\linewidth"
        output.extend(
            [
                rf"\begin{{{environment}}}[t]",
                r"\centering",
                rf"\includegraphics[width={width}]{{{include_path}}}",
                rf"\caption{{{render_inline(figure_caption(alt))}}}",
                rf"\label{{fig:figure-{self.figure_index}}}",
                rf"\end{{{environment}}}",
                "",
            ]
        )

    def display_math(self, lines: list[str], output: list[str]) -> None:
        if lines[0].strip() == "$$":
            body = lines[1:-1]
            output.extend([r"\[", *body, r"\]", ""])
        else:
            output.extend(lines)
            output.append("")

    def paragraph(self, lines: list[str], output: list[str]) -> None:
        text = " ".join(line.strip() for line in lines)
        if self.in_references:
            match = re.match(r"^\[(\d+)\]\s*(.*)$", text)
            if match:
                output.append(rf"\bibitem{{ref{match.group(1)}}} {render_inline(match.group(2))}")
                output.append("")
                return
        if self.keyword_line(text, output):
            return
        if self.in_abstract and self.abstract_prefix_pending:
            output.append(rf"\noindent\textbf{{Abstract. }}{render_inline(text)}")
            self.abstract_prefix_pending = False
        else:
            output.append(render_inline(text))
        output.append("")

    def convert(self) -> None:
        lines = self.source.read_text(encoding="utf-8").splitlines()
        output = [self.preamble()]
        index = 0
        seen_body_heading = False
        while index < len(lines):
            line = lines[index]
            stripped = line.strip()
            if not stripped:
                index += 1
                continue

            heading_match = re.match(r"^(#{1,3})\s+(.+?)\s*$", stripped)
            if heading_match:
                level = len(heading_match.group(1))
                if level == 1:
                    index += 1
                    continue
                seen_body_heading = True
                self.heading(level, heading_match.group(2), output)
                index += 1
                continue

            if not seen_body_heading:
                index += 1
                continue

            if self.in_references and re.match(r"^\[\d+\]\s+", stripped):
                self.paragraph([stripped], output)
                index += 1
                continue

            if is_table_separator(stripped) or stripped.startswith("|"):
                table_lines = []
                while index < len(lines) and (lines[index].strip().startswith("|") or is_table_separator(lines[index].strip())):
                    table_lines.append(lines[index].strip())
                    index += 1
                self.table(table_lines, output)
                continue

            if is_image(stripped):
                self.image(stripped, output)
                index += 1
                continue

            if stripped in {r"\[", "$$"}:
                math_lines = [stripped]
                index += 1
                closing = r"\]" if stripped == r"\[" else "$$"
                while index < len(lines):
                    math_lines.append(lines[index].strip())
                    if lines[index].strip() == closing:
                        index += 1
                        break
                    index += 1
                self.display_math(math_lines, output)
                continue

            if is_ordered_item(stripped):
                items = []
                while index < len(lines) and is_ordered_item(lines[index].strip()):
                    items.append(re.sub(r"^\d+\.\s+", "", lines[index].strip()))
                    index += 1
                output.extend([r"\begin{enumerate}[leftmargin=*]"])
                output.extend(rf"\item {render_inline(item)}" for item in items)
                output.extend([r"\end{enumerate}", ""])
                continue

            caption = caption_text(stripped)
            if caption is not None:
                self.pending_caption = caption
                index += 1
                continue

            paragraph_lines = [stripped]
            index += 1
            while index < len(lines):
                next_line = lines[index].strip()
                if not next_line:
                    break
                if (
                    re.match(r"^(#{1,3})\s+", next_line)
                    or next_line.startswith("|")
                    or is_table_separator(next_line)
                    or is_image(next_line)
                    or next_line in {r"\[", "$$"}
                    or is_ordered_item(next_line)
                    or caption_text(next_line) is not None
                ):
                    break
                paragraph_lines.append(next_line)
                index += 1
            self.paragraph(paragraph_lines, output)

        self.close_abstract(output)
        if self.in_references:
            output.append(r"\end{thebibliography}")
            output.append("")
        output.append(r"\end{document}")
        self.destination.write_text("\n".join(output) + "\n", encoding="utf-8")


def build_all() -> None:
    cn_source = PAPER_DIR / "EI_paper_final_CN.md"
    en_source = PAPER_DIR / "jirs_manuscript_EN.md"
    outputs = [
            ManuscriptConverter(
                cn_source,
                PAPER_DIR / "EI_paper_final_CN.tex",
            title="基于 LSTM 预测增强的 MPC-DWA 无人机动态避障方法",
            chinese=True,
            twocolumn=True,
        ),
        ManuscriptConverter(
            cn_source,
            PAPER_DIR / "target_sys_ele" / "system_engineering_electronics_manuscript_CN.tex",
            title="基于 LSTM 预测增强的 MPC-DWA 无人机动态避障方法",
            chinese=True,
            twocolumn=False,
        ),
        ManuscriptConverter(
            en_source,
            PAPER_DIR / "jirs" / "jirs_manuscript_EN.tex",
            title="Prediction--Planning Consistent LSTM-Enhanced MPC-DWA for UAV Dynamic Obstacle Avoidance",
            chinese=False,
            twocolumn=False,
        ),
    ]
    for converter in outputs:
        converter.destination.parent.mkdir(parents=True, exist_ok=True)
        converter.convert()
        print(converter.destination)


if __name__ == "__main__":
    build_all()
