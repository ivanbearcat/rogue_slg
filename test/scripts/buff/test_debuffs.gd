extends Node
## Debuff Buff测试
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

func assert_lte(actual, than, message: String = "") -> void:
	_assert_count += 1
	if actual > than:
		_test_failed = true
		print("    ASSERTION FAILED [%s]: %s" % [_current_test, message if message != "" else "Expected %s <= %s" % [actual, than]])

func assert_has(dict: Dictionary, key: String, message: String = "") -> void:
	_assert_count += 1
	if not dict.has(key):
		_test_failed = true
		print("    ASSERTION FAILED [%s]: %s" % [_current_test, message if message != "" else "Expected dict to have key '%s'" % key])

## ============================================================
## 测试方法
## ============================================================

## 1. fragile_buff - set记录防御值, process防御-1(最低0), clear恢复, 防御0不降负数
func test_fragile_buff() -> void:
	_current_test = "test_fragile_buff"
	var c = Current
	c.player_defense = 5

	var meta = {"buff_id": "fragile", "family": "", "tags": [], "buff_icon": "", "buff_tooltip": "", "debuff_icon": "debuff_icon", "debuff_tooltip": "fragile tooltip"}
	var buff = create_and_set_buff("res://scripts/debuff/fragile_buff.gd", meta)

	# set_buff时记录了防御值_before_fragile（内部变量，通过clear_buff行为验证）
	# process_buff后防御-1
	buff.process_buff()
	assert_eq(c.player_defense, 4, "fragile: defense should be 4 after 1st process (5-1)")

	# 连续process多次防御持续下降
	buff.process_buff()
	assert_eq(c.player_defense, 3, "fragile: defense should be 3 after 2nd process")
	buff.process_buff()
	assert_eq(c.player_defense, 2, "fragile: defense should be 2 after 3rd process")
	buff.process_buff()
	assert_eq(c.player_defense, 1, "fragile: defense should be 1 after 4th process")
	buff.process_buff()
	assert_eq(c.player_defense, 0, "fragile: defense should be 0 after 5th process")

	# 防御为0时process不降到负数
	buff.process_buff()
	assert_eq(c.player_defense, 0, "fragile: defense should stay 0, not go negative")
	buff.process_buff()
	assert_eq(c.player_defense, 0, "fragile: defense should stay 0 on repeated process at 0")

	# clear_buff恢复到记录的防御值（原始值5）
	buff.clear_buff()
	assert_eq(c.player_defense, 5, "fragile: defense should restore to 5 after clear_buff")

	# 边界：初始防御为0时set再clear
	c.player_defense = 0
	var meta2 = {"buff_id": "fragile2", "family": "", "tags": [], "buff_icon": "", "buff_tooltip": "", "debuff_icon": "debuff_icon", "debuff_tooltip": "fragile tooltip"}
	var buff2 = create_and_set_buff("res://scripts/debuff/fragile_buff.gd", meta2)
	# defense=0, _before_fragile=0
	buff2.process_buff()
	assert_eq(c.player_defense, 0, "fragile: defense stays 0 when starting at 0")
	buff2.clear_buff()
	assert_eq(c.player_defense, 0, "fragile: defense restores to 0 after clear_buff (original was 0)")

