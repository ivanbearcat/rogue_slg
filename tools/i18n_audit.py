# -*- coding: utf-8 -*-
"""阶段8：i18n 审计 v2 —— 代码/场景中文文案 ⊆「翻译」sheet keys。

基准不再是 POT msgids（gettext 方案已作废），改为 locale/translations.csv 的 keys 列
（由 tools/export_loc.py 从 config_table.xlsx「翻译」sheet 导出）。

扫描范围：
  - scripts/**/*.gd 中的中文字符串字面量（含 "..." 与 \"\"\"...\"\"\" 多行串；
    tr()/T() 参数、字典值、模板等均覆盖）
  - scenes/**/*.tscn 中 text / tooltip_text / popup/item_<n>/text 属性的中文值
排除规则：
  - 注释行（整行 # 开头）
  - print / push_warning / push_error / assert 所在行
  - 含 NO_TRANSLATE 标记的行
作用：防止"代码新加了 tr("新文案") 却忘记登记进表格"。

用法（先跑 export 再跑 audit）：
  py -3.14 -X utf8 tools/export_loc.py
  py -3.14 -X utf8 tools/i18n_audit.py
"""
import csv
import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
CSV = ROOT / "locale" / "translations.csv"

HAN = re.compile(r"[\u4e00-\u9fff\u3400-\u4dbf]")
STRING_LIT = re.compile(r'"((?:\\.|[^"\\])*)"')
GD_EXCLUDE_LINE = re.compile(
    r"(?i)\bprint\b|\bpush_warning\b|\bpush_error\b|\bassert\b|NO_TRANSLATE"
)
COMMENT_LINE = re.compile(r"^\s*#")
TSCN_PROP = re.compile(
    r"(?:popup/item_\d+/)?(?:text|tooltip_text)\s*=\s*\"((?:\\.|[^\"\\])*)\""
)


def unescape(s: str) -> str:
    """还原 GDScript/TSCN 字符串转义"""
    return (s.replace("\\r\\n", "\n").replace("\\n", "\n")
             .replace("\\t", "\t").replace("\\r", "\n")
             .replace("\\\"", "\"").replace("\\\\", "\\"))


def load_keys() -> set[str]:
    with open(CSV, encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        next(reader)  # 表头
        return {row[0].strip() for row in reader if row and row[0].strip()}


def audit_gd(keys: set[str], report: list) -> int:
    """扫描 scripts/**/*.gd，返回中文中文化文案处数，缺口进 report"""
    total = 0
    for fp in sorted((ROOT / "scripts").rglob("*.gd")):
        lines = fp.read_text(encoding="utf-8").splitlines()
        i = 0
        while i < len(lines):
            raw = lines[i]
            ln = i + 1
            if COMMENT_LINE.match(raw) or GD_EXCLUDE_LINE.search(raw):
                i += 1
                continue
            # 三引号多行字符串：起始行可能带排他前缀（如 var X = """...）
            if '"""' in raw:
                segs = raw.split('"""')
                # segs: [前缀, 均为字面量/空, ...]；奇数索引为字面量片段
                payload = [s for k, s in enumerate(segs) if k % 2 == 1]
                closer = sum(s.count('"""') for s in segs)
                # 找结尾三引号所在行（简单状态：成对出现即闭合）
                if len(segs) % 2 == 1 and closer % 2 == 0 and not raw.strip().endswith('"""') or \
                   (len(segs) % 2 == 1 and raw.count('"""') == 1):
                    j = i + 1
                    while j < len(lines):
                        if '"""' in lines[j]:
                            payload.append(lines[j].split('"""')[0])
                            break
                        payload.append(lines[j])
                        j += 1
                    payload = [s for s in payload if HAN.search(unescape(s))]
                    if payload:
                        text = unescape('"""'.join(payload))
                        for seg in text.splitlines():
                            if seg.strip() and HAN.search(seg):
                                total += 1
                                if seg.strip() not in keys:
                                    report.append((f"scripts/{fp.name}", ln, seg.strip()))
                    i = j if j > i and '"""' in lines[j] else j + 1 if j < len(lines) else i + 1
                    continue
                # 单行内闭合的多分段
                for lit in [unescape(s) for k, s in enumerate(segs) if k % 2 == 1]:
                    for seg in lit.splitlines():
                        if seg.strip() and HAN.search(seg):
                            total += 1
                            if seg.strip() not in keys:
                                report.append((f"scripts/{fp.name}", ln, seg.strip()))
                i += 1
                continue
            # 普通单行字符串
            for m in STRING_LIT.finditer(raw):
                lit = unescape(m.group(1))
                if not HAN.search(lit):
                    continue
                total += 1
                if lit not in keys:
                    report.append((f"scripts/{fp.name}", ln, lit))
            i += 1
    return total


def audit_tscn(keys: set[str], report: list) -> int:
    total = 0
    for fp in sorted((ROOT / "scenes").rglob("*.tscn")):
        content = fp.read_text(encoding="utf-8")
        for m in TSCN_PROP.finditer(content):
            lit = unescape(m.group(1)).strip()
            if not lit or not HAN.search(lit):
                continue
            total += 1
            if lit not in keys:
                line_no = content[: m.start()].count("\n") + 1
                report.append((f"scenes/{fp.name}", line_no, lit))
    return total


def main():
    if not CSV.exists():
        print(f"✗ 未找到 {CSV}；请先运行 tools/export_loc.py 导出 CSV")
        sys.exit(1)
    keys = load_keys()
    print(f"基准：{CSV.name} keys {len(keys)} 条")

    report: list = []
    n_gd = audit_gd(keys, report)
    n_tscn = audit_tscn(keys, report)
    total = n_gd + n_tscn

    print(f"扫描覆盖：scripts 中文字面量 {n_gd} 处 + scenes 属性值 {n_tscn} 处 = {total} 处")
    print(f"审计缺口（未登记进表格）：{len(report)} 条")
    for f, ln, lit in report:
        print(f"  ✗ {f}:{ln}  缺 key：{lit!r}")
    if len(report) > 40:
        print(f"  ...共 {len(report)} 条")

    sys.exit(2 if report else 0)


if __name__ == "__main__":
    main()
