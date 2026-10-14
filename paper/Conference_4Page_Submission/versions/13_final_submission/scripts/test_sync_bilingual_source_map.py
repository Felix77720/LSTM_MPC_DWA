"""Mechanical, data-free tests for sync_bilingual_source_map.py."""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from scripts.sync_bilingual_source_map import synchronize


ROOT = Path(__file__).resolve().parents[1]
SYNC_SCRIPT = ROOT / "scripts" / "sync_bilingual_source_map.py"


def fixture_paper() -> str:
    return """<a id="S001"></a>
**Source:** manuscript title

**Original:** New English title  
An author line.

**中文:** 新中文标题。

## Section heading

<a id="E001"></a>
**Source:** Eq. (7)

$$
x_{t+2}=x_t+1
$$

<a id="C001"></a>
**Original caption:** New caption.

**中文图注：** 新图注。

<a id="F001"></a>
### Figure 1 / 图 1：示意图

![图像替代文字](assets/new_figure.png)

<a id="T001"></a>
**Original caption:** New table caption.

**中文表注：** 新表注。

| Name / 名称 | Value / 数值 |
|---|---:|
| New item / 新项目 | 2 |

<a id="R001"></a> New bibliography line.
"""


def fixture_map() -> dict:
    ids = ["S001", "E001", "C001", "F001", "T001", "R001"]
    return {
        "schema_version": "2.0",
        "paper": {"title": "Keep me", "source_path": "../source/main.pdf"},
        "section_order": ["sec:intro"],
        "block_order": ids,
        "blocks": [
            {"id": "S001", "type": "front_matter", "order": 1, "source_location": "title",
             "original_text": "Old title", "translation": "旧标题", "refs": ["keep-ref"]},
            {"id": "E001", "type": "equation", "order": 2, "source_location": "eq",
             "original_text": "Equation label", "translation": "公式说明", "equation_number": "1",
             "latex": "x=0", "bbox": [1, 2, 3, 4]},
            {"id": "C001", "type": "caption", "order": 3, "source_location": "caption",
             "original_text": "Old caption", "translation": "旧图注", "refs": ["unchanged-ref"]},
            {"id": "F001", "type": "figure", "order": 4, "source_location": "figure",
             "original_text": "Keep English alt", "translation": "Keep Chinese alt",
             "image_path": "assets/old.png", "caption_id": "C001", "placed_after": "S001"},
            {"id": "T001", "type": "table", "order": 5, "source_location": "table",
             "original_text": "Old table caption", "translation": "旧表注", "caption_id": None,
             "columns": ["Old name", "Old value"], "rows": [["Old item", "0"]]},
            {"id": "R001", "type": "reference", "order": 6, "source_location": "ref",
             "original_text": "Canonical reference", "translation": "Keep reference", "refs": ["keep"]},
        ],
        "pages": [{"page": 1, "block_ids": ids, "bbox": "preserve-page-layout"}],
        "figures": [{"id": "F001", "caption_id": "C001", "image_path": "assets/old.png",
                     "placement_hint": "preserve-placement", "alt_text": "Keep English alt"}],
        "equations": [{"id": "E001", "equation_number": "1", "source_label": "eq:old",
                       "page": 1, "confidence": "high", "latex": "x=0"}],
        "tables": [{"id": "T001", "source_label": "tab:old", "caption_block": "T001",
                    "headers": ["Old name", "Old value"], "rows": [["Old item", "0"]]}],
        "citation_order": ["R001"],
        "glossary": [{"term": "keep"}],
        "audit_notes": ["keep"],
        "custom_metadata": {"must": "survive"},
    }


