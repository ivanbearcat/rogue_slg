extends Node2D
@onready var game_manager: Node2D = $".."
var _dice_adjust_target: Slime = null
var _swap_first_target: Slime = null

func _ready() -> void:
	EventBus.subscribe("reset_all_button", reset_all_button)
	EventBus.subscribe("reroll_all", reroll_all)
	EventBus.subscribe("reroll_all_clicked", reroll_all_clicked)
	EventBus.subscribe("reroll_dice", reroll_dice)
	EventBus.subscribe("reroll_dice_clicked", reroll_dice_clicked)
	EventBus.subscribe("reroll_color", reroll_color)
	EventBus.subscribe("reroll_color_clicked", reroll_color_clicked)
	EventBus.subscribe("add_power", add_power)
	EventBus.subscribe("add_power_clicked", add_power_clicked)
	EventBus.subscribe("dice_adjust", dice_adjust)
	EventBus.subscribe("dice_adjust_clicked", dice_adjust_clicked)
	EventBus.subscribe("dice_adjust_apply", dice_adjust_apply)
	EventBus.subscribe("move", move)
	EventBus.subscribe("cloud", cloud)
	EventBus.subscribe("mouse_up_clicked", mouse_up_clicked)
	EventBus.subscribe("mouse_left_clicked", mouse_left_clicked)
	EventBus.subscribe("mouse_right_clicked", mouse_right_clicked)
	EventBus.subscribe("mouse_down_clicked", mouse_down_clicked)
	EventBus.subscribe("double_score", double_score)
	EventBus.subscribe("double_score_clicked", double_score_clicked)
	EventBus.subscribe("swap", swap)
	EventBus.subscribe("swap_clicked", swap_clicked)
	EventBus.subscribe("swap_cancel", _on_swap_cancel)
	EventBus.subscribe("reset_cursor", _on_reset_cursor)

func _on_timer_timeout():
	## 按钮1
	if game_manager.coin_skill_1.button_pressed == true:
		game_manager.coin_skill_1_icon.position.y = 4.25
		game_manager.q_texture.position.y = 3
	else:
		game_manager.coin_skill_1_icon.position.y = 3.25
		game_manager.q_texture.position.y = 2
	## 按钮2
	if game_manager.coin_skill_2.button_pressed == true:
		game_manager.coin_skill_2_icon.position.y = 4.25
		game_manager.w_texture.position.y = 4
	else:
		game_manager.coin_skill_2_icon.position.y = 3.25
		game_manager.w_texture.position.y = 3
	## 按钮3
	if game_manager.coin_skill_3.button_pressed == true:
		game_manager.coin_skill_3_icon.position.y = 4.25
		game_manager.e_texture.position.y = 4
	else:
		game_manager.coin_skill_3_icon.position.y = 3.25
		game_manager.e_texture.position.y = 3

func _clicked_public_action(coin_skill_name):
	## 恢复所有UI初始状态
	CursorManager.reset_cursor()
	## 标记该技能本关已使用，并禁用对应技能按钮
	for i in range(Current.coin_skill_array_dict.size()):
		if Current.coin_skill_array_dict[i]["coin_skill_id"] == coin_skill_name:
			Current.coin_skill_used[i] = true
			## 禁用对应索引的技能按钮和图标
			match i:
				0:
					game_manager.coin_skill_1.disabled = true
					game_manager.coin_skill_1_icon.self_modulate = Color(1, 1, 1, 0.3)
				1:
					game_manager.coin_skill_2.disabled = true
					game_manager.coin_skill_2_icon.self_modulate = Color(1, 1, 1, 0.3)
				2:
					game_manager.coin_skill_3.disabled = true
					game_manager.coin_skill_3_icon.self_modulate = Color(1, 1, 1, 0.3)
			break

func reset_all_button():
	for button in [
		game_manager.coin_skill_1,
		game_manager.coin_skill_2,
		game_manager.coin_skill_3
		]:
		if button.button_pressed == true:
			button.button_pressed = false
	for icon in [game_manager.coin_skill_1_icon, game_manager.coin_skill_2_icon, game_manager.coin_skill_3_icon]:
		if icon.position.y != 3.25:
			icon.position.y = 3.25
	if game_manager.q_texture.position.y != 2:
		game_manager.q_texture.position.y = 2
	for texture in [game_manager.w_texture, game_manager.e_texture]:
		if texture.position.y != 3:
			texture.position.y = 3

func reroll_all():
	for grid in Current.all_grids_array:
		grid.target.show()
	if Current.within_grid_area:
		for grid in Current.all_grids_array:
			grid.attack.show()

