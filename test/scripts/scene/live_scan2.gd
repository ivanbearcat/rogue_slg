extends Node
## 实时热区扫描器 v2（诊断工具）：用 Input.warp_mouse 真实移动物理鼠标，
## 完整复现真实用户管线（真实motion→hover→点击→选中）。
## 结果写入 Current 元数据：livescan_done / livescan_result。

func _ready() -> void:
	await _run()

func _run() -> void:
	var hero = Current.hero
	var gm = Current.game_manager
	var cell := Vector2(3, 3)
	var tl: Vector2 = gm.get_viewport().canvas_transform * gm.grid_index_to_position(cell)
	var fails := []
	var hover_fails := 0
	var grid := ""
	for giy in range(8):
		for gix in range(8):
			var vp: Vector2 = tl + Vector2(2 + gix * 8.0, 2 + giy * 8.0)
			Input.warp_mouse(vp)
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().process_frame
			var hover_ok: bool = Current.grid_index == cell
			var mb := InputEventMouseButton.new()
			mb.button_index = MOUSE_BUTTON_LEFT
			mb.pressed = true
			mb.position = vp
			mb.global_position = vp
			Input.parse_input_event(mb)
			var mr := InputEventMouseButton.new()
			mr.button_index = MOUSE_BUTTON_LEFT
			mr.pressed = false
			mr.position = vp
			mr.global_position = vp
			Input.parse_input_event(mr)
			await get_tree().process_frame
			var moved: bool = hero.hero_state_machine.state.name == "move"
			if moved:
				hero.hero_state_machine.transition_to("idle")
				await get_tree().process_frame
			if hover_ok and moved:
				grid += "O"
			elif hover_ok:
				grid += "h"
				fails.append(vp)
			else:
				grid += "."
				hover_fails += 1
				fails.append(vp)
		grid += "\n"
	## 鼠标归位到格中心
	Input.warp_mouse(tl + Vector2(8, 8))
	Current.set_meta("livescan_done", true)
	Current.set_meta("livescan_result", "hover_fails=%d fails=%d\n%s" % [hover_fails, fails.size(), grid])
	queue_free()
