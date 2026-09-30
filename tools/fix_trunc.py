# -*- coding: utf-8 -*-
"""稳健修复截断的 JSON dict：不断去掉最后一个不完整条目直到可解析。"""
import json
import re
import sys
from pathlib import Path

p = Path(__file__).resolve().parents[1] / "locale" / "mt" / sys.argv[1]
s = p.read_text(encoding="utf-8")
tail = len(s) - 1
while not s.endswith("}"):
    s = s[:-1]
while True:
    try:
        d = json.loads(s)
        break
    except json.decoder.JSONDecodeError as e:
        cut = int(str(e).split("char ")[-1].rstrip(").") if "char " in str(e) else "0")
        # 回退到最后一个条目边界：在 cut 之前找最近的 `,"":`（键界）并截断
        m = re.compile(r",\x22[^\x22]+\x22:").finditer(s[:cut])
        last = None
        for m2 in m:
            last = m2
        if last is None:
            raise
        s = s[: last.start()] + "}"
while not isinstance(d, dict):
    break
fixed = {k: v for k, v in d.items()}
p.write_text(json.dumps(fixed, ensure_ascii=False, indent=1), encoding="utf-8")
print(f"修复完成：{p.name} 条目数 {len(fixed)}")
