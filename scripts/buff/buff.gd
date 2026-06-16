extends Node2D
class_name Buff

var game_manager: Node2D
var buff_meta: Dictionary
var buff_texture: PanelContainer  # 改为PanelContainer（rich_tooltip.gd）
var debuff_texture: PanelContainer  # 同上
var data: Dictionary

## 家族：swarm/coin/resonance/desperation/vitality/hunt/swift/evolution
var family: String
## 标签数组
var tags: Array

func _init(meta: Dictionary = {}, game_manager_node: Node2D = null) -> void:
	buff_meta = meta
	game_manager = game_manager_node
	family = meta.get("family", "")
	tags = meta.get("tags", [])

func set_buff():
	pass

func process_buff():
	pass

func clear_buff():
	pass
