@tool
extends EditorPlugin


## 编辑器内持有的 Fx 实例，供 FxProfile Preview 按钮使用。
var _editor_fx: Node


func _enter_tree() -> void:
	add_autoload_singleton("Fx", "res://addons/fx/fx.gd")
	# 创建编辑器专用 Fx 实例并注册为 Engine 单例，
	# 使 FxProfile 的 @export_tool_button Preview 在 Inspector 中可用。
	_editor_fx = load("res://addons/fx/fx.gd").new()
	_editor_fx.name = "Fx_Editor"
	add_child(_editor_fx)
	_ensure_editor_singleton()


func _exit_tree() -> void:
	if Engine.get_singleton("Fx") == _editor_fx:
		Engine.unregister_singleton("Fx")
	if is_instance_valid(_editor_fx):
		_editor_fx.queue_free()
		_editor_fx = null
	remove_autoload_singleton("Fx")


## 游戏停止后，运行时 Fx autoload 被销毁并移除单例注册。
## 此时需要重新注册编辑器实例，使 Preview 按钮继续可用。
func _process(_delta: float) -> void:
	if is_instance_valid(_editor_fx) and not Engine.get_singleton("Fx"):
		Engine.register_singleton("Fx", _editor_fx)


## 确保编辑器 Fx 单例已注册（避免重复注册）。
func _ensure_editor_singleton() -> void:
	if is_instance_valid(_editor_fx) and not Engine.get_singleton("Fx"):
		Engine.register_singleton("Fx", _editor_fx)
