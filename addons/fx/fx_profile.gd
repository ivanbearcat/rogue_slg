@tool
class_name FxProfile
extends Resource


## FxProfile — 声明式可序列化特效配方。
## 持有一组 FxEffect Spec，可在 Inspector 编辑、保存为 .tres 文件、
## 通过 Fx.play(target, profile) 调用。


## 特效列表，按顺序应用。
@export var effects: Array[FxEffect] = []

## 预览目标节点的路径（在当前编辑的场景中查找）。
@export var preview_target_path: NodePath = "PreviewNode"

## Inspector 预览按钮
@export_tool_button("Preview", "Play") var _preview: Callable = _on_preview


## 点击 Preview 按钮时的回调。
## 仅在编辑器内执行，运行时不执行。
func _on_preview() -> void:
	if not Engine.is_editor_hint():
		return
	var scene_root := EditorInterface.get_edited_scene_root()
	if not scene_root:
		push_warning("FxProfile: 请先打开一个场景")
		return
	var preview_node := scene_root.get_node_or_null(preview_target_path)
	if not preview_node:
		push_warning("FxProfile: 场景里没有 PreviewNode")
		return
	# 调用 Fx autoload 执行预览
	var fx := Engine.get_singleton("Fx")
	if fx:
		fx.play(preview_node, self)
