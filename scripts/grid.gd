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
	if attack.visible == true:
		## 等待分数结算动画和计分完成
		while Current.doing_skill_attack:
			await Tools.time_sleep(0.05)
		emit_signal("grid_cmd", "hide_skill_attack")
	
	
