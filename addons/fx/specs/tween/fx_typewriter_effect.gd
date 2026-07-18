@tool
class_name FxTypewriterEffect
extends FxTweenEffect


## FxTypewriterEffect — 打字机特效。
## 通过 tween_method 在 duration 内逐字显示 content 到目标的 text 属性。


@export var content: String = ""
@export var duration: float = 1.0


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	if not ("text" in target):
		return
	target.set("text", "")
	var tween: Tween = engine.get_tree().create_tween()
	tween.tween_method(_update_text.bind(target), 0.0, 1.0, duration)


func _update_text(progress: float, target: Node) -> void:
	if not is_instance_valid(target):
		return
	var total_chars: int = content.length()
	var visible_chars: int = int(total_chars * progress)
	target.set("text", content.substr(0, visible_chars))
