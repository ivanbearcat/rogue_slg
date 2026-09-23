extends CanvasLayer



func _ready() -> void:
	pass # Replace with function body.


func _on_resume_button_pressed() -> void:
	hide()
	get_tree().paused = false


func _on_texture_button_2_pressed() -> void:
	hide()
	get_tree().paused = false
	SceneManager.change_scene(&"splash")


func _on_texture_button_3_pressed() -> void:
	EventBus.event_emit('setting_ui', ['show'])


func _on_texture_button_4_pressed() -> void:
	get_tree().quit()
