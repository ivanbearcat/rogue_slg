extends HeroState


func enter():
	print(owner.hero_name, "进入idle")
	owner.animated_sprite_2d.play(owner.hero_name + "_idle")

func unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() == true:
		var grid_index = Current.grid_index
		print(Current.all_hero_grid_index_array.has(grid_index))
		print(Current.all_hero_grid_index_array)
		print(grid_index)
		print("-==")
		if Current.all_hero_grid_index_array.has(grid_index):
			hero_state_machine.transition_to("move")

func exit():
	print(owner.hero_name, "离开idle")
	if Current.clicked_hero != null and Current.clicked_hero != owner:
		Current.clicked_hero.hero_state_machine.transition_to("idle")
	Current.clicked_hero = owner
