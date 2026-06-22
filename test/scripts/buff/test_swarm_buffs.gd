extends Node
## 潮涌(Swarm)家族Buff测试
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

## 1. slime_tide_buff - set时HP+1/max_hp+1, clear时HP-1/max_hp-1
func test_slime_tide_buff() -> void:
	_current_test = "test_slime_tide_buff"
	var c = Current
	c.player_hp = 3
	c.max_hp = 3

	var meta = {"buff_id": "slime_tide", "family": "swarm", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/slime_tide_buff.gd", meta)

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

## 2. swarm_tithe_buff - 分数 = enemy_count × target_score × 0.0025
func test_swarm_tithe_buff() -> void:
	_current_test = "test_swarm_tithe_buff"
	var c = Current
	c.total_score = 0
	c.target_score = 1000

	var meta = {"buff_id": "swarm_tithe", "family": "swarm", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/swarm_tithe_buff.gd", meta)

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

## 3. full_range_assault_buff - die_count == range_size时触发
func test_full_range_assault_buff() -> void:
	_current_test = "test_full_range_assault_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_id": "full_range_assault", "family": "swarm", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/full_range_assault_buff.gd", meta)

	# die_count < range_size时不触发
	c.slime_die_sum = 2
	c.skill_attack_range = [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)]
	buff.process_buff()
	assert_eq(c.total_score, 0, "die_count < range_size: should not trigger")

	# die_count == range_size时触发，分数 = int(once_total_score * 0.4)
	c.slime_die_sum = 3
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.4), "die_count == range_size: score should be int(once_total_score * 0.4)")

## 4. swarm_heart_buff - bonus_count = slime_count / 3, 分数 = once_total_score × bonus_count × 0.10
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

	# 3个史莱姆：3/3=1, 分数 = int(1000 * 1 * 0.10) = 100
	c.total_score = 0
	add_slime(Vector2(2, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 1 * 0.10), "3 slimes: bonus_count=1, score should be int(1000 * 0.10)")

	# 6个史莱姆：6/3=2, 分数 = int(1000 * 2 * 0.10) = 200
	c.total_score = 0
	Current.all_enemy_array.clear()
	for i in range(6):
		add_slime(Vector2(i, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 2 * 0.10), "6 slimes: bonus_count=2, score should be int(1000 * 2 * 0.10)")

## 5. slime_explosion_buff - 只计算attack_range内的史莱姆, 每3个bonus=1, 每bonus +10%
func test_slime_explosion_buff() -> void:
	_current_test = "test_slime_explosion_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_id": "slime_explosion", "family": "swarm", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/slime_explosion_buff.gd", meta)

	# 2个范围内史莱姆：2/3=0, 不触发
	for i in range(2):
		add_slime_in_range(Vector2(i, 0))
	buff.process_buff()
	assert_eq(c.total_score, 0, "2 in-range slimes: 2/3=0, should not trigger")

	# 3个范围内史莱姆：3/3=1, 分数 = int(1000 * 1 * 0.10) = 100
	c.total_score = 0
	add_slime_in_range(Vector2(2, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 1 * 0.10), "3 in-range slimes: bonus=1, score should be int(1000 * 0.10)")

	# 6个范围内史莱姆：6/3=2, 分数 = int(1000 * 2 * 0.10) = 200
	c.total_score = 0
	Current.all_enemy_array.clear()
	Current.skill_attack_range.clear()
	for i in range(6):
		add_slime_in_range(Vector2(i, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 2 * 0.10), "6 in-range slimes: bonus=2, score should be int(1000 * 2 * 0.10)")

	# 9个范围内史莱姆：9/3=3, 分数 = int(1000 * 3 * 0.10) = 300
	c.total_score = 0
	Current.all_enemy_array.clear()
	Current.skill_attack_range.clear()
	for i in range(9):
		add_slime_in_range(Vector2(i, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 3 * 0.10), "9 in-range slimes: bonus=3, score should be int(1000 * 3 * 0.10)")

	# 范围外史莱姆不计算：3个总史莱姆但只有2个在范围内
	c.total_score = 0
	Current.all_enemy_array.clear()
	Current.skill_attack_range.clear()
	add_slime_in_range(Vector2(0, 0))
	add_slime_in_range(Vector2(1, 0))
	# 1个不在范围内的
	add_slime(Vector2(10, 0))
	buff.process_buff()
	assert_eq(c.total_score, 0, "2 in-range (3 total): 2/3=0, should not trigger")

## 6. tide_crusher_buff - ≥8个史莱姆时触发，分数 = once_total_score × 0.60
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

	# 8个史莱姆触发，分数 = int(1000 * 0.60) = 600
	c.total_score = 0
	add_slime(Vector2(7, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.60), "8 slimes: should trigger, score = int(once_total_score * 0.60)")

	# 9个史莱姆也触发
	c.total_score = 0
	add_slime(Vector2(8, 0))
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.60), "9 slimes: should trigger, score = int(once_total_score * 0.60)")

