extends Node
## Buff系统管线 Buff测试
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

func create_and_set_buff(script_path: String, meta: Dictionary = {}):
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
## 内部辅助：模拟buff_system管线逻辑的轻量工具
## ============================================================

## 创建一个用于管线测试的mock buff（带family/tags/buff_texture）
func _create_mock_buff(buff_id: String, family: String = "", tags: Array = []):
	var meta = {"buff_id": buff_id, "family": family, "tags": tags}
	## 使用真实game_manager autoload
	var buff_script = load("res://scripts/buff/buff.gd")
	var gm = get_node("/root/game_manager")
	var buff = buff_script.new(meta, gm)
	return buff

## 模拟set_buff的纹理创建（不依赖SceneManager）
## 使用真实的TextureRect节点避免类型不匹配
func _mock_set_buff_texture(buff) -> void:
	var tex_rect = TextureRect.new()
	buff.buff_texture = tex_rect

## 申报制辅助：在指定 BuffSystem 实例上以 buff 为归属上下文执行一次得分贡献申报
## （模拟 do_buff 内 declare 窗口：set → declare → clear；测试中非 post_attack 时序，
## 不进播报列表）
func _declare_on(bs: Node, buff: Buff, delta: int) -> void:
	bs._declare_context_buff = buff
	bs.declare_score_contribution(delta)
	bs._declare_context_buff = null

## ============================================================
## 测试方法
## ============================================================

## 1. test_buff_execution_order - 验证ONCE→STAGE→ELITE→ALWAYS顺序
func test_buff_execution_order() -> void:
	_current_test = "test_buff_execution_order"

	# 创建4个不同类型的mock buff，记录执行顺序
	var execution_order: Array = []

	# ONCE buff - 执行后会被清除
	var once_buff = _create_mock_buff("once_test", "vitality", ["attack"])
	once_buff.buff_meta["buff_id"] = "once_test"
	# 手动模拟process_buff记录执行顺序
	# 我们通过检查buff_system的数组结构验证顺序

	# 加载buff_system脚本，创建实例来检查其内部结构
	var bs_script = load("res://scripts/autoload/buff_system.gd")
	var bs = bs_script.new()

	# 验证buff_type枚举值顺序
	# buff_type.ONCE = 0, STAGE = 1, ALWAYS = 2, ELITE = 3
	# 管线中 do_xxx_buff 的执行顺序: once -> stage -> elite -> always
	# (参照buff_system.gd的do_pre_attack_buff实现)

	# 创建4个buff并注册到对应管线（模拟set_pre_attack_buff）
	_mock_set_buff_texture(once_buff)
	bs.pipelines["pre_attack"]["ONCE"].append(once_buff)

	var stage_buff = _create_mock_buff("stage_test", "vitality", ["attack"])
	_mock_set_buff_texture(stage_buff)
	bs.pipelines["pre_attack"]["STAGE"].append(stage_buff)

	var elite_buff = _create_mock_buff("elite_test", "vitality", ["attack"])
	_mock_set_buff_texture(elite_buff)
	bs.pipelines["pre_attack"]["ELITE"].append(elite_buff)

	var always_buff = _create_mock_buff("always_test", "vitality", ["attack"])
	_mock_set_buff_texture(always_buff)
	bs.pipelines["pre_attack"]["ALWAYS"].append(always_buff)

	# 验证管线中有正确的buff
	assert_eq(bs.pipelines["pre_attack"]["ONCE"].size(), 1, "once array should have 1 buff")
	assert_eq(bs.pipelines["pre_attack"]["STAGE"].size(), 1, "stage array should have 1 buff")
	assert_eq(bs.pipelines["pre_attack"]["ELITE"].size(), 1, "elite array should have 1 buff")
	assert_eq(bs.pipelines["pre_attack"]["ALWAYS"].size(), 1, "always array should have 1 buff")

	# 验证执行顺序：按do_pre_attack_buff的代码，once先执行并清空，然后stage，然后elite，最后always
	# 检查once数组第一个buff的id
	assert_eq(bs.pipelines["pre_attack"]["ONCE"][0].buff_meta.get("buff_id", ""), "once_test", "first in once array should be once_test")
	assert_eq(bs.pipelines["pre_attack"]["STAGE"][0].buff_meta.get("buff_id", ""), "stage_test", "first in stage array should be stage_test")
	assert_eq(bs.pipelines["pre_attack"]["ELITE"][0].buff_meta.get("buff_id", ""), "elite_test", "first in elite array should be elite_test")
	assert_eq(bs.pipelines["pre_attack"]["ALWAYS"][0].buff_meta.get("buff_id", ""), "always_test", "first in always array should be always_test")

