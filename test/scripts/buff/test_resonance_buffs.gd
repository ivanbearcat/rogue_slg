extends Node
## 共振(Resonance) Buff测试
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

## 创建测试用史莱姆。color 参数为场景名（如 "slime_small"、"slime_small_red"）
## 通过设置 scene_file_path 使 Tools.fetch_slime_scene 能正确提取场景名
func add_slime(grid_index: Vector2 = Vector2.ZERO, color: String = "slime_small", point: int = 1, is_power: bool = false):
	var slime = Node.new()
	slime.enemy_grid_index = grid_index
	slime.scene_file_path = "res://scenes/" + color + ".tscn"
	slime.slime_point = point
	slime.is_elite = false
	slime.is_boss = false
	Current.all_enemy_array.append(slime)
	return slime

func add_slime_in_range(grid_index: Vector2 = Vector2.ZERO, color: String = "slime_small", point: int = 1, is_power: bool = false):
	var slime = add_slime(grid_index, color, point, is_power)
	Current.skill_attack_range.append(grid_index)
	return slime

func _clear_slimes() -> void:
	Current.all_enemy_array.clear()
	Current.skill_attack_range.clear()

## ============================================================
## Assert方法
## ============================================================

func assert_eq(actual, expected, message: String = "") -> void:
	_assert_count += 1
	if actual != expected:
		_test_failed = true
		print("    FAIL [%s]: %s" % [_current_test, message if message != "" else "Expected %s got %s" % [expected, actual]])

func assert_ne(actual, not_expected, message: String = "") -> void:
	_assert_count += 1
	if actual == not_expected:
		_test_failed = true
		print("    FAIL [%s]: %s" % [_current_test, message if message != "" else "Expected not %s got %s" % [not_expected, actual]])

func assert_true(value: bool, message: String = "") -> void:
	_assert_count += 1
	if not value:
		_test_failed = true
		print("    FAIL [%s]: %s" % [_current_test, message if message != "" else "Expected true"])

func assert_false(value: bool, message: String = "") -> void:
	_assert_count += 1
	if value:
		_test_failed = true
		print("    FAIL [%s]: %s" % [_current_test, message if message != "" else "Expected false"])

func assert_gte(actual, than, message: String = "") -> void:
	_assert_count += 1
	if actual < than:
		_test_failed = true
		print("    FAIL [%s]: %s" % [_current_test, message if message != "" else "Expected %s >= %s" % [actual, than]])

func assert_approx(actual, expected, tolerance: float = 0.001, message: String = "") -> void:
	_assert_count += 1
	if abs(float(actual) - float(expected)) > tolerance:
		_test_failed = true
		print("    FAIL [%s]: %s" % [_current_test, message if message != "" else "Expected ~%s got %s" % [expected, actual]])

## ============================================================
## 测试方法
## ============================================================

## 1. color_resonance_buff - 被击杀≥2个同色→int(once×0.35); 混合色不触发; 单个不触发
func test_color_resonance_buff() -> void:
	_current_test = "test_color_resonance_buff"
	Current.once_total_score = 100
	Current.total_score = 0

	var meta = {"buff_icon": "", "buff_tooltip": "test", "family": "resonance", "tags": []}
	var buff = create_and_set_buff("res://scripts/buff/color_resonance_buff.gd", meta)

	# 同色(green)3个被击杀→触发（≥2同色）
	Current.killed_slime_colors = ["green", "green", "green"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(100 * 0.35), "3 green killed: should add int(once*0.35)")

	# 混合色→不触发
	Current.killed_slime_colors = ["green", "red"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, 0, "Mixed colors killed: should not trigger")

	# 单个同色→不触发（单个不构成"共鸣"）
	Current.killed_slime_colors = ["yellow"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, 0, "Single yellow killed: should NOT trigger (needs >=2)")

	# 2个同色→触发
	Current.killed_slime_colors = ["blue", "blue"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(100 * 0.35), "2 blue killed: should trigger")

	# 无击杀→不触发
	Current.killed_slime_colors = []
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, 0, "No kills: should not trigger")

