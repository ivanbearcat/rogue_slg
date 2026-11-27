# -*- coding: utf-8 -*-
"""一次性：把 i18n_audit 扫出的缺口 key 登记进 config_table.xlsx「翻译」sheet。

- key 列 = 中文源文本（= 运行时 tr() 查表 key，含 help_ui 整段 blob 的精确整串）
- zh_CN 列同文（阶段 9 口径：简中查自身）
- 9 个外语列留空，交给机翻闭环（locale/mt/*.json → merge_mt → check_mt → fill_loc）
- 写前自动备份 xlsx（与 fill_loc.py 同约定）

用法：py -3.14 -X utf8 tools/add_gap_keys.py [--dry]
运行前请关闭 Excel/WPS。
"""
import shutil
import sys
from datetime import datetime
from pathlib import Path

from openpyxl import load_workbook

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import i18n_audit  # noqa: E402  复用同一套扫描/重组口径，保证登记与审计零漂移

XLSX = ROOT / "config" / "config_table.xlsx"
DRY = "--dry" in sys.argv

## 按缺口来源写「备注」，给机翻/未来人工的语境说明
NOTE_BY_SOURCE = {
    "scripts/scene_transition.gd": "加载等待提示",
    "scripts/tooltip_formatter.gd": "精英/BOSS tooltip 骰型门槛句式；%s/%d 占位符与 BBCode 标签勿动",
    "scripts/drop_selection_ui.gd": "掉落骰子 tooltip 模板；%s 占位符勿动",
    "scripts/help_ui.gd": "帮助页整段 BBCode tooltip（源码括号拼接整串）；BBCode 标签与换行数不得增减",
    "scripts/splash_menu.gd": "继续按钮存档进度行",
    "scenes/clear_stage_ui.tscn": "结算界面列标题",
    "scenes/main.tscn": "主场景战斗栏/帮助页标注",
    "scenes/soldier_skills.tscn": "自带技能面板提示",
    "scenes/splash.tscn": "开始画面按钮",
    "config/buff.json": "buff 数据展示字段",
    "config/hero_skill.json": "英雄技能数据展示字段",
}


def collect_gap_keys() -> list[tuple[str, str]]:
    """(key, 首个来源) 按审计报告顺序去重"""
    keys = i18n_audit.load_keys()
    report: list = []
    i18n_audit.audit_gd(keys, report)
    i18n_audit.audit_tscn(keys, report)
    i18n_audit.audit_json(keys, report)
    seen: dict = {}
    for src, _ln, text in report:
        seen.setdefault(text, src)
    return list(seen.items())


def main():
    items = collect_gap_keys()
    print(f"audit 缺口去重后待登记 {len(items)} 条")
    if not items:
        print("无缺口，无需登记")
        return

    bak = XLSX.with_name(f"config_table.backup-{datetime.now():%Y%m%d-%H%M%S}.xlsx")
    if not DRY:
        shutil.copy2(XLSX, bak)
        print(f"已备份: {bak.name}")

    wb = load_workbook(XLSX)
    ws = wb["翻译"]
    header = [c.value for c in ws[1]]
    ci_key = header.index("keys") + 1
    ci_zh = header.index("zh_CN") + 1
    ci_note = header.index("备注") + 1 if "备注" in header else None

    last = max(
        (r for r in range(1, ws.max_row + 1)
         if ws.cell(r, ci_key).value not in (None, "")),
        default=1,
    )
    row = last
    for key, src in items:
        row += 1
        ws.cell(row, ci_key, key)
        ws.cell(row, ci_zh, key)
        if ci_note:
            ws.cell(row, ci_note, NOTE_BY_SOURCE.get(src, ""))
    print(f"追加 {len(items)} 行（第 {last + 1}~{row} 行）" + ("（试运行，未写盘）" if DRY else ""))
    if DRY:
        return

    try:
        wb.save(XLSX)
    except PermissionError:
        print("保存失败：config_table.xlsx 正被 Excel/WPS 占用，请关闭后重跑")
        sys.exit(1)

    ## 回读断言：key/zh_CN 逐条一致
    wb2 = load_workbook(XLSX, read_only=True)
    ws2 = wb2["翻译"]
    got: dict = {}
    for r in ws2.iter_rows(min_row=2, values_only=True):
        k = str(r[ci_key - 1] or "").strip()
        if k:
            got[k] = str(r[ci_zh - 1] or "")
    bad = [k for k, _src in items if got.get(k.strip()) != k.strip() and got.get(k) != k]
    missing = [k for k, _src in items if k.strip() not in got]
    if bad or missing:
        print(f"回读校验 ✗ 不一致 {len(bad)} 条 / 未找到 {len(missing)} 条")
        for k in (bad + missing)[:5]:
            print("  ✗", k[:60])
        sys.exit(1)
    print(f"回读校验 ✓ 一致（sheet 现有 {len(got)} 个 key）")


if __name__ == "__main__":
    main()
