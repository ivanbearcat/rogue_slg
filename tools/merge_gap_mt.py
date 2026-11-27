# -*- coding: utf-8 -*-
"""把 locale/mt/gap/<loc>.json（缺口 key 机翻）并入 locale/mt/<loc>.json。

背景：mt/<loc>_p*.json 分片是阶段 6 历史产物，后期 patch_*/fix_* 直接改过成品
<loc>.json，分片与成品已不一致——为防 merge_mt.py 回退修复，缺口译文走
gap/ 子目录独立并入（成品文件为唯一权威），并入前逐条校验占位符/BBCode/
换行数与 key 一致（与 export_loc/check_mt 同口径），写前备份成品文件。

用法：py -3.14 -X utf8 tools/merge_gap_mt.py
"""
import json
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
MT = ROOT / "locale" / "mt"
GAP = MT / "gap"
KEYS_FILE = ROOT / "locale" / "gap_keys.txt"

PH = re.compile(r"%(?![%d])[sd]")
TAG = re.compile(r"\[/?[a-z_]+[^\]]*")


def main():
    keys = [json.loads(line) for line in KEYS_FILE.read_text(encoding="utf-8").splitlines() if line.strip()]
    bad_all = False
    for gap_file in sorted(GAP.glob("*.json")):
        loc = gap_file.stem
        target = MT / f"{loc}.json"
        if not target.exists():
            print(f"✗ {loc}: 成品 {target.name} 不存在，请先确认基线")
            bad_all = True
            continue
        gap = json.loads(gap_file.read_text(encoding="utf-8"))
        if set(gap) != set(keys):
            print(f"✗ {loc}: gap key 集合与 _gap_keys.txt 不一致（{len(gap)} vs {len(keys)}）")
            bad_all = True
            continue
        ## 逐条校验：占位符/BBCode/换行数与 key 一致
        bad = 0
        for k, v in gap.items():
            if len(PH.findall(k)) != len(PH.findall(v)):
                print(f"  ✗ [{loc}] 占位符不一致: {k[:40]!r}")
                bad += 1
            kt = TAG.findall(k)
            if kt and len(kt) != len(TAG.findall(v)):
                print(f"  ✗ [{loc}] BBCode 标签数不一致: {k[:40]!r}")
                bad += 1
            if k.count("\n") != v.count("\n"):
                print(f"  ✗ [{loc}] 换行数不一致: {k[:40]!r}")
                bad += 1
        if bad:
            print(f"✗ {loc}: {bad} 条不匹配，未并入")
            bad_all = True
            continue
        ## 备份 + 并入（gap 覆盖同名 key 不应发生——集合已断言一致）
        full = json.loads(target.read_text(encoding="utf-8"))
        if isinstance(full, list):
            ## 数组形态（与 keys_unique.txt 对位）→ 先转字典（fill_loc 两种形态均支持，字典为规范形）
            ukeys = []
            for line in (ROOT / "locale" / "keys_unique.txt").read_text(encoding="utf-8").splitlines():
                if line.strip():
                    _i, rest = line.split(" ", 1)
                    ukeys.append(json.loads(rest))
            if len(full) != len(ukeys):
                print(f"✗ {loc}: 数组长度 {len(full)} != keys_unique {len(ukeys)}")
                bad_all = True
                continue
            full = dict(zip(ukeys, full))
        overlap = set(full) & set(gap)
        if overlap:
            print(f"✗ {loc}: 与成品重叠 {len(overlap)} 条（如 {next(iter(overlap))[:30]!r}），请人工核对")
            bad_all = True
            continue
        bak = target.with_name(f"{loc}.backup-{datetime.now():%Y%m%d-%H%M%S}.json")
        shutil.copy2(target, bak)
        full.update(gap)
        target.write_text(json.dumps(full, ensure_ascii=False, indent=1), encoding="utf-8")
        print(f"{loc}: 并入 {len(gap)} 条 → {target.name} 共 {len(full)} 条（备份 {bak.name}）")
    sys.exit(1 if bad_all else 0)


if __name__ == "__main__":
    main()
