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
var heros: MockContainer
var enemys: MockContainer
var slime_scene_array: Array = []
var buff_refresh_cost: int = 2
var grid_size: Vector2 = Vector2(64, 64)
var start_pos: Vector2 = Vector2(100, 100)

func _ready():
	buff_container = MockContainer.new()
	debuff_container = MockContainer.new()
	target_score = MockLabel.new()
	total_score = MockLabel.new()
	total_coins_label = MockLabel.new()
	turn_label = MockLabel.new()
	stage_label = MockLabel.new()
	heros = MockContainer.new()
	enemys = MockContainer.new()

class MockContainer extends Node2D:
	var children: Array = []
	func add_child(node): children.append(node)
	func get_children() -> Array: return children
	func remove_child(node): children.erase(node)

class MockLabel extends Node2D:
	var text: String = "0"
