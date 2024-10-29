extends Node2D

@onready var warning: Sprite2D = $Area2D/warning

var enemy_grid_index: Vector2i
var enemy_hp: int = 2
var target_position: Vector2

func _process(delta: float) -> void:
	if target_position:
		if self.position == target_position:
			target_position = Vector2.ZERO
		else:
			self.position = self.position.move_toward(target_position, 15 * delta)
