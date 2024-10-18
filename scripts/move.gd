extends HeroState

signal show_move_range
signal hide_move_range
signal hero_move

func enter():
	print(owner.hero_name + "进入move")
	owner.animated_sprite_2d.play(owner.hero_name + "_move")
	emit_signal("show_move_range")

func input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() == true:
		emit_signal("hero_move")
		if not Current.id_path.has(Current.grid_index):
			owner.hero_state_machine.transition_to("idle")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed() == true:
		Current.clicked_hero.hero_state_machine.transition_to("idle")
	if event.is_action_pressed("esc"):
		Current.clicked_hero.hero_state_machine.transition_to("idle")

func update(_delta: float) -> void:
	if not Current.id_path.is_empty():
		var target_grid_index = Current.id_path[0]
		var target_position = Vector2(target_grid_index.x * 16, target_grid_index.y * 16) + Vector2(16, 16)
		owner.position = owner.position.move_toward(target_position, 100 * _delta)
		if owner.position == target_position:
			Current.id_path.remove_at(0)
		
		if Current.id_path.is_empty():
			# 更新移动后英雄的位置
			for hero_name in Current.all_hero_dict:
				if hero_name == owner.hero_name:
					Current.all_hero_dict[hero_name].hero_grid_index = target_grid_index
			hero_state_machine.transition_to("end")
				

func exit():
	print(owner.hero_name, "离开move")
	emit_signal("hide_move_range")
	Current.clicked_hero = null
