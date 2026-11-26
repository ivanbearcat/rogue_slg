extends SceneTree

## elite-gate-tooltip-badge 冒烟自检（无头）：对照 delta spec 六场景 + design D2/D3
## 用法：Godot --headless --path . -s test/smoke_gate_tooltip.gd

var ok := true

func check(cond: bool, label: String) -> void:
	if not cond:
		ok = false
	print(("  [OK] " if cond else "  [NG] ") + label)

func _initialize() -> void:
	await _run()

func _run() -> void:
	var F = load("res://scripts/tooltip_formatter.gd")
	if F == null:
		print("FATAL: tooltip_formatter.gd 加载失败")
		quit(1)
		return

	# 场景1：格式化精英史莱姆（同顺，门槛2，红5点）
	var elite: String = F.format_elite_slime(false, "tongshun", 2, 5, "red")
	print("── 精英(tongshun,2,5,red) ──")
	print(elite)
	check(elite.contains("[color=#cc0808]★ 精英史莱姆[/color]"), "精英红标题")
	check(elite.contains("[color=#FFD700]击杀条件：[/color]"), "金色击杀条件标签")
	check(elite.contains(F._badge("2")), "数量N徽章(2)")
	check(elite.contains(F._badge(F.T("同顺"))), "骰型词徽章(同顺)")
	check(elite.contains("由 %s 个或以上的史莱姆组成 %s 骰型" % [F._badge("2"), F._badge(F.T("同顺"))]), "统一句式结构")
	check(elite.contains("[color=#FFB74D]（%s，需包含自身）[/color]" % F.T("同色且点数连续")), "琥珀色括号定义行")
	check(not elite.contains("2 连") and not elite.contains("2连"), "无『N连』歧义表述")
	check(elite.contains("自身骰子 [img=24]res://images/ui_icon/dice_red_5.tres[/img]"), "dice_red_5 骰面行")

	# 场景2：BOSS（N 取 BOSS 门槛数）
	var boss: String = F.format_elite_slime(true, "tongse", 3, 5, "blue")
	print("── BOSS(tongse,3,5,blue) ──")
	print(boss)
	check(boss.contains("[color=#AB47BC]★ BOSS史莱姆[/color]"), "BOSS紫标题")
	check(boss.contains(F._badge("3")), "BOSS门槛数徽章(3)")
	check(boss.contains("[color=#FFB74D]（%s，需包含自身）[/color]" % F.T("颜色相同")), "BOSS同色定义")
	check(boss.contains("dice_blue_5.tres"), "dice_blue_5 骰面行")

	# 场景3+4：五门槛定义映射（消除N连歧义 + 定义映射）
	var expect_def := {
		"duizi": "点数相同", "shunzi": "点数连续", "tongse": "颜色相同",
		"tongdui": "颜色点数都相同", "tongshun": "同色且点数连续",
	}
	var expect_word := {"duizi": "对子", "shunzi": "顺子", "tongse": "同色", "tongdui": "同对", "tongshun": "同顺"}
	for gate in expect_def:
		var out: String = F.format_elite_slime(false, gate, 3, 5, "green")
		check(out.contains("由 %s 个或以上的史莱姆组成 %s 骰型" % [F._badge("3"), F._badge(F.T(expect_word[gate]))]), "%s 句式N与骰型词" % gate)
		check(out.contains("（%s，需包含自身）" % F.T(expect_def[gate])), "%s 定义=%s" % [gate, expect_def[gate]])
		# "N连"歧义：数字+空格?+连（排除"连续"合法用字）
		var re_nlian := RegEx.create_from_string("\\d+\\s*连(?!续)")
		check(re_nlian.search(out) == null, "%s 无『N连』表述" % gate)

	# 场景5：骰面行随颜色/点数对应
	for combo in [["yellow", 3, "dice_yellow_3"], ["green", 1, "dice_green_1"], ["blue", 6, "dice_blue_6"]]:
		var out: String = F.format_elite_slime(false, "duizi", 3, combo[1], combo[0])
		check(out.contains("[img=24]res://images/ui_icon/%s.tres[/img]" % combo[2]), "骰面行 %s" % combo[2])

	# 假颜色/缺失资源 → 文字兜底不报错
	var fallback: String = F.format_elite_slime(false, "duizi", 3, 5, "fakecolor")
	check(fallback.contains("自身骰子：fakecolor 5 点"), "假颜色降级文字行（原样回显不报错）")
	print(fallback)
	# 真缺失资源（骰子1-6外）→ 文字兜底
	var fallback3: String = F.format_elite_slime(false, "duizi", 3, 9, "red")
	check(fallback3.contains("自身骰子：红 9 点"), "非法点数9降级文字行")
	print(fallback3)

	# 场景6：徽章规格（design D2 定稿：同字号不加粗，仅底色+金色）
	var badge: String = F._badge("2")
	check(badge == "[bgcolor=#4a3800][color=#FFD700] 2 [/color][/bgcolor]", "徽章BBCode符合D2定稿规格")
	check(not badge.contains("font_size") and not badge.contains("[b]"), "徽章无加粗无字号放大")

	# 1.4 兜底：未知门槛类型
	var unknown: String = F.format_elite_slime(false, "fake_gate", 3, 5, "red")
	check(unknown.contains("[color=#FFD700]需要: fake_gate ×3[/color]"), "未知门槛兜底：类型名+×N")
	check(not unknown.contains("击杀条件"), "未知门槛不输出新句式")
	print(unknown)

	print("RESULT: " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
