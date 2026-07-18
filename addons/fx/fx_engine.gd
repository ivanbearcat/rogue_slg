@tool
class_name FxEngine
extends Node


## FxEngine — 特效引擎辅助方法提供者
## 由 Fx autoload 持有，为 FxEffect Spec 的 _apply 方法提供场景操作、
## 节点生命周期管理、目标类型判定与占位符替换等辅助方法。


enum TargetType {
	NONE,
	NODE_2D,
	CONTROL,
	CAMERA_2D,
	CANVAS_ITEM,
}


## 将 node 添加到合适的位置。
## 若 target 有父节点，添加到 target 的父节点下（与 target 同级）；
## 否则添加到当前场景根。
func add_to_scene(node: Node, target: Node) -> void:
	if not is_instance_valid(node):
		return
	var parent: Node = target.get_parent() if is_instance_valid(target) else null
	if parent:
		parent.add_child(node)
	elif get_tree().current_scene:
		get_tree().current_scene.add_child(node)
	elif get_tree().root:
		get_tree().root.add_child(node)


## 延迟 delay 秒后自动 queue_free node。
func auto_free(node: Node, delay: float = 0.0) -> void:
	if not is_instance_valid(node):
		return
	if delay <= 0.0:
		node.queue_free()
		return
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(node):
		node.queue_free()


## 判定目标节点的类型，返回 TargetType 枚举。
func get_target_type(target: Node) -> TargetType:
	if target is Camera2D:
		return TargetType.CAMERA_2D
	if target is Node2D:
		return TargetType.NODE_2D
	if target is Control:
		return TargetType.CONTROL
	if target is CanvasItem:
		return TargetType.CANVAS_ITEM
	return TargetType.NONE


## 对 value 做占位符替换。
## 若 value 是字符串，替换其中的 {key} 为 params[key] 的字符串表示。
## 若 value 是字符串且完全等于 "{key}"，返回 params[key] 的原值（支持强类型）。
func resolve_placeholder(value: Variant, params: Dictionary) -> Variant:
	if params.is_empty():
		return value
	if value is String:
		var s: String = value
		# 完全匹配 {key} → 返回原值（保持类型）
		if s.begins_with("{") and s.ends_with("}") and s.count("{") == 1:
			var key: String = s.substr(1, s.length() - 2)
			if params.has(key):
				return params[key]
			return value
		# 部分匹配 → 字符串内替换
		for key in params:
			var placeholder: String = "{" + key + "}"
			if s.contains(placeholder):
				s = s.replace(placeholder, str(params[key]))
		return s
	return value


## 遍历 Resource 的所有 @export 属性，对字符串属性做占位符替换。
func resolve_placeholders_in_resource(res: Resource, params: Dictionary) -> void:
	if params.is_empty() or not res:
		return
	for prop in res.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		if prop.usage & PROPERTY_USAGE_EDITOR == 0:
			continue
		var current_val: Variant = res.get(prop.name)
		if current_val is String:
			var replaced: Variant = resolve_placeholder(current_val, params)
			if replaced != current_val:
				res.set(prop.name, replaced)
