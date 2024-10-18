extends Node

var current_scene : Node2D

func change_scene(view_name: StringName, msg:Dictionary = {}) -> Node:
	var scene_view := create_scene(view_name)
	if current_scene:
		current_scene.queue_free()
		print("退出场景： " + view_name)
	current_scene = scene_view
	get_tree().root.add_child(current_scene)
	if current_scene:
		print("进入场景： " + view_name)
	return scene_view

func create_scene(scene_name: StringName) -> Node:
	var scene_path: String = "res://scenes/" + scene_name + ".tscn"
	assert(ResourceLoader.exists(scene_path), "无法加载场景文件")
	return load(scene_path).instantiate()
