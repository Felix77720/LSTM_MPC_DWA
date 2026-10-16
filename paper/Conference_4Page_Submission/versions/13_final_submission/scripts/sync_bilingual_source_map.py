"""Synchronize maintained bilingual anchors into an existing source_map.json.

The map is treated as the authority for structure and metadata. This updater
only changes content fields represented by existing paper.md anchors. It never
rebuilds the map from the TeX source. By default it is a dry run; pass --write
to replace the map after all strict schema and anchor checks succeed.
"""
from __future__ import annotations

import argparse
import copy
import json
import os
import re
import tempfile
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PAPER = ROOT / "03_bilingual" / "paper.md"
DEFAULT_MAP = ROOT / "03_bilingual" / "source_map.json"

ANCHOR_RE = re.compile(r'<a id="([A-Z]\d{3})"></a>')
DISPLAY_MATH_RE = re.compile(r"\$\$\s*\n(.*?)^\$\$\s*$", re.M | re.S)
REQUIRED_TOP_LEVEL = {
    "schema_version", "paper", "section_order", "block_order", "blocks",
    "pages", "figures", "equations", "tables", "citation_order",
    "glossary", "audit_notes",
}
TEXT_TYPES = {"front_matter", "abstract", "keywords", "paragraph"}


def anchored_segments(text: str) -> tuple[list[str], dict[str, str]]:
    """Return all unique anchor IDs and the markdown following each anchor."""
    anchors = list(ANCHOR_RE.finditer(text))
    ids: list[str] = []
    segments: dict[str, str] = {}
    for index, anchor in enumerate(anchors):
        block_id = anchor.group(1)
        if block_id in segments:
            raise ValueError(f"Duplicate bilingual anchor: {block_id}.")
        end = anchors[index + 1].start() if index + 1 < len(anchors) else len(text)
        ids.append(block_id)
        segments[block_id] = text[anchor.end():end]
    if not anchors:
        raise ValueError("No bilingual anchor blocks were found in paper.md.")
    return ids, segments


def _unique_records(value: Any, label: str) -> dict[str, dict[str, Any]]:
    if not isinstance(value, list):
        raise ValueError(f"source_map.{label} must be an array.")
    records: dict[str, dict[str, Any]] = {}
    for index, record in enumerate(value):
        if not isinstance(record, dict) or not isinstance(record.get("id"), str):
            raise ValueError(f"source_map.{label}[{index}] must be an object with a string id.")
        record_id = record["id"]
        if record_id in records:
            raise ValueError(f"Duplicate id {record_id} in source_map.{label}.")
        records[record_id] = record
    return records


def _require_fields(record: dict[str, Any], fields: set[str], label: str) -> None:
    missing = sorted(fields - record.keys())
    if missing:
        raise ValueError(f"{label} is missing required field(s): {', '.join(missing)}.")


def _same_ids(expected: set[str], records: dict[str, dict[str, Any]], label: str) -> None:
    actual = set(records)
    if actual != expected:
        missing = sorted(expected - actual)
        extra = sorted(actual - expected)
        details = []
        if missing:
            details.append("missing " + ", ".join(missing))
        if extra:
            details.append("unanchored " + ", ".join(extra))
        raise ValueError(f"{label} ID mismatch: {'; '.join(details)}.")


def _normalise_content(value: str, *, preserve_hard_breaks: bool = False) -> str:
    """Remove reader-only layout while preserving math and title line breaks."""
    value = value.replace("\r\n", "\n").replace("\r", "\n").strip()
    value = DISPLAY_MATH_RE.sub(lambda match: "$" + match.group(1).strip() + "$", value)
    if preserve_hard_breaks:
        value = re.sub(r"[ \t]*\n[ \t]*", "\n", value)
        value = re.sub(r"\n{2,}", "\n", value)
        value = re.sub(r"[ \t]+", " ", value)
        return value.strip()
    return re.sub(r"\s+", " ", value).strip()


