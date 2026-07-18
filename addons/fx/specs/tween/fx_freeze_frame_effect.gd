@tool
class_name FxFreezeFrameEffect
extends FxEffect


## FxFreezeFrameEffect — 时间冻结帧特效。
## 设置 Engine.time_scale 为低值，延迟后恢复为 1.0。
## 注意：直接继承 FxEffect（不走 FxLayer 机制），因为操作的是全局 Engine 属性而非节点属性。


@export var duration: float = 0.1
@export var time_scale: float = 0.05


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	Engine.time_scale = time_scale
	await engine.get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
