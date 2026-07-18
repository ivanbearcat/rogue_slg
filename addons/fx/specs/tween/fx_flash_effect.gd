@tool
class_name FxFlashEffect
extends FxTweenEffect


## FxFlashEffect — 闪白特效（受击通用）。
## 通过 Tween 操作目标 modulate，闪指定颜色后恢复。


@export var color: Color = Color.WHITE
@export var duration: float = 0.1


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	if not target is CanvasItem:
		return
	var original: Color = target.modulate
	target.modulate = color
	var tween: Tween = engine.get_tree().create_tween()
	tween.tween_property(target, "modulate", original, duration)
