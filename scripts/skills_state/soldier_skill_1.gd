extends HeroState

signal show_skill_range
signal hide_skill_range
signal skill_attack

func enter():
	print(owner.hero_name + "进入soldier_skill_1")
	owner.animated_sprite_2d.play(owner.hero_name + "_end")
	Current.skill_num = "1"
	emit_signal("show_skill_range")

func input(event: InputEvent) -> void:
	## 点击释放技能的格子触发技能信号
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() == true:
		## 判断点击的格子在技能范围:
		if Current.grid_index in Current.skill_target_range:
			Current.attack_animation_finished = 0
			owner.animated_sprite_2d.play(owner.hero_name + "_skill_" + Current.skill_num)
			emit_signal("skill_attack")
			

func exit():
	print(owner.hero_name, "离开soldier_skill_2")
	emit_signal("hide_skill_range")
	Current.skill_num = ""
