extends Node
## BuffTestHelper - Mock game state for isolated buff testing
## Provides mock implementations of Current, game_manager, SceneManager, EffectManager
## that buff scripts depend on, enabling deterministic unit testing without a running game.

## ============================================================
## Mock Current - 替代 Current autoload
## ============================================================
class MockCurrent extends RefCounted:
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
	var total_score: int = 0
	var once_total_score: int = 0
	var target_score: int = 100
	var base_score: int = 0
	var percent_score: float = 0.0
	# HP相关
	var player_hp: int = 5
	var max_hp: int = 5
	var player_defense: int = 2
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
	# 战斗标记
	var slime_die_sum: int = 0
	var killed_power_slime: bool = false
	var last_turn_attacked: bool = false
	var consecutive_score_turns: int = 0
	var skip_hp_damage_this_turn: bool = false
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
	# 掉落格子骰子
	var _drop_slot_dice = null

	# hero mock (简化版)
	var hero: MockHero

	func _init():
		hero = MockHero.new()

	## get_prop/set_prop 方法模拟 Current 的动态属性访问
	## 注意：不能重写 Object.get()/set()，所以用不同方法名
	## buff脚本中 Current.get("xxx") 实际调用 Object.get()，
	## 在mock环境中需要通过 _get/_set 虚方法来拦截
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

## ============================================================
## Mock Hero
## ============================================================
class MockHero extends RefCounted:
	var hero_movement: int = 0
	var hero_grid_index: Vector2 = Vector2.ZERO
	var children: Array = []  # 模拟 add_child

	func add_child(node):
		children.append(node)

	func remove_child(node):
		children.erase(node)

## ============================================================
## Mock Game Manager
## ============================================================
class MockGameManager extends RefCounted:
	var buff_container: MockContainer
	var debuff_container: MockContainer
	var target_score: MockLabel
	var total_score: MockLabel
	var total_coins_label: MockLabel
	var turn_label: MockLabel
	var stage_label: MockLabel
	var heros: MockContainer
	var enemys: MockContainer

	func _init():
		buff_container = MockContainer.new()
		debuff_container = MockContainer.new()
		target_score = MockLabel.new()
		total_score = MockLabel.new()
		total_coins_label = MockLabel.new()
		turn_label = MockLabel.new()
		stage_label = MockLabel.new()
		heros = MockContainer.new()
		enemys = MockContainer.new()

## ============================================================
## Mock Container - 模拟 Node 容器
## ============================================================
class MockContainer extends RefCounted:
	var children: Array = []

	func add_child(node):
		children.append(node)

	func get_children() -> Array:
		return children

	func remove_child(node):
		children.erase(node)

## ============================================================
## Mock Label
## ============================================================
class MockLabel extends RefCounted:
	var text: String = "0"

## ============================================================
## Mock SceneManager
## ============================================================
class MockSceneManager extends RefCounted:
	var _scenes: Dictionary = {}

	func create_scene(scene_type: String) -> MockTextureRect:
		var scene = MockTextureRect.new()
		_scenes[scene_type] = scene
		return scene

## ============================================================
## Mock TextureRect
## ============================================================
class MockTextureRect extends RefCounted:
	var texture = null
	var tooltip_text: String = ""
	var modulate: Color = Color(1, 1, 1, 1)
	var visible: bool = true
	var position: Vector2 = Vector2.ZERO

	func queue_free():
		visible = false

## ============================================================
## Mock EffectManager
## ============================================================
class MockEffectManager extends RefCounted:
	var _float_effects: Array = []
	var _big_flow_effects: Array = []

	func float_number_effect(value, color: String = "") -> MockNode:
		var effect = MockNode.new()
		_float_effects.append({"value": value, "color": color, "node": effect})
		return effect

	func big_flow_effect(target) -> void:
		_big_flow_effects.append(target)

## ============================================================
## Mock Node (通用)
## ============================================================
class MockNode extends RefCounted:
	var children: Array = []

	func add_child(node):
		children.append(node)

## ============================================================
## Mock Slime (用于 all_enemy_array)
## ============================================================
class MockSlime extends RefCounted:
	var enemy_grid_index: Vector2 = Vector2.ZERO
	var is_elite: bool = false
	var is_boss: bool = false
	var slime_color: String = "green"
	var slime_point: int = 1
	var animated_sprite_2d: MockAnimatedSprite

	func _init():
		animated_sprite_2d = MockAnimatedSprite.new()

## ============================================================
## Mock AnimatedSprite
## ============================================================
class MockAnimatedSprite extends RefCounted:
	var material: MockMaterial

	func _init():
		material = MockMaterial.new()

