extends HeroState

signal show_skill_range
signal hide_skill_range
signal skill_attack

func enter():
	print(owner.hero_name + "进入soldier_slash")
	owner.animated_sprite_2d.play(owner.hero_name + "_idle")
	Current.skill_num = "1"
	emit_signal("show_skill_range")

func input(event: InputEvent) -> void:
	## 点击释放技能的格子触发技能信号
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() == true:
		owner.animated_sprite_2d.play("soldier_slash")
		emit_signal("skill_attack")
		## 判断技能动画、移动等完成后进入end状态
		hero_state_machine.transition_to("end")	

func exit():
	print(owner.hero_name, "离开soldier_slash")
	emit_signal("hide_skill_range")
	Current.skill_num = ""
