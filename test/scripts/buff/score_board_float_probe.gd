extends Node2D
## score-board-delta-float 行为验证探针（真实 Current setter / EffectManager / float_number 场景实例）
## 用法: godot --path <项目> res://test/scripts/buff/score_board_float_probe.tscn
##
## 覆盖 spec 场景（对照 openspec/changes/score-board-delta-float/specs）：
##   基础分值增减飘字     —— 卡牌增/减、封印清零(8→0 红 -8)、mul 实际增量(+2)、
##                           mul 四舍五入 0 静默、钳制(3→0 显示 -3)
##   骰型倍率增减飘字     —— +6% 绿 / 封印清零 -6% 红
##   触发覆盖全部修改渠道 —— 全体 6 行同弹、封印过关恢复照弹绿 +x
##   初始化与读档静音     —— 静音窗口内 setter 修改零飘字、解除后恢复
##   来源图标归属         —— 掉落强化窗口带图标、卡牌路径纯数字、相邻窗口不串、
##                           霸主占位图标照常使用
##   飘字字号档           —— 计分板 24 档 < 得分 36 档，既有默认参数不变
##   进化霸主反馈迁移     —— 霸主窗口内 +1 / +1% 两行飘字带霸主图标
##   （自毁）             —— 计分板飘字约 1s 自毁；既有默认飘字生命周期不变
## 截图保存到 test/scripts/buff/out/score_board_float/，行为断言打印到 stdout

const OUT_DIR := "res://test/scripts/buff/out/score_board_float"
## mock 板祖先缩放：对齐 main.tscn score_panal 内 MarginContainer 的 scale=0.24
## （验证飘字挂载的运行时缩放补偿逻辑）
const BOARD_SCALE := 0.24

## mock game_manager：Current 11 个属性 setter 与计分板飘字辅助的访问面
## （行 frame + label 桩；基础分 setter 的 label 空判与倍率 setter 的直写均走真实路径）
class MockGameManager:
	extends Node2D
	var one_score_frame: PanelContainer
	var two_score_frame: PanelContainer
	var three_score_frame: PanelContainer
	var four_score_frame: PanelContainer
	var five_score_frame: PanelContainer
	var six_score_frame: PanelContainer
	var duizi_percent_frame: PanelContainer
	var shunzi_percent_frame: PanelContainer
	var tongse_percent_frame: PanelContainer
	var tongdui_percent_frame: PanelContainer
	var tongshun_percent_frame: PanelContainer
	var one_score: Label
	var two_score: Label
	var three_score: Label
	var four_score: Label
	var five_score: Label
	var six_score: Label
	var duizi_percent: Label
	var shunzi_percent: Label
	var tongse_percent: Label
	var tongdui_percent: Label
	var tongshun_percent: Label

var _board: MockGameManager
var _results: Array = []

func _ready() -> void:
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_setup_mock_board()
	await _run_all()

## ---------- mock 装配 ----------

func _setup_mock_board() -> void:
	_board = MockGameManager.new()
	_board.position = Vector2(600, 60)
	_board.scale = Vector2(BOARD_SCALE, BOARD_SCALE)
	add_child(_board)
	## 按计分板真实行序装配 frame（PanelContainer）与 label 桩
	var y := 0.0
	for prop in EffectManager.SCORE_BOARD_FRAMES.keys():
		var frame := PanelContainer.new()
		frame.size = Vector2(120, 23)
		frame.position = Vector2(0, y)
		_board.add_child(frame)
		_board.set(EffectManager.SCORE_BOARD_FRAMES[prop], frame)
		var lbl := Label.new()
		lbl.text = str(Current.get(prop))
		lbl.position = Vector2(60, 4)
		_board.add_child(lbl)
		_board.set(prop, lbl)
		y += 26.0
	Current.game_manager = _board

## ---------- 数据/行为辅助（沿 float_icon_probe 惯例） ----------

func _meta_rows(config_path: String) -> Array:
	var raw := FileAccess.get_file_as_string(config_path)
	var parsed = JSON.parse_string(raw)
	if parsed is Array:
		return parsed
	if parsed is Dictionary:
		for v in parsed.values():
			if v is Array:
				return v
	return []

