extends SceneTree

## 阶段8自检：退役 loc_glossary.json 后回归 + 验证模板 key 运行时可查表

const TEMPLATES := [
	"[color=%s]当前烙印：%s[/color]",
	"[color=#888888]当前烙印：无[/color]",
	"[color=#42A5F5]当前叠层：%d层（+%d%%）[/color]",
	"[color=%s]%s系[/color]",
	"[color=%s]▼ 减益[/color]",
	"[color=#FFD700]需要: %s ×%d[/color]",
	"[color=#FFD700]击杀条件：[/color]单次攻击中打出 [color=#FFD700][b]%d 个 %d 点[/b][/color]骰子",
	"[color=#FFD700]击杀条件：[/color]单次攻击中打出含 [color=#FFD700][b]%d 点[/b][/color]的 [color=#FFD700][b]%d 连[/b][/color]顺子",
	"[color=#FFD700]击杀条件：[/color]单次攻击中打出 [color=#FFD700][b]%d 个[/b][/color]与它同色的骰子",
	"[color=#FFD700]击杀条件：[/color]单次攻击中打出 [color=#FFD700][b]%d 个[/b][/color]与它同色同点的骰子",
	"[color=#FFD700]击杀条件：[/color]单次攻击中打出含 [color=#FFD700][b]%d 点[/b][/color]的 [color=#FFD700][b]%d 连[/b][/color]同色顺子",
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
