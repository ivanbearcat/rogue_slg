@tool
class_name FxTweenLayer
extends FxLayer


## FxTweenLayer — 基于 Tween 属性动画的装饰节点。
## 在 _on_attach 时快照目标节点的 position/rotation/scale/modulate（根据目标类型），
## 在 _on_detach 时恢复这些属性。


var _snapshot: Dictionary = {}


func _on_attach() -> void:
	if not is_instance_valid(_target):
		return
	_snapshot = _take_snapshot(_target)
	if spec:
		spec._apply(_target, engine, params)
	_schedule_finish()


func _on_detach() -> void:
	if not is_instance_valid(_target) or _snapshot.is_empty():
		return
	_restore_snapshot(_target, _snapshot)


## 根据目标类型快照对应属性。
func _take_snapshot(target: Node) -> Dictionary:
	var snap: Dictionary = {}
	if target is Camera2D:
		snap["offset"] = target.offset
	elif target is Node2D:
		snap["position"] = target.position
		snap["rotation"] = target.rotation
		snap["scale"] = target.scale
		snap["modulate"] = target.modulate
	elif target is Control:
		snap["position"] = target.position
		snap["modulate"] = target.modulate
	elif target is CanvasItem:
		snap["modulate"] = target.modulate
	return snap


## 恢复快照属性。
func _restore_snapshot(target: Node, snap: Dictionary) -> void:
	for key in snap:
		target.set(key, snap[key])


## 若 spec 有 duration > 0，延迟结束后自动 finish。
func _schedule_finish() -> void:
	if not spec:
		return
	var dv: Variant = spec.get("duration")
	if dv != null and dv > 0.0:
		await get_tree().create_timer(float(dv)).timeout
		finish()
