extends Node
## 猎杀(Hunt)与进化(Evolution) Buff测试
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
## 内部辅助
## ============================================================

func _create_mock_buff(buff_id: String, family: String = "", tags: Array = []):
	var meta = {"buff_id": buff_id, "family": family, "tags": tags}
	var buff_script = load("res://scripts/buff/buff.gd")
	var gm = get_node("/root/game_manager")
	var buff = buff_script.new(meta, gm)
	return buff

func _mock_set_buff_texture(buff) -> void:
	var tex_rect = TextureRect.new()
	buff.buff_texture = tex_rect

## ============================================================
## 测试方法
## ============================================================

## 1. test_hunt_overlord_realtime_accumulation - 累积值不再陈旧，同一次do_buff中实时可读
func test_hunt_overlord_realtime_accumulation() -> void:
	_current_test = "test_hunt_overlord_realtime_accumulation"

	var bs_script = load("res://scripts/autoload/buff_system.gd")
	var bs = bs_script.new()
	var c = Current
	c.total_score = 0

	# 注册4个hunt buff + hunt_overlord到post_attack/ALWAYS
	for i in range(4):
		var buff = _create_mock_buff("hunt_%d" % i, "hunt", ["attack"])
		_mock_set_buff_texture(buff)
		bs.pipelines["post_attack"]["ALWAYS"].append(buff)

	# 注册hunt_overlord
	var overlord_meta = {"buff_id": "hunt_overlord", "family": "hunt", "tags": ["legendary"], "auto_activate": true}
	var overlord_script = load("res://scripts/buff/hunt_overlord_buff.gd")
	var gm = get_node("/root/game_manager")
	var overlord = overlord_script.new(overlord_meta, gm)
	bs.pipelines["post_attack"]["ALWAYS"].append(overlord)

	# 模拟do_buff流程：先执行普通hunt buff贡献分数，再执行overlord读取累积
	bs._current_family_accumulation.clear()

	# 模拟4个hunt buff各贡献25分（共100）
	for i in range(4):
		var buff = bs.pipelines["post_attack"]["ALWAYS"][i]
		var score_before = c.total_score
		c.total_score += 25  # 每个buff贡献25分
		bs._track_family_contribution(buff, score_before)

	# 验证当前轮累积值为100（实时）
	assert_eq(bs.get_family_accumulation("hunt"), 100, "hunt accumulation should be 100 (realtime, not stale)")

	# 执行hunt_overlord的process_buff
	# hunt_overlord会读取get_family_accumulation("hunt")=100, bonus=roundi(100*0.50)=50
	var score_before_overlord = c.total_score
	overlord.process_buff()
	# process_buff中会 Current.total_score += bonus
	# bonus = roundi(100 * 0.50) = 50
	var expected_bonus = roundi(100 * 0.50)
	assert_eq(c.total_score - score_before_overlord, expected_bonus, "hunt_overlord should add bonus=roundi(accumulation*0.50)")

	# 清理
	c.total_score = 0

## 2. test_hunt_overlord_stale_value_fixed - 验证不再读取上一轮陈旧值
func test_hunt_overlord_stale_value_fixed() -> void:
	_current_test = "test_hunt_overlord_stale_value_fixed"

	var bs_script = load("res://scripts/autoload/buff_system.gd")
	var bs = bs_script.new()
	var c = Current
	c.total_score = 0

	# 设置上一轮的累积值（陈旧值）
	bs._last_family_accumulation = {"hunt": 999}

	# do_buff开始时清空_current_family_accumulation
	bs._current_family_accumulation.clear()

	# 没有buff贡献时，get_family_accumulation应返回0（当前轮），而非999（上一轮）
	assert_eq(bs.get_family_accumulation("hunt"), 0, "get_family_accumulation should return 0 (current round), not 999 (stale last round)")

	# 清理
	bs._last_family_accumulation = {}

## 3. test_evolution_overlord_pre_hero_turn - 进化霸主在pre_hero_turn时序触发
func test_evolution_overlord_pre_hero_turn() -> void:
	_current_test = "test_evolution_overlord_pre_hero_turn"

	var bs_script = load("res://scripts/autoload/buff_system.gd")
	var bs = bs_script.new()
	var c = Current

	# 记录初始分数值
	var one_before = c.one_score
	var duizi_before = c.duizi_percent

	# 注册4个evolution buff + evolution_overlord到pre_hero_turn/ALWAYS
	for i in range(4):
		var buff = _create_mock_buff("evo_%d" % i, "evolution", ["attack"])
		_mock_set_buff_texture(buff)
		bs.pipelines["pre_hero_turn"]["ALWAYS"].append(buff)

	# 注册evolution_overlord
	var overlord_meta = {"buff_id": "evolution_overlord", "family": "evolution", "tags": ["legendary"], "auto_activate": true}
	var overlord_script = load("res://scripts/buff/evolution_overlord_buff.gd")
	var gm = get_node("/root/game_manager")
	var overlord = overlord_script.new(overlord_meta, gm)
	bs.pipelines["pre_hero_turn"]["ALWAYS"].append(overlord)

	# 验证evolution_overlord注册在pre_hero_turn管线
	assert_true(bs.is_buff_registered("evolution_overlord"), "evolution_overlord should be registered")
	var found_in_pre_hero_turn = false
	for buff in bs.pipelines["pre_hero_turn"]["ALWAYS"]:
		if buff.buff_meta.get("buff_id", "") == "evolution_overlord":
			found_in_pre_hero_turn = true
	assert_true(found_in_pre_hero_turn, "evolution_overlord should be in pre_hero_turn/ALWAYS pipeline")

	# 执行process_buff（模拟pre_hero_turn触发）
	overlord.process_buff()

	# 验证某个基础分+1（总共6个点数中随机1个）
	var score_changed = (c.one_score != one_before or c.two_score != one_before or \
		c.three_score != one_before or c.four_score != one_before or \
		c.five_score != one_before or c.six_score != one_before)
	# 注：one_before对所有6个点数都是同一个初始值，所以检查是否有任意一个变了
	var any_score_increased = false
	for score_val in [c.one_score, c.two_score, c.three_score, c.four_score, c.five_score, c.six_score]:
		if score_val == one_before + 1:
			any_score_increased = true
	assert_true(any_score_increased, "one of the six base scores should be +1")

	# 验证某个倍率+1%
	var any_percent_increased = false
	for pct_val in [c.duizi_percent, c.shunzi_percent, c.tongse_percent, c.tongdui_percent, c.tongshun_percent]:
		if pct_val == duizi_before + 1:
			any_percent_increased = true
	assert_true(any_percent_increased, "one of the five multiplier percents should be +1")

## 4. test_evolution_overlord_non_attack_turn - 非攻击回合也触发
func test_evolution_overlord_non_attack_turn() -> void:
	_current_test = "test_evolution_overlord_non_attack_turn"

	# 进化霸主注册在pre_hero_turn，每回合开始时触发
	# 即使玩家不攻击直接结束回合，pre_hero_turn仍会执行
	# 此测试验证：evolution_overlord的buff_type为pre_hero_turn_buff
	var gm = get_node("/root/game_manager")
	var buff_json_data = gm.buff_json_data
	var evo_overlord_row = null
	for row in buff_json_data:
		if row.get("buff_id", "") == "evolution_overlord":
			evo_overlord_row = row
			break
	assert_true(evo_overlord_row != null, "evolution_overlord should exist in buff_json_data")
	assert_eq(evo_overlord_row["buff_type"], "pre_hero_turn_buff", "evolution_overlord buff_type should be pre_hero_turn_buff")
