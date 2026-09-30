# -*- coding: utf-8 -*-
"""修复 it_p2.json 尾部被截断的条目。"""
import json
import re
from pathlib import Path

p = Path(__file__).resolve().parents[1] / "locale" / "mt" / "it_p2.json"
s = p.read_text(encoding="utf-8")
s = re.sub(r',\x22下一关\x22:\x22Livello[^\x22]*\x22', "", s)
s = s.rstrip().rstrip(",") + "}"
json.loads(s)
p.write_text(s, encoding="utf-8")
print("repaired it_p2")
