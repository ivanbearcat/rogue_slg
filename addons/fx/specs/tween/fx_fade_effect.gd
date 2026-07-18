@tool
class_name FxFadeEffect
extends FxTweenEffect


## FxFadeEffect — 淡入淡出特效。
## mode=0 为淡入（modulate.a 0→1），mode=1 为淡出（modulate.a 1→0）。


@export var duration: float = 0.5
@export var mode: int = 0


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	if not target is CanvasItem:
		return
	var tween: Tween = engine.get_tree().create_tween()
	if mode == 0:
		# fade_in: 0 → 1
		target.modulate.a = 0.0
		tween.tween_property(target, "modulate:a", 1.0, duration)
	else:
		# fade_out: 1 → 0
		target.modulate.a = 1.0
		tween.tween_property(target, "modulate:a", 0.0, duration)
