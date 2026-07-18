@tool
class_name FxEffect
extends Resource


## FxEffect — 所有特效 Spec 的抽象基类。
## 子类必须实现 _apply(target, engine, params) 方法以执行特效逻辑。
## FxEffect 是 Resource 子类，可通过 @export 序列化到 .tres 文件。


## 应用特效到目标节点。
## [param target] 特效作用的目标节点
## [param engine] FxEngine 实例，提供辅助方法
## [param params] 参数字典，用于占位符替换
func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	push_warning("FxEffect: _apply() 未被子类实现: " + get_class())
