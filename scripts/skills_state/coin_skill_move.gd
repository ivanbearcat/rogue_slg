extends HeroState

signal show_move_range
signal hide_move_range
signal hero_move

func enter():
	print(owner.hero_name + "进入coin_skill_move")
	owner.animated_sprite_2d.play(owner.hero_name + "_move")
	emit_signal("show_move_range")	

func input(event: InputEvent) -> void:
	## 点击释放技能的格子触发技能信号
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() == true:
		emit_signal("hero_move")
		## 恢复鼠标重置状态
		CursorManager.reset_cursor()
		## 扣除费用
		for row in Current.coin_skill_array_dict:
			if row["coin_skill_id"] == "move":
				Current.total_coins -= row["coin_skill_cost"]
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and \
		event.is_pressed() == true or event.is_action_pressed("esc"):
			EventBus.event_emit("reset_cursor")
			if Current.is_moved == true:
				Current.clicked_hero.hero_state_machine.transition_to("move")
				owner.animated_sprite_2d.play(owner.hero_name + "_end")
			else:
				Current.clicked_hero.hero_state_machine.transition_to("idle")

func update(_delta: float) -> void:
	if ! Current.id_path.is_empty():
		var target_grid_index = Current.id_path[0]
		var target_position = Vector2(target_grid_index.x * 16, target_grid_index.y * 16) + Vector2(16, 16)
		#print(owner.position, target_position)
		owner.position = owner.position.move_toward(target_position, 100 * _delta)
		if owner.position == target_position:
			Current.id_path.remove_at(0)
		if Current.id_path.is_empty():
			if Current.is_moved == false:
				owner.animated_sprite_2d.play(owner.hero_name + "_idle")
				Current.clicked_hero.hero_state_machine.transition_to("idle")
			else:
				owner.animated_sprite_2d.play(owner.hero_name + "_end")
				Current.clicked_hero.hero_state_machine.transition_to("move")
			emit_signal("hide_move_range")
			EventBus.event_emit("hide_all_skills")

func exit():
	print(owner.hero_name, "离开coin_skill_move")
	emit_signal("hide_move_range")
	
	
