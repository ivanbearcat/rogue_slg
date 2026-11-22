extends Node

## game_manager引用（跟随 Current 注册状态，场景切换后自动指向新战局）
var game_manager: Node2D:
	get:
		return Current.game_manager

var color := {
	"green": "00ff00",
	"red": "ff0000",
	"purple": "ff00ff",
	"yellow": "ffd700",
	"dark_yellow": "b8860b"
}

var _content: String
var _object: Object

## buff/debuff 执行窗口上下文（飘字图标归属用）：
## 写入方 = buff_system.gd do_buff() 四条管线、game_manager._trigger_drop_bonus()、
## skill_system._apply_drop_bonus()（各自在 await buff.process_buff() 前 set、后 clear，
## 与 buff_system._current_timing 同款惯例）
## 读取方 = float_number_effect()（构造飘字时据此注入来源图标）
var float_context_buff: Node = null

## 把图片对象快速放大恢复的效果
## 注意：不再修改pivot_offset，避免在HFlowContainer等容器中
## 因布局重算导致节点位置偏移（浮空BUG的根因）
func big_flow_effect(object, _auto_pivot_offset=1, scale_size=1.5, duration=0.07):
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(object, "scale:x", scale_size, duration)
	tween.parallel().tween_property(object, "scale:y", scale_size, duration)
	## 缩小
	tween.tween_property(object, "scale:x", 1, duration/1.5)
	tween.parallel().tween_property(object, "scale:y", 1, duration/1.5)
	await tween.finished

## BUFF图标专用效果：纯modulate颜色闪烁
## 完全不修改position/scale/pivot，零布局影响
func buff_pop_effect(object) -> void:
	var orig_modulate = object.modulate
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# 快速亮白闪烁
	tween.tween_property(object, "modulate", Color(3, 3, 3, 1), 0.05)
	tween.tween_property(object, "modulate", Color(0.7, 0.7, 0.7, 1), 0.05)
	tween.tween_property(object, "modulate", Color(2.5, 2.5, 2.5, 1), 0.05)
	tween.tween_property(object, "modulate", orig_modulate, 0.1)
	await tween.finished

## 飘字默认字号（36 = 既有飘字观感；计分板小档见 SCORE_BOARD_FONT_SIZE）。
## 观感微调入口：Label 节点缩放 0.25 固定，有效视觉字高 = 字号 × 0.25
##（36 档 ≈ 9px 高）；调小改这里（如 32 ≈ 8px），图标经 _apply_icon_layout
## 等比跟随保持与数字同高，计分板 24 独立档不受影响
const FLOAT_FONT_DEFAULT := 36

## 飘字效果
## text_suffix：数字后缀（计分板倍率行 "%"），默认空 = 既有纯数字
## font_size：字号档，默认 36 = 既有观感
## auto_free：淡出后自毁（计分板行节点整局存活时用），默认 false = 既有生命周期
func float_number_effect(float_num, num_color="green", gravity=Vector2(0, 75), velocity=Vector2(randi_range(-10,10), -50), text_suffix="", font_size=FLOAT_FONT_DEFAULT, auto_free=false) -> Node2D:
	if float_num >-1 and float_num < 1:
		return
	var float_number_instantiate = SceneManager.create_scene("float_number")
	float_number_instantiate.num_color = color[num_color]
	## 先装配后缀/字号/自毁，再写数字（float_num setter 内拼装文本与图标布局）
	float_number_instantiate.text_suffix = text_suffix
	float_number_instantiate.font_size = font_size
	float_number_instantiate.auto_free = auto_free
	float_number_instantiate.float_num = float_num
	float_number_instantiate.gravity = gravity
	float_number_instantiate.velocity = velocity
	## buff/debuff 执行窗口内：从 buff_meta 解析来源图标注入（buff_icon → debuff_icon 回退），
	## 无上下文/无图标/图标路径失效时保持纯数字，不阻断
	if float_context_buff != null:
		var context_meta = float_context_buff.get("buff_meta")
		if context_meta is Dictionary:
			var icon_path: String = str(context_meta.get("buff_icon", ""))
			if icon_path.is_empty():
				icon_path = str(context_meta.get("debuff_icon", ""))
			if not icon_path.is_empty():
				var icon_tex = load(icon_path)
				if icon_tex != null:
					float_number_instantiate.icon_texture = icon_tex
	return float_number_instantiate

