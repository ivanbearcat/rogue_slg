extends Node
## 实时热区扫描器（诊断工具）：由 game_eval 注入运行中的游戏。
## 对英雄格做整数视口行扫描 + 2px 行为网格，走真实输入管线，
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
	var select_fails := 0
	for iy in range(64):
		for vx in [int(tl.x) + 2, int(tl.x) + 62]:
			var vp := Vector2(vx, int(tl.y) + iy)
			var r := await _try_select(hero, cell, vp)
			if not r.ok:
				fails.append(vp)
				if not r.hover:
					hover_fails += 1
				else:
					select_fails += 1
	var grid := ""
	for giy in range(8):
		for gix in range(8):
			var world: Vector2 = gm.grid_index_to_position(cell) + Vector2(1 + gix * 2.0, 1 + giy * 2.0)
			var vp2: Vector2 = gm.get_viewport().canvas_transform * world
			var r2 := await _try_select(hero, cell, vp2)
			if r2.ok:
				grid += "O"
			else:
				grid += "."
				fails.append(vp2)
		grid += "\n"
	var summary := "fails=%d hover_fails=%d select_fails=%d\n%s" % [fails.size(), hover_fails, select_fails, grid]
	if fails.size() > 0:
		summary += "first_fails=%s\n" % str(fails.slice(0, 10))
	Current.set_meta("livescan_done", true)
	Current.set_meta("livescan_result", summary)
	queue_free()

func _try_select(hero, cell: Vector2, vp: Vector2) -> Dictionary:
	var mm := InputEventMouseMotion.new()
	mm.position = vp
	mm.global_position = vp
	Input.parse_input_event(mm)
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
	return {"ok": hover_ok and moved, "hover": hover_ok}
