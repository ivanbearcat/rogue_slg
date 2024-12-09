extends MarginContainer

@onready var nine_patch_rect_3: NinePatchRect = $NinePatchRect3
@onready var mask_1: ColorRect = $"../MarginContainer/TextureRect/mask1"
@onready var mask_2: ColorRect = $"../MarginContainer2/TextureRect2/mask2"
@onready var mask_3: ColorRect = $TextureRect3/mask3


var is_enterd := false

func _input(event: InputEvent) -> void:
	## 点击英雄才显示
	if Current.clicked_hero == null:
		return
	else:
		## 移动状态才显示
		if Current.clicked_hero.hero_state_machine.state.name != "move":
			print(Current.clicked_hero.hero_state_machine.state.name)
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and \
	event.is_pressed() == true and is_enterd == true:
		mask_1.visible = false
		mask_2.visible = false
		nine_patch_rect_3.material.set_shader_parameter("is_high_light", true)
		mask_3.visible = true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and \
	event.is_pressed() == true or event.is_action_pressed("esc"):
		nine_patch_rect_3.material.set_shader_parameter("is_high_light", false)
		mask_3.visible = false

func _on_mouse_entered() -> void:
	nine_patch_rect_3.material.set_shader_parameter("is_high_light", true)
	is_enterd = true


func _on_mouse_exited() -> void:
	if mask_3.visible == false:
		nine_patch_rect_3.material.set_shader_parameter("is_high_light", false)
	is_enterd = false