## ============================================================
## 计分板增减飘字（score-board-delta-float）
## ============================================================
## 计分板行 frame 映射（属性名 → game_manager 场景行 PanelContainer 名）
const SCORE_BOARD_FRAMES := {
	"one_score": "one_score_frame",
	"two_score": "two_score_frame",
	"three_score": "three_score_frame",
	"four_score": "four_score_frame",
	"five_score": "five_score_frame",
	"six_score": "six_score_frame",
	"duizi_percent": "duizi_percent_frame",
	"shunzi_percent": "shunzi_percent_frame",
	"tongse_percent": "tongse_percent_frame",
	"tongdui_percent": "tongdui_percent_frame",
	"tongshun_percent": "tongshun_percent_frame",
}
## 计分板飘字小字号档（小于得分飘字 36 档，spec「飘字字号档」）
const SCORE_BOARD_FONT_SIZE := 24
## frame 左上角起的挂载偏移（屏幕像素口径，挂载时按祖先缩放换算本地值）：
## 基础分行无名称列（数值列占右半），倍率行左侧是名称列（"对子"等）——倍率飘字偏到数值列
const SCORE_BOARD_FLOAT_OFFSET_SCORE := Vector2(12, 1)
const SCORE_BOARD_FLOAT_OFFSET_PERCENT := Vector2(22, 1)
## 6.3 目测定稿：固定垂直匀速上飘（无随机横漂），上升距离收紧
## （velocity -4 / gravity 0 → 1s 生涯内匀速上浮共 4px，末态驻留顶部淡出不回落）
const SCORE_BOARD_VELOCITY_Y := -4.0
const SCORE_BOARD_GRAVITY := Vector2(0, 0)

## 计分板增减飘字：在属性对应行的 frame 内弹 delta 飘字
## （绿增红减，倍率属性带 "%" 后缀，淡出后自毁防行节点堆积）。
## 由 Current 11 个属性 setter 统一收口调用 → 渠道无关覆盖卡牌/buff/debuff
## 全部修改路径；走 float_number_effect() 复用 float_context_buff 图标注入。
## 静音窗口（关卡重置链）与 delta=0 在此静默；恢复路径（封印解除写回）不静音。
func score_board_float_effect(property: String, delta: int) -> void:
	if delta == 0 or Current.score_board_float_muted:
		return
	var frame_name: String = SCORE_BOARD_FRAMES.get(property, "")
	if frame_name.is_empty():
		return
	var gm = Current.game_manager
	if gm == null or gm.get(frame_name) == null:
		return
	var suffix := "%" if property.ends_with("_percent") else ""
	var fx = float_number_effect(
		delta,
		"green" if delta > 0 else "red",
		SCORE_BOARD_GRAVITY,
		Vector2(0, SCORE_BOARD_VELOCITY_Y),
		suffix, SCORE_BOARD_FONT_SIZE, true
	)
	if fx == null:
		return
	var frame: PanelContainer = gm.get(frame_name)
	frame.add_child(fx)
	## 祖先缩放补偿：行 frame 处于 score_panal 缩放容器内（≈0.24），
	## 飘字根节点按倒数补偿，使字号/偏移/上升/重力均回到屏幕像素口径
	## （24 档 ≈ 6px 有效字高，小于得分飘字的 9px）
	var inv := 1.0 / maxf(frame.get_global_transform().get_scale().x, 0.001)
	fx.scale = Vector2(inv, inv)
	## 倍率行数值列在右侧（左侧为名称列），基础分行数值列占右半 → 分档偏移
	var offset := SCORE_BOARD_FLOAT_OFFSET_PERCENT if property.ends_with("_percent") else SCORE_BOARD_FLOAT_OFFSET_SCORE
	fx.position = offset * inv
	fx.velocity *= inv
	fx.gravity *= inv

## 过关金币滚动音效参数：每单位一声，最多 20 声（大数值防爆音）
const COIN_ROLL_MAX_SFX := 20
const COIN_ROLL_PITCH := 1.5

