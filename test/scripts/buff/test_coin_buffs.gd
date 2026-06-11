extends Node
## 金币(Coin) Buff测试
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

## 1. turn_coin_increase_buff - process_buff时金币+1，调用多次金币累加
func test_turn_coin_increase_buff() -> void:
	_current_test = "test_turn_coin_increase_buff"
	var c = Current
	c.total_coins = 0

	var meta = {"buff_id": "turn_coin_increase", "family": "coin", "tags": ["turn"]}
	var buff = create_and_set_buff("res://scripts/buff/turn_coin_increase_buff.gd", meta)

	# process_buff一次，金币+1
	buff.process_buff()
	assert_eq(c.total_coins, 1, "After 1 process_buff: total_coins should be 1")

	# 多次调用金币累加
	buff.process_buff()
	assert_eq(c.total_coins, 2, "After 2 process_buff: total_coins should be 2")

	buff.process_buff()
	assert_eq(c.total_coins, 3, "After 3 process_buff: total_coins should be 3")

	# 从非零初始金币开始
	c.total_coins = 5
	buff.process_buff()
	assert_eq(c.total_coins, 6, "From 5 coins: after process_buff should be 6")

	# clear_buff无操作
	buff.clear_buff()
	assert_eq(c.total_coins, 6, "After clear_buff: total_coins should remain 6")

## 2. coin_attack_score_increase_buff - 分数 = once_total_score × coins × 0.02，0金币时分数不变
func test_coin_attack_score_increase_buff() -> void:
	_current_test = "test_coin_attack_score_increase_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 500

	var meta = {"buff_id": "coin_attack_score_increase", "family": "coin", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/coin_attack_score_increase_buff.gd", meta)

	# 0金币：0 * 0.02 * 500 = 0，分数不变
	c.total_coins = 0
	buff.process_buff()
	assert_eq(c.total_score, 0, "0 coins: total_score should not change")

	# 5金币：int(5 * 0.02 * 500) = int(50.0) = 50
	c.total_score = 0
	c.total_coins = 5
	buff.process_buff()
	assert_eq(c.total_score, int(5 * 0.02 * 500), "5 coins: score should be int(coins * 0.02 * once_total_score)")

	# 10金币：int(10 * 0.02 * 500) = int(100.0) = 100
	c.total_score = 0
	c.total_coins = 10
	buff.process_buff()
	assert_eq(c.total_score, int(10 * 0.02 * 500), "10 coins: score should be int(10 * 0.02 * 500)")

	# 1金币：int(1 * 0.02 * 500) = int(10.0) = 10
	c.total_score = 0
	c.total_coins = 1
	buff.process_buff()
	assert_eq(c.total_score, int(1 * 0.02 * 500), "1 coin: score should be int(1 * 0.02 * 500)")

## 3. golden_touch_buff - 分数 = once_total_score × (coins/5) × 0.15
func test_golden_touch_buff() -> void:
	_current_test = "test_golden_touch_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_id": "golden_touch", "family": "coin", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/golden_touch_buff.gd", meta)

	# 0金币：0/5=0, 不触发
	c.total_coins = 0
	buff.process_buff()
	assert_eq(c.total_score, 0, "0 coins: bonus_count=0, should not trigger")

	# 4金币：4/5=0（整数除法），不触发
	c.total_coins = 4
	buff.process_buff()
	assert_eq(c.total_score, 0, "4 coins: 4/5=0, should not trigger")

	# 5金币：5/5=1, 分数 = int(1000 * 1 * 0.15) = 150
	c.total_score = 0
	c.total_coins = 5
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 1 * 0.15), "5 coins: bonus_count=1, score should be int(1000 * 1 * 0.15)")

	# 10金币：10/5=2, 分数 = int(1000 * 2 * 0.15) = 300
	c.total_score = 0
	c.total_coins = 10
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 2 * 0.15), "10 coins: bonus_count=2, score should be int(1000 * 2 * 0.15)")

	# 9金币：9/5=1, 分数 = int(1000 * 1 * 0.15) = 150
	c.total_score = 0
	c.total_coins = 9
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 1 * 0.15), "9 coins: bonus_count=1, score should be int(1000 * 1 * 0.15)")

## 4. coin_storm_buff - 金币≥8时触发，分数 = target_score × 0.03
func test_coin_storm_buff() -> void:
	_current_test = "test_coin_storm_buff"
	var c = Current
	c.total_score = 0
	c.target_score = 1000

	var meta = {"buff_id": "coin_storm", "family": "coin", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/coin_storm_buff.gd", meta)

	# 7金币时不触发
	c.total_coins = 7
	buff.process_buff()
	assert_eq(c.total_score, 0, "7 coins: should not trigger (< 8)")

	# 8金币时触发，分数 = int(1000 * 0.03) = 30
	c.total_score = 0
	c.total_coins = 8
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.03), "8 coins: should trigger, score = int(target_score * 0.03)")

	# 10金币时也触发
	c.total_score = 0
	c.total_coins = 10
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.03), "10 coins: should trigger, score = int(target_score * 0.03)")

	# 0金币不触发
	c.total_score = 0
	c.total_coins = 0
	buff.process_buff()
	assert_eq(c.total_score, 0, "0 coins: should not trigger")