class SyncBilingualSourceMapTests(unittest.TestCase):
    def test_updates_supported_content_and_preserves_other_metadata(self) -> None:
        original_map = fixture_map()
        updated, changes = synchronize(fixture_paper(), original_map)
        blocks = {record["id"]: record for record in updated["blocks"]}

        self.assertEqual(blocks["S001"]["original_text"], "New English title\nAn author line.")
        self.assertEqual(blocks["S001"]["translation"], "新中文标题。")
        self.assertEqual(blocks["S001"]["refs"], ["keep-ref"])
        self.assertEqual(blocks["E001"]["equation_number"], "7")
        self.assertEqual(blocks["E001"]["latex"], "x_{t+2}=x_t+1")
        self.assertEqual(updated["equations"][0]["equation_number"], "7")
        self.assertEqual(updated["equations"][0]["source_label"], "eq:old")
        self.assertEqual(blocks["C001"]["original_text"], "New caption.")
        self.assertEqual(blocks["C001"]["translation"], "新图注。")
        self.assertEqual(blocks["F001"]["image_path"], "assets/new_figure.png")
        self.assertEqual(blocks["F001"]["original_text"], "Keep English alt")
        self.assertEqual(updated["figures"][0]["image_path"], "assets/new_figure.png")
        self.assertEqual(updated["figures"][0]["placement_hint"], "preserve-placement")
        self.assertEqual(blocks["T001"]["columns"], ["Name", "Value"])
        self.assertEqual(blocks["T001"]["rows"], [["New item", "2"]])
        self.assertEqual(updated["tables"][0]["headers"], ["Name", "Value"])
        self.assertEqual(updated["tables"][0]["source_label"], "tab:old")
        self.assertEqual(blocks["R001"], original_map["blocks"][-1])
        self.assertEqual(updated["pages"], original_map["pages"])
        self.assertEqual(updated["block_order"], original_map["block_order"])
        self.assertEqual(updated["custom_metadata"], original_map["custom_metadata"])
        self.assertTrue(changes)
        self.assertEqual(original_map["blocks"][0]["original_text"], "Old title")

    def test_anchor_mismatch_fails_closed(self) -> None:
        paper = fixture_paper().replace('<a id="R001"></a>', '<a id="R002"></a>')
        with self.assertRaisesRegex(ValueError, "ID mismatch"):
            synchronize(paper, fixture_map())

    def test_ambiguous_table_fails_without_mutating_input(self) -> None:
        paper = fixture_paper().replace("| New item / 新项目 | 2 |", "| New item | 2 |")
        original_map = fixture_map()
        with self.assertRaisesRegex(ValueError, "English/Chinese separator"):
            synchronize(paper, original_map)
        self.assertEqual(original_map["tables"][0]["rows"], [["Old item", "0"]])

    def test_cli_defaults_to_dry_run_and_write_is_opt_in(self) -> None:
        with tempfile.TemporaryDirectory(dir=ROOT) as directory:
            folder = Path(directory)
            paper_path = folder / "paper.md"
            map_path = folder / "source_map.json"
            paper_path.write_text(fixture_paper(), encoding="utf-8")
            original_json = json.dumps(fixture_map(), ensure_ascii=False, indent=2) + "\n"
            map_path.write_text(original_json, encoding="utf-8")

            dry_run = subprocess.run(
                [sys.executable, str(SYNC_SCRIPT), "--paper", str(paper_path), "--source-map", str(map_path)],
                cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace", check=False,
            )
            self.assertEqual(dry_run.returncode, 0, dry_run.stderr)
            self.assertIn("Dry run", dry_run.stdout)
            self.assertEqual(map_path.read_text(encoding="utf-8"), original_json)

            write = subprocess.run(
                [sys.executable, str(SYNC_SCRIPT), "--paper", str(paper_path), "--source-map", str(map_path), "--write"],
                cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace", check=False,
            )
            self.assertEqual(write.returncode, 0, write.stderr)
            self.assertIn("Wrote", write.stdout)
            written = json.loads(map_path.read_text(encoding="utf-8"))
            self.assertEqual(written["blocks"][0]["original_text"], "New English title\nAn author line.")


if __name__ == "__main__":
    unittest.main()
