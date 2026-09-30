# -*- coding: utf-8 -*-
"""阶段6：把机翻结果写入 config_table.xlsx「翻译」sheet 的 9 个语列。

输入：locale/mt/<loc>.json —— 与 locale/keys_unique.txt 对位的 JSON 数组（长度=385）
     zh_TW 列不直接来自文件，而是用 OpenCC s2twp 从中文 key 预转换。

匹配规则：按"strip 后的 key"对位（keys_unique 的生成方式：首次出现顺序去重）。
strip 前的换行结构（如前导 \\n）以 key 原形为准：均为空切，回填时不加换行，
因为此处 key 列丝始终保留 strip 后含义（导出 CSV 用原始 key 与译文拼行）。

用法：py -3.14 -X utf8 tools/fill_loc.py [--dry]
运行前请关闭 Excel/WPS。
"""
import json
import shutil
import sys
from datetime import datetime
from pathlib import Path

from openpyxl import load_workbook

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
XLSX = ROOT / "config" / "config_table.xlsx"
MT_DIR = ROOT / "locale" / "mt"
LOCALES = ["en", "ja", "ko", "zh_TW", "fr", "de", "es", "pt_BR", "it"]
DRY = "--dry" in sys.argv


def main():
    import opencc
    wb0 = load_workbook(XLSX, read_only=True)
    ws0 = wb0["翻译"]
    keys = [str(r[0]).strip() for r in ws0.iter_rows(min_row=2, values_only=True) if r[0]]
    uniq = list(dict.fromkeys(keys))
    idx = {k: i for i, k in enumerate(uniq)}
    n = len(uniq)

    trans = {}
    for loc in LOCALES:
        if loc == "zh_TW":
            conv = opencc.OpenCC("s2twp")
            trans[loc] = [conv.convert(k) for k in uniq]
            continue
        p = MT_DIR / f"{loc}.json"
        data = json.loads(p.read_text(encoding="utf-8"))
        if isinstance(data, dict):
            missing = [k for k in uniq if k not in data]
            arr = [data.get(k) for k in uniq]
        else:
            arr = data
        if len(arr) != n:
            print(f"✗ {loc}: 数组长度 {len(arr)} != {n}")
            sys.exit(1)
        trans[loc] = ["" if v is None else str(v) for v in arr]

    bak = XLSX.with_name(f"config_table.backup-{datetime.now():%Y%m%d-%H%M%S}.xlsx")
    if not DRY:
        shutil.copy2(XLSX, bak)
        print(f"已备份: {bak.name}")

    wb = load_workbook(XLSX)
    ws = wb["翻译"]
    header = [c.value for c in ws[1]]
    ci = {loc: header.index(loc) + 1 for loc in LOCALES}

    filled = 0
    for row in ws.iter_rows(min_row=2):
        key_cell = row[0].value
        if key_cell is None or not str(key_cell).strip():
            continue
        i = idx[str(key_cell).strip()]
        for loc, col in ci.items():
            if not DRY:
                ws.cell(row=row[0].row, column=col, value=trans[loc][i])
        filled += 1

    try:
        wb.save(XLSX)
    except PermissionError:
        print("保存失败：config_table.xlsx 正被 Excel/WPS 占用，请关闭后重跑")
        sys.exit(1)
    print(f"已写入 {filled} 行 × {len(LOCALES)} 语列" + ("（试运行，未写盘）" if DRY else ""))

    wb2 = load_workbook(XLSX, read_only=True)
    ws2 = wb2["翻译"]
    ok = True
    for row in ws2.iter_rows(min_row=2, values_only=True):
        key = str(row[0] or "").strip()
        if not key:
            continue
        i = idx[key]
        for j, loc in enumerate(LOCALES, start=1):
            if loc == "zh_TW":
                continue
            got = str(row[j] or "")
            if got != trans[loc][i]:
                ok = False
                print(f"  ✗ [{loc}] {key[:12]}… 不一致")
    if not DRY:
        print("回读校验", "✓ 一致" if ok else "✗ 存在不一致")
        sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