## 设置数字并滚动
## coin_sfx=true 时，滚动期间随显示数值递增同步播放 coin（每个单位一声，最多 max_coin_sfx 声）
func label_num_rolling_effect(object, value, sync=1, coin_sfx=false, max_coin_sfx=COIN_ROLL_MAX_SFX):
	_object = object
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if coin_sfx:
		var state := {
			"end": int(value),
			"max": max_coin_sfx,
			"played": 0,
		}
		tween.tween_method(_label_num_rolling_update_text_with_coin.bind(state), int(_object.text), value, 0.5)
	else:
		tween.tween_method(label_num_rolling_update_text, int(_object.text), value, 0.5)
	if sync:
		await tween.finished
func label_num_rolling_update_text(value):
	_object.text = str(value)
	EffectManager.big_flow_effect(_object, 0)

## 滚动更新文本 + 按整数递增同步播放 coin：显示值每越过一个发声阈值放一声
func _label_num_rolling_update_text_with_coin(value, state: Dictionary) -> void:
	_object.text = str(value)
	EffectManager.big_flow_effect(_object, 0)
	var end: int = state["end"]
	if end <= 0:
		return
	var total: int = mini(end, int(state["max"]))
	var shown: int = int(value)
	while int(state["played"]) < total:
		var next_index: int = int(state["played"]) + 1
		var threshold: int = int(ceil(float(end) * next_index / total))
		if shown < threshold:
			break
		AudioManager.play_sfx("coin", 0.0, 0.0, 0.0, COIN_ROLL_PITCH)
		state["played"] = next_index

## 打字机效果
func typewriter_effect(object, content, duration, sync=1):
	_object = object
	_content = content
	_object.text = ""
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(_typewriter_update_text, 0.0, 1.0, duration)
	if sync:
		await tween.finished
func _typewriter_update_text(progress: float):
	var total_chars = _content.length()
	var visible_chars = int(total_chars * progress)
	_object.text = _content.substr(0, visible_chars)

## 淡入效果
func fade_in_effect(object, duration, sync=1):
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(object, "modulate:a", 0, 0)
	tween.tween_property(object, "modulate:a", 1, duration)
	if sync:
		await tween.finished

## 上部进入
func top_to_bottom_effect(object, duration, sync=1):
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var size_y = object.size.y
	var postion_y = object.position.y
	tween.tween_property(object, "position:y", -size_y, 0)
	tween.tween_property(object, "position:y", postion_y+postion_y*0.2, duration)
	tween.tween_property(object, "position:y", postion_y, duration*0.2)
	if sync:
		await tween.finished

## 关卡切换效果
func stage_change_effect():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	game_manager.stage_effect_ui.scale.y = 0
	tween.tween_property(game_manager.stage_effect_ui, "scale:y", 1, 0.2)
	await Tools.time_sleep(1.5)
	var tween2 = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween2.tween_property(game_manager.stage_effect_ui, "scale:y", 0, 0.1)

## 获得BOSS效果
func debuff_change_effect():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	game_manager.debuff_effect_ui.scale.y = 0
	tween.tween_property(game_manager.debuff_effect_ui, "scale:y", 1, 0.2)
	await Tools.time_sleep(1.5)
	var tween2 = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween2.tween_property(game_manager.debuff_effect_ui, "scale:y", 0, 0.1)

## level_up飘字
func level_up_effect(object):
	## 升级音效：飘字 + 萤火虫演出开始处同刻一声（progression-sfx「升级飘字与音效同刻」）；
	## fire-and-forget，不阻塞后续演出与升级选卡流程
	AudioManager.play_sfx("level_up")
	Current.public_lock_array.append("level_up_effect")
	var label = SceneManager.create_scene("level_up_label")
	object.add_child(label)
	# 动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 35, 0.9)
	tween.tween_property(label, "modulate:a", 0.2, 0.9).set_ease(Tween.EASE_OUT).set_delay(0.1)
	var fireflies_effect = EnvVFX.create_fireflies(Current.hero.animated_sprite_2d, Current.hero.animated_sprite_2d.position)
	await tween.finished
	fireflies_effect.queue_free()
	label.queue_free()
	Current.public_lock_array.erase("level_up_effect")
