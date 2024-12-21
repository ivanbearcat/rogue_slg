extends Node2D

var float_num: String:
	set(v):
		$Label.text = v
	get:
		return $Label.text

var velocity := Vector2.ZERO
var gravity := Vector2.ZERO
var mass := 100

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property($Label, "modulate:a", 0, 0.8).set_delay(0.2)


func _process(delta: float) -> void:
	velocity += gravity * mass * delta
	position += velocity * delta
	
