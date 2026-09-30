# -*- coding: utf-8 -*-
"""打印某语言翻译文件与 key 的占位符/标签差异明细。用法: py -3.14 -X utf8 tools/mt_detail.py <loc>"""
import json
import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
PH = re.compile(r"%(?![%d])[sd]")
TAG = re.compile(r"\[/?[a-z_]+[^\]]*")
loc = sys.argv[1]

keys = []
for line in (ROOT / "locale" / "keys_unique.txt").read_text(encoding="utf-8").splitlines():
    if line.strip():
        i, rest = line.split(" ", 1)
        keys.append(json.loads(rest))
d = json.loads((ROOT / "locale" / "mt" / f"{loc}.json").read_text(encoding="utf-8"))

for i, k in enumerate(keys):
    v = d.get(k)
    if v is None or not isinstance(v, str):
        print("缺失", i, repr(k))
        continue
    if len(PH.findall(k)) != len(PH.findall(v)):
        print("占位符不匹配", i)
        print(" key:", repr(k))
        print(" val:", repr(v))
    kt = TAG.findall(k)
    if kt and len(kt) != len(TAG.findall(v)):
        print("标签不匹配", i)
        print(" key:", repr(k))
        print(" val:", repr(v))
