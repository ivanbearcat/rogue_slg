extends Node

## headless 集成验证：help_ui 富文本 tooltip
## 覆盖：18 项文案、目标映射、TooltipManager 注册、关闭回收、语言切换重绑、边缘定位与长文案尺寸

const HELP_UI_SCRIPT_PATH := "res://scripts/ui/help_ui.gd"

const EXPECTED_KEYS := [
	"dice_type",
	"dice_type_desc",
	"dice_score",
	"dice_pocket",
	"score_preview",
	"buff_bar",
	"debuff_bar",
	"skill_grid",
	"potion_progress",
	"exp_bar",
	"shield",
	"power",
	"hero_skill",
	"power_button",
	"end_trun",
	"reset_move",
	"use_potion",
	"close_help",
]

var failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await _run()
	if failures.is_empty():
		print("HELP_UI_TOOLTIP_TEST_ALL_PASS")
	else:
		for f in failures:
			print("HELP_UI_TOOLTIP_TEST_FAIL: " + f)
	get_tree().quit(0 if failures.is_empty() else 1)

func _check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)

func _tooltip_text(tooltip_data: Dictionary, key: String) -> String:
	return str(tooltip_data.get(key, ""))

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	_check(packed != null, "main.tscn 可加载")
	if packed == null:
		return
	var main: Node = packed.instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame

	var help_ui: Control = main.get_node_or_null("help_ui")
	_check(help_ui != null, "help_ui 节点存在")
	if help_ui == null:
		return
	var help_ui_script: GDScript = load(HELP_UI_SCRIPT_PATH)
	_check(help_ui_script != null, "help_ui.gd 可加载")
	if help_ui_script == null:
		return
	## 2.4：脚本挂载成功且布局节点数量未变（18 标注 + 关闭按钮 + 快捷键面板 = 20）
	_check(help_ui.get_script() == help_ui_script, "help_ui 挂载 help_ui.gd")
	var panel: Panel = help_ui.get_node_or_null("Panel")
	_check(panel != null, "help_ui/Panel 存在")
	if panel == null:
		return
	_check(panel.get_child_count() == 20, "帮助界面布局节点数量不变（期望 20，实际 %d）" % panel.get_child_count())

	var constants := help_ui_script.get_script_constant_map()
	var help_tooltips: Dictionary = constants.get("HELP_TOOLTIPS", {})
	## 1.1：18 个 key 完整、文案非空、无占位文案
	_check(help_tooltips.size() == EXPECTED_KEYS.size(), "HELP_TOOLTIPS key 数量为 18（实际 %d）" % help_tooltips.size())
	for key: String in EXPECTED_KEYS:
		_check(help_tooltips.has(key), "HELP_TOOLTIPS 缺少 key: " + key)
		var text := _tooltip_text(help_tooltips, key)
		_check(not text.strip_edges().is_empty(), "key 文案为空: " + key)
		for placeholder in ["TODO", "FIXME", "占位", "待补充", "Lorem"]:
			_check(not text.contains(placeholder), "key %s 含占位文案 %s" % [key, placeholder])

	## 1.2 / 2.1：每个 key 至少解析到一个 Control，且全部注册进 TooltipManager
	var bound: Dictionary = help_ui.get_bound_targets()
	_check(bound.size() == EXPECTED_KEYS.size(), "已绑定 key 数量为 18（实际 %d）" % bound.size())
	var dual_keys: Array[String] = []
	for key: String in EXPECTED_KEYS:
		var paths: Array[String] = help_ui.get_target_paths(key)
		var targets: Array = bound.get(key, [])
		_check(targets.size() >= 1, "key 未解析到 Control: " + key)
		_check(paths.size() == targets.size(), "key 目标路径数与绑定节点数不一致: " + key)
		if paths.size() > 1:
			dual_keys.append(key)
		for path: String in paths:
			var target := help_ui.get_node_or_null(path)
			_check(target is Control, "目标节点不存在: " + path)
			_check(targets.has(target), "目标节点未记录到绑定表: " + path)
			if target is Control:
				_check(target.mouse_filter != Control.MOUSE_FILTER_IGNORE, "目标 mouse_filter 可接收 hover: " + path)
				_check(TooltipManager._tooltip_data.has(target), "目标未注册 tooltip: " + path)
				var tooltip_data: Dictionary = TooltipManager._tooltip_data.get(target, {})
				_check(not str(tooltip_data.get("text", "")).strip_edges().is_empty(), "已注册文案为空: " + path)

	## 只有 close_help 是双目标，且两个路径都正确
	_check(dual_keys.size() == 1 and dual_keys[0] == "close_help", "只有 close_help 是双目标（实际 %s）" % str(dual_keys))
	var close_paths: Array[String] = help_ui.get_target_paths("close_help")
	_check("Panel/close_help" in close_paths, "close_help 绑定文字标注")
	_check("Panel/help_button_close" in close_paths, "close_help 绑定实际关闭按钮")
	for key: String in EXPECTED_KEYS:
		if key != "close_help":
			var default_paths: Array[String] = help_ui.get_target_paths(key)
			_check(default_paths.size() == 1 and default_paths[0] == "Panel/%s" % key, "默认目标解析错误: " + key)

	## 3.2：关键文案口径
	var dice_type := _tooltip_text(help_tooltips, "dice_type")
	_check(dice_type.contains("多个骰型") and dice_type.contains("分数相加"), "骰型文案：多骰型组合相加")
	_check(dice_type.contains("只取") and dice_type.contains("最高分") and dice_type.contains("不重复叠加"), "骰型文案：同分组不重复叠加")
	var dice_type_desc := _tooltip_text(help_tooltips, "dice_type_desc")
	for type_name in ["对子", "顺子", "同色", "同对", "同顺"]:
		_check(dice_type_desc.contains(type_name), "骰型组合文案：五种骰型名齐全（缺 %s）" % type_name)
	_check(dice_type_desc.contains("例："), "骰型组合文案：含组合示例")
	_check(dice_type_desc.count("例：") >= 5, "骰型组合文案：每种骰型至少一个示例（实际 %d 个）" % dice_type_desc.count("例："))
	_check(dice_type_desc.contains("重复点数只按 1 个"), "骰型组合文案：顺子/同顺去重说明")
	_check(dice_type_desc.contains("去重后的连续点数量计算"), "骰型组合文案：等级按去重后连续点计算")
	_check(dice_type_desc.contains("2 个为 Lv.1") and dice_type_desc.contains("6 个及以上为 Lv.5"), "骰型组合文案：等级口径与骰型倍率一致")
	_check(dice_type_desc.contains("只取") and dice_type_desc.contains("最高分") and dice_type_desc.contains("不重复叠加"), "骰型组合文案：同分组不重复叠加")
	var exp_bar := _tooltip_text(help_tooltips, "exp_bar")
	_check(exp_bar.contains("每升 5 级") and exp_bar.contains("生命上限 +1"), "经验条文案：每 5 级生命上限 +1")
	_check(exp_bar.contains("当前生命不会因此恢复"), "经验条文案：升级不恢复当前生命")
	var score_preview := _tooltip_text(help_tooltips, "score_preview")
	_check(score_preview.contains("不包含攻击结算后由 BUFF 额外追加的分数"), "分数预告文案：排除 BUFF 追加分")
	var debuff_bar := _tooltip_text(help_tooltips, "debuff_bar")
	_check(debuff_bar.contains("可提前清除"), "DEBUFF 文案：可提前清除")
	var hero_skill := _tooltip_text(help_tooltips, "hero_skill")
	_check(hero_skill.contains("数字键 1/2/3"), "英雄技能文案：1/2/3")
	var skill_grid := _tooltip_text(help_tooltips, "skill_grid")
	_check(skill_grid.contains("Q/W/E"), "额外技能文案：Q/W/E")
	var dice_pocket := _tooltip_text(help_tooltips, "dice_pocket")
	_check(dice_pocket.contains("参与计分后立即消耗"), "骰子口袋文案：参与计分后消耗")
	var potion_progress := _tooltip_text(help_tooltips, "potion_progress")
	_check(potion_progress.contains("不包含 BUFF 额外追加分数"), "血瓶进度文案：排除 BUFF 追加分")

	## 2.3：语言切换后重新绑定文案，节点映射不变
	var original_locale := TranslationServer.get_locale()
	var dice_type_node: Control = help_ui.get_node("Panel/dice_type")
	var translated_text := "[b]EN DICE TYPE[/b]"
	var translation := Translation.new()
	translation.locale = "en"
	translation.add_message(StringName(_tooltip_text(help_tooltips, "dice_type")), StringName(translated_text))
	TranslationServer.add_translation(translation)
	TranslationServer.set_locale("en")
	await get_tree().process_frame
	var translated_tooltip: Dictionary = TooltipManager._tooltip_data.get(dice_type_node, {})
	_check(str(translated_tooltip.get("text", "")) == translated_text, "切换语言后文案更新")
	_check(help_ui.get_bound_targets().get("dice_type", [])[0] == dice_type_node, "切换语言后节点映射不变")
	TranslationServer.remove_translation(translation)
	TranslationServer.set_locale(original_locale)
	await get_tree().process_frame
	var restored_tooltip: Dictionary = TooltipManager._tooltip_data.get(dice_type_node, {})
	_check(str(restored_tooltip.get("text", "")) == _tooltip_text(help_tooltips, "dice_type"), "恢复语言后文案还原（locale=%s，实际=%s）" % [original_locale, str(restored_tooltip.get("text", "")).left(40)])
	_check(dice_type_node.get_signal_connection_list("mouse_entered").size() == 1, "语言切换后 mouse_entered 连接不重复（实际 %d）" % dice_type_node.get_signal_connection_list("mouse_entered").size())

	## 2.2：帮助界面隐藏时回收仍在显示的 tooltip
	help_ui.show()
	await get_tree().process_frame
	TooltipManager.show_tooltip(dice_type_node, _tooltip_text(help_tooltips, "dice_type"))
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_check(TooltipManager._popup.visible, "关闭前 tooltip 正在显示")
	var close_button: TextureButton = help_ui.get_node("Panel/help_button_close")
	close_button.pressed.emit()
	await get_tree().process_frame
	_check(not help_ui.visible, "关闭按钮隐藏帮助界面")
	_check(not TooltipManager._popup.visible, "关闭帮助后文本 tooltip 隐藏")
	_check(not TooltipManager._skill_popup.visible, "关闭帮助后技能 tooltip 隐藏")

	## 3.3：悬停信号触发说明，并检查顶部/底部/左右边缘条目的边界显示
	help_ui.show()
	await get_tree().process_frame
	for key: String in ["dice_pocket", "potion_progress", "exp_bar", "close_help"]:
		var edge_node: Control = help_ui.get_node("Panel/" + key)
		edge_node.mouse_entered.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		_check(TooltipManager._popup.visible, "%s 悬停显示 tooltip" % key)
		_check(TooltipManager._rich_label.text == tr(_tooltip_text(help_tooltips, key)), "%s 悬停显示当前文案" % key)
		edge_node.mouse_exited.emit()
		await get_tree().process_frame
		_check(not TooltipManager._popup.visible, "%s 移出隐藏 tooltip" % key)

	## 窗口模式下用真实鼠标事件验证 18 项都能被 GUI 命中（防止 mouse_filter=IGNORE 回归）
	if DisplayServer.get_name() != "headless":
		for key: String in EXPECTED_KEYS:
			var hover_node: Control = help_ui.get_node("Panel/" + key)
			var hover_rect := Rect2(hover_node.get_screen_position(), hover_node.size * hover_node.get_global_transform_with_canvas().get_scale())
			var motion := InputEventMouseMotion.new()
			motion.position = hover_rect.get_center()
			motion.global_position = hover_rect.get_center()
			Input.parse_input_event(motion)
			await get_tree().process_frame
			await get_tree().process_frame
			_check(TooltipManager._popup.visible, "%s 真实悬停显示 tooltip" % key)
			_check(TooltipManager._rich_label.text == tr(_tooltip_text(help_tooltips, key)), "%s 真实悬停文案正确" % key)
			TooltipManager.hide_tooltip()
			await get_tree().process_frame

	## 3.3：全部帮助项（含顶部/底部/左右边缘条目）在四个视口角落均完整显示，长文案不超出视口
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_check(viewport_size.x > 0 and viewport_size.y > 0, "视口尺寸有效")
	for key: String in EXPECTED_KEYS:
		var node: Control = help_ui.get_node("Panel/" + key)
		TooltipManager.show_tooltip(node, _tooltip_text(help_tooltips, key))
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		var popup_size: Vector2 = TooltipManager._popup.get_combined_minimum_size()
		_check(popup_size.x <= viewport_size.x, "%s tooltip 宽度不超出视口（%s / %s）" % [key, popup_size, viewport_size])
		_check(popup_size.y <= viewport_size.y, "%s tooltip 高度不超出视口（%s / %s）" % [key, popup_size, viewport_size])
		for corner: Vector2 in [
			Vector2(1, 1),
			Vector2(viewport_size.x - 1, 1),
			Vector2(1, viewport_size.y - 1),
			Vector2(viewport_size.x - 1, viewport_size.y - 1),
		]:
			TooltipManager._position_at(corner)
			var popup_rect := Rect2(TooltipManager._popup.position, popup_size)
			_check(Rect2(Vector2.ZERO, viewport_size).encloses(popup_rect), "%s tooltip 在角落 %s 超出视口（%s）" % [key, corner, popup_rect])
