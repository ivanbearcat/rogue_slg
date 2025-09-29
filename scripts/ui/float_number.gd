extends Node2D

var float_num: int:
	set(v):
		$Label.text = "+" + str(v)
	get:
		return $Label.text

var velocity := Vector2.ZERO
var gravity := Vector2.ZERO

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property($Label, "modulate:a", 0, 1).set_delay(0.5)


func _process(delta: float) -> void:
	velocity += gravity * delta
	position += velocity * delta
	
