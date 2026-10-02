# -*- coding: utf-8 -*-
"""阶段9一次性工具：在 config_table.xlsx「翻译」sheet 的 en 列前插入 zh_CN 列。

值 = keys 列原文（简体中文即源文案）。写前备份；写后回读断言。
用法：py -3.14 -X utf8 tools/add_zhcn_column.py（运行前关闭 Excel）
"""
import shutil
import sys
from datetime import datetime
from pathlib import Path

from openpyxl import load_workbook

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
XLSX = ROOT / "config" / "config_table.xlsx"

wb = load_workbook(XLSX)
ws = wb["翻译"]
rows = list(ws.iter_rows(values_only=True))
header = rows[0]
assert header[0] == "keys", header
assert header[1] == "en", f"zh_CN 应插在 en 前，当前第二列 {header[1]}"

ws.insert_cols(2)
n = 0
for row in ws.iter_rows(min_row=2):
    if row[0].value:
        ws.cell(row=row[0].row, column=2, value=row[0].value)
        n += 1
assert ws.cell(row=1, column=2).value is None
ws.cell(row=1, column=2, value="zh_CN")

bak = XLSX.with_name(f"config_table.backup-{datetime.now():%Y%m%d-%H%M%S}.xlsx")
wb.save(XLSX)
shutil.copy2(XLSX, bak)
print(f"已插入 zh_CN 列 {n} 行并备份 {bak.name}")

wb2 = load_workbook(XLSX, read_only=True)
rows2 = list(wb2["翻译"].iter_rows(values_only=True))
h2 = list(rows2[0])
assert h2[:3] == ["keys", "zh_CN", "en"], h2[:3]
bad = sum(1 for r in rows2[1:] if r[0] and (r[1] is None or str(r[1]) != str(r[0])))
assert bad == 0, f"zh_CN 列与 keys 不一致的行数 {bad}"
print("回读断言 ✓")