def _extract_pair(
    segment: str,
    original_label: str,
    chinese_label: str,
    block_id: str,
) -> tuple[str, str]:
    original_marker = re.compile(
        rf"(?m)^\*\*{re.escape(original_label)}:\*\*[ \t]*"
    )
    chinese_marker = re.compile(
        rf"(?m)^\*\*{re.escape(chinese_label)}[：:]\*\*[ \t]*"
    )
    originals = list(original_marker.finditer(segment))
    chineses = list(chinese_marker.finditer(segment))
    if len(originals) != 1 or len(chineses) != 1:
        raise ValueError(
            f"{block_id} must contain exactly one '**{original_label}:**' and "
            f"one '**{chinese_label}:**' field."
        )
    original_match, chinese_match = originals[0], chineses[0]
    if original_match.start() >= chinese_match.start():
        raise ValueError(f"{block_id} has bilingual fields in the wrong order.")
    original = _normalise_content(
        segment[original_match.end():chinese_match.start()],
        preserve_hard_breaks=(block_id == "S001"),
    )
    # Anchored segments can also contain the next section heading, linked
    # image, or markdown table before the next anchor. A blank line ends the
    # bilingual paragraph/caption, so do not absorb that following layout.
    chinese_tail = re.split(r"\n[ \t]*\n", segment[chinese_match.end():], maxsplit=1)[0]
    chinese = _normalise_content(chinese_tail)
    if not original or not chinese:
        raise ValueError(f"{block_id} has an empty English or Chinese field.")
    return original, chinese


def _extract_equation(segment: str, block_id: str) -> tuple[str, str]:
    formulas = list(DISPLAY_MATH_RE.finditer(segment))
    if len(formulas) != 1 or segment.count("$$") != 2:
        raise ValueError(f"{block_id} must contain exactly one delimited display equation.")
    source = re.search(r"Eq\.\s*\((\d+)\)", segment)
    if not source:
        raise ValueError(f"{block_id} is missing its source equation number.")
    latex = formulas[0].group(1).strip()
    if not latex:
        raise ValueError(f"{block_id} has an empty display equation.")
    return source.group(1), latex


def _extract_figure_path(segment: str, block_id: str) -> str:
    number = int(block_id[1:])
    main_heading = re.search(
        r"(?m)^###\s+Figure\s+(\d+)\s*/\s*图\s*(\d+)[：:].+$", segment
    )
    supplementary_heading = re.search(
        r"(?m)^###\s+Supplementary Figure S(\d+)\s*/\s*补图\s*S(\d+)[：:].+$",
        segment,
    )
    images = list(re.finditer(r"!\[[^\]]*\]\(([^)]+)\)", segment))
    main_match = bool(
        main_heading
        and (int(main_heading.group(1)), int(main_heading.group(2))) == (number, number)
    )
    supplementary_match = bool(
        supplementary_heading
        and (int(supplementary_heading.group(1)), int(supplementary_heading.group(2)))
        == (number, number)
    )
    if not (main_match or supplementary_match):
        raise ValueError(f"{block_id} is missing its matching bilingual figure heading.")
    if len(images) != 1:
        raise ValueError(f"{block_id} must contain exactly one linked image.")
    path = images[0].group(1).strip()
    if not path:
        raise ValueError(f"{block_id} has an empty image path.")
    return path


def _split_bilingual_cell(cell: str, label: str) -> tuple[str, str]:
    parts = cell.split(" / ")
    if len(parts) != 2 or not all(part.strip() for part in parts):
        raise ValueError(f"{label} must contain exactly one ' / ' English/Chinese separator.")
    return parts[0].strip(), parts[1].strip()


def _markdown_table(segment: str, block_id: str) -> tuple[list[str], list[list[str]]]:
    lines = [line.strip() for line in segment.splitlines() if line.strip().startswith("|")]
    if len(lines) < 3:
        raise ValueError(f"{block_id} must contain a header, separator, and at least one data row.")

    def cells(line: str, label: str) -> list[str]:
        if not line.endswith("|"):
            raise ValueError(f"{label} has an unmatched table border.")
        values = [part.strip() for part in line[1:-1].split("|")]
        if not values or any(not value for value in values):
            raise ValueError(f"{label} contains an empty or unparseable table cell.")
        return values

    raw_headers = cells(lines[0], f"{block_id} header")
    separators = cells(lines[1], f"{block_id} separator")
    if len(separators) != len(raw_headers) or any(
        not re.fullmatch(r":?-{3,}:?", item) for item in separators
    ):
        raise ValueError(f"{block_id} has an invalid markdown table separator row.")
    headers = [
        _split_bilingual_cell(cell, f"{block_id} header {index + 1}")[0]
        for index, cell in enumerate(raw_headers)
    ]

    rows: list[list[str]] = []
    for row_index, line in enumerate(lines[2:], start=1):
        raw_row = cells(line, f"{block_id} row {row_index}")
        if len(raw_row) != len(headers):
            raise ValueError(
                f"{block_id} row {row_index} has {len(raw_row)} cells; expected {len(headers)}."
            )
        english_first, _ = _split_bilingual_cell(raw_row[0], f"{block_id} row {row_index}, first cell")
        remaining: list[str] = []
        for column_index, cell in enumerate(raw_row[1:], start=2):
            if " / " in cell:
                raise ValueError(
                    f"{block_id} row {row_index}, cell {column_index} has an unsupported bilingual delimiter."
                )
            remaining.append(cell)
        rows.append([english_first, *remaining])
    if not rows:
        raise ValueError(f"{block_id} has no data rows.")
    return headers, rows


