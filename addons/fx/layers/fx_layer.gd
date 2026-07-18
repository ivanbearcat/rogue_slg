@tool
class_name FxLayer
extends Node


## FxLayer — 特效装饰节点基类。
## 作为子节点挂载到目标节点上，承担"保存原状态 → 应用特效 → 结束恢复"的生命周期管理。
## 子类需实现 _on_attach() / _on_detach() 方法。


## 持有的特效 Spec 引用
var spec: FxEffect

## FxEngine 引用，供 spec._apply 使用
var engine: FxEngine

## 参数字典（占位符替换后）
var params: Dictionary = {}

## 目标节点引用（即父节点）
var _target: Node

## 是否已完成（防止重复 finish）
var _finished: bool = false


func _ready() -> void:
	_target = get_parent()
	_on_attach()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# finish() 已提前调用 _on_detach，此处仅作兜底
		if not _finished:
			_on_detach()


## 挂载时调用。子类在此快照原状态并应用特效。
func _on_attach() -> void:
	pass


## queue_free 前调用。子类在此恢复原状态。
func _on_detach() -> void:
	pass


## 结束特效：立即恢复原状态，然后 queue_free。
## 必须在 queue_free 之前调用 _on_detach，否则后续 layer 的快照会捕获到
## 当前 layer 修改过的状态（而非原始状态）。
func finish() -> void:
	if _finished:
		return
	_finished = true
	_on_detach()
	if is_instance_valid(self):
		queue_free()
