extends Node2D
## buff-float-icon 行为验证探针（真实 EffectManager/场景实例/buff_meta）
## 用法: godot --path <项目> res://test/scripts/buff/float_icon_probe.tscn
## 每个 spec 场景截图保存到 test/scripts/buff/out/float_icon/，并打印行为断言结果

const OUT_DIR := "res://test/scripts/buff/out/float_icon"
const ZOOM := 4.0
const EXPECTED_OFFSET := 26.0

var _anchor: Node2D
var _results: Array = []

func _ready() -> void:
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	## 放大容器：只放大观察，不改变飘字内部构图
	_anchor = Node2D.new()
	_anchor.position = Vector2(320, 260)
	_anchor.scale = Vector2(ZOOM, ZOOM)
	add_child(_anchor)
	await _run_all()

func _run_all() -> void:
	await _scenario_pure_number()
	await _scenario_buff_coin_storm()
	await _scenario_adjacent_stand_guard()
	await _scenario_debuff_attack_weaken()
	await _scenario_overlord_swarm()
	await _scenario_delayed_pop()
	print("\n========== buff-float-icon probe ==========")
	for r in _results:
		print("  %s" % r)
	print("===========================================\n")
	get_tree().quit()

## ---------- 数据辅助 ----------

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

## ---------- 行为辅助 ----------

func _spawn(value, color_name: String, buff: Node, delayed: bool = false) -> Node2D:
	## 与真实管线同款窗口注入：仅构造瞬间上下文有效（延迟弹出同理，见 spec 场景）
	EffectManager.float_context_buff = buff
	var fx = EffectManager.float_number_effect(value, color_name)
	EffectManager.float_context_buff = null
	if delayed:
		await get_tree().create_timer(0.3).timeout
	_anchor.add_child(fx)
	return fx

func _check(step: String, ok: bool, detail: String) -> void:
	var tag: String = "PASS:" if ok else "FAIL:"
	_results.append("%s %s — %s" % [tag, step, detail])

func _shot(file_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT_DIR + "/" + file_name))

func _drop(fx: Node2D, buff: Node = null) -> void:
	fx.queue_free()
	if buff != null:
		buff.queue_free()
	await get_tree().process_frame

## ---------- 场景（对照 spec） ----------

## spec「非 buff 来源飘字保持无图标」
func _scenario_pure_number() -> void:
	var fx = await _spawn(2, "green", null)
	var icon: TextureRect = fx.get_node("Icon")
	var label: Label = fx.get_node("Label")
	var ok: bool = fx.icon_texture == null and not icon.visible and is_zero_approx(label.position.x)
	_check("纯数字飘字保持无图标", ok, "icon_texture=%s visible=%s label_x=%s" % [fx.icon_texture, icon.visible, label.position.x])
	await _shot("01_pure_number.png")
	await _drop(fx)

## spec「buff 加分显示其图标」
func _scenario_buff_coin_storm() -> void:
	var buff = await _meta_buff("res://config/buff.json", "buff_id", "coin_storm")
	var fx = await _spawn(2, "yellow", buff)
	var icon: TextureRect = fx.get_node("Icon")
	var tex: Texture2D = fx.icon_texture
	var path: String = tex.resource_path if tex != null else "<null>"
	var label2: Label = fx.get_node("Label")
	var ok: bool = icon.visible and tex != null and path == "res://images/buff_icon/coin_storm.png" and is_equal_approx(label2.position.x, EXPECTED_OFFSET)
	_check("coin_storm 显示 buff_icon 且 Label 右移", ok, "texture=%s visible=%s label_x=%s" % [path, icon.visible, label2.position.x])
	await _shot("02_coin_storm.png")
	await _drop(fx, buff)

## spec「相邻效果不串图标」：效果A窗口结束并clear后，效果B的飘字只带B的图标
func _scenario_adjacent_stand_guard() -> void:
	var buff_a = await _meta_buff("res://config/buff.json", "buff_id", "coin_storm")
	var buff_b = await _meta_buff("res://config/buff.json", "buff_id", "stand_guard")
	var fx_a = await _spawn(2, "yellow", buff_a)
	await _drop(fx_a, buff_a)
	var fx_b = await _spawn(2, "yellow", buff_b)
	var tex: Texture2D = fx_b.icon_texture
	var path: String = tex.resource_path if tex != null else "<null>"
	var ok: bool = path == "res://images/buff_icon/stand_guard.png" and is_instance_valid(fx_b.get_node("Icon")) and fx_b.get_node("Icon").visible
	_check("相邻效果不串图标(stand_guard)", ok, "texture=%s（应 stand_guard 而非 coin_storm）" % path)
	await _shot("03_stand_guard_adjacent.png")
	await _drop(fx_b, buff_b)

## spec「debuff 减分显示其图标」
func _scenario_debuff_attack_weaken() -> void:
	var buff = await _meta_buff("res://config/debuff.json", "debuff_id", "attack_weaken")
	var fx = await _spawn(-3, "red", buff)
	var icon: TextureRect = fx.get_node("Icon")
	var tex: Texture2D = fx.icon_texture
	var path: String = tex.resource_path if tex != null else "<null>"
	var label: Label = fx.get_node("Label")
	var ok: bool = icon.visible and tex != null and path == "res://images/debuff_icon/attack_weaken.png" and label.text == "-3"
	_check("attack_weaken 显示 debuff_icon 且为红色负数", ok, "texture=%s text=%s color=%s" % [path, label.text, label.label_settings.font_color])
	await _shot("04_attack_weaken_debuff.png")
	await _drop(fx, buff)

## spec「霸主占位图标照常使用」：icon.svg 按普通路径照常加载，不特殊过滤
func _scenario_overlord_swarm() -> void:
	var buff = await _meta_buff("res://config/buff.json", "buff_id", "swarm_overlord")
	var fx = await _spawn(2, "green", buff)
	var icon: TextureRect = fx.get_node("Icon")
	var tex: Texture2D = fx.icon_texture
	var path: String = tex.resource_path if tex != null else "<null>"
	var ok: bool = icon.visible and tex != null and path.contains("icon.svg")
	_check("swarm_overlord 占位 icon.svg 照常显示", ok, "texture=%s visible=%s" % [path, icon.visible])
	await _shot("05_swarm_overlord_placeholder.png")
	await _drop(fx, buff)

## spec「延迟弹出的飘字仍归属本 buff」：窗口延迟期间弹出仍带图标（构造瞬间捕获）
func _scenario_delayed_pop() -> void:
	var buff = await _meta_buff("res://config/buff.json", "buff_id", "resonance_chain")
	var fx = await _spawn(5, "green", buff, true)
	var icon: TextureRect = fx.get_node("Icon")
	var tex: Texture2D = fx.icon_texture
	var path: String = tex.resource_path if tex != null else "<null>"
	var ok: bool = icon.visible and tex != null and path == "res://images/buff_icon/resonance_chain.png"
	_check("延迟弹出仍带 resonance_chain 图标", ok, "延迟0.3s后挂载 texture=%s visible=%s" % [path, icon.visible])
	await _shot("06_delayed_pop.png")
	await _drop(fx, buff)