def _set_field(
    record: dict[str, Any],
    field: str,
    value: Any,
    path: str,
    changes: list[tuple[str, Any, Any]],
) -> None:
    if field not in record:
        raise ValueError(f"Cannot update {path}: the existing field is missing.")
    if record[field] != value:
        changes.append((path, copy.deepcopy(record[field]), copy.deepcopy(value)))
        record[field] = value


def synchronize(paper_text: str, source_map: dict[str, Any]) -> tuple[dict[str, Any], list[tuple[str, Any, Any]]]:
    """Validate all anchors and return an updated copy plus field-level changes."""
    if not isinstance(source_map, dict):
        raise ValueError("source_map.json must contain a JSON object.")
    missing_top = sorted(REQUIRED_TOP_LEVEL - source_map.keys())
    if missing_top:
        raise ValueError("source_map.json is missing required top-level field(s): " + ", ".join(missing_top))

    anchor_order, segments = anchored_segments(paper_text)
    blocks = _unique_records(source_map["blocks"], "blocks")
    block_order = source_map["block_order"]
    if not isinstance(block_order, list) or not all(isinstance(item, str) for item in block_order):
        raise ValueError("source_map.block_order must be an array of string IDs.")
    _same_ids(set(anchor_order), blocks, "blocks versus paper anchors")
    if anchor_order != block_order:
        raise ValueError("paper anchor order does not exactly match source_map.block_order.")
    if [record["id"] for record in source_map["blocks"]] != block_order:
        raise ValueError("source_map.blocks order does not exactly match source_map.block_order.")

    expected_by_prefix = {
        "E": "equation", "F": "figure", "C": "caption", "T": "table", "R": "reference"
    }
    for block_id, record in blocks.items():
        if block_id.startswith("S"):
            if record.get("type") not in TEXT_TYPES:
                raise ValueError(f"{block_id} must map to an existing text block type.")
        elif record.get("type") != expected_by_prefix.get(block_id[0]):
            raise ValueError(f"{block_id} has incompatible existing map type {record.get('type')!r}.")
        _require_fields(record, {"original_text", "translation"}, f"blocks[{block_id}]")

    equation_records = _unique_records(source_map["equations"], "equations")
    figure_records = _unique_records(source_map["figures"], "figures")
    table_records = _unique_records(source_map["tables"], "tables")
    _same_ids({block_id for block_id in blocks if block_id.startswith("E")}, equation_records, "equations")
    _same_ids({block_id for block_id in blocks if block_id.startswith("F")}, figure_records, "figures")
    _same_ids({block_id for block_id in blocks if block_id.startswith("T")}, table_records, "tables")

    updated = copy.deepcopy(source_map)
    updated_blocks = {record["id"]: record for record in updated["blocks"]}
    updated_equations = {record["id"]: record for record in updated["equations"]}
    updated_figures = {record["id"]: record for record in updated["figures"]}
    updated_tables = {record["id"]: record for record in updated["tables"]}
    changes: list[tuple[str, Any, Any]] = []

    for block_id in anchor_order:
        record = updated_blocks[block_id]
        segment = segments[block_id]
        if block_id.startswith("S"):
            original, translation = _extract_pair(segment, "Original", "中文", block_id)
            _set_field(record, "original_text", original, f"blocks.{block_id}.original_text", changes)
            _set_field(record, "translation", translation, f"blocks.{block_id}.translation", changes)
        elif block_id.startswith("C"):
            original, translation = _extract_pair(segment, "Original caption", "中文图注", block_id)
            _set_field(record, "original_text", original, f"blocks.{block_id}.original_text", changes)
            _set_field(record, "translation", translation, f"blocks.{block_id}.translation", changes)
        elif block_id.startswith("E"):
            _require_fields(record, {"equation_number", "latex"}, f"blocks[{block_id}]")
            equation_record = updated_equations[block_id]
            _require_fields(equation_record, {"equation_number", "latex"}, f"equations[{block_id}]")
            number, latex = _extract_equation(segment, block_id)
            _set_field(record, "equation_number", number, f"blocks.{block_id}.equation_number", changes)
            _set_field(record, "latex", latex, f"blocks.{block_id}.latex", changes)
            _set_field(equation_record, "equation_number", number, f"equations.{block_id}.equation_number", changes)
            _set_field(equation_record, "latex", latex, f"equations.{block_id}.latex", changes)
        elif block_id.startswith("F"):
            _require_fields(record, {"image_path", "caption_id"}, f"blocks[{block_id}]")
            figure_record = updated_figures[block_id]
            _require_fields(figure_record, {"image_path", "caption_id"}, f"figures[{block_id}]")
            if record["caption_id"] != figure_record["caption_id"]:
                raise ValueError(f"{block_id} caption_id differs between blocks and figures.")
            path = _extract_figure_path(segment, block_id)
            _set_field(record, "image_path", path, f"blocks.{block_id}.image_path", changes)
            _set_field(figure_record, "image_path", path, f"figures.{block_id}.image_path", changes)
        elif block_id.startswith("T"):
            _require_fields(record, {"columns", "rows"}, f"blocks[{block_id}]")
            table_record = updated_tables[block_id]
            _require_fields(table_record, {"headers", "rows"}, f"tables[{block_id}]")
            original, translation = _extract_pair(segment, "Original caption", "中文表注", block_id)
            headers, rows = _markdown_table(segment, block_id)
            _set_field(record, "original_text", original, f"blocks.{block_id}.original_text", changes)
            _set_field(record, "translation", translation, f"blocks.{block_id}.translation", changes)
            _set_field(record, "columns", headers, f"blocks.{block_id}.columns", changes)
            _set_field(record, "rows", rows, f"blocks.{block_id}.rows", changes)
            _set_field(table_record, "headers", headers, f"tables.{block_id}.headers", changes)
            _set_field(table_record, "rows", rows, f"tables.{block_id}.rows", changes)
        elif block_id.startswith("R"):
            # References are intentionally preserved: the reader map retains
            # canonical bibliography metadata that is not represented as a
            # bilingual pair in paper.md.
            if not segment.strip():
                raise ValueError(f"{block_id} has an empty reference anchor.")

    return updated, changes


