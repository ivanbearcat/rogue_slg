extends Node2D

var float_num: String:
	set(v):
		$Label.text = v
	get:
		return $Label.text

var velocity := Vector2.ZERO
var gravity := Vector2.ZERO
var mass := 100

func _process(delta: float) -> void:
	velocity += gravity * mass * delta
	position += velocity * delta
