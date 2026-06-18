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

## 1. triple_round_toll_buff - count_round % 3 == 0时金币+3，否则不变
func test_triple_round_toll_buff() -> void:
	_current_test = "test_triple_round_toll_buff"
	var c = Current
	c.total_coins = 0

	var meta = {"buff_id": "triple_round_toll", "family": "coin", "tags": ["turn"]}
	var buff = create_and_set_buff("res://scripts/buff/triple_round_toll_buff.gd", meta)

	# count_round % 3 == 0 时（round 0），金币+3
	c.count_round = 0
	buff.process_buff()
	assert_eq(c.total_coins, 3, "Round 0 (0%%3==0): total_coins should be 3")

	# count_round % 3 != 0 时，金币不变
	c.count_round = 1
	buff.process_buff()
	assert_eq(c.total_coins, 3, "Round 1 (1%%3!=0): total_coins should remain 3")

	c.count_round = 2
	buff.process_buff()
	assert_eq(c.total_coins, 3, "Round 2 (2%%3!=0): total_coins should remain 3")

	# count_round % 3 == 0 时（round 3），金币再+3
	c.count_round = 3
	buff.process_buff()
	assert_eq(c.total_coins, 6, "Round 3 (3%%3==0): total_coins should be 6")

	# count_round % 3 == 0 时（round 6），金币再+3
	c.count_round = 6
	buff.process_buff()
	assert_eq(c.total_coins, 9, "Round 6 (6%%3==0): total_coins should be 9")

	# 从非零初始金币开始
	c.total_coins = 5
	c.count_round = 9
	buff.process_buff()
	assert_eq(c.total_coins, 8, "From 5 coins, round 9 (9%%3==0): total_coins should be 8")

	# clear_buff无操作
	buff.clear_buff()
	assert_eq(c.total_coins, 8, "After clear_buff: total_coins should remain 8")

