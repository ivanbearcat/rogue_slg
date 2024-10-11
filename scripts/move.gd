extends HeroState

signal show_move_range
signal hide_move_range

func enter():
	# 把已经在移动态的英雄改回idel
	if Current.move_state_hero and Current.move_state_hero != Current.hero:
		var tmp_hero = Current.hero
		Current.hero = Current.move_state_hero
		emit_signal("hide_move_range")
		Current.hero.hero_state_machine.transition_to("idle")
		Current.hero = tmp_hero
	print(Current.hero.hero_name, "进入move")
	emit_signal("show_move_range")
	Current.move_state_hero = Current.hero
	# 播放移动动画
	Current.hero.animated_sprite_2d.play(Current.hero.hero_name + "_move")

func unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed() == true:
		hero_state_machine.transition_to("idle")
	if event.is_action_pressed("esc"):
		hero_state_machine.transition_to("idle")

func exit():
	print(Current.hero.hero_name, "离开move")
	emit_signal("hide_move_range")
