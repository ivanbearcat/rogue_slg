extends Node

## 当前场景（战局根为 Node2D，菜单根为 Control，统一放宽为 Node）
var current_scene : Node
## 同帧内挂起待挂载的场景（防止重复切换创建多个场景实例）
var _pending_scene: Node = null

func change_scene(view_name: StringName) -> Node:
	if _pending_scene != null:
		print("切换进行中，忽略重复切换： " + view_name)
		return _pending_scene
	var scene_view := create_scene(view_name)
	_free_current_scene(view_name)
	current_scene = scene_view
	## 延迟挂载：避免在父节点装配子节点期间 add_child 失败（如从 _ready 中触发切换）
	_pending_scene = scene_view
	get_tree().root.add_child.call_deferred(current_scene)
	_register_tree_current_scene.call_deferred()
	_clear_pending.call_deferred()
	if current_scene:
		print("进入场景： " + view_name)
	return scene_view

## 与 deferred 挂载同帧执行（FIFO 保证在 add_child 之后）
func _clear_pending() -> void:
	_pending_scene = null

## 释放旧场景：优先用 Godot 原生 current_scene（含项目启动主场景，如 splash），
## 已释放时退回本单例维护的 current_scene；写回见 _register_tree_current_scene
func _free_current_scene(view_name: StringName) -> void:
	var old_scene: Node = get_tree().current_scene
	if old_scene == null or not is_instance_valid(old_scene) or old_scene.is_queued_for_deletion():
		old_scene = current_scene
	if old_scene != null and is_instance_valid(old_scene) and not old_scene.is_queued_for_deletion():
		old_scene.queue_free()
		print("退出场景： " + view_name)

## 与 deferred 挂载同帧执行（FIFO 保证在 add_child 之后）
func _register_tree_current_scene() -> void:
	if current_scene != null and is_instance_valid(current_scene):
		get_tree().current_scene = current_scene

func create_scene(scene_name: StringName) -> Node:
	var scene_path: String = "res://scenes/" + scene_name + ".tscn"
	assert(ResourceLoader.exists(scene_path), "无法加载场景文件: " + scene_path)
	return load(scene_path).instantiate()

## 在后台线程预加载场景资源（大场景如 main 建议在菜单界面期间调用）
func preload_scene(view_name: StringName) -> void:
	ResourceLoader.load_threaded_request("res://scenes/" + view_name + ".tscn")

## 等待预加载完成后切换场景；未调用 preload_scene 时自动退回同步加载
func change_scene_preloaded(view_name: StringName) -> Node:
	var scene_path: String = "res://scenes/" + view_name + ".tscn"
	var status := ResourceLoader.load_threaded_get_status(scene_path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		while ResourceLoader.load_threaded_get_status(scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
	if status != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		## 已请求过的路径显式取回，确保资源入缓存，create_scene 的 load 立即命中
		ResourceLoader.load_threaded_get(scene_path)
	return change_scene(view_name)