## 5. mint_press_buff - 金币 += slime_die_sum，slime_die_sum为0时不加
func test_mint_press_buff() -> void:
	_current_test = "test_mint_press_buff"
	var c = Current
	c.total_coins = 3

	var meta = {"buff_id": "mint_press", "family": "coin", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/mint_press_buff.gd", meta)

	# slime_die_sum为0时不加金币
	c.slime_die_sum = 0
	buff.process_buff()
	assert_eq(c.total_coins, 3, "slime_die_sum=0: total_coins should not change")

	# slime_die_sum为5时金币+5
	c.slime_die_sum = 5
	buff.process_buff()
	assert_eq(c.total_coins, 8, "slime_die_sum=5: total_coins should increase by 5")

	# slime_die_sum为1时金币+1
	c.slime_die_sum = 1
	buff.process_buff()
	assert_eq(c.total_coins, 9, "slime_die_sum=1: total_coins should increase by 1")

	# 从0金币开始
	c.total_coins = 0
	c.slime_die_sum = 3
	buff.process_buff()
	assert_eq(c.total_coins, 3, "From 0 coins with slime_die_sum=3: total_coins should be 3")

## 6. tax_collector_buff - 仅在购买后触发(_just_bought为true时)
func test_tax_collector_buff() -> void:
	_current_test = "test_tax_collector_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_id": "tax_collector", "family": "coin", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/tax_collector_buff.gd", meta)

	# 未购买时(_just_bought=false)不触发
	buff._just_bought = false
	buff.process_buff()
	assert_eq(c.total_score, 0, "_just_bought=false: should not trigger")

	# 购买后(_just_bought=true)触发，分数 = int(1000 * 0.25) = 250
	buff._just_bought = true
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.25), "_just_bought=true: score should be int(once_total_score * 0.25)")

	# 触发后_just_bought重置为false
	assert_false(buff._just_bought, "After trigger: _just_bought should be reset to false")

	# 再次process_buff不触发
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.25), "After reset: should not trigger again")

	# 再次设置_just_bought=true可以再次触发
	c.total_score = 0
	buff._just_bought = true
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.25), "Re-set _just_bought=true: should trigger again")

## 7. gold_empire_buff - 被动buff，process_buff为空（族主逻辑在buff_system）
func test_gold_empire_buff() -> void:
	_current_test = "test_gold_empire_buff"

	var meta = {"buff_id": "gold_empire", "family": "coin", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/gold_empire_buff.gd", meta)

	# 验证process_buff是被动标记（无操作）
	var c = Current
	var score_before = c.total_score
	buff.process_buff()
	assert_eq(c.total_score, score_before, "gold_empire: process_buff should not change total_score")

	# 验证coins不变
	var coins_before = c.total_coins
	buff.process_buff()
	assert_eq(c.total_coins, coins_before, "gold_empire: process_buff should not change total_coins")

	# clear_buff也是空操作
	buff.clear_buff()
	assert_eq(c.total_score, score_before, "gold_empire: clear_buff should not change total_score")

## 8. free_refresh_one_times_buff - set时zero_coin_refresh_times+1/zero_coin_refresh_max_times+1
func test_free_refresh_one_times_buff() -> void:
	_current_test = "test_free_refresh_one_times_buff"
	var c = Current
	c.zero_coin_refresh_times = 0
	c.zero_coin_refresh_max_times = 0

	var meta = {"buff_id": "free_refresh_one_times", "family": "coin", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/free_refresh_one_times_buff.gd", meta)

	# set_buff后zero_coin_refresh_times和zero_coin_refresh_max_times各+1
	assert_eq(c.zero_coin_refresh_times, 1, "After set_buff: zero_coin_refresh_times should be 1")
	assert_eq(c.zero_coin_refresh_max_times, 1, "After set_buff: zero_coin_refresh_max_times should be 1")

	# 再设置一个buff，累加
	var meta2 = {"buff_id": "free_refresh_one_times_2", "family": "coin", "tags": ["passive"], "buff_icon": "", "buff_tooltip": "test"}
	var buff2 = create_and_set_buff("res://scripts/buff/free_refresh_one_times_buff.gd", meta2)
	assert_eq(c.zero_coin_refresh_times, 2, "After 2nd set_buff: zero_coin_refresh_times should be 2")
	assert_eq(c.zero_coin_refresh_max_times, 2, "After 2nd set_buff: zero_coin_refresh_max_times should be 2")

	# process_buff无操作
	var times_before = c.zero_coin_refresh_times
	buff.process_buff()
	assert_eq(c.zero_coin_refresh_times, times_before, "After process_buff: zero_coin_refresh_times should not change")

	# clear_buff无操作（源码中clear_buff为空）
	buff.clear_buff()
	assert_eq(c.zero_coin_refresh_times, 2, "After clear_buff: zero_coin_refresh_times should remain 2")
	assert_eq(c.zero_coin_refresh_max_times, 2, "After clear_buff: zero_coin_refresh_max_times should remain 2")
