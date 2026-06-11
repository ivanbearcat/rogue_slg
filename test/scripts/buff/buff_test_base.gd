extends Node
## BuffTestBase - 所有 buff 测试的基类
## 提供 assert 方法和 mock 游戏状态

const BuffTestHelper = preload("res://test/scripts/buff/buff_test_helper.gd")

var _test_failed: bool = false
var _current_test: String = ""
var _assert_count: int = 0

## Mock 游戏状态 - 每个测试方法前重置
var mock_current: BuffTestHelper.MockCurrent
var mock_game_manager: BuffTestHelper.MockGameManager
var mock_scene_manager: BuffTestHelper.MockSceneManager
var mock_effect_manager: BuffTestHelper.MockEffectManager
var mock_buff_system: BuffTestHelper.MockBuffSystem

func before_all() -> void:
	pass

func before_each() -> void:
	_test_failed = false
	_current_test = ""
	_assert_count = 0
	# 每次测试前创建新的 mock 实例
	mock_current = BuffTestHelper.MockCurrent.new()
	mock_game_manager = BuffTestHelper.MockGameManager.new()
	mock_scene_manager = BuffTestHelper.MockSceneManager.new()
	mock_effect_manager = BuffTestHelper.MockEffectManager.new()
	mock_buff_system = BuffTestHelper.MockBuffSystem.new()
	# 安装 mock 到全局（覆盖 autoload）
	_install_mocks()

func after_each() -> void:
	_uninstall_mocks()

func after_all() -> void:
	pass

## ============================================================
## Mock 安装/卸载
## ============================================================

var _original_current = null
var _original_scene_manager = null
var _original_effect_manager = null
var _original_buff_system = null
var _original_game_manager = null

func _install_mocks() -> void:
	# 保存原始 autoload 引用
	if Engine.has_singleton("Current"):
		_original_current = Engine.get_singleton("Current")
	# 因为 Godot autoload 机制，我们需要直接修改 _ready 中的引用
	# 更实用的方式：在创建 buff 时直接传入 mock 对象
	pass

func _uninstall_mocks() -> void:
	pass

## ============================================================
## 创建 Buff 实例（注入 mock）
## ============================================================

## 创建 buff 实例并注入 mock 依赖
func create_buff(script_path: String, meta: Dictionary = {}):
	var script := load(script_path)
	if script == null:
		_fail("Could not load script: %s" % script_path)
		return null
	var buff = script.new(meta, mock_game_manager)
	# 替换全局引用为 mock（关键步骤）
	_override_globals()
	return buff

## 覆盖全局 autoload 引用
func _override_globals() -> void:
	# Current 是全局自动加载，buff 脚本直接用 Current.xxx 访问
	# 我们无法替换自动加载本身，但可以通过修改 ProjectSettings 临时替换
	# 更实际的方式：由于 buff 脚本直接用 Current，我们需要临时替换
	# 在 Godot 4 中，autoloads 存在于 /root/ 下
	# 最简单的方式：在测试场景中先添加 mock 节点到 /root/
	pass

## ============================================================
## Assert 方法
## ============================================================

func assert_eq(actual, expected, message: String = "") -> void:
	_assert_count += 1
	if actual != expected:
		var msg := message if message != "" else "Expected %s but got %s" % [expected, actual]
		_fail(msg)

func assert_ne(actual, not_expected, message: String = "") -> void:
	_assert_count += 1
	if actual == not_expected:
		var msg := message if message != "" else "Expected not equal to %s but got %s" % [not_expected, actual]
		_fail(msg)

func assert_true(value: bool, message: String = "") -> void:
	_assert_count += 1
	if not value:
		var msg := message if message != "" else "Expected true but got false"
		_fail(msg)

func assert_false(value: bool, message: String = "") -> void:
	_assert_count += 1
	if value:
		var msg := message if message != "" else "Expected false but got true"
		_fail(msg)

func assert_gt(actual, than, message: String = "") -> void:
	_assert_count += 1
	if actual <= than:
		var msg := message if message != "" else "Expected %s > %s" % [actual, than]
		_fail(msg)

func assert_gte(actual, than, message: String = "") -> void:
	_assert_count += 1
	if actual < than:
		var msg := message if message != "" else "Expected %s >= %s" % [actual, than]
		_fail(msg)

func assert_lt(actual, than, message: String = "") -> void:
	_assert_count += 1
	if actual >= than:
		var msg := message if message != "" else "Expected %s < %s" % [actual, than]
		_fail(msg)

func assert_lte(actual, than, message: String = "") -> void:
	_assert_count += 1
	if actual > than:
		var msg := message if message != "" else "Expected %s <= %s" % [actual, than]
		_fail(msg)

func assert_has(dict: Dictionary, key: String, message: String = "") -> void:
	_assert_count += 1
	if not dict.has(key):
		var msg := message if message != "" else "Expected dict to have key '%s'" % key
		_fail(msg)

func _fail(message: String) -> void:
	_test_failed = true
	var script_name := get_script().resource_path.get_file() if get_script() else "unknown"
	print("    ASSERTION FAILED [%s::%s]: %s" % [script_name, _current_test, message])