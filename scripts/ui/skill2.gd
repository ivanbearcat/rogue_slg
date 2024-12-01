extends MarginContainer

@onready var nine_patch_rect_2: NinePatchRect = $NinePatchRect2

func _on_mouse_entered() -> void:
	nine_patch_rect_2.material.set_shader_parameter("is_high_light", true)

func _on_mouse_exited() -> void:
	nine_patch_rect_2.material.set_shader_parameter("is_high_light", false)
