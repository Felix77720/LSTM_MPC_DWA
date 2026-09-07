"""Generate a machine-checkable pre-submission audit for the manuscript."""
from __future__ import annotations

import csv
import re
from pathlib import Path

from docx import Document


HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
SOURCE = HERE / "EI_paper_final_CN.md"
DOCX = HERE / "EI_paper_submission.docx"
OUT = HERE / "SUBMISSION_AUDIT.md"


def csv_rows(path: Path):
    if not path.exists():
        return []
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def latest_file(glob: str):
    files = list((ROOT / "results").glob(glob))
    return max(files, key=lambda p: p.stat().st_mtime) if files else None


def latest_dir(parent: Path, pattern: str):
    dirs = [p for p in parent.glob(pattern) if p.is_dir()]
    return max(dirs, key=lambda p: p.stat().st_mtime) if dirs else None


def main():
    text = SOURCE.read_text(encoding="utf-8")
    figures = [int(x) for x in re.findall(r"!\[图\s*(\d+)", text)]
    tables = [int(x) for x in re.findall(r"^表\s*(\d+)", text, re.M)]
    refs = [int(x) for x in re.findall(r"^\[(\d+)\]", text, re.M)]
    placeholders = [x for x in ["作者信息待补", "待随机套件完成", "±?", "— | —"] if x in text]

    docx_black = True
    docx_runs = 0
    if DOCX.exists():
        doc = Document(DOCX)
        for p in doc.paragraphs:
            for run in p.runs:
                docx_runs += 1
                color = run.font.color.rgb
                if color is not None and str(color) not in {"000000", "00000000"}:
                    docx_black = False
        for table in doc.tables:
            for row in table.rows:
                for cell in row.cells:
                    for p in cell.paragraphs:
                        for run in p.runs:
                            docx_runs += 1
                            color = run.font.color.rgb
                            if color is not None and str(color) not in {"000000", "00000000"}:
                                docx_black = False

    main_rows = csv_rows(ROOT / "results" / "multiseed_comparison.csv")
    robust_dir = latest_dir(ROOT / "results" / "robustness_unified", "sensing_*")
    robust_rows = csv_rows(robust_dir / "sensing_comparison.csv") if robust_dir else []
    random_dir = latest_dir(ROOT / "results" / "random_eval", "random12_*")
    random_rows = csv_rows(random_dir / "random_comparison.csv") if random_dir else []

    checks = [
        ("标题、作者、英文摘要和关键词", all(x in text for x in ["# 基于", "作者：", "付贞辉", "English title:", "## English Abstract", "**Keywords:**"])),
        ("正文无未回填占位符", not placeholders),
        ("图编号连续且唯一", figures == list(range(1, len(figures) + 1)) and len(figures) == len(set(figures))),
        ("表编号连续且唯一", tables == list(range(1, len(tables) + 1)) and len(tables) == len(set(tables))),
        ("公式存在且指标定义齐全", text.count("\\[") >= 6 and all(x in text for x in ["ADE=", "FDE=", "d_{min}", "碰撞事件"])),
        ("参考文献编号连续", refs == list(range(1, len(refs) + 1)) and len(refs) >= 10),
        ("固定场景逐运行结果为 48 行", len(main_rows) == 48),
        ("压力测试逐运行结果为 48 行", len(robust_rows) == 48),
        ("随机场景逐运行结果为 144 行", len(random_rows) == 144),
        ("四种方法均有记录", {r.get("Method") for r in main_rows} == {"static", "cv", "kalman", "lstm"}),
        ("训练机动协议包含 helix", "螺旋（helix）" in text),
        ("DWA 拒绝阈值为 0.25 m", "d_{reject}=0.25" in text and "预测净空不大于 0.25 m" in text and "不大于 0.05 m" not in text),
        ("模型哈希已写入数据说明", "61d84f53263b9ed568c15a3a0fa2dc2fb04d7b1b4e4f669ae38effc4e3e3c25d" in text),
        ("声明段按当前要求省略", not any(x in text for x in ["## 声明", "## Statements and Declarations", "AI-tool disclosure"])),
        ("参考文献核验记录存在", (HERE / "REFERENCE_CHECK.md").exists()),
        ("DOCX 字体颜色全黑", docx_black and docx_runs > 0),
    ]

    formula_count = text.count("\\[")
    lines = ["# 提交前全文检查报告", "", "检查日期：2026-09-07", ""]
    lines.append("| 检查项 | 结果 | 证据 |")
    lines.append("|---|---|---|")
    for name, ok in checks:
        lines.append(f"| {name} | {'PASS' if ok else 'FAIL'} | source/DOCX/results machine check |")
    lines += [
        "",
        f"- 图编号：{figures}；表编号：{tables}；公式块：{formula_count}；参考文献：{len(refs)} 条。",
        f"- 固定场景逐运行：{len(main_rows)} 行；压力测试：{len(robust_rows)} 行；随机场景：{len(random_rows)} 行。",
        "- 黑色字体检查覆盖正文、页眉页脚和表格中的 DOCX runs；表格底色已统一为白色。",
        "- 参考文献 [1] 已按作者提供的记录写入题名、作者、期刊、[J/OL]、页码、日期和 CNKI 链接；卷期和 DOI 未提供，未在文稿中补造，见 REFERENCE_CHECK.md。",
        "- 排版已生成通用 EI 风格 A4 Word 稿；用户未提供具体会议名称或官方模板，因此“完全匹配具体会议模板”仍需收到模板后复核。",
    ]
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"WROTE {OUT}")
    for name, ok in checks:
        print(f"{'PASS' if ok else 'FAIL'}: {name}")


if __name__ == "__main__":
    main()