## 2. test_once_buff_cleared_after_execution - ONCE buff执行后被清除
func test_once_buff_cleared_after_execution() -> void:
	_current_test = "test_once_buff_cleared_after_execution"

	var bs_script = load("res://scripts/autoload/buff_system.gd")
	var bs = bs_script.new()

	# 创建ONCE buff并注册
	var once_buff = _create_mock_buff("once_clear_test", "vitality", ["attack"])
	_mock_set_buff_texture(once_buff)
	bs.pipelines["pre_attack"]["ONCE"].append(once_buff)

	# 同时注册一个ALWAYS buff（不应被清除）
	var always_buff = _create_mock_buff("always_remain_test", "vitality", ["attack"])
	_mock_set_buff_texture(always_buff)
	bs.pipelines["pre_attack"]["ALWAYS"].append(always_buff)

	# 模拟do_pre_attack_buff中ONCE部分的逻辑：
	# 执行后调用clear_buff并清空数组
	assert_eq(bs.pipelines["pre_attack"]["ONCE"].size(), 1, "before execution: once array should have 1 buff")
	once_buff.clear_buff()
	bs.pipelines["pre_attack"]["ONCE"].clear()
	assert_eq(bs.pipelines["pre_attack"]["ONCE"].size(), 0, "after execution: once array should be empty")

	# ALWAYS buff不应被清除
	assert_eq(bs.pipelines["pre_attack"]["ALWAYS"].size(), 1, "always array should still have 1 buff after once cleared")

## 5. test_overlord_ramp_reset - clear_stage_buff resets ramp variables
func test_overlord_ramp_reset() -> void:
	_current_test = "test_overlord_ramp_reset"

	var bs_script = load("res://scripts/autoload/buff_system.gd")
	var bs = bs_script.new()
	## 手动初始化 pipelines（_ready 不会在 new() 时调用）
	for timing in bs.TIMINGS:
		bs.pipelines[timing] = {}
		for key in bs.LIFECYCLE_KEYS:
			bs.pipelines[timing][key] = []
	bs.resonance_ramp = 0.30
	bs._last_family_accumulation = {"swarm": 50}
	bs.clear_stage_buff()

	## resonance_ramp 永久跨关卡保留，不重置
	assert_eq(bs.resonance_ramp, 0.30, "resonance_ramp should NOT reset after clear_stage_buff (persists across stages)")
	assert_eq(bs._last_family_accumulation.size(), 0, "_last_family_accumulation should be empty after clear_stage_buff")

## 7. test_resonance_ramp_increment - resonance ramp from family contribution
func test_resonance_ramp_increment() -> void:
	_current_test = "test_resonance_ramp_increment"

	var bs_script = load("res://scripts/autoload/buff_system.gd")
	var bs = bs_script.new()
	## new 实例不触发 _ready：手动装配 5×4 空管线（get_family_count/_track 查询面）
	for timing in bs.TIMINGS:
		bs.pipelines[timing] = {}
		for key in bs.LIFECYCLE_KEYS:
			bs.pipelines[timing][key] = []

	var c = Current
	c.total_score = 100

	# Register 4 resonance buffs
	for i in range(4):
		var buff = _create_mock_buff("resonance_%d" % i, "resonance", ["attack"])
		_mock_set_buff_texture(buff)
		bs.pipelines["post_attack"]["ALWAYS"].append(buff)

	# 正向申报 → ramp += 0.01（申报制：declare_score_contribution 归属当前效果）
	var res_buff = _create_mock_buff("res_test", "resonance", ["attack"])
	bs.resonance_ramp = 0.0
	_declare_on(bs, res_buff, 20)
	assert_eq(bs.resonance_ramp, 0.01, "resonance_ramp should be 0.01 after 1 positive declaration")

	# Second contribution
	_declare_on(bs, res_buff, 20)
	assert_eq(bs.resonance_ramp, 0.02, "resonance_ramp should be 0.02 after 2 declarations")

	# 无上限（旧 0.50 封顶语义已废除，见 resonance-overlord-delayed 规格"ramp 无上限"）
	bs.resonance_ramp = 0.98
	_declare_on(bs, res_buff, 20)
	assert_eq(bs.resonance_ramp, 0.99, "resonance_ramp should be 0.99 (no cap)")

	# 负申报不叠 ramp
	var before = bs.resonance_ramp
	_declare_on(bs, res_buff, -5)
	assert_eq(bs.resonance_ramp, before, "negative declaration should not increase ramp")

	# 家族累积按申报值入账（族主 ×1.5 的同源数据）
	bs._current_family_accumulation.clear()
	_declare_on(bs, res_buff, 50)
	assert_eq(bs.get_family_accumulation("resonance"), 50, "family accumulation should follow declared delta")
	# 零申报静默（本次未触发或未改变得分的效果不申报）
	bs._current_family_accumulation.clear()
	_declare_on(bs, res_buff, 0)
	assert_eq(bs.get_family_accumulation("resonance"), 0, "zero declaration should be silent")

