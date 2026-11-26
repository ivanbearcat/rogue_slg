extends SceneTree

## 阶段8自检：退役 loc_glossary.json 后回归 + 验证模板 key 运行时可查表

const TEMPLATES := [
	"[color=%s]当前烙印：%s[/color]",
	"[color=#888888]当前烙印：无[/color]",
	"[color=#42A5F5]当前叠层：%d层（+%d%%）[/color]",
	"[color=%s]%s系[/color]",
	"[color=%s]▼ 减益[/color]",
	"[color=#FFD700]需要: %s ×%d[/color]",
	"[color=#FFD700]击杀条件：[/color]由 %s 个或以上的史莱姆组成 %s 骰型[color=#FFB74D]（%s，需包含自身）[/color]",
	"点数相同",
	"点数连续",
	"颜色相同",
	"颜色点数都相同",
	"同色且点数连续",
	"自身骰子 [img=24]%s[/img]",
	"自身骰子：%s %d 点",
]

func _initialize() -> void:
	var ok := true
	for p in ["res://scripts/tooltip_formatter.gd", "res://scripts/buff/color_brand_buff.gd",
			"res://scripts/buff/resonance_chain_buff.gd", "res://scripts/autoload/game_settings.gd"]:
		var s = load(p)
		print("load ", p, " → ", s != null)
		ok = ok and s != null
	for loc in ["en", "ja"]:
		TranslationServer.set_locale(loc)
		for t in TEMPLATES:
			var got := TranslationServer.translate(t)
			# 译文与原文相同也算命中（如 ja 的"系"沿用）；
			# 真正的 miss 判据：CSV 中该 (loc, key) 单元格为空
			var hit: bool = _is_registered(loc, t)
			if not hit:
				ok = false
			print("  ", loc, " hit=", hit, " | ", t, " → ", got)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

func _is_registered(loc: String, key: String) -> bool:
	var f := FileAccess.open("res://locale/translations.csv", FileAccess.READ)
	if f == null:
		return false
	var ci := -1
	var first := f.get_csv_line()
	for i in first.size():
		if i > 0 and first[i] == loc:
			ci = i
			break
	if ci < 0:
		return false
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() > ci and row[0] == key:
			return row[ci].strip_edges() != ""
	return false
