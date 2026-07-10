extends Node
## 绝境(Desperation) Buff测试
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

## 1. iron_wall_buff - set时player_defense+1, clear时-1
func test_iron_wall_buff() -> void:
	_current_test = "test_iron_wall_buff"
	var c = Current
	c.player_defense = 2

	var meta = {"buff_id": "iron_wall", "family": "desperation", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/iron_wall_buff.gd", meta)

	# set_buff后defense+1
	assert_eq(c.player_defense, 3, "player_defense should increase by 1 after set_buff")

	# clear_buff后defense-1
	buff.clear_buff()
	assert_eq(c.player_defense, 2, "player_defense should decrease by 1 after clear_buff")

	# 边界：defense=0时set再clear
	c.player_defense = 0
	buff.set_buff()
	assert_eq(c.player_defense, 1, "player_defense should be 1 after set_buff from 0")
	buff.clear_buff()
	assert_eq(c.player_defense, 0, "player_defense should be 0 after clear_buff")

## 3. life_barrier_buff - HP≤2时+2防御, HP>2时不加, clear时减2防御（如果在低HP状态下加的）
func test_life_barrier_buff() -> void:
	_current_test = "test_life_barrier_buff"
	var c = Current

	var meta = {"buff_id": "life_barrier", "family": "desperation", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/life_barrier_buff.gd", meta)

	# set_buff不直接加防御（防御在process_buff中根据HP条件加）
	assert_eq(c.player_defense, 2, "player_defense should not change after set_buff (no immediate effect)")

	# HP>2时process_buff不加防御
	c.player_hp = 5
	c.player_defense = 2
	buff.process_buff()
	assert_eq(c.player_defense, 2, "HP=5: player_defense should not increase")

	# HP≤2时process_buff+2防御
	c.player_hp = 2
	buff.process_buff()
	assert_eq(c.player_defense, 4, "HP=2: player_defense should increase by 2")

	# 再次process_buff：先回退上回合的+2，再判断HP≤2再加+2
	buff.process_buff()
	assert_eq(c.player_defense, 4, "HP=2 repeated process: defense should stay at 4 (rollback then re-apply)")

	# HP恢复到>2时，process_buff回退+2
	c.player_hp = 5
	buff.process_buff()
	assert_eq(c.player_defense, 2, "HP=5 after low HP: player_defense should decrease by 2 (rollback)")

	# clear_buff时如果在低HP状态下加的防御，回退+2
	c.player_hp = 1
	c.player_defense = 2
	buff.process_buff()  # +2, defense=4
	assert_eq(c.player_defense, 4, "HP=1: player_defense should be 4 after process")
	buff.clear_buff()    # rollback +2
	assert_eq(c.player_defense, 2, "clear_buff while low HP: player_defense should decrease by 2")

	# clear_buff时如果不在低HP状态，不回退
	c.player_hp = 5
	c.player_defense = 2
	buff.set_buff()
	buff.process_buff()  # HP=5, no defense added
	assert_eq(c.player_defense, 2, "HP=5 process: defense unchanged")
	buff.clear_buff()    # no rollback needed
	assert_eq(c.player_defense, 2, "clear_buff while high HP: defense unchanged")

## 8. late_bloom_buff - round≥7时触发，分数 = once_total_score × 0.30
func test_late_bloom_buff() -> void:
	_current_test = "test_late_bloom_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_id": "late_bloom", "family": "desperation", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/late_bloom_buff.gd", meta)

	# round=6时不触发
	c.count_round = 6
	buff.process_buff()
	assert_eq(c.total_score, 0, "round=6: should not trigger")

	# round=7时触发，分数 = int(1000 * 0.30) = 300
	c.count_round = 7
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.30), "round=7: score should be int(once_total_score * 0.30)")

	# round=10时也触发
	c.total_score = 0
	c.count_round = 10
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.30), "round=10: score should be int(once_total_score * 0.30)")

	# round=1时不触发
	c.total_score = 0
	c.count_round = 1
	buff.process_buff()
	assert_eq(c.total_score, 0, "round=1: should not trigger")

	# clear_buff无操作
	buff.clear_buff()

