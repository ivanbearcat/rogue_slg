extends Node2D

## Color.html
var num_color: String
var float_num: int:
	set(v):
		$Label.label_settings.font_color = Color.html(num_color)
		if v >= 0:
			$Label.text = "+" + str(v)
		else:
			$Label.text = str(v)
	get:
		return $Label.text

var velocity := Vector2.ZERO
var gravity := Vector2.ZERO

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property($Label, "modulate:a", 0, 0.8).set_delay(0.2)


func _process(delta: float) -> void:
	velocity += gravity * delta
	position += velocity * delta
	