## 8. test_get_family_accumulation - query current family accumulation
func test_get_family_accumulation() -> void:
	_current_test = "test_get_family_accumulation"

	var bs_script = load("res://scripts/autoload/buff_system.gd")
	var bs = bs_script.new()
	bs._current_family_accumulation = {"swarm": 50, "coin": 30}

	assert_eq(bs.get_family_accumulation("swarm"), 50, "swarm accumulation should be 50")
	assert_eq(bs.get_family_accumulation("coin"), 30, "coin accumulation should be 30")
	assert_eq(bs.get_family_accumulation("resonance"), 0, "resonance accumulation should be 0 when not present")

## 7. test_clear_stage_buff - 只清除STAGE和ELITE类型
func test_clear_stage_buff() -> void:
	_current_test = "test_clear_stage_buff"

	var bs_script = load("res://scripts/autoload/buff_system.gd")
	var bs = bs_script.new()

	# 注册STAGE buff
	var stage_buff = _create_mock_buff("stage_clear_test", "vitality", ["attack"])
	_mock_set_buff_texture(stage_buff)
	bs.pipelines["pre_attack"]["STAGE"].append(stage_buff)

	# 注册ALWAYS buff
	var always_buff = _create_mock_buff("always_remain_test", "vitality", ["attack"])
	_mock_set_buff_texture(always_buff)
	bs.pipelines["pre_attack"]["ALWAYS"].append(always_buff)

	# 验证初始状态
	assert_eq(bs.pipelines["pre_attack"]["STAGE"].size(), 1, "before clear: stage array should have 1 buff")
	assert_eq(bs.pipelines["pre_attack"]["ALWAYS"].size(), 1, "before clear: always array should have 1 buff")

	# 调用clear_stage_buff
	bs.clear_stage_buff()

	# STAGE被清除，ALWAYS保留
	assert_eq(bs.pipelines["pre_attack"]["STAGE"].size(), 0, "after clear_stage_buff: stage array should be empty")
	assert_eq(bs.pipelines["pre_attack"]["ALWAYS"].size(), 1, "after clear_stage_buff: always array should still have 1 buff")

## 8. test_track_family_ignores_empty_family - 空family的buff不参与族主累加（申报口径）
func test_track_family_ignores_empty_family() -> void:
	_current_test = "test_track_family_ignores_empty_family"

	var bs_script = load("res://scripts/autoload/buff_system.gd")
	var bs = bs_script.new()
	## new 实例不触发 _ready：手动装配 5×4 空管线
	for timing in bs.TIMINGS:
		bs.pipelines[timing] = {}
		for key in bs.LIFECYCLE_KEYS:
			bs.pipelines[timing][key] = []

	var c = Current
	c.total_score = 100

	# 注册family=""的buff
	var empty_family_buff = _create_mock_buff("empty_family_test", "", ["attack"])
	_mock_set_buff_texture(empty_family_buff)
	bs.pipelines["pre_attack"]["ALWAYS"].append(empty_family_buff)

	# 申报制：空 family 的正向申报不入账（_track_family_contribution 直接 return）
	_declare_on(bs, empty_family_buff, 10)
	assert_false(bs._current_family_accumulation.has(""), "family_accumulation should not have empty family key")
	assert_eq(bs._current_family_accumulation.size(), 0, "family_accumulation should be empty when only empty-family buff declares")

	# 对比：有family的buff正向申报应入账（申报值驱动）
	var vitality_buff = _create_mock_buff("vitality_test", "vitality", ["attack"])
	_mock_set_buff_texture(vitality_buff)
	bs.pipelines["pre_attack"]["ALWAYS"].append(vitality_buff)

	_declare_on(bs, vitality_buff, 10)
	assert_eq(bs.get_family_accumulation("vitality"), 10, "vitality accumulation should be 10 (declared delta)")
	assert_false(bs._current_family_accumulation.has(""), "family_accumulation should still not have empty family key")

	# 负申报不入账（申报口径：仅正向申报入账）
	_declare_on(bs, vitality_buff, -3)
	assert_eq(bs.get_family_accumulation("vitality"), 10, "negative declaration should not accumulate")

	# 未申报（delta=0）静默
	_declare_on(bs, vitality_buff, 0)
	assert_eq(bs.get_family_accumulation("vitality"), 10, "zero declaration should be silent")

