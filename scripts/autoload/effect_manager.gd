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

## 飘字效果
func float_number_effect(float_num, num_color="green", gravity=Vector2(0, 75), velocity=Vector2(randi_range(-10,10), -50)) -> Node2D:
	if float_num >-1 and float_num < 1:
		return
	var float_number_instantiate = SceneManager.create_scene("float_number")
	float_number_instantiate.num_color = color[num_color]
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
