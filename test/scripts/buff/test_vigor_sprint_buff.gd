extends Node
## 旺盛疾跑(Vigor Sprint) Buff测试 - HP联动移动力判定
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

## ============================================================
## Assert方法
## ============================================================

func assert_eq(actual, expected, message: String = "") -> void:
	_assert_count += 1
	if actual != expected:
		_test_failed = true
		print("    ASSERTION FAILED [%s]: %s" % [_current_test, message if message != "" else "Expected %s but got %s" % [expected, actual]])

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

## ============================================================
## 测试方法
## ============================================================

## 1. test_vigor_sprint_hp_high_grants_move - HP≥80%时授予移动力
func test_vigor_sprint_hp_high_grants_move() -> void:
	_current_test = "test_vigor_sprint_hp_high_grants_move"
	var c = Current
	c.max_hp = 5
	c.player_hp = 5  # 100% ≥ 80%
	# 确保hero存在且有hero_movement
	if c.hero:
		c.hero.hero_movement = 0

	var meta = {"buff_id": "vigor_sprint", "family": "swift", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/vigor_sprint_buff.gd", meta)

	# process_buff应检测HP≥80%并授予+1移动力
	buff.process_buff()
	if c.hero:
		assert_eq(c.hero.hero_movement, 1, "HP=100%: hero_movement should be +1 after process_buff")

	# 再次process_buff不应重复授予（_move_granted标志）
	buff.process_buff()
	if c.hero:
		assert_eq(c.hero.hero_movement, 1, "HP=100% repeated: hero_movement should stay at 1 (no duplicate)")

	# clear_buff回退移动力
	buff.clear_buff()
	if c.hero:
		assert_eq(c.hero.hero_movement, 0, "after clear_buff: hero_movement should be 0")

## 2. test_vigor_sprint_hp_low_no_move - HP<80%时不授予移动力
func test_vigor_sprint_hp_low_no_move() -> void:
	_current_test = "test_vigor_sprint_hp_low_no_move"
	var c = Current
	c.max_hp = 5
	c.player_hp = 3  # 60% < 80%
	if c.hero:
		c.hero.hero_movement = 0

	var meta = {"buff_id": "vigor_sprint", "family": "swift", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/vigor_sprint_buff.gd", meta)

	# process_buff应检测HP<80%不授予移动力
	buff.process_buff()
	if c.hero:
		assert_eq(c.hero.hero_movement, 0, "HP=60%: hero_movement should stay 0")

	buff.clear_buff()

## 3. test_vigor_sprint_hp_change_triggers_recalc - HP变化触发重新判定
func test_vigor_sprint_hp_change_triggers_recalc() -> void:
	_current_test = "test_vigor_sprint_hp_change_triggers_recalc"
	var c = Current
	c.max_hp = 5
	c.player_hp = 5  # 100% ≥ 80%
	if c.hero:
		c.hero.hero_movement = 0

	var meta = {"buff_id": "vigor_sprint", "family": "swift", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/vigor_sprint_buff.gd", meta)

	# 初始HP≥80%，授予移动力
	buff.process_buff()
	if c.hero:
		assert_eq(c.hero.hero_movement, 1, "HP=100%: movement should be +1")

	# HP从≥80%降到<80%（如4→3，60%），通过hp_changed事件触发process_buff
	# setter发射hp_changed事件，vigor_sprint订阅了该事件
	c.player_hp = 3  # 60% < 80%
	# 事件回调会调用process_buff，检测到HP<80%移除移动力
	if c.hero:
		assert_eq(c.hero.hero_movement, 0, "HP dropped to 60%: movement should be removed (via hp_changed event)")

	# HP从<80%升到≥80%（3→4，80%），事件触发重新授予
	c.player_hp = 4  # 80% ≥ 80%
	if c.hero:
		assert_eq(c.hero.hero_movement, 1, "HP rose to 80%: movement should be re-granted (via hp_changed event)")

	buff.clear_buff()

## 4. test_vigor_sprint_hp_no_cross_threshold - HP变化但未跨越80%阈值时不改变
func test_vigor_sprint_hp_no_cross_threshold() -> void:
	_current_test = "test_vigor_sprint_hp_no_cross_threshold"
	var c = Current
	c.max_hp = 5
	c.player_hp = 5  # 100%
	if c.hero:
		c.hero.hero_movement = 0

	var meta = {"buff_id": "vigor_sprint", "family": "swift", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/vigor_sprint_buff.gd", meta)

	buff.process_buff()
	if c.hero:
		assert_eq(c.hero.hero_movement, 1, "HP=100%: movement should be +1")

	# HP从100%降到90%（5→4.5不可能，用max_hp=10）
	c.max_hp = 10
	c.player_hp = 10  # 100%
	if c.hero:
		c.hero.hero_movement = 0
	buff.process_buff()
	if c.hero:
		assert_eq(c.hero.hero_movement, 1, "HP=100% (max_hp=10): movement should be +1")

	# HP从100%降到90%（10→9），仍≥80%
	c.player_hp = 9  # 90% ≥ 80%
	if c.hero:
		assert_eq(c.hero.hero_movement, 1, "HP=90% (still ≥80%): movement should stay at 1 (no change)")

	buff.clear_buff()
