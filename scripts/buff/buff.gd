extends Node2D
class_name Buff

var game_manager: Node2D
var buff_meta: Dictionary
var debuff_texture: TextureRect
var data: Dictionary

func _init(meta: Dictionary = {}, game_manager_node: Node2D = null) -> void:
	buff_meta = meta
	game_manager = game_manager_node
	
func set_buff():
	pass
	
func process_buff():
	pass
	
func clear_buff():
	pass
