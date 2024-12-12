extends MarginContainer

@onready var nine_patch_rect: NinePatchRect = $NinePatchRect
@onready var nine_patch_rect_2: NinePatchRect = $"../MarginContainer2/NinePatchRect2"
@onready var nine_patch_rect_3: NinePatchRect = $"../MarginContainer3/NinePatchRect3"
@onready var mask_1: ColorRect = $TextureRect/mask1
@onready var mask_2: ColorRect = $"../MarginContainer2/TextureRect2/mask2"
@onready var mask_3: ColorRect = $"../MarginContainer3/TextureRect3/mask3"

var is_enterd := false

func _input(event: InputEvent) -> void:
	## 点击英雄才显示
	if Current.clicked_hero == null:
		return
	else:
		## 移动状态才显示
		if ["move", "skill_1", "skill_2", "skill_3"].has(Current.clicked_hero.hero_state_machine.state.name):
			## 左键点击显示技能被按下的图
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and \
			event.is_pressed() == true and is_enterd == true or event.is_action_pressed("1"):
				## 取消显示其他技能
				mask_2.visible = false
				nine_patch_rect_2.material.set_shader_parameter("is_high_light", false)
				mask_3.visible = false
				nine_patch_rect_3.material.set_shader_parameter("is_high_light", false)
				## 显示技能1
				mask_1.visible = true
				nine_patch_rect.material.set_shader_parameter("is_high_light", true)
				Current.clicked_hero.hero_state_machine.transition_to("skill_1")
		
	## 右键点击恢复
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and \
	event.is_pressed() == true or event.is_action_pressed("esc"):
		nine_patch_rect.material.set_shader_parameter("is_high_light", false)
		mask_1.visible = false
		Current.clicked_hero.hero_state_machine.transition_to("move")

func _on_mouse_entered() -> void:
	nine_patch_rect.material.set_shader_parameter("is_high_light", true)
	is_enterd = true

func _on_mouse_exited() -> void:
	if mask_1.visible == false:
		nine_patch_rect.material.set_shader_parameter("is_high_light", false)
	is_enterd = false
