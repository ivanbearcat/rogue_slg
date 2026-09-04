extends Node
## 实时点击记录器（诊断工具）：由 game_eval 注入运行中的游戏。
## 记录每次左键按下：_input 层到达、当时 GUI 悬停的 Control、_unhandled_input 层到达
## 与完整状态快照。结果写入 Current 元数据 click_log（数组），外部轮询读取。

var logs: Array = []

func _ready() -> void:
	Current.set_meta("click_log", logs)

func _record(phase: String, event: InputEvent) -> void:
	var entry := {
		"phase": phase,
		"pos": str(event.position),
		"grid": str(Current.grid_index),
		"mouse_status": Current.mouse_status,
		"turn": Current.turn,
		"in_hero_array": Current.grid_index in Current.all_hero_grid_index_array,
	}
	if Current.hero != null:
		entry["hero_state"] = Current.hero.hero_state_machine.state.name
		entry["hero_grid"] = str(Current.hero.hero_grid_index)
	else:
		entry["hero_state"] = "no_hero"
		entry["hero_grid"] = "none"
	if phase == "input":
		var hc := get_viewport().gui_get_hovered_control()
		if hc != null:
			entry["hovered_control"] = "%s filter=%d rect=%s" % [
				hc.get_path(), hc.mouse_filter, str(hc.get_global_rect())]
		else:
			entry["hovered_control"] = "null"
		entry["handled_before"] = get_viewport().is_input_handled()
	logs.append(entry)
	if logs.size() > 300:
		logs.pop_front()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.is_pressed():
		_record("input", event)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.is_pressed():
		_record("unhandled", event)
