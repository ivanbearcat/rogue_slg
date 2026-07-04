extends Node2D
## MockGameManager - 替代 game_manager autoload 用于测试
## 提供buff脚本所需的接口

var buff_container: MockContainer
var debuff_container: MockContainer
var target_score: MockLabel
var total_score: MockLabel
var total_coins_label: MockLabel
var turn_label: MockLabel
var stage_label: MockLabel
var clear_stage_label: MockLabel
var stage_effect_label: MockLabel
var potion_button: MockLabel
var heros: MockContainer
var enemys: MockContainer
var slime_scene_array: Array = []
var buff_refresh_cost: int = 2
var grid_size: Vector2 = Vector2(64, 64)
var start_pos: Vector2 = Vector2(100, 100)
var stage_info_json_data: Array = []

func _ready():
	buff_container = MockContainer.new()
	debuff_container = MockContainer.new()
	target_score = MockLabel.new()
	total_score = MockLabel.new()
	total_coins_label = MockLabel.new()
	turn_label = MockLabel.new()
	stage_label = MockLabel.new()
	clear_stage_label = MockLabel.new()
	stage_effect_label = MockLabel.new()
	potion_button = MockLabel.new()
	heros = MockContainer.new()
	enemys = MockContainer.new()

## MockContainer 继承 Node，使用原生 add_child/get_children/remove_child
## 避免 Godot 4.7 中 RefCounted 子类覆盖 Node 原生方法的解析错误
class MockContainer extends Node:
	pass

class MockLabel extends RefCounted:
	var text: String = "0"
