@tool
class_name FxShakeEffect
extends FxTweenEffect


## FxShakeEffect — 抖动特效。
## 通过 Tween 随机偏移目标 position 制造抖动效果。


@export var intensity: float = 10.0
@export var duration: float = 0.2
@export var axes: Vector2 = Vector2(1, 1)


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	var pos_prop: String = get_position_property(target)
	var original: Variant = target.get(pos_prop)
	var tween: Tween = engine.get_tree().create_tween()
	var steps: int = int(duration / 0.05)
	if steps < 1:
		steps = 1
	for i in steps:
		var shake_offset := Vector2(
			randf_range(-intensity, intensity) * axes.x,
			randf_range(-intensity, intensity) * axes.y
		)
		tween.tween_property(target, pos_prop, original + shake_offset, 0.05)
	tween.tween_property(target, pos_prop, original, 0.05)
