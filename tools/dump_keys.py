# -*- coding: utf-8 -*-
"""重建 locale/keys_unique.txt（UTF-8）：格式 `i json.dumps(key)`，可精确解析。"""
import json

import openpyxl
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ws = openpyxl.load_workbook(ROOT / "config" / "config_table.xlsx", read_only=True)["翻译"]
keys = [str(r[0]).strip() for r in ws.iter_rows(min_row=2, values_only=True) if r[0]]
uniq = list(dict.fromkeys(keys))
with open(ROOT / "locale" / "keys_unique.txt", "w", encoding="utf-8") as f:
    for i, k in enumerate(uniq):
        f.write(f"{i} {json.dumps(k, ensure_ascii=False)}\n")
print(len(uniq))