func reroll_all_clicked():
	if Current.within_grid_area:
		for slime in Current.all_enemy_array:
			game_manager.slime_reroll(slime)
		_clicked_public_action("reroll_all")

func reroll_dice():
	var all_slime_array = Current.all_enemy_grid_index_array
	for grid in Current.all_grids_array:
		if grid.grid_index in all_slime_array:
			grid.target.show()
	if Current.grid_index in all_slime_array:
		for grid in Current.all_grids_array:
			if Current.grid_index == grid.grid_index:
				grid.attack.show()

func reroll_dice_clicked():
	if Current.slime:
		game_manager.slime_reroll(Current.slime, 1, 0)
		_clicked_public_action("reroll_dice")

func reroll_color():
	var all_slime_array = Current.all_enemy_grid_index_array
	for grid in Current.all_grids_array:
		if grid.grid_index in all_slime_array:
			grid.target.show()
	if Current.grid_index in all_slime_array:
		for grid in Current.all_grids_array:
			if Current.grid_index == grid.grid_index:
				grid.attack.show()

func reroll_color_clicked():
	if Current.slime:
		game_manager.slime_reroll(Current.slime, 0, 1)
		_clicked_public_action("reroll_color")

func add_power():
	for grid in Current.all_grids_array:
		if Current.hero.hero_grid_index == grid.grid_index:
			grid.target.show()

func add_power_clicked():
	if Current.grid_index == Current.hero.hero_grid_index and Current.power < Current.max_power:
		Current.power += 1
		_clicked_public_action("add_power")
	else:
		CursorManager.reset_cursor()

func dice_adjust():
	## 阶段1：显示目标选择光标，等玩家点击有骰子的格子
	var all_slime_array = Current.all_enemy_grid_index_array
	for grid in Current.all_grids_array:
		if grid.grid_index in all_slime_array:
			grid.target.show()
	if Current.grid_index in all_slime_array:
		for grid in Current.all_grids_array:
			if Current.grid_index == grid.grid_index:
				grid.attack.show()

func dice_adjust_clicked():
	## 阶段2：点击有骰子的格子后，弹出▲/▼面板
	if Current.slime:
		_dice_adjust_target = Current.slime
		get_tree().paused = true
		game_manager.dice_adjust_ui.show()
	else:
		## 点击空格子，无反应
		CursorManager.reset_cursor()

func dice_adjust_apply(coin_skill_name: String, target_slime = null):
	## 阶段3：▲或▼按钮点击后，技能消耗
	_clicked_public_action(coin_skill_name)
	_dice_adjust_target = null

func move():
	Current.hero.hero_state_machine.transition_to("coin_skill_move")

func cloud():
	get_tree().paused = true
	game_manager.direction_ui.show()

func cloud_clicked(direction):
	match direction:
		"up":
			var all_slime_array = Current.all_enemy_array.duplicate()
			all_slime_array.sort_custom(func(a, b): return a.enemy_grid_index.y < b.enemy_grid_index.y)
			for slime in all_slime_array:
				var target_position = slime.position + Vector2(0, -16)
				if target_position not in Current.all_enemy_position_array and \
				target_position != Current.hero.position and \
				target_position.x <= 7 * 16 and \
				target_position.x >= 16 and \
				target_position.y <= 7 * 16 and \
				target_position.y >= 16:
					slime.target_position = target_position
					var old_position = slime.position
					while slime.position == old_position:
						await Tools.time_sleep(0.01)
		"left":
			var all_slime_array = Current.all_enemy_array.duplicate()
			all_slime_array.sort_custom(func(a, b): return a.enemy_grid_index.x < b.enemy_grid_index.x)
			for slime in all_slime_array:
				var target_position = slime.position + Vector2(-16, 0)
				if target_position not in Current.all_enemy_position_array and \
				target_position != Current.hero.position and \
				target_position.x <= 7 * 16 and \
				target_position.x >= 16 and \
				target_position.y <= 7 * 16 and \
				target_position.y >= 16:
					slime.target_position = target_position
					var old_position = slime.position
					while slime.position == old_position:
						await Tools.time_sleep(0.01)
		"right":
			var all_slime_array = Current.all_enemy_array.duplicate()
			all_slime_array.sort_custom(func(a, b): return a.enemy_grid_index.x > b.enemy_grid_index.x)
			for slime in all_slime_array:
				var target_position = slime.position + Vector2(16, 0)
				if target_position not in Current.all_enemy_position_array and \
				target_position != Current.hero.position and \
				target_position.x <= 7 * 16 and \
				target_position.x >= 16 and \
				target_position.y <= 7 * 16 and \
				target_position.y >= 16:
					slime.target_position = target_position
					var old_position = slime.position
					while slime.position == old_position:
						await Tools.time_sleep(0.01)
		"down":
			var all_slime_array = Current.all_enemy_array.duplicate()
			all_slime_array.sort_custom(func(a, b): return a.enemy_grid_index.y > b.enemy_grid_index.y)
			for slime in all_slime_array:
				var target_position = slime.position + Vector2(0, 16)
				if target_position not in Current.all_enemy_position_array and \
				target_position != Current.hero.position and \
				target_position.x <= 7 * 16 and \
				target_position.x >= 16 and \
				target_position.y <= 7 * 16 and \
				target_position.y >= 16:
					slime.target_position = target_position
					var old_position = slime.position
					while slime.position == old_position:
						await Tools.time_sleep(0.01)
	_clicked_public_action("cloud")

