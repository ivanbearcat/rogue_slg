# -*- coding: utf-8 -*-
"""合并 locale/mt/<loc>_p1.json/_p2.json... 为 <loc>.json 并校验。"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MT = ROOT / "locale" / "mt"

for loc in sys.argv[1:]:
    parts = sorted(MT.glob(f"{loc}_p*.json"))
    if not parts:
        print(f"{loc}: 无分段文件")
        continue
    d = {}
    for p in parts:
        d.update(json.loads(p.read_text(encoding="utf-8")))
    out = MT / f"{loc}.json"
    out.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"{loc}: 合并 {len(parts)} 段 → {out.name}，共 {len(d)} 条")
