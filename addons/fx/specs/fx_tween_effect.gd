@tool
class_name FxTweenEffect
extends FxEffect


## FxTweenEffect — 基于 Tween 属性动画的特效基类。
## 提供创建 Tween 的辅助方法与目标类型适配逻辑（区分 Node2D / Control / Camera2D）。


## 创建一个绑定到 engine 的 SceneTree 的 Tween。
func create_tween(engine: FxEngine) -> Tween:
	return engine.get_tree().create_tween()


## 获取目标的 position 属性（根据类型适配）。
## Camera2D → offset，Node2D/Control → position。
func get_position_property(target: Node) -> String:
	if target is Camera2D:
		return "offset"
	return "position"
