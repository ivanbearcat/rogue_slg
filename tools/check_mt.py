# -*- coding: utf-8 -*-
"""校验 locale/mt/<loc>.json：数组对位长度 + 占位符/BBCode 数量与 key 一致。"""
import json
import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
PH = re.compile(r"%(?![%d])[sd]")
TAG = re.compile(r"\[/?[a-z_]+[^\]]*")

keys = []
import json
for line in (ROOT / "locale" / "keys_unique.txt").read_text(encoding="utf-8").splitlines():
    if not line.strip():
        continue
    i, rest = line.split(" ", 1)
    keys.append(json.loads(rest))

bad_all = False
for p in sorted((ROOT / "locale" / "mt").glob("*.json")):
    if p.name == "parsed_keys.json" or "_p" in p.name:
        continue
    try:
        arr = json.loads(p.read_text(encoding="utf-8"))
    except ValueError as e:
        print(f"{p.name}: ✗ JSON损坏 {e}")
        bad_all = True
        continue
    if isinstance(arr, dict):
        arr = [arr.get(k) for k in keys]
    if len(arr) != len(keys):
        print(f"{p.name}: ✗ 长度 {len(arr)} != {len(keys)}")
        bad_all = True
        continue
    bad = 0
    sample = []
    for i, (k, v) in enumerate(zip(keys, arr)):
        if not isinstance(v, str):
            bad += 1
            continue
        if len(PH.findall(k)) != len(PH.findall(v)):
            bad += 1
            sample.append(i)
        kt = TAG.findall(k)
        if kt and len(kt) != len(TAG.findall(v)):
            bad += 1
            sample.append(i)
    status = "✓" if bad == 0 else f"✗ {bad} 条占位符/标签不匹配（如 {sample[:5]}）"
    print(f"{p.name}: {status}")


sys.exit(1 if bad_all else 0)
