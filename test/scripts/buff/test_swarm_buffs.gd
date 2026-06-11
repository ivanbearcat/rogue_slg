extends Node
## 虫群(Swarm)家族Buff测试
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

## 1. slime_plus_one_buff - set时HP+1/max_hp+1, clear时HP-1/max_hp-1
func test_slime_plus_one_buff() -> void:
	_current_test = "test_slime_plus_one_buff"
	var c = Current
	c.player_hp = 3
	c.max_hp = 3

	var meta = {"buff_id": "slime_plus_one", "family": "swarm", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/slime_plus_one_buff.gd", meta)

	# set_buff后HP和max_hp各+1
	assert_eq(c.max_hp, 4, "max_hp should increase by 1 after set_buff")
	assert_eq(c.player_hp, 4, "player_hp should increase by 1 after set_buff")

	# clear_buff后HP和max_hp各-1
	buff.clear_buff()
	assert_eq(c.max_hp, 3, "max_hp should decrease by 1 after clear_buff")
	assert_eq(c.player_hp, 3, "player_hp should decrease by 1 after clear_buff")

	# 边界：HP已为0时clear
	c.player_hp = 0
	c.max_hp = 0
	buff.set_buff()
	assert_eq(c.max_hp, 1, "max_hp should be 1 after set_buff from 0")
	assert_eq(c.player_hp, 1, "player_hp should be 1 after set_buff from 0")
	buff.clear_buff()
	assert_eq(c.max_hp, 0, "max_hp should be 0 after clear_buff")
	assert_eq(c.player_hp, 0, "player_hp should be 0 after clear_buff from 1")

## 2. slime_sum_score_increase_buff - 分数 = enemy_count × target_score × 0.0025
func test_slime_sum_score_increase_buff() -> void:
	_current_test = "test_slime_sum_score_increase_buff"
	var c = Current
	c.total_score = 0
	c.target_score = 1000

	var meta = {"buff_id": "slime_sum_score_increase", "family": "swarm", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/slime_sum_score_increase_buff.gd", meta)

	# 0个敌人时分数不变
	buff.process_buff()
	assert_eq(c.total_score, 0, "No enemies: total_score should not change")

	# 添加5个敌人：5 * 1000 * 0.0025 = 12.5 -> int(12.5) = 12
	c.total_score = 0
	for i in range(5):
		add_slime(Vector2(i, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(5 * 1000 * 0.0025), "5 enemies: score should be int(5 * 1000 * 0.0025)")

	# 大量敌人：100个
	c.total_score = 0
	Current.all_enemy_array.clear()
	c.target_score = 200
	for i in range(100):
		add_slime(Vector2(i, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(100 * 200 * 0.0025), "100 enemies with target_score=200: score should be int(100 * 200 * 0.0025)")

## 3. full_range_slime_double_score_buff - die_count == range_size时触发
func test_full_range_slime_double_score_buff() -> void:
	_current_test = "test_full_range_slime_double_score_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_id": "full_range_slime_double_score", "family": "swarm", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/full_range_slime_double_score_buff.gd", meta)

	# die_count < range_size时不触发
	c.slime_die_sum = 2
	c.skill_attack_range = [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)]
	buff.process_buff()
	assert_eq(c.total_score, 0, "die_count < range_size: should not trigger")

	# die_count == range_size时触发，分数 = int(once_total_score * 0.4)
	c.slime_die_sum = 3
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.4), "die_count == range_size: score should be int(once_total_score * 0.4)")

## 4. swarm_heart_buff - bonus_count = slime_count / 3, 分数 = once_total_score × bonus_count × 0.15
func test_swarm_heart_buff() -> void:
	_current_test = "test_swarm_heart_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_id": "swarm_heart", "family": "swarm", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/swarm_heart_buff.gd", meta)

	# 2个史莱姆：2/3=0, 不触发
	add_slime(Vector2(0, 0))
	add_slime(Vector2(1, 0))
	buff.process_buff()
	assert_eq(c.total_score, 0, "2 slimes: bonus_count=0, should not trigger")

	# 3个史莱姆：3/3=1, 分数 = int(1000 * 1 * 0.15) = 150
	c.total_score = 0
	add_slime(Vector2(2, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 1 * 0.15), "3 slimes: bonus_count=1, score should be int(1000 * 0.15)")

	# 6个史莱姆：6/3=2, 分数 = int(1000 * 2 * 0.15) = 300
	c.total_score = 0
	Current.all_enemy_array.clear()
	for i in range(6):
		add_slime(Vector2(i, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 2 * 0.15), "6 slimes: bonus_count=2, score should be int(1000 * 2 * 0.15)")

## 5. slime_explosion_buff - 只计算attack_range内的史莱姆, 每5个bonus=1
func test_slime_explosion_buff() -> void:
	_current_test = "test_slime_explosion_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_id": "slime_explosion", "family": "swarm", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/slime_explosion_buff.gd", meta)

	# 4个范围内史莱姆：4/5=0, 不触发
	for i in range(4):
		add_slime_in_range(Vector2(i, 0))
	buff.process_buff()
	assert_eq(c.total_score, 0, "4 in-range slimes: 4/5=0, should not trigger")

	# 5个范围内史莱姆：5/5=1, 分数 = int(1000 * 1 * 0.20) = 200
	c.total_score = 0
	add_slime_in_range(Vector2(4, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 1 * 0.20), "5 in-range slimes: bonus=1, score should be int(1000 * 0.20)")

	# 10个范围内史莱姆：10/5=2, 分数 = int(1000 * 2 * 0.20) = 400
	c.total_score = 0
	Current.all_enemy_array.clear()
	Current.skill_attack_range.clear()
	for i in range(10):
		add_slime_in_range(Vector2(i, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 2 * 0.20), "10 in-range slimes: bonus=2, score should be int(1000 * 2 * 0.20)")

	# 范围外史莱姆不计算：5个总史莱姆但只有3个在范围内
	c.total_score = 0
	Current.all_enemy_array.clear()
	Current.skill_attack_range.clear()
	add_slime_in_range(Vector2(0, 0))
	add_slime_in_range(Vector2(1, 0))
	add_slime_in_range(Vector2(2, 0))
	# 2个不在范围内的
	add_slime(Vector2(10, 0))
	add_slime(Vector2(11, 0))
	buff.process_buff()
	assert_eq(c.total_score, 0, "3 in-range (5 total): 3/5=0, should not trigger")

## 6. tide_crusher_buff - ≥8个史莱姆时触发，分数 = once_total_score × 0.50
func test_tide_crusher_buff() -> void:
	_current_test = "test_tide_crusher_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_id": "tide_crusher", "family": "swarm", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/tide_crusher_buff.gd", meta)

	# 7个史莱姆不触发
	for i in range(7):
		add_slime(Vector2(i, 0))
	buff.process_buff()
	assert_eq(c.total_score, 0, "7 slimes: should not trigger (< 8)")

	# 8个史莱姆触发，分数 = int(1000 * 0.50) = 500
	c.total_score = 0
	add_slime(Vector2(7, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.50), "8 slimes: should trigger, score = int(once_total_score * 0.50)")

	# 9个史莱姆也触发
	c.total_score = 0
	add_slime(Vector2(8, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.50), "9 slimes: should trigger, score = int(once_total_score * 0.50)")

## 7. swarm_overlord_buff - 被动buff，process_buff为空
func test_swarm_overlord_buff() -> void:
	_current_test = "test_swarm_overlord_buff"

	var meta = {"buff_id": "swarm_overlord", "family": "swarm", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/swarm_overlord_buff.gd", meta)

	# 验证process_buff是被动标记（无操作）
	var c = Current
	var score_before = c.total_score
	buff.process_buff()
	assert_eq(c.total_score, score_before, "swarm_overlord: process_buff should not change total_score")

	# clear_buff也是空操作
	buff.clear_buff()
	assert_eq(c.total_score, score_before, "swarm_overlord: clear_buff should not change total_score")

## 8. slime_resonance_buff - 分数 = once_total_score × slime_count × 0.03
func test_slime_resonance_buff() -> void:
	_current_test = "test_slime_resonance_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_id": "slime_resonance", "family": "swarm", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/slime_resonance_buff.gd", meta)

	# 0个史莱姆时分数不变
	buff.process_buff()
	assert_eq(c.total_score, 0, "0 slimes: total_score should not change")

	# 4个史莱姆：int(1000 * 4 * 0.03) = int(120) = 120
	c.total_score = 0
	for i in range(4):
		add_slime(Vector2(i, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 4 * 0.03), "4 slimes: score should be int(1000 * 4 * 0.03)")

## 9. slime_base_score_increase_buff - scored_dice_info中每个dice对应的score+1
func test_slime_base_score_increase_buff() -> void:
	_current_test = "test_slime_base_score_increase_buff"
	var c = Current

	var meta = {"buff_id": "slime_base_score_increase", "family": "swarm", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/slime_base_score_increase_buff.gd", meta)

	# 空scored_dice_info - 不影响任何分数
	buff.process_buff()
	assert_eq(c.one_score, 0, "Empty scored_dice_info: one_score should remain 0")
	assert_eq(c.six_score, 0, "Empty scored_dice_info: six_score should remain 0")

	# scored_dice_info中有[slime, 1], [slime, 3], [slime, 6]
	c.scored_dice_info = [["slime", 1], ["slime", 3], ["slime", 6]]
	buff.process_buff()
	assert_eq(c.one_score, 1, "After process: one_score should be 1")
	assert_eq(c.three_score, 1, "After process: three_score should be 1")
	assert_eq(c.six_score, 1, "After process: six_score should be 1")
	assert_eq(c.two_score, 0, "After process: two_score should remain 0")

	# 重复的dice type: 两个[slime, 2]
	c.one_score = 0; c.three_score = 0; c.six_score = 0
	c.scored_dice_info = [["slime", 2], ["slime", 2]]
	buff.process_buff()
	assert_eq(c.two_score, 2, "Two dice with type 2: two_score should be 2")

## 10. slime_percent_score_increase_buff - active_dice_types中每个type对应的percent+2
func test_slime_percent_score_increase_buff() -> void:
	_current_test = "test_slime_percent_score_increase_buff"
	var c = Current

	var meta = {"buff_id": "slime_percent_score_increase", "family": "swarm", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/slime_percent_score_increase_buff.gd", meta)

	# 空active_dice_types - 不影响任何percent
	buff.process_buff()
	assert_eq(c.duizi_percent, 0, "Empty active_dice_types: duizi_percent should remain 0")
	assert_eq(c.shunzi_percent, 0, "Empty active_dice_types: shunzi_percent should remain 0")

	# active_dice_types包含"duizi"和"shunzi"
	c.active_dice_types = ["duizi", "shunzi"]
	buff.process_buff()
	assert_eq(c.duizi_percent, 2, "After process: duizi_percent should be 2")
	assert_eq(c.shunzi_percent, 2, "After process: shunzi_percent should be 2")
	assert_eq(c.tongse_percent, 0, "After process: tongse_percent should remain 0")

	# 所有5种type
	c.duizi_percent = 0; c.shunzi_percent = 0
	c.active_dice_types = ["duizi", "shunzi", "tongse", "tongdui", "tongshun"]
	buff.process_buff()
	assert_eq(c.duizi_percent, 2, "All types: duizi_percent should be 2")
	assert_eq(c.shunzi_percent, 2, "All types: shunzi_percent should be 2")
	assert_eq(c.tongse_percent, 2, "All types: tongse_percent should be 2")
	assert_eq(c.tongdui_percent, 2, "All types: tongdui_percent should be 2")
	assert_eq(c.tongshun_percent, 2, "All types: tongshun_percent should be 2")

	# 重复type: 两个"duizi"
	c.duizi_percent = 0
	c.active_dice_types = ["duizi", "duizi"]
	buff.process_buff()
	assert_eq(c.duizi_percent, 4, "Two duizi types: duizi_percent should be 4")

## 11. attack_power_slime_score_increase_buff - killed_power_slime为true时触发
func test_attack_power_slime_score_increase_buff() -> void:
	_current_test = "test_attack_power_slime_score_increase_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_id": "attack_power_slime_score_increase", "family": "swarm", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/attack_power_slime_score_increase_buff.gd", meta)

	# killed_power_slime为false时不触发
	c.killed_power_slime = false
	buff.process_buff()
	assert_eq(c.total_score, 0, "killed_power_slime=false: should not trigger")

	# killed_power_slime为true时触发，分数 = int(1000 * 0.30) = 300
	c.killed_power_slime = true
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.30), "killed_power_slime=true: score should be int(once_total_score * 0.30)")

## 12. power_slime_plus_one_buff - set时power_slime_num+1, clear时-1
func test_power_slime_plus_one_buff() -> void:
	_current_test = "test_power_slime_plus_one_buff"
	var c = Current
	c.power_slime_num = 2

	var meta = {"buff_id": "power_slime_plus_one", "family": "swarm", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/power_slime_plus_one_buff.gd", meta)

	# set_buff后power_slime_num+1
	assert_eq(c.power_slime_num, 3, "power_slime_num should increase by 1 after set_buff")

	# clear_buff后power_slime_num-1
	buff.clear_buff()
	assert_eq(c.power_slime_num, 2, "power_slime_num should decrease by 1 after clear_buff")

## 13. max_power_puls_one_buff - set时max_power+1, clear时-1
func test_max_power_puls_one_buff() -> void:
	_current_test = "test_max_power_puls_one_buff"
	var c = Current
	c.max_power = 3

	var meta = {"buff_id": "max_power_puls_one", "family": "swarm", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/max_power_puls_one_buff.gd", meta)

	# set_buff后max_power+1
	assert_eq(c.max_power, 4, "max_power should increase by 1 after set_buff")

	# clear_buff后max_power-1
	buff.clear_buff()
	assert_eq(c.max_power, 3, "max_power should decrease by 1 after clear_buff")
