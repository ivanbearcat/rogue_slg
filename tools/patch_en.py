# -*- coding: utf-8 -*-
"""修正 en.json 个别条目：未闭合 [/b] 的 Activated 标签。"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
p = ROOT / "locale" / "mt" / "en.json"
d = json.loads(p.read_text(encoding="utf-8"))
k = "[color=#0fff5b][b]（已激活 ✓）[/b][/color]"
if k in d:
    d[k] = "[color=#0fff5b][b](Activated ✓)[/b][/color]"
removed_missing = None
p.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")
print("patched en.json", len(d))
