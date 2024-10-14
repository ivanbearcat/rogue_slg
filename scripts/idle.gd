extends HeroState


func enter():
	print(Current.hero.hero_name, "进入idle")
	if Current.move_state_hero:
		Current.move_state_hero.animated_sprite_2d.play(Current.move_state_hero.hero_name + "_idle")

func unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() == true:
		hero_state_machine.transition_to("move")

func exit():
	print(Current.hero.hero_name, "离开idle")
