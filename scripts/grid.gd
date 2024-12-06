extends Node2D

@onready var range: Sprite2D = $Area2D/range
@onready var cursor: Sprite2D = $Area2D/cursor
@onready var warning: Sprite2D = $Area2D/warning

var grid_index: Vector2i


func _on_area_2d_mouse_entered() -> void:
	cursor.show()
	Current.grid_index = grid_index
	print(Current.grid_index)

func _on_area_2d_mouse_exited() -> void:
	cursor.hide()
	
	
