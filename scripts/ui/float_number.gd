extends Node2D

var color := {
	"green": "0fff5b",
	"red": "ff0000"
}

var float_num: int:
	set(v):
		if v >= 0:
			$Label.label_settings.font_color = Color.html(color["green"])
			$Label.text = "+" + str(v)
		else:
			$Label.label_settings.font_color = Color.html(color["red"])
			$Label.text = str(v)
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
	
