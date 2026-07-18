@tool
class_name FxNumberRollEffect
extends FxTweenEffect


## FxNumberRollEffect — 数字滚动特效。
## 通过 Tween 方法操作 Label.text 实现数字从 0 滚动到目标值。


@export var value: int = 0
@export var duration: float = 0.5


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	if not target is Label:
		return
	var label: Label = target as Label
	var target_value: int = value
	var tween: Tween = engine.get_tree().create_tween()
	# 使用 method tween 逐帧更新文本
	tween.tween_method(func(v: float) -> void:
		if is_instance_valid(label):
			label.text = str(roundi(v))
	, 0.0, float(target_value), duration)
