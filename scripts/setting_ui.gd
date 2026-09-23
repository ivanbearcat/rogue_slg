extends CanvasLayer

@onready var main_volume_progress: TextureProgressBar = %main_volume_progress
@onready var music_volume_progress: TextureProgressBar = %music_volume_progress
@onready var effect_volume_progress: TextureProgressBar = %effect_volume_progress

func _ready() -> void:
	EventBus.subscribe('setting_ui', setting_ui)


func setting_ui(ops: String):
	if ops == 'show':
		show()
	elif ops == 'hide':
		hide()


func _on_texture_button_pressed() -> void:
	hide()


func _on_check_box_pressed() -> void:
	pass # Replace with function body.


func _on_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif toggled_on == false:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_reduce_main_volum_pressed() -> void:
	main_volume_progress.value -= 5


func _on_increase_main_volume_pressed() -> void:
	main_volume_progress.value += 5


func _on_reduce_music_volume_pressed() -> void:
	music_volume_progress.value -= 5


func _on_increase_music_volume_pressed() -> void:
	music_volume_progress.value += 5


func _on_reduce_effect_volume_pressed() -> void:
	effect_volume_progress.value -= 5


func _on_increase_effect_volume_pressed() -> void:
	effect_volume_progress.value += 5