func _meta_buff(config_path: String, id_key: String, id_value: String):
	for row in _meta_rows(config_path):
		if row is Dictionary and row.get(id_key, "") == id_value:
			return load(row.get("buff_res", "res://scripts/buff/buff.gd")).new(row)
	return null

func _check(step: String, ok: bool, detail: String) -> void:
	var tag: String = "PASS:" if ok else "FAIL:"
	_results.append("%s %s — %s" % [tag, step, detail])

func _shot(file_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT_DIR + "/" + file_name))

func _frame_of(prop: String) -> PanelContainer:
	return _board.get(EffectManager.SCORE_BOARD_FRAMES[prop])

func _floats_of(prop: String) -> Array:
	return _frame_of(prop).get_children()

## 静音窗口内重置属性（零飘字副作用），供场景间隔离状态
func _reset_scores(vals: Dictionary) -> void:
	Current.score_board_float_muted = true
	for key in vals:
		Current.set(key, vals[key])
	Current.score_board_float_muted = false

func _clear_floats() -> void:
	for prop in EffectManager.SCORE_BOARD_FRAMES.keys():
		for fx in _floats_of(prop):
			fx.queue_free()
	await get_tree().process_frame

## 校验一个计分板飘字的核心断言集：挂载行/文本/颜色/字号/后缀/补偿
## 返回汇总 ok
func _verify_float(prop: String, fx, expect_text: String, expect_green: bool, step: String) -> bool:
	if fx == null:
		_check(step, false, "无飘字实例")
		return false
	var label: Label = fx.get_node("Label")
	var ok_parent: bool = fx.get_parent() == _frame_of(prop)
	var ok_text: bool = label.text == expect_text
	var ok_color: bool = label.label_settings.font_color == Color.html("00ff00" if expect_green else "ff0000")
	var ok_font: bool = label.label_settings.font_size == EffectManager.SCORE_BOARD_FONT_SIZE \
		and label.label_settings.font_size < EffectManager.FLOAT_FONT_DEFAULT
	## 祖先缩放补偿：fx.scale × frame 全局缩放 ≈ 1（字号/偏移回到屏幕像素口径）
	var ok_scale: bool = absf(fx.scale.x * _frame_of(prop).get_global_transform().get_scale().x - 1.0) < 0.01
	var ok := ok_parent and ok_text and ok_color and ok_font and ok_scale
	_check(step, ok, "text=%s parent_ok=%s color_ok=%s font=%s scale_comp_ok=%s" % [
		label.text, ok_parent, ok_color, label.label_settings.font_size, ok_scale])
	return ok

## buff/debuff 执行窗口内修改属性（模拟 float_context_buff 窗口写入方惯例）
func _windowed_set(buff, prop: String, new_val: int):
	EffectManager.float_context_buff = buff
	Current.set(prop, new_val)
	EffectManager.float_context_buff = null
	var floats := _floats_of(prop)
	return floats[floats.size() - 1] if floats.size() > 0 else null

## ---------- 场景（对照 spec） ----------

func _run_all() -> void:
	await _scenario_base_score_delta()
	await _scenario_mul_real_delta()
	await _scenario_percent_suffix()
	await _scenario_mute_window()
	await _scenario_all_rows_and_restore()
	await _scenario_icon_drop_boost()
	await _scenario_icon_card_pure()
	await _scenario_icon_adjacent()
	await _scenario_icon_overlord_placeholder()
	await _scenario_evolution_overlord_migrated()
	await _scenario_font_tiers()
	await _scenario_auto_free()
	print("\n========== score-board-delta-float probe ==========")
	for r in _results:
		print("  %s" % r)
	print("===================================================\n")
	## stdout 在 quit 时可能未捕获，结果同步落盘（headless/编辑器运行两用）
	var result_path := ProjectSettings.globalize_path(OUT_DIR + "/probe_result.txt")
	var result_file := FileAccess.open(result_path, FileAccess.WRITE)
	if result_file != null:
		for r in _results:
			result_file.store_line(r)
		result_file.close()
	get_tree().quit()

