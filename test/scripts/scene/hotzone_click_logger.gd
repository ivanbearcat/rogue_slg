extends Node
## 探针内嵌 logger：记录到达 _input / _unhandled_input 层的左键按下事件，
## 以及到达 unhandled 层时的 Current 状态快照。

var probe: Node

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.is_pressed():
		probe.log_click_event("input", event.position,
				"handled=%s" % get_viewport().is_input_handled())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.is_pressed():
		var snap := "state=%s grid=%s turn=%s mouse_status=%s clicked=%s" % [
			Current.clicked_hero.hero_state_machine.state.name if Current.clicked_hero else "null",
			Current.grid_index, Current.turn, Current.mouse_status,
			Current.clicked_hero != null]
		probe.log_click_event("unhandled", event.position, snap)