## ============================================================
## Mock Material
## ============================================================
class MockMaterial extends RefCounted:
	var _shader_params: Dictionary = {}

	func get_shader_parameter(name: String) -> Variant:
		return _shader_params.get(name, null)

	func set_shader_parameter(name: String, value: Variant) -> void:
		_shader_params[name] = value

## ============================================================
## Mock BuffSystem
## ============================================================
class MockBuffSystem extends RefCounted:
	var _registered_buffs: Dictionary = {}  # buff_id -> Buff
	var _family_counts: Dictionary = {}  # family -> count

	func get_family_count(family_name: String) -> int:
		return _family_counts.get(family_name, 0)

	func get_buffs_by_tag(tag: String) -> Array:
		var result = []
		for buff_id in _registered_buffs:
			var buff = _registered_buffs[buff_id]
			if tag in buff.tags:
				result.append(buff)
		return result

	func is_buff_registered(buff_id: String) -> bool:
		return _registered_buffs.has(buff_id)

	func register_buff(buff_id: String, buff):
		_registered_buffs[buff_id] = buff
		# 更新家族计数
		if buff.family != "":
			_family_counts[buff.family] = _family_counts.get(buff.family, 0) + 1

## ============================================================
## 创建 Buff 实例的辅助方法
## ============================================================

## 创建标准 buff_meta 字典
static func make_buff_meta(buff_id: String = "test_buff", family: String = "",
	tags: Array = [], buff_icon: String = "",
	buff_tooltip: String = "test tooltip", debuff_icon: String = "",
	debuff_tooltip: String = "") -> Dictionary:
	return {
		"buff_id": buff_id,
		"family": family,
		"tags": tags,
		"buff_icon": buff_icon,
		"buff_tooltip": buff_tooltip,
		"debuff_icon": debuff_icon,
		"debuff_tooltip": debuff_tooltip,
	}

## 创建 MockSlime 并加入 all_enemy_array
static func add_slime(mock_current: MockCurrent, grid_index: Vector2 = Vector2.ZERO,
	color: String = "green", point: int = 1, is_power: bool = false) -> MockSlime:
	var slime = MockSlime.new()
	slime.enemy_grid_index = grid_index
	slime.slime_color = color
	slime.slime_point = point
	slime.animated_sprite_2d = MockAnimatedSprite.new()
	slime.animated_sprite_2d.material = MockMaterial.new()
	slime.animated_sprite_2d.material.set_shader_parameter("is_high_light", is_power)
	if is_power:
		slime.animated_sprite_2d.material.set_shader_parameter("outline_color", Color(0.0, 18.892, 18.892))
	mock_current.all_enemy_array.append(slime)
	return slime

## 创建 MockSlime 并同时加入 skill_attack_range
static func add_slime_in_range(mock_current: MockCurrent, grid_index: Vector2 = Vector2.ZERO,
	color: String = "green", point: int = 1, is_power: bool = false) -> MockSlime:
	var slime = add_slime(mock_current, grid_index, color, point, is_power)
	mock_current.skill_attack_range.append(grid_index)
	return slime

## 重置 MockCurrent 到默认值
static func reset_mock_current(mock_current: MockCurrent) -> void:
	mock_current.total_score = 0
	mock_current.once_total_score = 0
	mock_current.target_score = 100
	mock_current.player_hp = 5
	mock_current.max_hp = 5
	mock_current.player_defense = 2
	mock_current.count_stage = 1
	mock_current.count_round = 1
	mock_current.total_coins = 0
	mock_current.power_slime_num = 1
	mock_current.max_power = 2
	mock_current.hero_movement = 0
	mock_current.all_enemy_array = []
	mock_current.skill_attack_range = []
	mock_current.dice_type_count = 0
	mock_current.slime_die_sum = 0
	mock_current.killed_power_slime = false
	mock_current.last_turn_attacked = false
	mock_current.consecutive_score_turns = 0
	mock_current.skip_hp_damage_this_turn = false
	mock_current.zero_coin_refresh_times = 0
	mock_current.zero_coin_refresh_max_times = 0
	mock_current.score_heal_accumulated = 0
	mock_current.score_heal_threshold = 35
	mock_current._potion_count = 1
	mock_current._potion_max = 3
	mock_current.iron_stomach_reduction = 0
	mock_current.public_lock_array = []
	mock_current.drop_slot_dice = null
	mock_current.dropped_dice_count = 0
	mock_current.scored_dice_info = []
	mock_current.active_dice_types = []
	mock_current.one_score = 0
	mock_current.two_score = 0
	mock_current.three_score = 0
	mock_current.four_score = 0
	mock_current.five_score = 0
	mock_current.six_score = 0
	mock_current.duizi_percent = 0
	mock_current.shunzi_percent = 0
	mock_current.tongse_percent = 0
	mock_current.tongdui_percent = 0
	mock_current.tongshun_percent = 0