## spec「基础分值增减飘字」：卡牌增(+8 绿)/封印清零(8→0 红 -8)/delta=0 静默
func _scenario_base_score_delta() -> void:
	await _clear_floats()
	_reset_scores({"one_score": 0})
	Current.one_score = 8
	var fx = _floats_of("one_score")[0]
	_verify_float("one_score", fx, "+8", true, "基础分 +8 绿色挂 one_score_frame")
	Current.one_score = 0
	var fx2 = _floats_of("one_score")[1]
	_verify_float("one_score", fx2, "-8", false, "封印清零 8→0 弹红色 -8")
	var before := _floats_of("one_score").size()
	Current.one_score = 0
	_check("delta=0 静默不弹", _floats_of("one_score").size() == before, "数量 %s→%s" % [before, _floats_of("one_score").size()])
	await _shot("01_base_score_delta.png")

## spec「mul 卡牌按实际增量显示 / 四舍五入 0 静默 / 钳制」
func _scenario_mul_real_delta() -> void:
	await _clear_floats()
	_reset_scores({"three_score": 10, "five_score": 3, "two_score": 3})
	## mul 卡牌：基础分 10 经 ×1.15 = 11.5 → roundi 12（_modifiy_value 既有钳制/四舍五入在 setter 之前）
	Current.three_score = 12
	_verify_float("three_score", _floats_of("three_score")[0], "+2", true, "mul 实际增量显示 +2 而非 +15%")
	## mul 四舍五入不变：3 经 ×1.15 = 3.45 → 3（独立属性避免前值残留）
	Current.two_score = 3
	_check("mul 四舍五入 0 静默", _floats_of("two_score").is_empty(), "two_score 3→3 飘字数 %s" % _floats_of("two_score").size())
	## 钳制：基础分 3 被 -5 → 实际钳制为 0
	Current.five_score = 0
	_verify_float("five_score", _floats_of("five_score")[0], "-3", false, "钳制后显示实际减少量 -3 而非 -5")

## spec「骰型倍率增减飘字」：随机蜕变 +6% / 类型封印清零 -6%
func _scenario_percent_suffix() -> void:
	await _clear_floats()
	_reset_scores({"duizi_percent": 0})
	Current.duizi_percent = 6
	_verify_float("duizi_percent", _floats_of("duizi_percent")[0], "+6%", true, "倍率 +6% 绿色带 % 后缀")
	Current.duizi_percent = 0
	_verify_float("duizi_percent", _floats_of("duizi_percent")[1], "-6%", false, "类型封印清零弹 -6% 红色")
	await _shot("02_percent_suffix.png")

## spec「初始化与读档静音」：静音窗口内零飘字、解除后恢复
func _scenario_mute_window() -> void:
	await _clear_floats()
	Current.score_board_float_muted = true
	Current.six_score = 15
	Current.tongshun_percent = 20
	var muted_ok: bool = _floats_of("six_score").is_empty() and _floats_of("tongshun_percent").is_empty()
	_check("静音窗口内 setter 修改零飘字", muted_ok, "six/tongshun 飘字数 %s/%s" % [
		_floats_of("six_score").size(), _floats_of("tongshun_percent").size()])
	Current.score_board_float_muted = false
	Current.six_score = 16
	_check("静音解除后恢复弹飘字", _floats_of("six_score").size() == 1, "six_score 弹出 %s 个" % _floats_of("six_score").size())
	_verify_float("six_score", _floats_of("six_score")[0], "+1", true, "解除后 +1 正常弹出")

