extends Node
## 冒烟测试 - 验证测试基础设施能正常工作
## 直接操作真实Current autoload属性

var _test_failed: bool = false
var _current_test: String = ""
var _assert_count: int = 0

## 测试运行器引用（由runner注入）
var test_runner: Node2D = null

func before_all() -> void:
	pass

func before_each() -> void:
	_test_failed = false
	_current_test = ""
	_assert_count = 0
	## 重置Current到默认测试值
	if test_runner:
		test_runner.reset_current_to_defaults()

func after_each() -> void:
	pass

func after_all() -> void:
	pass

## 测试1: Current autoload 可访问
func test_current_accessible() -> void:
	_current_test = "test_current_accessible"
	assert_ne(Current, null, "Current autoload should be accessible")
	assert_eq(Current.total_score, 0, "Default total_score should be 0")

## 测试2: Current 属性可设置
func test_current_properties_settable() -> void:
	_current_test = "test_current_properties_settable"
	Current.total_score = 100
	assert_eq(Current.total_score, 100, "total_score should be settable to 100")
	Current.player_hp = 3
	assert_eq(Current.player_hp, 3, "player_hp should be settable to 3")

## 测试3: Buff基类可实例化
func test_buff_base_class() -> void:
	_current_test = "test_buff_base_class"
	var meta := {"buff_id": "test", "family": "swarm", "tags": ["attack"]}
	var gm = get_node("/root/game_manager")
	var buff := Buff.new(meta, gm)
	assert_eq(buff.family, "swarm", "Buff family should be swarm")
	assert_eq(buff.tags, ["attack"], "Buff tags should match")

## 测试4: Current重置到默认值
func test_current_reset() -> void:
	_current_test = "test_current_reset"
	Current.total_score = 999
	Current.player_hp = 1
	Current.player_defense = 0
	if test_runner:
		test_runner.reset_current_to_defaults()
	assert_eq(Current.total_score, 0, "After reset: total_score should be 0")
	assert_eq(Current.player_hp, 5, "After reset: player_hp should be 5")
	assert_eq(Current.player_defense, 2, "After reset: player_defense should be 2")

## ============================================================
## Assert 方法
## ============================================================

func assert_eq(actual, expected, message: String = "") -> void:
	_assert_count += 1
	if actual != expected:
		_test_failed = true
		var msg := message if message != "" else "Expected %s but got %s" % [expected, actual]
		print("    ASSERTION FAILED [test_smoke::%s]: %s" % [_current_test, msg])

func assert_ne(actual, not_expected, message: String = "") -> void:
	_assert_count += 1
	if actual == not_expected:
		_test_failed = true
		var msg := message if message != "" else "Expected not equal to %s but got %s" % [not_expected, actual]
		print("    ASSERTION FAILED [test_smoke::%s]: %s" % [_current_test, msg])

func assert_true(value: bool, message: String = "") -> void:
	_assert_count += 1
	if not value:
		_test_failed = true
		var msg := message if message != "" else "Expected true but got false"
		print("    ASSERTION FAILED [test_smoke::%s]: %s" % [_current_test, msg])

func assert_false(value: bool, message: String = "") -> void:
	_assert_count += 1
	if value:
		_test_failed = true
		var msg := message if message != "" else "Expected false but got true"
		print("    ASSERTION FAILED [test_smoke::%s]: %s" % [_current_test, msg])
