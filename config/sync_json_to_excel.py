# -*- coding: utf-8 -*-
"""反向同步：以 config/*.json 为准，重写 config_table.xlsx 对应 sheet 的数据区。

- 表头(第2行)保留原样；JSON 中多出的字段会自动追加为新列（写在第2行表头尾部）
- 数据区(第3行起)整体按 JSON 重写，多余旧行清空
- JSON 里的 list/dict（如 card_effects）以 JSON 文本形式写入单元格
- 正式运行前自动备份 config_table.xlsx → config_table.backup-时间戳.xlsx
- 保存后回读校验，与 JSON 逐值比对
- boss_debuff.json 不存在 → boss_debuff sheet 原样保留，不参与本次同步

用法：
  python config/sync_json_to_excel.py --dry   # 试运行，只报告将发生的变更，不写盘
  python config/sync_json_to_excel.py         # 正式同步
注意：
  1) 运行前请关闭 Excel，否则保存会报文件占用
  2) openpyxl 重存会丢失工作簿里的图表/图片（如有请从备份恢复）
  3) 同步后 cell 里的 card_effects 等是 JSON 文本，直接再跑 excel_to_json.py
     会把它们导出成字符串而非数组——需先给 excel_to_json.py 加解析逻辑
"""
import json
import os
import sys
import shutil
from datetime import datetime

from openpyxl import load_workbook

# Windows 控制台默认 GBK，强制 UTF-8 输出避免 ✓/中文报 UnicodeEncodeError
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

HERE = os.path.dirname(os.path.abspath(__file__))
XLSX = os.path.join(HERE, "config_table.xlsx")
SHEETS = ["card_level_up", "stage_info", "coin_skill", "buff", "debuff", "boss_debuff", "dice_multiplier"]
DRY = "--dry" in sys.argv


def norm(v):
    """归一化用于比较：空->None，数字文本->float，JSON文本->排序后重序列化"""
    if v is None:
        return None
    if isinstance(v, str):
        s = v.strip()
        if s == "":
            return None
        if s[0] in "[{":
            try:
                return json.dumps(json.loads(s), ensure_ascii=False, sort_keys=True)
            except ValueError:
                return s
        try:
            return float(s)
        except ValueError:
            return s
    if isinstance(v, bool):
        return v
    if isinstance(v, (int, float)):
        return float(v)
    if isinstance(v, (list, dict)):
        return json.dumps(v, ensure_ascii=False, sort_keys=True)
    return v


def cell_out(v):
    """写单元格：list/dict 序列化为 JSON 文本"""
    if isinstance(v, (list, dict)):
        return json.dumps(v, ensure_ascii=False)
    return v


def sheet_rows(ws):
    headers = [c.value for c in ws[2]]
    rows = []
    for r in ws.iter_rows(min_row=3, values_only=True):
        d = {h: v for h, v in zip(headers, r) if h is not None}   # 跳过 None 表头填充列
        rows.append(d)
    return headers, rows


def count_mismatch(old_rows, data):
    """旧数据 vs JSON 的不一致行数，返回 (不一致行数, 首个样例描述)。
    比较语义：excel 空单元格 ≡ json 缺字段（两侧剔除 None 后再比）"""
    old = [r for r in old_rows if any(norm(v) is not None for v in r.values())]
    if len(old) != len(data):
        return abs(len(old) - len(data)), f"行数 excel={len(old)} json={len(data)}"
    bad, sample = 0, None
    for i, (a, b) in enumerate(zip(old, data)):
        ka = {k: norm(v) for k, v in a.items() if norm(v) is not None}
        kb = {k: norm(v) for k, v in b.items() if norm(v) is not None}
        if ka != kb:
            bad += 1
            if sample is None:
                diff = [k for k in set(ka) | set(kb) if ka.get(k) != kb.get(k)]
                sample = f"Excel第{i+3}行 字段{diff}"
    return bad, sample


print(f"模式: {'试运行(--dry)' if DRY else '正式同步'}")
if not DRY:
    bak = XLSX.replace(".xlsx", f".backup-{datetime.now():%Y%m%d-%H%M%S}.xlsx")
    shutil.copy2(XLSX, bak)
    print(f"已备份: {bak}")