## 2. coin_mirror_score_buff - total_score += total_coins * 3（金币×3加成分数）
func test_coin_mirror_score_buff() -> void:
	_current_test = "test_coin_mirror_score_buff"
	var c = Current
	c.total_score = 0

	var meta = {"buff_id": "coin_mirror_score", "family": "coin", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/coin_mirror_score_buff.gd", meta)

	# 0金币：total_score += 0*3，分数不变
	c.total_coins = 0
	buff.process_buff()
	assert_eq(c.total_score, 0, "0 coins: total_score should not change")

	# 5金币：total_score += 5*3 = 15
	c.total_score = 0
	c.total_coins = 5
	buff.process_buff()
	assert_eq(c.total_score, 15, "5 coins: total_score should be 15")

	# 10金币：total_score += 10*3 = 30
	c.total_score = 0
	c.total_coins = 10
	buff.process_buff()
	assert_eq(c.total_score, 30, "10 coins: total_score should be 30")

	# 1金币：total_score += 1*3 = 3
	c.total_score = 0
	c.total_coins = 1
	buff.process_buff()
	assert_eq(c.total_score, 3, "1 coin: total_score should be 3")

	# 从非零分数开始，累加
	c.total_score = 100
	c.total_coins = 3
	buff.process_buff()
	assert_eq(c.total_score, 109, "From 100 score with 3 coins: total_score should be 109")

## 3. golden_touch_buff - process_buff不做任何事（效果在外部流程中执行）
func test_golden_touch_buff() -> void:
	_current_test = "test_golden_touch_buff"
	var c = Current
	c.total_score = 0
	c.total_coins = 10
	c.once_total_score = 1000

	var meta = {"buff_id": "golden_touch", "family": "coin", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/golden_touch_buff.gd", meta)

	# process_buff是pass，不应改变任何状态
	var score_before = c.total_score
	var coins_before = c.total_coins
	buff.process_buff()
	assert_eq(c.total_score, score_before, "golden_touch process_buff: total_score should not change")
	assert_eq(c.total_coins, coins_before, "golden_touch process_buff: total_coins should not change")

	# clear_buff也是pass
	buff.clear_buff()
	assert_eq(c.total_score, score_before, "golden_touch clear_buff: total_score should not change")
	assert_eq(c.total_coins, coins_before, "golden_touch clear_buff: total_coins should not change")

## 4. coin_storm_buff - 50%概率金币+2，process_buff不崩溃
func test_coin_storm_buff() -> void:
	_current_test = "test_coin_storm_buff"
	var c = Current
	c.total_coins = 5

	var meta = {"buff_id": "coin_storm", "family": "coin", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/coin_storm_buff.gd", meta)

	# coin_storm_buff使用randf() < 0.5概率触发，无法确定性测试
	# 验证process_buff调用不会崩溃
	# 注意：process_buff含await，在测试中调用不会阻塞
	buff.process_buff()
	# 只验证process_buff不崩溃，金币值可能+2或不变
	assert_true(c.total_coins >= 5, "coin_storm process_buff: total_coins should be >= 5 (may or may not add 2)")
	assert_true(c.total_coins <= 7, "coin_storm process_buff: total_coins should be <= 7 (at most +2)")

	# clear_buff无操作
	buff.clear_buff()

## 5. mint_press_buff - slime_die_sum >= 3时金币+2，<3时不变
func test_mint_press_buff() -> void:
	_current_test = "test_mint_press_buff"
	var c = Current
	c.total_coins = 3

	var meta = {"buff_id": "mint_press", "family": "coin", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/mint_press_buff.gd", meta)

	# slime_die_sum < 3时不加金币
	c.slime_die_sum = 0
	buff.process_buff()
	assert_eq(c.total_coins, 3, "slime_die_sum=0: total_coins should not change")

	c.slime_die_sum = 2
	buff.process_buff()
	assert_eq(c.total_coins, 3, "slime_die_sum=2: total_coins should not change")

	# slime_die_sum == 3时金币+2
	c.slime_die_sum = 3
	buff.process_buff()
	assert_eq(c.total_coins, 5, "slime_die_sum=3: total_coins should increase by 2")

	# slime_die_sum > 3时金币+2
	c.total_coins = 3
	c.slime_die_sum = 7
	buff.process_buff()
	assert_eq(c.total_coins, 5, "slime_die_sum=7: total_coins should increase by 2")

	# 从0金币开始
	c.total_coins = 0
	c.slime_die_sum = 3
	buff.process_buff()
	assert_eq(c.total_coins, 2, "From 0 coins with slime_die_sum=3: total_coins should be 2")

## 6. tax_collector_buff - set_buff增加buff_price_discount+1，process_buff无操作，clear_buff减少buff_price_discount-1
func test_tax_collector_buff() -> void:
	_current_test = "test_tax_collector_buff"
	var c = Current
	c.buff_price_discount = 0

	var meta = {"buff_id": "tax_collector", "family": "coin", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/tax_collector_buff.gd", meta)

	# set_buff后buff_price_discount应该+1
	assert_eq(c.buff_price_discount, 1, "After set_buff: buff_price_discount should be 1")

	# process_buff是pass，不应改变discount
	var discount_before = c.buff_price_discount
	buff.process_buff()
	assert_eq(c.buff_price_discount, discount_before, "After process_buff: buff_price_discount should not change")

	# clear_buff后buff_price_discount应该-1
	buff.clear_buff()
	assert_eq(c.buff_price_discount, 0, "After clear_buff: buff_price_discount should be 0")

	# 多次set_buff累加
	c.buff_price_discount = 0
	var meta2 = {"buff_id": "tax_collector_2", "family": "coin", "tags": ["attack"]}
	var buff2 = create_and_set_buff("res://scripts/buff/tax_collector_buff.gd", meta2)
	assert_eq(c.buff_price_discount, 1, "After 2nd set_buff: buff_price_discount should be 1")

	# clear_buff不会低于0（maxi保护）
	c.buff_price_discount = 0
	buff2.clear_buff()
	assert_eq(c.buff_price_discount, 0, "clear_buff with discount=0: should stay 0 (maxi protection)")

## 7. gold_empire_buff - coin系≥4时 bonus=roundi(once_total_score*(total_coins/5)*0.10)，<4无效果
func test_gold_empire_buff() -> void:
	_current_test = "test_gold_empire_buff"
	var c = Current
	c.total_score = 0
	c.total_coins = 10
	c.once_total_score = 500

	# 设置BuffSystem._family_counts使coin家族计数<4（不触发）
	BuffSystem._family_counts = {"coin": 3}
	var meta = {"buff_id": "gold_empire", "family": "coin", "tags": ["legendary", "multiplicative"]}
	var buff = create_and_set_buff("res://scripts/buff/gold_empire_buff.gd", meta)

	# coin系<4时不触发
	buff.process_buff()
	assert_eq(c.total_score, 0, "coin family < 4: total_score should not change")

	# 设置coin家族计数>=4（触发）
	BuffSystem._family_counts = {"coin": 4}

	# total_coins=10, once_total_score=500: bonus = roundi(500 * (10/5) * 0.10) = roundi(500 * 2 * 0.10) = roundi(100) = 100
	c.total_score = 0
	c.total_coins = 10
	c.once_total_score = 500
	buff.process_buff()
	assert_eq(c.total_score, 100, "coin family >=4, 10 coins: bonus should be roundi(500*(10/5)*0.10)=100")

	# total_coins < 5时，整数除法 4/5=0，bonus=0
	c.total_score = 0
	c.total_coins = 4
	c.once_total_score = 500
	buff.process_buff()
	assert_eq(c.total_score, 0, "coin family >=4, 4 coins: 4/5=0 (int div), bonus should be 0")

	# total_coins=5: bonus = roundi(500 * (5/5) * 0.10) = roundi(500 * 1 * 0.10) = roundi(50) = 50
	c.total_score = 0
	c.total_coins = 5
	c.once_total_score = 500
	buff.process_buff()
	assert_eq(c.total_score, 50, "coin family >=4, 5 coins: bonus should be roundi(500*(5/5)*0.10)=50")

	# total_coins=15, once_total_score=1000: bonus = roundi(1000 * (15/5) * 0.10) = roundi(1000 * 3 * 0.10) = roundi(300) = 300
	c.total_score = 0
	c.total_coins = 15
	c.once_total_score = 1000
	buff.process_buff()
	assert_eq(c.total_score, 300, "coin family >=4, 15 coins: bonus should be roundi(1000*(15/5)*0.10)=300")

	# clear_buff无操作
	buff.clear_buff()

	# 清理
	BuffSystem._family_counts = {}

## 8. free_refresh_one_times_buff - set时zero_coin_refresh_times+1/zero_coin_refresh_max_times+1
func test_free_refresh_one_times_buff() -> void:
	_current_test = "test_free_refresh_one_times_buff"
	var c = Current
	c.zero_coin_refresh_times = 0
	c.zero_coin_refresh_max_times = 0

	var meta = {"buff_id": "free_refresh_one_times", "family": "", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/free_refresh_one_times_buff.gd", meta)

	# set_buff后zero_coin_refresh_times和zero_coin_refresh_max_times各+1
	assert_eq(c.zero_coin_refresh_times, 1, "After set_buff: zero_coin_refresh_times should be 1")
	assert_eq(c.zero_coin_refresh_max_times, 1, "After set_buff: zero_coin_refresh_max_times should be 1")

	# 再设置一个buff，累加
	var meta2 = {"buff_id": "free_refresh_one_times_2", "family": "", "tags": ["passive"], "buff_icon": "", "buff_tooltip": "test"}
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
