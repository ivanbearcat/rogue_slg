@tool
class_name FxFloatTextEffect
extends FxTweenEffect


## FxFloatTextEffect — 浮动文字特效。
## 在目标位置创建 Label，向上飘动并淡出。


@export var text: String = "{value}"
@export var size: int = 24
@export var color: Color = Color.WHITE
@export var rise: float = 50.0
@export var duration: float = 0.8


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	var label := Label.new()
	engine.add_to_scene(label, target)
	# 设置位置
	if target is Node2D:
		label.global_position = target.global_position
	elif target is Control:
		label.position = target.position
	# 设置文本样式
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.z_index = 100
	# 动画：上飘 + 淡出
	var tween: Tween = engine.get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - rise, duration)
	tween.tween_property(label, "modulate:a", 0.0, duration).set_delay(duration * 0.25)
	# 自动删除 Label
	engine.auto_free(label, duration)
