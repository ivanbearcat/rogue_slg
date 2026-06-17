extends Node
## MockCurrent - 替代 Current autoload 用于测试
## 提供 buff 脚本所需的所有属性，不涉及真实 UI 交互

# 基础分数
var one_score: int = 0
var two_score: int = 0
var three_score: int = 0
var four_score: int = 0
var five_score: int = 0
var six_score: int = 0
# 倍率
var duizi_percent: int = 0
var shunzi_percent: int = 0
var tongse_percent: int = 0
var tongdui_percent: int = 0
var tongshun_percent: int = 0
# 总分相关
var _total_score: int = 0
var total_score: int:
	set(v):
		if v < 0:
			v = 0
		_total_score = v
	get:
		return _total_score
var once_total_score: int = 0
var target_score: int = 100
var base_score: int = 0
var percent_score: float = 0.0
# HP相关
var _player_hp: int = 5
var player_hp: int:
	set(v):
		_player_hp = v
	get:
		return _player_hp
var _max_hp: int = 5
var max_hp: int:
	set(v):
		_max_hp = v
	get:
		return _max_hp
var _player_defense: int = 2
var player_defense: int:
	set(v):
		_player_defense = v
	get:
		return _player_defense
# 关卡/回合
var count_stage: int = 1
var count_round: int = 1
# 金币
var total_coins: int = 0
# 能量史莱姆
var power_slime_num: int = 1
var max_power: int = 2
var power: int = 0
# 移动
var hero_movement: int = 0
# 史莱姆/敌人
var all_enemy_array: Array = []
var skill_attack_range: Array = []
# 骰子相关
var dice_type_count: int = 0
var dropped_dice_count: int = 0
var scored_dice_info: Array = []
var active_dice_types: Array = []
var highest_dice_num: int = 1
var drop_slot_dice = null
var drop_slot_consumed_this_turn: bool = false
# 战斗标记
var slime_die_sum: int = 0
var killed_power_slime: bool = false
var last_turn_attacked: bool = false
var consecutive_score_turns: int = 0
# buff/商店
var zero_coin_refresh_times: int = 0
var zero_coin_refresh_max_times: int = 0
# 回血
var _score_heal_accumulated: int = 0
var score_heal_accumulated: int:
	set(v):
		_score_heal_accumulated = maxi(v, 0)
	get:
		return _score_heal_accumulated
var _score_heal_threshold: int = 20
var score_heal_threshold: int:
	set(v):
		_score_heal_threshold = maxi(v, 1)
	get:
		return _score_heal_threshold
var score_heal_threshold_increase: int = 15
var score_heal_base_threshold: int = 35
var iron_stomach_reduction: int = 0
var has_death_immunity: bool = false
var death_immunity_used: bool = false
# 血瓶
var _potion_count: int = 1
var potion_count: int:
	set(v):
		_potion_count = clampi(v, 0, potion_max)
	get:
		return _potion_count
var _potion_max: int = 3
var potion_max: int:
	set(v):
		_potion_max = maxi(v, 1)
		if _potion_count > _potion_max:
			_potion_count = _potion_max
	get:
		return _potion_max
# 公共锁
var public_lock_array: Array = []
# 英雄
var hero: MockHero

func _init():
	hero = MockHero.new()

## get/set 方法模拟 Current 的动态属性访问
func get_prop(prop_name: String) -> Variant:
	var props = {
		"one_score": one_score, "two_score": two_score, "three_score": three_score,
		"four_score": four_score, "five_score": five_score, "six_score": six_score,
		"duizi_percent": duizi_percent, "shunzi_percent": shunzi_percent,
		"tongse_percent": tongse_percent, "tongdui_percent": tongdui_percent,
		"tongshun_percent": tongshun_percent,
	}
	if props.has(prop_name):
		return props[prop_name]
	return null

func set_prop(prop_name: String, value: Variant) -> void:
	match prop_name:
		"one_score": one_score = value
		"two_score": two_score = value
		"three_score": three_score = value
		"four_score": four_score = value
		"five_score": five_score = value
		"six_score": six_score = value
		"duizi_percent": duizi_percent = value
		"shunzi_percent": shunzi_percent = value
		"tongse_percent": tongse_percent = value
		"tongdui_percent": tongdui_percent = value
		"tongshun_percent": tongshun_percent = value

## 重置到默认值
func reset_to_defaults() -> void:
	one_score = 0; two_score = 0; three_score = 0
	four_score = 0; five_score = 0; six_score = 0
	duizi_percent = 0; shunzi_percent = 0; tongse_percent = 0
	tongdui_percent = 0; tongshun_percent = 0
	_total_score = 0; once_total_score = 0; target_score = 100
	base_score = 0; percent_score = 0.0
	_player_hp = 5; _max_hp = 5; _player_defense = 2
	count_stage = 1; count_round = 1
	total_coins = 0; power_slime_num = 1; max_power = 2; power = 0
	hero_movement = 0
	all_enemy_array = []; skill_attack_range = []
	dice_type_count = 0; dropped_dice_count = 0
	scored_dice_info = []; active_dice_types = []
	highest_dice_num = 1; drop_slot_dice = null
	drop_slot_consumed_this_turn = false
	slime_die_sum = 0; killed_power_slime = false
	last_turn_attacked = false; consecutive_score_turns = 0
	zero_coin_refresh_times = 0; zero_coin_refresh_max_times = 0
	score_heal_accumulated = 0; score_heal_threshold = 35
	_potion_count = 1; _potion_max = 3
	iron_stomach_reduction = 0
	has_death_immunity = false
	death_immunity_used = false
	public_lock_array = []
	if hero:
		hero.hero_movement = 0

## ============================================================
## Mock Hero
## ============================================================
class MockHero extends RefCounted:
	var hero_movement: int = 0
	var hero_grid_index: Vector2 = Vector2.ZERO
	var _children: Array = []

	func add_child(node) -> void:
		_children.append(node)

	func remove_child(node) -> void:
		_children.erase(node)