## spec「触发覆盖全部修改渠道」：全体 6 行同弹、封印过关恢复照弹
func _scenario_all_rows_and_restore() -> void:
	await _clear_floats()
	_reset_scores({
		"one_score": 5, "two_score": 5, "three_score": 5,
		"four_score": 5, "five_score": 5, "six_score": 16,
	})
	## all_score 全体卡：6 个点数同时 +1（_apply_card_effect 的 all_score 分支即逐属性 set）
	var score_names := ["one_score", "two_score", "three_score", "four_score", "five_score", "six_score"]
	for score_name in score_names:
		Current.set(score_name, Current.get(score_name) + 1)
	var all_ok := true
	for score_name in score_names:
		var floats := _floats_of(score_name)
		all_ok = all_ok and floats.size() == 1 and floats[0].get_node("Label").text == "+1"
	var counts := []
	for score_name in score_names:
		counts.append(_floats_of(score_name).size())
	_check("全体卡 6 行同弹 +1", all_ok, "各行飘字数 %s" % str(counts))
	await _shot("03_all_rows.png")
	## 封印过关恢复：0 → 8 写回照弹绿色 +8，不做静音特判（清掉全体卡飘字后独立断言）
	await _clear_floats()
	_reset_scores({"one_score": 0})
	Current.one_score = 8
	_verify_float("one_score", _floats_of("one_score")[0], "+8", true, "封印过关恢复照弹绿 +8")
	await _shot("03_all_rows_and_restore.png")

## spec「来源图标归属」场景1：掉落强化窗口内 +2 → 飘字带掉落强化图标
func _scenario_icon_drop_boost() -> void:
	await _clear_floats()
	_reset_scores({"two_score": 5})
	var buff = _meta_buff("res://config/buff.json", "buff_id", "drop_base_boost")
	var fx = _windowed_set(buff, "two_score", 7)
	var ok: bool = fx != null and fx.icon_texture != null \
		and fx.icon_texture.resource_path == "res://images/buff_icon/drop_base_boost.png"
	_check("掉落强化窗口内飘字带来源图标", ok, "texture=%s" % (fx.icon_texture.resource_path if fx != null and fx.icon_texture != null else "<null>"))
	if fx != null:
		var label: Label = fx.get_node("Label")
		_check("带图标飘字 Label 右移(24档小偏移)", absf(label.position.x - 12.0) < 0.01, "label_x=%s" % label.position.x)
	await _shot("04_icon_drop_boost.png")
	buff.free()

## spec「来源图标归属」场景2：卡牌来源（无执行窗口）保持纯数字
func _scenario_icon_card_pure() -> void:
	await _clear_floats()
	_reset_scores({"four_score": 5})
	Current.four_score = 6
	var fx = _floats_of("four_score")[0]
	var ok: bool = fx.icon_texture == null and not fx.get_node("Icon").visible
	_check("卡牌来源纯数字无图标", ok, "icon=%s visible=%s" % [fx.icon_texture, fx.get_node("Icon").visible])

## spec「来源图标归属」场景3：相邻窗口不串图标（A 结束后 B 的飘字只带 B 图标）
func _scenario_icon_adjacent() -> void:
	await _clear_floats()
	_reset_scores({"five_score": 0})
	var buff_a = _meta_buff("res://config/buff.json", "buff_id", "coin_storm")
	var buff_b = _meta_buff("res://config/buff.json", "buff_id", "stand_guard")
	_windowed_set(buff_a, "five_score", 2)
	## A 窗口结束（clear）后 B 窗口开始
	var fx_b = _windowed_set(buff_b, "five_score", 4)
	var path: String = fx_b.icon_texture.resource_path if fx_b != null and fx_b.icon_texture != null else "<null>"
	_check("相邻窗口不串图标", fx_b != null and path == "res://images/buff_icon/stand_guard.png", "B texture=%s（应 stand_guard 而非 coin_storm）" % path)
	buff_a.free()
	buff_b.free()

## spec「来源图标归属」场景4：霸主图标照常加载显示，不做特殊过滤
## （swarm_overlord 的 buff_icon 已由占位 icon.svg 演进为专属 png——spec 场景语义为
## "霸主窗口内飘字照常加载并显示其图标字段、无过滤逻辑"，与路径是否占位无关）
func _scenario_icon_overlord_placeholder() -> void:
	await _clear_floats()
	_reset_scores({"six_score": 10})
	var buff = _meta_buff("res://config/buff.json", "buff_id", "swarm_overlord")
	var fx = _windowed_set(buff, "six_score", 12)
	var path: String = fx.icon_texture.resource_path if fx != null and fx.icon_texture != null else "<null>"
	var ok: bool = fx != null and fx.icon_texture != null \
		and path == "res://images/buff_icon/swarm_overlord.png" \
		and fx.get_node("Icon").visible
	_check("霸主图标照常显示(无过滤)", ok, "texture=%s visible=%s" % [path, fx.get_node("Icon").visible if fx != null else "<null>"])
	buff.free()

