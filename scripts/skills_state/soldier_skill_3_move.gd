extends HeroState

signal show_move_range
signal hide_move_range
signal hero_move

## 使用能量标记，保证一次技能只消耗一次能量
var power_flag: int

func enter():
	print(owner.hero_name + "进入soldier_skill_3")
	owner.animated_sprite_2d.play(owner.hero_name + "_move")
	emit_signal("show_move_range")
	power_flag = 1
	


func input(event: InputEvent) -> void:
	## 点击释放技能的格子触发技能信号
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() == true:
		emit_signal("hero_move")
		print(Current.power)
		Current.power -= power_flag
		power_flag = 0
		EventBus.event_emit("skill_button_reset")
		EventBus.event_emit("skill_power_reset")

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
	print(owner.hero_name, "离开soldier_skill_3")
	emit_signal("hide_move_range")
	
	
