extends Node2D

signal grid_cmd

@onready var range: Sprite2D = $Area2D/range
@onready var cursor: Sprite2D = $Area2D/cursor
@onready var warning: Sprite2D = $Area2D/warning
@onready var target: Sprite2D = $Area2D/target
@onready var attack: Sprite2D = $Area2D/attack

var grid_index: Vector2i


func _on_area_2d_mouse_entered() -> void:
	cursor.show()
	Current.grid_index = grid_index
	print(Current.grid_index)
	if target.visible == true:
		emit_signal("grid_cmd", "show_skill_attack")

func _on_area_2d_mouse_exited() -> void:
	cursor.hide()
	
	
