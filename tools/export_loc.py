# -*- coding: utf-8 -*-
"""阶段5：从 config_table.xlsx「翻译」sheet 导出 Godot 原生 CSV locale/translations.csv。

Godot 项目设置→本地化→翻译 挂载该 CSV，按列自动生成各语言 Translation 资源。
校验规则：
  - 占位符 %s/%d 数量与位置必须一致（且 %d%% 中的 %% 不算占位符）
  - BBCode 标签数量必须一致
  - 缺翻逐条列出（试点阶段允许 >0，但校验错误必须为 0）

用法：py -3.14 -X utf8 tools/export_loc.py
运行前请关闭 Excel/WPS。
"""
import csv
import re
import sys
from pathlib import Path

from openpyxl import load_workbook

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
XLSX = ROOT / "config" / "config_table.xlsx"
OUT = ROOT / "locale" / "translations.csv"
LOCALES = ["zh_CN", "en", "ja", "ko", "zh_TW", "fr", "de", "es", "pt_BR", "it"]

# %s/%d 占位符（%% 转义的百分号不算）
PLACEHOLDER = re.compile(r"%(?![%d])[sd]")
TAG = re.compile(r"\[/?[a-z_]+[^\]]*")


def main():
    wb = load_workbook(XLSX, read_only=True)
    ws = wb["翻译"]
    rows = ws.iter_rows(values_only=True)
    header = next(rows)
    header = list(header)
    assert header[: len(LOCALES) + 1] == ["keys"] + LOCALES, f"表头必须为 keys + locale 代码，实际 {header}"
    assert len(header) == len(LOCALES) + 2, "应含「备注」列（其余列忽略）"

    OUT.parent.mkdir(exist_ok=True)
    errors, missing, n = [], [], 0
    with open(OUT, "w", newline="", encoding="utf-8") as f:
        out = csv.writer(f)
        out.writerow(["keys"] + LOCALES)
        for row in rows:
            key = str(row[0] or "").strip()
            if not key:
                continue
            cells = [str(row[i + 1] or "") for i in range(len(LOCALES))]
            out.writerow([key] + cells)
            n += 1
            for loc, cell in zip(LOCALES, cells):
                if not cell.strip():
                    missing.append((loc, key))
                    continue
                if len(PLACEHOLDER.findall(key)) != len(PLACEHOLDER.findall(cell)):
                    errors.append(("占位符数不一致", loc, key))
                kt = TAG.findall(key)
                if kt and len(kt) != len(TAG.findall(cell)):
                    errors.append(("BBCode标签数不一致", loc, key))

    print(f"导出完成：{OUT}（{n} 行）")
    print(f"缺翻 {len(missing)} 条；校验错误 {len(errors)} 条")
    for e in errors:
        print("  ✗", *e)
    for loc, key in missing[:20]:
        print(f"  - 缺翻[{loc}] {key!r}")
    if len(missing) > 20:
        print(f"  ...共 {len(missing)} 条")

    sys.exit(2 if errors else 0)


if __name__ == "__main__":
    main()
