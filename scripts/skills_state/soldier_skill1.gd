extends HeroState

signal show_soldier_slash_range
signal hide_soldier_slash_range
signal soldier_slash

func enter():
	print(owner.hero_name + "进入soldier_slash")
	owner.animated_sprite_2d.play(owner.hero_name + "_idle")
	emit_signal("show_soldier_slash_range")

func input(event: InputEvent) -> void:
	## 点击释放技能的格子触发技能信号
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() == true:
		owner.animated_sprite_2d.play("soldier_slash")
		emit_signal("soldier_slash")
		## 判断技能动画、移动等完成后进入end状态
		hero_state_machine.transition_to("end")

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and \
	event.is_pressed() == true or event.is_action_pressed("esc"):
		Current.clicked_hero.hero_state_machine.transition_to("move")		

func exit():
	print(owner.hero_name, "离开soldier_slash")
	emit_signal("hide_soldier_slash_range")