## 7. swarm_overlord_buff - 数量压制：每有1个史莱姆存活，潮涌系得分3%/只
func test_swarm_overlord_buff() -> void:
	_current_test = "test_swarm_overlord_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000
	# 添加10个史莱姆
	for i in range(10):
		add_slime(Vector2(i, 0))
	var meta = {"buff_id": "swarm_overlord", "family": "swarm", "tags": ["legendary", "multiplicative"]}
	var buff = create_and_set_buff("res://scripts/buff/swarm_overlord_buff.gd", meta)
	# 需要潮涌系≥4才能激活，单独1个overlord不满足，process_buff应该跳过
	buff.process_buff()
	assert_eq(c.total_score, 0, "swarm_overlord with <4 swarm buffs: should not trigger")
	# clear_buff无操作
	buff.clear_buff()
	# 清理
	Current.all_enemy_array.clear()

## 8. slime_rebirth_buff - 史莱姆转生：每击杀1个史莱姆，30%概率生成1个新史莱姆
func test_slime_rebirth_buff() -> void:
	_current_test = "test_slime_rebirth_buff"
	var c = Current
	c.total_score = 0

	var meta = {"buff_id": "slime_rebirth", "family": "swarm", "tags": ["on_kill", "slime_count", "linear", "aggression", "common"]}
	var buff = create_and_set_buff("res://scripts/buff/slime_rebirth_buff.gd", meta)

	# 0击杀时不应执行任何操作（不生成史莱姆，不显示浮动数字）
	c.slime_die_sum = 0
	buff.process_buff()
	assert_eq(c.total_score, 0, "0 kills: total_score should not change")

	# 3击杀时：由于30%概率判定，无法精确断言生成数量，
	# 但可以验证public_lock_array在处理期间正确加锁和解锁
	# （此测试依赖运行时game_manager，在集成测试中验证完整流程）

## 9. slime_kill_empower_buff - 分数 = once_total_score × kill_count × 0.03
func test_slime_kill_empower_buff() -> void:
	_current_test = "test_slime_kill_empower_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_id": "slime_kill_empower", "family": "evolution", "tags": ["on_kill", "slime_count", "linear", "aggression", "rare"]}
	var buff = create_and_set_buff("res://scripts/buff/slime_kill_empower_buff.gd", meta)

	# 0击杀时分数不变
	c.slime_die_sum = 0
	buff.process_buff()
	assert_eq(c.total_score, 0, "0 kills: total_score should not change")

	# 3击杀：int(1000 * 3 * 0.03) = 90
	c.total_score = 0
	c.slime_die_sum = 3
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 3 * 0.03), "3 kills: score should be int(once_total_score * 3 * 0.03)")

## 11. power_slime_bounty_buff - killed_power_slime为true时触发
func test_power_slime_bounty_buff() -> void:
	_current_test = "test_power_slime_bounty_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_id": "power_slime_bounty", "family": "swarm", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/power_slime_bounty_buff.gd", meta)

	# killed_power_slime为false时不触发
	c.killed_power_slime = false
	buff.process_buff()
	assert_eq(c.total_score, 0, "killed_power_slime=false: should not trigger")

	# killed_power_slime为true时触发，分数 = int(1000 * 0.40) = 400
	c.killed_power_slime = true
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.40), "killed_power_slime=true: score should be int(once_total_score * 0.40)")

## 12. extra_power_slime_buff - set时power_slime_num+1, clear时-1
func test_extra_power_slime_buff() -> void:
	_current_test = "test_extra_power_slime_buff"
	var c = Current
	c.power_slime_num = 2

	var meta = {"buff_id": "extra_power_slime", "family": "swarm", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/extra_power_slime_buff.gd", meta)

	# set_buff后power_slime_num+1
	assert_eq(c.power_slime_num, 3, "power_slime_num should increase by 1 after set_buff")

	# clear_buff后power_slime_num-1
	buff.clear_buff()
	assert_eq(c.power_slime_num, 2, "power_slime_num should decrease by 1 after clear_buff")

## 13. power_cap_up_buff - set时max_power+1, clear时-1
func test_power_cap_up_buff() -> void:
	_current_test = "test_power_cap_up_buff"
	var c = Current
	c.max_power = 3

	var meta = {"buff_id": "power_cap_up", "family": "swarm", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/power_cap_up_buff.gd", meta)

	# set_buff后max_power+1
	assert_eq(c.max_power, 4, "max_power should increase by 1 after set_buff")

	# clear_buff后max_power-1
	buff.clear_buff()
	assert_eq(c.max_power, 3, "max_power should decrease by 1 after clear_buff")
