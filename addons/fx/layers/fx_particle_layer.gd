@tool
class_name FxParticleLayer
extends FxLayer


## FxParticleLayer — 基于粒子场景的装饰节点。
## 在 _on_attach 时实例化 Spec 指定的 PackedScene，挂载到 target 的父节点（或场景根），
## 设置 emitting=true；在 _on_detach 时 queue_free 粒子节点。


var _particle_node: Node


func _on_attach() -> void:
	if not is_instance_valid(_target):
		return
	if spec:
		spec._apply(_target, engine, params)
	_schedule_finish()


func _on_detach() -> void:
	if is_instance_valid(_particle_node):
		_particle_node.queue_free()


## 若 spec 有 lifetime 或 duration > 0，延迟结束后自动 finish。
func _schedule_finish() -> void:
	if not spec:
		return
	var delay: float = 0.0
	var lv: Variant = spec.get("lifetime")
	if lv != null and lv > 0.0:
		delay = float(lv)
	if delay <= 0.0:
		var dv: Variant = spec.get("duration")
		if dv != null and dv > 0.0:
			delay = float(dv)
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
		finish()
