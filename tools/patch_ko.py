# -*- coding: utf-8 -*-
"""修复 ko.json 缺失键：站岗赏金。"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
p = ROOT / "locale" / "mt" / "ko.json"
d = json.loads(p.read_text(encoding="utf-8"))
candidates = [k for k in d if "赏" in k and ("站岗" in k or "岗" in k)]
for c in candidates:
    d["站岗赏金"] = d.pop(c)
p.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")
print("repaired", candidates)