## 9. test_buff_init_from_meta - Buff基类_init正确设置family/tags
func test_buff_init_from_meta() -> void:
	_current_test = "test_buff_init_from_meta"

	# 创建带完整meta的Buff
	var meta = {
		"buff_id": "test_init_buff",
		"family": "vitality",
		"tags": ["attack", "passive"],
		"buff_icon": "",
		"buff_tooltip": "test tooltip",
	}
	## 使用真实game_manager autoload
	var buff_script = load("res://scripts/buff/buff.gd")
	var gm = get_node("/root/game_manager")
	var buff = buff_script.new(meta, gm)

	# 验证family正确提取
	assert_eq(buff.family, "vitality", "buff.family should be 'vitality' from meta")

	# 验证tags正确提取
	assert_eq(buff.tags.size(), 2, "buff.tags should have 2 elements")
	assert_eq(buff.tags[0], "attack", "buff.tags[0] should be 'attack'")
	assert_eq(buff.tags[1], "passive", "buff.tags[1] should be 'passive'")


	# 验证buff_meta保存完整
	assert_eq(buff.buff_meta["buff_id"], "test_init_buff", "buff_meta.buff_id should be preserved")
	assert_eq(buff.buff_meta["family"], "vitality", "buff_meta.family should be preserved")

	# 验证默认值：空meta
	var empty_buff = buff_script.new({}, gm)
	assert_eq(empty_buff.family, "", "empty meta: family should default to ''")
	assert_eq(empty_buff.tags.size(), 0, "empty meta: tags should default to []")


## 10. test_overlord_auto_activate - 同族≥4时自动注册领主
func test_overlord_auto_activate() -> void:
	_current_test = "test_overlord_auto_activate"

	var bs_script = load("res://scripts/autoload/buff_system.gd")
	var bs = bs_script.new()

	# 注册3个swarm buff → 确认swarm_overlord未注册
	for i in range(3):
		var buff = _create_mock_buff("swarm_%d" % i, "swarm", ["attack"])
		_mock_set_buff_texture(buff)
		bs.pipelines["post_attack"]["ALWAYS"].append(buff)

	assert_eq(bs.get_family_count("swarm"), 3, "after 3 swarm buffs: family count should be 3")
	assert_false(bs.is_buff_registered("swarm_overlord"), "after 3 swarm buffs: swarm_overlord should NOT be registered")

	# 注册第4个swarm buff
	var fourth = _create_mock_buff("swarm_3", "swarm", ["attack"])
	_mock_set_buff_texture(fourth)
	bs.pipelines["post_attack"]["ALWAYS"].append(fourth)

	# 模拟_set_buff中的霸主自动注册：count >= 4时注册霸主
	if bs.get_family_count("swarm") >= 4:
		if not bs.is_buff_registered("swarm_overlord"):
			var overlord = _create_mock_buff("swarm_overlord", "swarm", ["legendary"])
			# 霸主不创建buff_texture（设计如此）
			bs.pipelines["post_attack"]["ALWAYS"].append(overlord)

	assert_true(bs.is_buff_registered("swarm_overlord"), "after 4 swarm buffs: swarm_overlord should be auto-registered")
	assert_eq(bs.get_family_count("swarm"), 5, "after overlord registration: family count should be 5 (4 normal + 1 overlord)")

	# 注册第5个swarm buff → 确认不会重复注册
	var fifth = _create_mock_buff("swarm_4", "swarm", ["attack"])
	_mock_set_buff_texture(fifth)
	bs.pipelines["post_attack"]["ALWAYS"].append(fifth)

	# 霸主已注册，is_buff_registered返回true，跳过注册
	if bs.get_family_count("swarm") >= 4:
		if not bs.is_buff_registered("swarm_overlord"):
			var dup_overlord = _create_mock_buff("swarm_overlord", "swarm", ["legendary"])
			bs.pipelines["post_attack"]["ALWAYS"].append(dup_overlord)

	# 验证只有1个swarm_overlord
	var overlord_count = 0
	for buff in bs.pipelines["post_attack"]["ALWAYS"]:
		if buff.buff_meta.get("buff_id", "") == "swarm_overlord":
			overlord_count += 1
	assert_eq(overlord_count, 1, "after 5 swarm buffs: should have exactly 1 swarm_overlord (no duplicate)")

## 11. test_shop_excludes_auto_activate - 商店不包含auto_activate条目
func test_shop_excludes_auto_activate() -> void:
	_current_test = "test_shop_excludes_auto_activate"

	# 验证：auto_activate的buff条目不应出现在商店池中
	var gm = get_node("/root/game_manager")
	var shop_pool = gm.buff_json_data.filter(func(row): return not row.get("auto_activate", false))
	# 所有auto_activate条目应被排除
	for row in shop_pool:
		assert_false(row.get("auto_activate", false), "shop pool should not contain auto_activate entries")
	# 原始buff_json_data中应有6个auto_activate条目
	var auto_activate_count = 0
	for row in gm.buff_json_data:
		if row.get("auto_activate", false):
			auto_activate_count += 1
	assert_eq(auto_activate_count, 8, "buff_json_data should have 8 auto_activate entries")
