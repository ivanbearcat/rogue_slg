extends Node2D

@onready var cursor: Sprite2D = $Area2D/cursor
var grid_index: Vector2i


func _on_area_2d_mouse_entered() -> void:
	cursor.show()

func _on_area_2d_mouse_exited() -> void:
	cursor.hide()
	
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == 1 and event.is_pressed() == true:
		print(grid_index)