## 2. attack_weaken_buff - process时分数减少20%, total_score=100减20, total_score=0不减
func test_attack_weaken_buff() -> void:
	_current_test = "test_attack_weaken_buff"
	var c = Current

	var meta = {"buff_id": "attack_weaken", "family": "", "tags": [], "buff_icon": "", "buff_tooltip": "", "debuff_icon": "debuff_icon", "debuff_tooltip": "attack score down tooltip"}
	var buff = create_and_set_buff("res://scripts/debuff/attack_weaken_buff.gd", meta)

	# total_score=100时减少20（int(100*0.20)=20）
	c.total_score = 100
	buff.process_buff()
	assert_eq(c.total_score, 80, "attack_weaken: total_score should be 80 after process (100-20)")

	# total_score=0时不减少
	c.total_score = 0
	buff.process_buff()
	assert_eq(c.total_score, 0, "attack_weaken: total_score should stay 0 when already 0")

	# total_score=50时减少10（int(50*0.20)=10）
	c.total_score = 50
	buff.process_buff()
	assert_eq(c.total_score, 40, "attack_weaken: total_score should be 40 after process (50-10)")

	# total_score=3时减少0（int(3*0.20)=int(0.6)=0）
	c.total_score = 3
	buff.process_buff()
	assert_eq(c.total_score, 3, "attack_weaken: total_score should stay 3 when int(3*0.20)=0")

	# clear_buff释放debuff_texture
	buff.clear_buff()

## 3. point_seal_buff - 禁用指定点数得分，clear时恢复
func test_point_seal_buff() -> void:
	_current_test = "test_point_seal_buff"
	var c = Current
	c.one_score = 10
	c.three_score = 20
	c.six_score = 30

	# 禁用1点和6点
	var meta = {
		"buff_id": "point_seal", "family": "", "tags": [],
		"buff_icon": "", "buff_tooltip": "", "debuff_icon": "debuff_icon", "debuff_tooltip": "disable points",
		"data": {"disabled_points": [1, 6]}
	}
	var buff = create_and_set_buff("res://scripts/debuff/point_seal_buff.gd", meta)

	# set_buff后禁用的点数分数应被设为0
	assert_eq(c.one_score, 0, "point_seal: one_score should be 0 after set_buff")
	assert_eq(c.six_score, 0, "point_seal: six_score should be 0 after set_buff")
	# 未禁用的点数不受影响
	assert_eq(c.three_score, 20, "point_seal: three_score should remain 20")

	# process_buff持续禁用：如果分数被恢复，再次设为0并累积
	c.one_score = 5
	buff.process_buff()
	assert_eq(c.one_score, 0, "point_seal: one_score should be 0 after process (re-disabled)")

	# clear_buff后恢复保存的分数
	buff.clear_buff()
	assert_eq(c.one_score, 10, "point_seal: one_score should restore to 10 after clear_buff")
	assert_eq(c.six_score, 30, "point_seal: six_score should restore to 30 after clear_buff")

## 4. type_seal_buff - 禁用指定骰型百分比，clear时恢复
func test_type_seal_buff() -> void:
	_current_test = "test_type_seal_buff"
	var c = Current
	c.duizi_percent = 30
	c.shunzi_percent = 20
	c.tongse_percent = 15

	# 禁用duizi和shunzi
	var meta = {
		"buff_id": "type_seal", "family": "", "tags": [],
		"buff_icon": "", "buff_tooltip": "", "debuff_icon": "debuff_icon", "debuff_tooltip": "disable dice type",
		"data": {"disabled_types": ["duizi", "shunzi"]}
	}
	var buff = create_and_set_buff("res://scripts/debuff/type_seal_buff.gd", meta)

	# set_buff后禁用的骰型百分比应被设为0
	assert_eq(c.duizi_percent, 0, "type_seal: duizi_percent should be 0 after set_buff")
	assert_eq(c.shunzi_percent, 0, "type_seal: shunzi_percent should be 0 after set_buff")
	# 未禁用的骰型不受影响
	assert_eq(c.tongse_percent, 15, "type_seal: tongse_percent should remain 15")

	# process_buff持续禁用：如果百分比被恢复，再次设为0
	c.duizi_percent = 10
	buff.process_buff()
	assert_eq(c.duizi_percent, 0, "type_seal: duizi_percent should be 0 after process (re-disabled)")

	# clear_buff后恢复保存的百分比
	buff.clear_buff()
	assert_eq(c.duizi_percent, 30, "type_seal: duizi_percent should restore to 30 after clear_buff")
	assert_eq(c.shunzi_percent, 20, "type_seal: shunzi_percent should restore to 20 after clear_buff")