## 2. rainbow_surge_buff - 渐进式：每色+10%，4色=+40%; 3色=+30%; 2色=+20%; 1色=+10%
func test_rainbow_surge_buff() -> void:
	_current_test = "test_rainbow_surge_buff"
	Current.once_total_score = 200
	Current.total_score = 0

	var meta = {"buff_icon": "", "buff_tooltip": "test", "family": "resonance", "tags": []}
	var buff = create_and_set_buff("res://scripts/buff/rainbow_surge_buff.gd", meta)

	# 4种颜色→+40%
	Current.killed_slime_colors = ["green", "red", "yellow", "blue"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(200 * 4 * 0.10), "4 colors: should add int(once*4*0.10)")

	# 3种颜色→+30%
	Current.killed_slime_colors = ["green", "red", "yellow"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(200 * 3 * 0.10), "3 colors: should add int(once*3*0.10)")

	# 2种颜色→+20%
	Current.killed_slime_colors = ["green", "red"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(200 * 2 * 0.10), "2 colors: should add int(once*2*0.10)")

	# 1种颜色→+10%
	Current.killed_slime_colors = ["green"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(200 * 1 * 0.10), "1 color: should add int(once*1*0.10)")

## 3. resonance_chain_buff - 延迟叠层：同色类骰型触发+10%，未触发衰减-10%
func test_resonance_chain_buff() -> void:
	_current_test = "test_resonance_chain_buff"
	Current.once_total_score = 100
	Current.total_score = 0

	var meta = {"buff_icon": "", "buff_tooltip": "test", "family": "resonance", "tags": []}
	var buff = create_and_set_buff("res://scripts/buff/resonance_chain_buff.gd", meta)

	# 首次触发 tongse：chain_multiplier=0 不加分，之后 chain_multiplier→0.10
	Current.active_dice_types = ["tongse"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(buff.chain_multiplier, 0.10, "After 1st trigger (tongse): chain_multiplier should be 0.10")
	assert_eq(Current.total_score, 0, "First trigger: should NOT add score (delayed)")

	# 第二次触发 tongse：先应用 chain_multiplier=0.10 加分，之后 chain_multiplier→0.20
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(buff.chain_multiplier, 0.20, "After 2nd trigger: chain_multiplier should be 0.20")
	assert_eq(Current.total_score, int(100 * 0.10), "2nd attack: should add int(once*0.10)")

	# 第三次未触发（仅 duizi）：先应用 chain_multiplier=0.20 加分，之后衰减到 0.10
	Current.active_dice_types = ["duizi"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(buff.chain_multiplier, 0.10, "After no trigger (duizi): chain_multiplier should decay to 0.10")
	assert_eq(Current.total_score, int(100 * 0.20), "3rd attack: should add int(once*0.20)")

	# chain_multiplier=0 时未触发：保持 0.0
	buff.chain_multiplier = 0.0
	Current.active_dice_types = ["duizi"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(buff.chain_multiplier, 0.0, "At 0 with no trigger: should stay 0.0")
	assert_eq(Current.total_score, 0, "At 0 with no trigger: no score")

	# tongdui 触发
	Current.active_dice_types = ["tongdui"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(buff.chain_multiplier, 0.10, "After tongdui trigger: chain_multiplier should be 0.10")

	# tongshun 触发
	Current.active_dice_types = ["tongshun"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(buff.chain_multiplier, 0.20, "After tongshun trigger: chain_multiplier should be 0.20")

	# clear_buff 重置
	buff.clear_buff()
	assert_eq(buff.chain_multiplier, 0.0, "After clear_buff: chain_multiplier should be 0.0")

## 4. dice_mastery_buff - 纯色精通：被击杀同色≥3只+15%，≥4只+30%，≥5只+50%
func test_dice_mastery_buff() -> void:
	_current_test = "test_dice_mastery_buff"
	Current.once_total_score = 200
	Current.total_score = 0

	var meta = {"buff_icon": "", "buff_tooltip": "test", "family": "resonance", "tags": []}
	var buff = create_and_set_buff("res://scripts/buff/dice_mastery_buff.gd", meta)

	# 同色≥5只→+50%
	Current.killed_slime_colors = ["green", "green", "green", "green", "green"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(200 * 0.50), "5 green killed: should add int(once*0.50)")

	# 同色=4只→+30%
	Current.killed_slime_colors = ["green", "green", "green", "green"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(200 * 0.30), "4 green killed: should add int(once*0.30)")

	# 同色=3只→+15%
	Current.killed_slime_colors = ["green", "green", "green"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(200 * 0.15), "3 green killed: should add int(once*0.15)")

	# 同色=2只→不触发
	Current.killed_slime_colors = ["green", "green"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, 0, "2 green killed: should not trigger")

	# 混合色（3蓝+2绿）→取蓝色3只→+15%
	Current.killed_slime_colors = ["blue", "blue", "blue", "green", "green"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(200 * 0.15), "3 blue + 2 green killed: should add int(once*0.15)")

	# 无击杀→不触发
	Current.killed_slime_colors = []
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, 0, "No kills: should not trigger")

## 5. resonance_overlord_buff - ≥4门槛 + 永久ramp延迟应用
func test_resonance_overlord_buff() -> void:
	_current_test = "test_resonance_overlord_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_icon": "", "buff_tooltip": "test", "family": "resonance", "tags": ["legendary", "multiplicative"]}
	var buff = create_and_set_buff("res://scripts/buff/resonance_overlord_buff.gd", meta)

	## 创建用于测试的 resonance buff
	var resonance_meta = {"buff_icon": "", "buff_tooltip": "test", "family": "resonance", "tags": []}
	var resonance_buff = create_and_set_buff("res://scripts/buff/color_resonance_buff.gd", resonance_meta)

	## --- <4 门槛时：ramp 不累加，overlord 不加分 ---
	# 清空 pipelines 确保无 resonance buff 注册
	for timing in BuffSystem.TIMINGS:
		for key in BuffSystem.LIFECYCLE_KEYS:
			BuffSystem.pipelines[timing][key].clear()
	BuffSystem.resonance_ramp = 0.0
	c.total_score = 100
	BuffSystem._track_family_contribution(resonance_buff, 50, {})
	assert_eq(BuffSystem.resonance_ramp, 0.0, "<4 buffs: positive delta should NOT increase ramp")

	BuffSystem.resonance_ramp = 0.05
	c.once_total_score = 1000
	c.total_score = 0
	buff.process_buff()
	assert_eq(c.total_score, 0, "<4 buffs: overlord should NOT add score even with ramp>0")

	## --- ≥4 门槛时：ramp 累加 +0.01，overlord 应用 ramp ---
	# 注册 4 个 resonance buff 到 post_attack ALWAYS 管线
	for i in range(4):
		var dummy = create_and_set_buff("res://scripts/buff/color_resonance_buff.gd", resonance_meta)
		BuffSystem.set_post_attack_buff(dummy, BuffSystem.buff_type.ALWAYS)
	assert_eq(BuffSystem.get_family_count("resonance"), 4, "Should have 4 resonance buffs registered")

	# 正向贡献 → ramp += 0.01
	BuffSystem.resonance_ramp = 0.0
	c.total_score = 100
	BuffSystem._track_family_contribution(resonance_buff, 50, {})
	assert_approx(BuffSystem.resonance_ramp, 0.01, 0.001, "≥4 buffs: positive delta should increase ramp by 0.01")

	# 无贡献 → ramp 不变
	var ramp_before = BuffSystem.resonance_ramp
	c.total_score = 100
	BuffSystem._track_family_contribution(resonance_buff, 100, {})
	assert_eq(BuffSystem.resonance_ramp, ramp_before, "Zero delta: ramp should not change")

	# 负贡献 → ramp 不变
	c.total_score = 40
	BuffSystem._track_family_contribution(resonance_buff, 50, {})
	assert_eq(BuffSystem.resonance_ramp, ramp_before, "Negative delta: ramp should not change")

	## --- ramp 无上限 ---
	BuffSystem.resonance_ramp = 0.0
	c.total_score = 100
	for i in range(100):
		BuffSystem._track_family_contribution(resonance_buff, 50, {})
	assert_approx(BuffSystem.resonance_ramp, 1.0, 0.001, "100 positive contributions: ramp should be ~1.0 (no cap)")

	## --- ramp 跨 clear_stage_buff 保留 ---
	BuffSystem.resonance_ramp = 0.05
	BuffSystem.clear_stage_buff()
	assert_approx(BuffSystem.resonance_ramp, 0.05, 0.001, "clear_stage_buff should NOT reset resonance_ramp")

	## --- overlord process_buff 应用 ramp ---
	# 重新注册 4 个（clear_stage_buff 清了 STAGE，但 ALWAYS 也在 clear_elite_buff 中被清了？）
	for timing in BuffSystem.TIMINGS:
		for key in BuffSystem.LIFECYCLE_KEYS:
			BuffSystem.pipelines[timing][key].clear()
	for i in range(4):
		var dummy = create_and_set_buff("res://scripts/buff/color_resonance_buff.gd", resonance_meta)
		BuffSystem.set_post_attack_buff(dummy, BuffSystem.buff_type.ALWAYS)

	BuffSystem.resonance_ramp = 0.05
	c.once_total_score = 1000
	c.total_score = 0
	buff.process_buff()
	assert_eq(c.total_score, roundi(1000 * 0.05), "≥4 buffs with ramp=0.05: should add roundi(once*0.05)")

	# ramp = 0 时不加分
	BuffSystem.resonance_ramp = 0.0
	c.total_score = 0
	buff.process_buff()
	assert_eq(c.total_score, 0, "ramp=0: overlord should not add score")

	# 清理
	for timing in BuffSystem.TIMINGS:
		for key in BuffSystem.LIFECYCLE_KEYS:
			BuffSystem.pipelines[timing][key].clear()
	buff.clear_buff()
	BuffSystem.resonance_ramp = 0.0

## 6. four_color_resonance_buff - 被击杀4色齐备→+100%；3色不触发
func test_four_color_resonance_buff() -> void:
	_current_test = "test_four_color_resonance_buff"
	Current.once_total_score = 200
	Current.total_score = 0

	var meta = {"buff_icon": "", "buff_tooltip": "test", "family": "resonance", "tags": []}
	var buff = create_and_set_buff("res://scripts/buff/four_color_resonance_buff.gd", meta)

	# 4色齐备→+100%
	Current.killed_slime_colors = ["green", "red", "yellow", "blue"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(200 * 1.0), "4 colors killed: should add int(once*1.0)")

	# 仅3色→不触发
	Current.killed_slime_colors = ["green", "red", "yellow"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, 0, "3 colors killed: should NOT trigger")

	# 无击杀→不触发
	Current.killed_slime_colors = []
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, 0, "No kills: should NOT trigger")

## 7. chromatic_frenzy_buff - ≥3色+30%，≤1色-5%，2色无效果
func test_chromatic_frenzy_buff() -> void:
	_current_test = "test_chromatic_frenzy_buff"
	Current.once_total_score = 100
	Current.total_score = 0

	var meta = {"buff_icon": "", "buff_tooltip": "test", "family": "resonance", "tags": []}
	var buff = create_and_set_buff("res://scripts/buff/chromatic_frenzy_buff.gd", meta)

	# ≥3色→+30%
	Current.killed_slime_colors = ["green", "red", "yellow"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(100 * 0.30), "3 colors killed: should add int(once*0.30)")

	# ≤1色→-5%
	Current.killed_slime_colors = ["green"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(100 * -0.05), "1 color killed: should add int(once*-0.05)")

	# 2色→无效果
	Current.killed_slime_colors = ["green", "red"]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, 0, "2 colors killed: should not change score")

	# 无击杀→-5%（0色≤1色）
	Current.killed_slime_colors = []
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(100 * -0.05), "0 colors killed: should add int(once*-0.05)")