wb = load_workbook(XLSX)
report = []

for name in SHEETS:
    jp = os.path.join(HERE, name + ".json")
    if name not in wb.sheetnames:
        report.append(f"[{name}] ✗ 工作簿无此 sheet，跳过")
        continue
    if not os.path.exists(jp):
        report.append(f"[{name}] ⚠ 无对应 JSON（boss_debuff）→ sheet 原样保留，不参与本次同步")
        continue
    data = json.load(open(jp, encoding="utf-8"))
    ws = wb[name]
    headers, old_rows = sheet_rows(ws)
    bad, sample = count_mismatch(old_rows, data)

    # 收集 JSON 全部键（保持首次出现顺序），表头列完全按 JSON 重建（JSON 为唯一权威）
    json_keys = []
    for e in data:
        for k in e:
            if k not in json_keys:
                json_keys.append(k)
    old_headers = [h for h in headers if h is not None]
    discarded = [h for h in old_headers if h not in json_keys]
    headers = list(json_keys)

    old_max_row = ws.max_row
    old_ncols = ws.max_column
    if not DRY:
        # 重写表头（第2行），多余旧列表头清空
        for ci, h in enumerate(headers, start=1):
            ws.cell(row=2, column=ci).value = h
        for ci in range(len(headers) + 1, old_ncols + 1):
            ws.cell(row=2, column=ci).value = None
        # 清空旧数据区（含被丢弃列）
        for r in range(3, old_max_row + 1):
            for c in range(1, old_ncols + 1):
                ws.cell(row=r, column=c).value = None
        # 写入 JSON 数据
        for i, e in enumerate(data):
            for ci, h in enumerate(headers, start=1):
                ws.cell(row=3 + i, column=ci).value = cell_out(e.get(h))

    cleared = max(0, old_max_row - (2 + len(data)))
    status = "原本一致" if bad == 0 else f"原有 {bad} 行不一致（{sample}）"
    line = f"[{name}] ✓ 按 JSON 重写 {len(data)} 行×{len(headers)} 列；{status}"
    if discarded:
        line += f"；丢弃 Excel 旧列 {discarded}"
    if cleared:
        line += f"；清空尾部旧数据 {cleared} 行"
    report.append(line)

if DRY:
    print("（试运行结束，未写盘。去掉 --dry 正式执行）")
else:
    try:
        wb.save(XLSX)
    except PermissionError:
        print("保存失败：config_table.xlsx 正被 Excel 占用，请关闭 Excel 后重跑（备份未动，数据未写）")
        sys.exit(1)

for line in report:
    print(line)

if DRY:
    sys.exit(0)

# ---- 回读校验 ----
print("\n---- 回读校验 ----")
wb2 = load_workbook(XLSX)
all_ok = True
for name in SHEETS:
    jp = os.path.join(HERE, name + ".json")
    if name not in wb2.sheetnames or not os.path.exists(jp):
        continue
    data = json.load(open(jp, encoding="utf-8"))
    _, rows = sheet_rows(wb2[name])
    rows = [r for r in rows if any(norm(v) is not None for v in r.values())]
    if len(rows) != len(data):
        print(f"[{name}] ✗ 行数不符 excel={len(rows)} json={len(data)}")
        all_ok = False
        continue
    bad = 0
    for i, (a, b) in enumerate(zip(rows, data)):
        ka = {k: norm(v) for k, v in a.items() if norm(v) is not None}
        kb = {k: norm(v) for k, v in b.items() if norm(v) is not None}
        if ka != kb:
            bad += 1
            if bad <= 3:
                diff = [k for k in set(ka) | set(kb) if ka.get(k) != kb.get(k)]
                print(f"[{name}] ✗ 第{i+3}行差异 {diff}: excel={[ka.get(k) for k in diff]} json={[kb.get(k) for k in diff]}")
    if bad:
        all_ok = False
        print(f"[{name}] ✗ {bad} 行不一致")
    else:
        print(f"[{name}] ✓ 与 JSON 完全一致（{len(data)} 行）")

print("\n结论:", "✓ 反向同步成功，Excel 已与所有 JSON 一致" if all_ok else "✗ 存在不一致，见上方 ✗ 详情")
sys.exit(0 if all_ok else 1)