func mouse_up_clicked():
	cloud_clicked("up")

func mouse_left_clicked():
	cloud_clicked("left")

func mouse_right_clicked():
	cloud_clicked("right")

func mouse_down_clicked():
	cloud_clicked("down")

func double_score():
	add_power()

func double_score_clicked():
	if Current.grid_index == Current.hero.hero_grid_index:
		BuffSystem.set_post_attack_buff(DoubleScoreBuff.new(), BuffSystem.buff_type.ONCE)
		_clicked_public_action("double_score")

func swap():
	## SELECT_1 阶段：显示所有有史莱姆格子的 target 蓝框
	var all_slime_array = Current.all_enemy_grid_index_array
	for grid in Current.all_grids_array:
		if grid.grid_index in all_slime_array:
			grid.target.show()
	## 如果鼠标当前格子有史莱姆则显示 attack 红框
	if Current.grid_index in all_slime_array:
		for grid in Current.all_grids_array:
			if Current.grid_index == grid.grid_index:
				grid.attack.show()

func swap_clicked():
	## 动画期间禁止操作
	if Current.action_lock:
		return
	## 两阶段选择逻辑
	if not Current.slime:
		## 点击空格子，无反应
		return
	if _swap_first_target == null:
		## 第一阶段：选中第1个史莱姆
		_swap_first_target = Current.slime
		## 隐藏第1个目标的蓝框和红框
		for grid in Current.all_grids_array:
			if grid.grid_index == _swap_first_target.enemy_grid_index:
				grid.target.hide()
				grid.attack.hide()
				grid.select.show()
	else:
		## 第二阶段：选中第2个史莱姆
		var second_target = Current.slime
		## 再次点击同一史莱姆，取消选择，回到第一阶段
		if second_target == _swap_first_target:
			for grid in Current.all_grids_array:
				if grid.grid_index == _swap_first_target.enemy_grid_index:
					grid.select.hide()
					grid.target.show()
			_swap_first_target = null
			return
		## 隐藏所有蓝框、红框和选中框
		for grid in Current.all_grids_array:
			grid.target.hide()
			grid.attack.hide()
			grid.select.hide()
		## 执行交换
		_execute_swap(_swap_first_target, second_target)
		_swap_first_target = null

func _execute_swap(slime_a: Slime, slime_b: Slime):
	## 记录两个史莱姆位置
	var pos_a = slime_a.position
	var pos_b = slime_b.position
	## 动画期间禁止操作
	Current.action_lock = true
	## 使用 Tween 并行动画移动到对方位置（1秒）
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(slime_a, "position", pos_b, 1.0)
	tween.tween_property(slime_b, "position", pos_a, 1.0)
	tween.set_parallel(false)
	tween.tween_callback(func():
		## 动画结束后更新A*碰撞网格
		game_manager.reset_astar_solid()
		## 解除操作锁定
		Current.action_lock = false
		## 消耗技能
		_clicked_public_action("swap")
	)

func _on_reset_cursor():
	## reset_cursor 时清理 swap 状态（由其他流程触发 reset_cursor 时使用）
	_swap_first_target = null
	for grid in Current.all_grids_array:
		grid.select.hide()

func _on_swap_cancel():
	## swap技能专用取消处理（右键/ESC时由cursor_manager触发）
	if _swap_first_target != null:
		## 已选了第1个目标，取消时回到第1阶段重新选择
		for grid in Current.all_grids_array:
			grid.select.hide()
		_swap_first_target = null
		## 不调用 reset_cursor()，直接重新进入 swap 第1阶段
		## mouse_status 仍为 swap，只需重新显示蓝框
		swap()
	else:
		## 未选目标，完全取消技能
		CursorManager.reset_cursor()