## spec「进化霸主反馈迁移」：霸主窗口内 +1 / +1% 由计分板两行飘字承接（带霸主图标）
func _scenario_evolution_overlord_migrated() -> void:
	await _clear_floats()
	_reset_scores({"five_score": 5, "tongshun_percent": 10})
	var buff = _meta_buff("res://config/buff.json", "buff_id", "evolution_overlord")
	## 模拟 evolution_overlord process_buff 的属性写入路径（英雄头顶 add_child 调用已按任务 5.1 移除）
	var fx_score = _windowed_set(buff, "five_score", 6)
	var fx_percent = _windowed_set(buff, "tongshun_percent", 11)
	var score_tex: String = fx_score.icon_texture.resource_path if fx_score != null and fx_score.icon_texture != null else "<null>"
	var percent_tex: String = fx_percent.icon_texture.resource_path if fx_percent != null and fx_percent.icon_texture != null else "<null>"
	var ok_score: bool = fx_score != null and fx_score.get_node("Label").text == "+1" \
		and score_tex == "res://images/buff_icon/evolution_overlord.png"
	var ok_percent: bool = fx_percent != null and fx_percent.get_node("Label").text == "+1%" \
		and percent_tex == "res://images/buff_icon/evolution_overlord.png"
	_check("霸主 +1/+1% 两行飘字带霸主图标", ok_score and ok_percent, "score=%s percent=%s" % [score_tex, percent_tex])
	await _shot("05_evolution_overlord_migrated.png")
	buff.free()

## spec「飘字字号档」：计分板飘字 24 < 得分 36；既有默认参数（36/无后缀/不自毁）不变
func _scenario_font_tiers() -> void:
	await _clear_floats()
	Current.three_score += 1
	var fx = _floats_of("three_score")[0]
	_check("计分板飘字字号小于得分飘字", fx.get_node("Label").label_settings.font_size == 24 and EffectManager.FLOAT_FONT_DEFAULT == 36,
		"计分板=%s 得分默认=%s" % [fx.get_node("Label").label_settings.font_size, EffectManager.FLOAT_FONT_DEFAULT])
	## 既有默认路径：float_number_effect 不传新参数 → 字号 36/无后缀/不自毁
	var legacy = EffectManager.float_number_effect(2)
	var legacy_ok: bool = legacy.get_node("Label").label_settings.font_size == 36 \
		and legacy.auto_free == false and legacy.text_suffix == "" \
		and legacy.get_node("Label").text == "+2"
	_check("既有飘字默认参数零变化", legacy_ok, "font=%s auto_free=%s suffix='%s' text=%s" % [
		legacy.get_node("Label").label_settings.font_size, legacy.auto_free, legacy.text_suffix, legacy.get_node("Label").text])
	add_child(legacy)
	legacy.queue_free()
	await get_tree().process_frame

## （design D5）自毁开关：计分板飘字淡出后自毁；既有默认飘字生命周期不变
func _scenario_auto_free() -> void:
	await _clear_floats()
	Current.four_score += 2
	var fx = _floats_of("four_score")[0]
	var legacy = EffectManager.float_number_effect(3)
	add_child(legacy)
	await get_tree().create_timer(1.3).timeout
	_check("计分板飘字淡出后自毁", not is_instance_valid(fx), "is_instance_valid=%s（约1.0s: 0.2延迟+0.8淡出）" % is_instance_valid(fx))
	_check("既有默认飘字生命周期不变(不自毁)", is_instance_valid(legacy), "is_instance_valid=%s" % is_instance_valid(legacy))
	legacy.queue_free()
