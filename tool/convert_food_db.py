#!/usr/bin/env python3
"""
`음식DB.xlsx` 파일을 Flutter 앱에서 활용할 수 있는 JSON 형태로 변환합니다.

외부 라이브러리에 의존하지 않도록 표준 라이브러리만 사용하며, 첫 번째 시트에서
`COLUMNS`에 명시된 열만 추려 `assets/data/foods.json` 파일로 내보냅니다.

실행 방법:
    python3 tool/convert_food_db.py [--source 음식DB.xlsx] [--output assets/data/foods.json]
"""

from __future__ import annotations

import argparse
import json
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from typing import Iterable, List, Sequence


# Columns we care about for the initial recommendation prototype.
# Update this list if you need more nutrients.
COLUMNS: Sequence[str] = (
    "식품코드",
    "식품명",
    "대표식품명",
    "식품대분류명",
    "식품중분류명",
    "식품소분류명",
    "영양성분함량기준량",
    "에너지(kcal)",
    "단백질(g)",
    "지방(g)",
    "탄수화물(g)",
    "당류(g)",
    "식이섬유(g)",
    "나트륨(mg)",
    "칼륨(mg)",
    "칼슘(mg)",
    "철(mg)",
    "비타민 C(mg)",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="음식DB.xlsx를 foods.json으로 변환합니다.")
    parser.add_argument(
        "--source",
        type=Path,
        default=Path("음식DB.xlsx"),
        help="원본 Excel(음식DB.xlsx) 파일 경로",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("assets/data/foods.json"),
        help="생성할 JSON 파일 경로",
    )
    return parser.parse_args()


def extract_shared_strings(zf: zipfile.ZipFile) -> List[str]:
    try:
        raw = zf.read("xl/sharedStrings.xml")
    except KeyError:
        return []

    root = ET.fromstring(raw)
    ns = {"main": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
    strings: List[str] = []
    for si in root.findall("main:si", ns):
        text = "".join(t.text or "" for t in si.findall(".//main:t", ns))
        strings.append(text)
    return strings


def iter_rows(zf: zipfile.ZipFile, shared_strings: Sequence[str]) -> Iterable[List[str]]:
    sheet_name = "xl/worksheets/sheet1.xml"
    try:
        raw = zf.read(sheet_name)
    except KeyError as exc:
        raise FileNotFoundError(f"워크북에서 {sheet_name} 을(를) 찾을 수 없습니다.") from exc

    root = ET.fromstring(raw)
    ns = {"main": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}

    for row in root.findall("main:sheetData/main:row", ns):
        values: List[str] = []
        for cell in row.findall("main:c", ns):
            cell_type = cell.get("t")
            v = cell.find("main:v", ns)
            if v is None:
                values.append("")
                continue
            if cell_type == "s":  # shared string
                idx = int(v.text or 0)
                values.append(shared_strings[idx] if idx < len(shared_strings) else "")
            else:
                values.append(v.text or "")
        yield values


def convert(source: Path, output: Path) -> None:
    if not source.exists():
        raise FileNotFoundError(f"원본 파일을 찾을 수 없습니다: {source}")

    with zipfile.ZipFile(source) as zf:
        shared_strings = extract_shared_strings(zf)
        rows = list(iter_rows(zf, shared_strings))

    if not rows:
        raise ValueError("워크북에 데이터가 없습니다.")

    header = rows[0]
    missing = [col for col in COLUMNS if col not in header]
    if missing:
        raise ValueError(f"다음 열을 찾을 수 없습니다: {', '.join(missing)}")

    indices = [header.index(col) for col in COLUMNS]
    records = []
    for row in rows[1:]:
        record = {}
        for idx, column in zip(indices, COLUMNS):
            value = row[idx] if idx < len(row) else ""
            record[column] = _coerce(value)
        records.append(record)

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {len(records)} records to {output}")


def _coerce(value: str):
    """Convert numeric-looking strings to floats, leave others as-is."""
    if value is None or value == "":
        return None
    try:
        # Some numeric values are expressed in scientific notation already.
        num = float(value)
        # Preserve integers as int for cleanliness.
        if num.is_integer():
            return int(num)
        return num
    except ValueError:
        return value.strip()


def main() -> int:
    args = parse_args()
    try:
        convert(args.source, args.output)
    except Exception as exc:  # pragma: no cover - command line helper
        print(f"[convert_food_db] 오류: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
