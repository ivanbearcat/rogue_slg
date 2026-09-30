# -*- coding: utf-8 -*-
"""把语言词典里带前导 \\n 的键去掉换行后与 strip 后的 key 对齐。用法: tools/fix_strip_key.py ja"""
import json
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
loc = sys.argv[1]
p = ROOT / "locale" / "mt" / f"{loc}.json"
d = json.loads(p.read_text(encoding="utf-8"))
out = {}
changed = 0
for k, v in d.items():
    ks = k.strip()
    if ks != k:
        changed += 1
        if ks not in out:
            out[ks] = v
        out.setdefault(ks, v)
    else:
        out.setdefault(ks, v)
p.write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")
print(f"{loc}: 归一化 strip 键 {changed} 条，总计 {len(out)} 条")
