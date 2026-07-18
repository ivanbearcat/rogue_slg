@tool
class_name FxShaderLayer
extends FxLayer


## FxShaderLayer — 基于 ShaderMaterial 的装饰节点。
## 在 _on_attach 时快照目标节点的 material 与 modulate，调用 spec._apply 挂载新 ShaderMaterial；
## 在 _on_detach 时恢复原 material 与 modulate。


var _snapshot_material: Variant = null
var _snapshot_modulate: Variant = null
var _has_material: bool = false
var _has_modulate: bool = false


func _on_attach() -> void:
	if not is_instance_valid(_target):
		return
	# 快照原 material
	if _target.get("material") != null:
		_has_material = true
		_snapshot_material = _target.get("material")
	# 快照原 modulate
	if _target.get("modulate") != null:
		_has_modulate = true
		_snapshot_modulate = _target.get("modulate")
	# 应用 shader 特效
	if spec:
		spec._apply(_target, engine, params)
	# 若 spec 有 duration > 0，延迟结束后自动 finish
	_schedule_finish()


func _on_detach() -> void:
	if not is_instance_valid(_target):
		return
	# 恢复原 material
	if _has_material and _target.get("material") != null:
		_target.set("material", _snapshot_material)
	# 恢复原 modulate
	if _has_modulate and _target.get("modulate") != null:
		_target.set("modulate", _snapshot_modulate)


func _schedule_finish() -> void:
	if not spec:
		return
	var dv: Variant = spec.get("duration")
	if dv != null and dv > 0.0:
		await get_tree().create_timer(float(dv)).timeout
		finish()
