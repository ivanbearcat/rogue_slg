extends Node
## 生命(Vitality) Buff测试
## 直接使用真实autoload（Current/SceneManager/EffectManager/BuffSystem/game_manager）

var _test_failed: bool = false
var _current_test: String = ""
var _assert_count: int = 0
var test_runner: Node2D = null

func before_all() -> void:
	pass

func before_each() -> void:
	_test_failed = false
	_current_test = ""
	_assert_count = 0
	if test_runner:
		test_runner.reset_current_to_defaults()

func after_each() -> void:
	pass

func after_all() -> void:
	pass

func create_and_set_buff(script_path: String, meta: Dictionary = {}) -> Buff:
	var script = load(script_path)
	var gm = get_node("/root/game_manager")
	var buff = script.new(meta, gm)
	buff.set_buff()
	return buff

func add_slime(grid_index: Vector2 = Vector2.ZERO, color: String = "green", point: int = 1, is_power: bool = false):
	var slime = Node.new()
	slime.enemy_grid_index = grid_index
	slime.slime_color = color
	slime.slime_point = point
	slime.is_elite = false
	slime.is_boss = false
	Current.all_enemy_array.append(slime)
	return slime

func add_slime_in_range(grid_index: Vector2 = Vector2.ZERO, color: String = "green", point: int = 1, is_power: bool = false):
	var slime = add_slime(grid_index, color, point, is_power)
	Current.skill_attack_range.append(grid_index)
	return slime

## ============================================================
## Assert方法
## ============================================================

func assert_eq(actual, expected, message: String = "") -> void:
	_assert_count += 1
	if actual != expected:
		_test_failed = true
		print("    ASSERTION FAILED [%s]: %s" % [_current_test, message if message != "" else "Expected %s but got %s" % [expected, actual]])

func assert_ne(actual, not_expected, message: String = "") -> void:
	_assert_count += 1
	if actual == not_expected:
		_test_failed = true
		print("    ASSERTION FAILED [%s]: %s" % [_current_test, message if message != "" else "Expected not %s but got %s" % [not_expected, actual]])

func assert_true(value: bool, message: String = "") -> void:
	_assert_count += 1
	if not value:
		_test_failed = true
		print("    ASSERTION FAILED [%s]: %s" % [_current_test, message if message != "" else "Expected true"])

func assert_false(value: bool, message: String = "") -> void:
	_assert_count += 1
	if value:
		_test_failed = true
		print("    ASSERTION FAILED [%s]: %s" % [_current_test, message if message != "" else "Expected false"])

func assert_gte(actual, than, message: String = "") -> void:
	_assert_count += 1
	if actual < than:
		_test_failed = true
		print("    ASSERTION FAILED [%s]: %s" % [_current_test, message if message != "" else "Expected %s >= %s" % [actual, than]])

## ============================================================
## 测试方法
## ============================================================

## 1. iron_stomach_buff - set时Current.iron_stomach_reduction=1, clear时重置为0
func test_iron_stomach_buff() -> void:
	_current_test = "test_iron_stomach_buff"
	var c = Current

	var meta = {"buff_id": "iron_stomach", "family": "vitality", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/iron_stomach_buff.gd", meta)

	# set_buff后iron_stomach_reduction应为1
	assert_eq(c.iron_stomach_reduction, 1, "iron_stomach_reduction should be 1 after set_buff")

	# clear_buff后iron_stomach_reduction应重置为0
	buff.clear_buff()
	assert_eq(c.iron_stomach_reduction, 0, "iron_stomach_reduction should be 0 after clear_buff")

	# 验证初始状态为0
	assert_eq(c.iron_stomach_reduction, 0, "iron_stomach_reduction should be 0 (default)")

## 2. blood_fury_buff - 被动buff，降低血瓶阈值，溢出保留
func test_blood_fury_buff() -> void:
	_current_test = "test_blood_fury_buff"
	var c = Current

	var meta = {"buff_id": "blood_fury", "family": "vitality", "tags": ["blood_fury", "passive"]}
	var buff = create_and_set_buff("res://scripts/buff/blood_fury_buff.gd", meta)

	# process_buff是被动（不改变total_score）
	var score_before = c.total_score
	buff.process_buff()
	assert_eq(c.total_score, score_before, "blood_fury: process_buff should not change total_score")

	# clear_buff也是空操作
	buff.clear_buff()
	assert_eq(c.total_score, score_before, "blood_fury: clear_buff should not change total_score")

	# 1 blood_fury: 阈值-5（外部_apply_score_heal中通过get_buffs_by_tag计算）
	# 2 blood_fury: 阈值-10
	# 溢出: accumulated - threshold（不重置为0）
	# 无blood_fury: accumulated = 0（重置为0）
	# 此处验证buff本身是被动标记，阈值逻辑在外部流程中处理

## 3. comeback_king_buff - 被动buff，process_buff为空
func test_comeback_king_buff() -> void:
	_current_test = "test_comeback_king_buff"
	var c = Current

	var meta = {"buff_id": "comeback_king", "family": "vitality", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/comeback_king_buff.gd", meta)

	# 验证process_buff是被动
	var score_before = c.total_score
	buff.process_buff()
	assert_eq(c.total_score, score_before, "comeback_king: process_buff should not change total_score")

	# clear_buff也是空操作
	buff.clear_buff()
	assert_eq(c.total_score, score_before, "comeback_king: clear_buff should not change total_score")

## 4. sustain_buff - 被动buff，process_buff为空（外部stage clear逻辑）
func test_sustain_buff() -> void:
	_current_test = "test_sustain_buff"
	var c = Current

	var meta = {"buff_id": "sustain", "family": "vitality", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/sustain_buff.gd", meta)

	# 验证process_buff是被动
	var score_before = c.total_score
	buff.process_buff()
	assert_eq(c.total_score, score_before, "sustain: process_buff should not change total_score")

	# clear_buff也是空操作
	buff.clear_buff()
	assert_eq(c.total_score, score_before, "sustain: clear_buff should not change total_score")

## 5. war_supply_buff - 被动buff，process_buff为空（外部购买+血瓶逻辑）
func test_war_supply_buff() -> void:
	_current_test = "test_war_supply_buff"
	var c = Current

	var meta = {"buff_id": "war_supply", "family": "vitality", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/war_supply_buff.gd", meta)

	# 验证process_buff是被动
	var score_before = c.total_score
	buff.process_buff()
	assert_eq(c.total_score, score_before, "war_supply: process_buff should not change total_score")

	# clear_buff也是空操作
	buff.clear_buff()
	assert_eq(c.total_score, score_before, "war_supply: clear_buff should not change total_score")

## 6. vitality_overlord_buff - 被动buff，process_buff为空（逻辑在buff_system._apply_overlord_multiplier中）
func test_vitality_overlord_buff() -> void:
	_current_test = "test_vitality_overlord_buff"
	var c = Current

	var meta = {"buff_id": "vitality_overlord", "family": "vitality", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/vitality_overlord_buff.gd", meta)

	# 验证process_buff是被动
	var score_before = c.total_score
	buff.process_buff()
	assert_eq(c.total_score, score_before, "vitality_overlord: process_buff should not change total_score")

	# clear_buff也是空操作
	buff.clear_buff()
	assert_eq(c.total_score, score_before, "vitality_overlord: clear_buff should not change total_score"