## 9. crisis_power_buff - HP≤2时触发，分数 = once_total_score × 0.70
func test_crisis_power_buff() -> void:
	_current_test = "test_crisis_power_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_id": "crisis_power", "family": "desperation", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/crisis_power_buff.gd", meta)

	# HP=3时不触发
	c.player_hp = 3
	buff.process_buff()
	assert_eq(c.total_score, 0, "HP=3: should not trigger")

	# HP=2时触发，分数 = int(1000 * 0.70) = 700
	c.player_hp = 2
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.70), "HP=2: score should be int(once_total_score * 0.70)")

	# HP=1时也触发
	c.total_score = 0
	c.player_hp = 1
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.70), "HP=1: score should be int(once_total_score * 0.70)")

	# HP=5时不触发
	c.total_score = 0
	c.player_hp = 5
	buff.process_buff()
	assert_eq(c.total_score, 0, "HP=5: should not trigger")

	# clear_buff无操作
	buff.clear_buff()

## 10. curse_burner_buff - 分数 = once_total_score × debuff_count × 0.08
func test_curse_burner_buff() -> void:
	_current_test = "test_curse_burner_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	## 确保 Current.hero 可用（process_buff 中会 add_child 浮动数字）
	var _mock_hero = null
	if not c.hero:
		_mock_hero = Node2D.new()
		_mock_hero.name = "MockHero"
		c.hero = _mock_hero

	var meta = {"buff_id": "curse_burner", "family": "desperation", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/curse_burner_buff.gd", meta)

	var gm = get_node("/root/game_manager")

	# 0个debuff时分数不变
	_clear_debuff_container(gm)
	await buff.process_buff()
	assert_eq(c.total_score, 0, "0 debuffs: total_score should not change")

	# 1个debuff：分数 = int(1000 * 1 * 0.08) = 80
	c.total_score = 0
	_clear_debuff_container(gm)
	_add_mock_debuff(gm)
	await buff.process_buff()
	assert_eq(c.total_score, int(1000 * 1 * 0.08), "1 debuff: score should be int(once_total_score * 1 * 0.08)")

	# 3个debuff：分数 = int(1000 * 3 * 0.08) = 240
	c.total_score = 0
	_clear_debuff_container(gm)
	_add_mock_debuff(gm)
	_add_mock_debuff(gm)
	_add_mock_debuff(gm)
	await buff.process_buff()
	assert_eq(c.total_score, int(1000 * 3 * 0.08), "3 debuffs: score should be int(once_total_score * 3 * 0.08)")

	# public_lock_array为空但debuff_container有debuff时仍触发
	c.total_score = 0
	c.public_lock_array = []
	_clear_debuff_container(gm)
	_add_mock_debuff(gm)
	_add_mock_debuff(gm)
	await buff.process_buff()
	assert_eq(c.total_score, int(1000 * 2 * 0.08), "public_lock_array empty + 2 debuffs: score should be int(once_total_score * 2 * 0.08)")

	# 清理
	_clear_debuff_container(gm)
	buff.clear_buff()
	if _mock_hero:
		c.hero = null
		_mock_hero.queue_free()

## 11. desperation_overlord_buff - 绝境霸主：仅授予全局免死
func test_desperation_overlord_buff() -> void:
	_current_test = "test_desperation_overlord_buff"
	var c = Current
	c.total_score = 0
	c.has_death_immunity = false
	c.death_immunity_used = false
	var meta = {"buff_id": "desperation_overlord", "family": "desperation", "tags": ["legendary", "multiplicative"]}
	var buff = create_and_set_buff("res://scripts/buff/desperation_overlord_buff.gd", meta)
	# set_buff授予免死
	assert_true(c.has_death_immunity, "desperation_overlord: should grant death immunity on set_buff")
	assert_false(c.death_immunity_used, "desperation_overlord: death_immunity_used should be false")
	# process_buff不再有计分逻辑（仅pass），即使有累积值和debuff也不加分
	BuffSystem._current_family_accumulation = {"desperation": 100}
	buff.process_buff()
	assert_eq(c.total_score, 0, "desperation_overlord: process_buff should not add score (logic removed)")
	# clear_buff无操作
	buff.clear_buff()
	# 清理
	BuffSystem._current_family_accumulation = {}
	c.has_death_immunity = false
	c.death_immunity_used = false

## 辅助：清空debuff_container
func _clear_debuff_container(gm: Node) -> void:
	for child in gm.debuff_container.get_children():
		child.queue_free()

## 辅助：添加mock debuff节点到debuff_container
func _add_mock_debuff(gm: Node) -> void:
	var debuff_node = Node.new()
	gm.debuff_container.add_child(debuff_node)