def _atomic_write_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=False, exist_ok=True)
    rendered = json.dumps(value, ensure_ascii=False, indent=2) + "\n"
    temp_name: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", newline="\n", dir=path.parent,
            prefix=path.name + ".", suffix=".tmp", delete=False,
        ) as temporary:
            temp_name = temporary.name
            temporary.write(rendered)
        os.replace(temp_name, path)
    finally:
        if temp_name and os.path.exists(temp_name):
            os.unlink(temp_name)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--paper", type=Path, default=DEFAULT_PAPER, help="maintained bilingual paper.md")
    parser.add_argument("--source-map", type=Path, default=DEFAULT_MAP, help="existing source_map.json to update")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="validate and report changes without writing (default)")
    mode.add_argument("--write", action="store_true", help="write the validated, minimally updated source map")
    args = parser.parse_args()

    try:
        paper_text = args.paper.read_text(encoding="utf-8-sig")
        existing_map = json.loads(args.source_map.read_text(encoding="utf-8-sig"))
        updated_map, changes = synchronize(paper_text, existing_map)
        anchor_ids, _ = anchored_segments(paper_text)
        if args.write:
            _atomic_write_json(args.source_map, updated_map)
            action = "Wrote"
        else:
            action = "Dry run; would update"
        print(f"{action} {args.source_map.name}: validated {len(anchor_ids)} anchors; {len(changes)} field change(s).")
        for path, _old, _new in changes:
            print(f"  {path}")
        if not changes:
            print("  No content differences found.")
        return 0
    except (OSError, json.JSONDecodeError, ValueError) as error:
        parser.exit(2, f"ERROR: {error}\n")


if __name__ == "__main__":
    raise SystemExit(main())
