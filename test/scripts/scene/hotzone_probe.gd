extends Node
## 热区探针 v4（诊断工具）：横幅 IGNORE 后用户仍复现问题，做全面复检。
## A) 审计：所有 visible 且 mouse_filter=STOP 且与棋盘(世界16..128²)相交的 Control
## B) 选中热区：英雄在 (3,3)/(5,2)/(2,5) 三个位置，整数视口行扫描（抓发丝线）+ 2px 行为网格
## C) 移动流程：选中后对可移动目标格整格点击，验证 hero_move 全格有效

const BOARD := Rect2(16, 16, 112, 112)

func _ready() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(8.0).timeout

	_audit_stop_controls()

	var hero = Current.hero
	var gm = Current.game_manager

	for cell in [Vector2(3, 3), Vector2(5, 2), Vector2(2, 5)]:
		hero.position = gm.grid_index_to_position(cell)
		hero.hero_state_machine.transition_to("idle")
		await get_tree().process_frame
		await _probe_cell_select(hero, cell)

	## 还原英雄位置
	hero.position = gm.grid_index_to_position(Vector2(3, 3))
	hero.hero_state_machine.transition_to("idle")
	await get_tree().process_frame
	await _probe_target_move(hero)
	get_tree().quit()

## ---------- A) STOP 控件审计 ----------
func _audit_stop_controls() -> void:
	print("[probe] ===== A) STOP 控件审计（visible & filter==STOP & 与棋盘相交）=====")
	var controls := get_tree().root.find_children("*", "Control", true, false)
	var found := 0
	for c in controls:
		var ctl: Control = c
		if not ctl.is_visible_in_tree():
			continue
		if ctl.mouse_filter != 0: ## STOP
			continue
		var r: Rect2 = ctl.get_global_rect().grow(0.5)
		if r.intersects(BOARD):
			found += 1
			print("[probe]   EATER: %s (%s) rect=%s path=%s" % [
					ctl.name, ctl.get_class(), ctl.get_global_rect(), ctl.get_path()])
	print("[probe]   共 %d 个" % found)

## ---------- B) 选中热区 ----------
func _probe_cell_select(hero, cell: Vector2) -> void:
	var gm = Current.game_manager
	var tl: Vector2 = get_viewport().canvas_transform * gm.grid_index_to_position(cell)
	var fails := []
	## 整数视口行扫描（真实鼠标可达集），2 个 x 位置
	for iy in range(64):
		for vx in [int(tl.x) + 2, int(tl.x) + 62]:
			var vy := int(tl.y) + iy
			var ok: bool = await _try_select(hero, cell, Vector2(vx, vy))
			if not ok:
				fails.append(Vector2i(vx, vy))
	## 2px 行为网格（8×8，世界奇数偏移）
	var grid := ""
	for giy in range(8):
		for gix in range(8):
			var world: Vector2 = gm.grid_index_to_position(cell) + Vector2(1 + gix * 2.0, 1 + giy * 2.0)
			var vp: Vector2 = get_viewport().canvas_transform * world
			var ok: bool = await _try_select(hero, cell, vp)
			grid += "O" if ok else "."
			if not ok:
				fails.append(vp)
	print("[probe] --- cell %s 选中热区 (fails=%d) ---" % [cell, fails.size()])
	print(grid)
	if fails.size() > 0:
		print("[probe]   fail samples: ", fails.slice(0, 12))

func _try_select(hero, cell: Vector2, vp: Vector2) -> bool:
	_send_motion(vp)
	await get_tree().process_frame
	await get_tree().process_frame
	var hover_ok: bool = Current.grid_index == cell
	_send_click(vp)
	await get_tree().process_frame
	var moved: bool = hero.hero_state_machine.state.name == "move"
	if moved:
		hero.hero_state_machine.transition_to("idle")
		await get_tree().process_frame
	return hover_ok and moved

## ---------- C) 目标格移动流程 ----------
func _probe_target_move(hero) -> void:
	var gm = Current.game_manager
	## 选中英雄（点英雄格中心）
	var hero_vp: Vector2 = get_viewport().canvas_transform * (hero.position + Vector2(8, 8))
	_send_motion(hero_vp)
	await get_tree().process_frame
	await get_tree().process_frame
	_send_click(hero_vp)
	await get_tree().process_frame
	if hero.hero_state_machine.state.name != "move":
		print("[probe] --- C) 移动流程：选中失败，跳过 ---")
		return
	## 从可移动集合挑一个目标格
	var target := Vector2.ZERO
	for g in Current.movable_grid_index_array:
		if g != hero.hero_grid_index:
			target = g
			break
	var fails := []
	var grid := ""
	for giy in range(8):
		for gix in range(8):
			var world: Vector2 = gm.grid_index_to_position(target) + Vector2(1 + gix * 2.0, 1 + giy * 2.0)
			var vp: Vector2 = get_viewport().canvas_transform * world
			_send_motion(vp)
			await get_tree().process_frame
			await get_tree().process_frame
			_send_click(vp)
			await get_tree().process_frame
			var ok: bool = Current.id_path.size() > 0
			grid += "O" if ok else "."
			if ok:
				Current.id_path = [] ## 取消行走，保持 move 态继续采样
			else:
				fails.append(vp)
	print("[probe] --- C) 目标格 %s 移动点击热区 (fails=%d) ---" % [target, fails.size()])
	print(grid)
	hero.hero_state_machine.transition_to("idle")

func _send_motion(vp: Vector2) -> void:
	var mm := InputEventMouseMotion.new()
	mm.position = vp
	mm.global_position = vp
	Input.parse_input_event(mm)

func _send_click(vp: Vector2) -> void:
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
