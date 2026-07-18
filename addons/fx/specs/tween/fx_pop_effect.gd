@tool
class_name FxPopEffect
extends FxTweenEffect


## FxPopEffect — 弹跳缩放特效（UI 强调）。
## Tween 操作 scale 放大后恢复，不修改 pivot_offset（避免容器布局 BUG）。


@export var scale_size: float = 1.5
@export var duration: float = 0.07


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	if not ("scale" in target):
		return
	var original_scale: Variant = target.get("scale")
	var tween: Tween = engine.get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(target, "scale", original_scale * scale_size, duration)
	tween.chain().tween_property(target, "scale", original_scale, duration / 1.5)
