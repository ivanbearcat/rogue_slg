@tool
class_name FxScreenShakeEffect
extends FxTweenEffect


## FxScreenShakeEffect — 屏幕抖动特效。
## 优先偏移 Camera2D.offset；无 Camera2D 时回退到抖动目标 position。


@export var intensity: float = 10.0
@export var duration: float = 0.2


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	var camera: Camera2D = null
	if target is Camera2D:
		camera = target as Camera2D
	else:
		camera = target.get_viewport().get_camera_2d() if target else null
	if camera:
		_shake_camera(camera, engine)
	elif target is Node2D:
		_shake_position(target, engine)


func _shake_camera(camera: Camera2D, engine: FxEngine) -> void:
	var original: Vector2 = camera.offset
	var tween: Tween = engine.get_tree().create_tween()
	var steps: int = _calc_steps()
	for i in steps:
		var shake_offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(camera, "offset", original + shake_offset, 0.05)
	tween.tween_property(camera, "offset", original, 0.05)


func _shake_position(node: Node2D, engine: FxEngine) -> void:
	var original: Vector2 = node.position
	var tween: Tween = engine.get_tree().create_tween()
	var steps: int = _calc_steps()
	for i in steps:
		var shake_offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(node, "position", original + shake_offset, 0.05)
	tween.tween_property(node, "position", original, 0.05)


func _calc_steps() -> int:
	var steps: int = int(duration / 0.05)
	return maxi(steps, 1)
