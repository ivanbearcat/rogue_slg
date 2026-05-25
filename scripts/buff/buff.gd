extends Node2D
class_name Buff

var game_manager: Node2D
var buff_meta: Dictionary
var buff_texture: TextureRect
var debuff_texture: TextureRect
var data: Dictionary

## 家族：swarm/coin/resonance/combo/desperation
var family: String
## 标签数组
var tags: Array
## 依赖的 buff_id 数组
var requires: Array
## 是否处于沉睡状态（requires 未满足）
var is_dormant: bool = false

func _init(meta: Dictionary = {}, game_manager_node: Node2D = null) -> void:
	buff_meta = meta
	game_manager = game_manager_node
	family = meta.get("family", "")
	tags = meta.get("tags", [])
	requires = meta.get("requires", [])

func set_buff():
	pass

func process_buff():
	pass

func clear_buff():
	pass
