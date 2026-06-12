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

## 4. point_guard_buff - 随机选择一个点数免疫，保存分数值，process时恢复
func test_point_guard_buff() -> void:
	_current_test = "test_point_guard_buff"
	var c = Current

	var meta = {"buff_id": "point_guard", "family": "desperation", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/point_guard_buff.gd", meta)

	# set_buff后应选择了免疫点数并保存了当前分数
	assert_true(buff._immune_point >= 1 and buff._immune_point <= 6,
		"_immune_point should be between 1 and 6 after set_buff")

	# 手动设置内部变量以消除随机性，测试process逻辑
	buff._immune_point = 3  # 免疫三点
	buff._saved_score = 10
	c.three_score = 10

	# 分数未降低时，process更新保存值跟踪正常增长
	c.three_score = 15
	buff.process_buff()
	assert_eq(c.three_score, 15, "score increased: should keep new value")
	assert_eq(buff._saved_score, 15, "score increased: _saved_score should update to track growth")

	# 分数被降低时，process恢复到保存值
	c.three_score = 5  # 被debuff降低了
	buff.process_buff()
	assert_eq(c.three_score, 15, "score decreased: should restore to _saved_score")

	# 测试其他点数不受影响
	buff._immune_point = 1
	buff._saved_score = 20
	c.one_score = 8  # 被降低
	c.two_score = 5  # 不受影响
	buff.process_buff()
	assert_eq(c.one_score, 20, "one_score decreased: should restore to _saved_score")
	assert_eq(c.two_score, 5, "two_score should not be affected by point_guard on one_score")

	# clear_buff无操作
	buff.clear_buff()
	assert_eq(c.one_score, 20, "clear_buff: score should not change")

## 6. type_guard_buff - 随机选择一个骰型免疫，保存百分比值，process时恢复
func test_type_guard_buff() -> void:
	_current_test = "test_type_guard_buff"
	var c = Current

	var meta = {"buff_id": "type_guard", "family": "desperation", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/type_guard_buff.gd", meta)

	# set_buff后应选择了免疫骰型
	assert_ne(buff._immune_type, "", "_immune_type should be set after set_buff")
	assert_true(buff._immune_type in ["duizi", "shunzi", "tongse", "tongdui", "tongshun"],
		"_immune_type should be a valid dice type")

	# 手动设置内部变量以消除随机性
	buff._immune_type = "duizi"
	buff._saved_percent = 30
	c.duizi_percent = 30

	# 百分比未降低时，process更新保存值跟踪正常增长
	c.duizi_percent = 50
	buff.process_buff()
	assert_eq(c.duizi_percent, 50, "percent increased: should keep new value")
	assert_eq(buff._saved_percent, 50, "percent increased: _saved_percent should update to track growth")

	# 百分比被降低时，process恢复到保存值
	c.duizi_percent = 10  # 被debuff降低了
	buff.process_buff()
	assert_eq(c.duizi_percent, 50, "percent decreased: should restore to _saved_percent")

	# 测试其他骰型不受影响
	buff._immune_type = "shunzi"
	buff._saved_percent = 40
	c.shunzi_percent = 15  # 被降低
	c.tongse_percent = 5   # 不受影响
	buff.process_buff()
	assert_eq(c.shunzi_percent, 40, "shunzi_percent decreased: should restore to _saved_percent")
	assert_eq(c.tongse_percent, 5, "tongse_percent should not be affected by type_guard on shunzi")

	# clear_buff无操作
	buff.clear_buff()
	assert_eq(c.shunzi_percent, 40, "clear_buff: percent should not change")

## 7. score_shield_buff - 被动buff，process_buff无主动逻辑
func test_score_shield_buff() -> void:
	_current_test = "test_score_shield_buff"
	var c = Current

	var meta = {"buff_id": "score_shield", "family": "desperation", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/score_shield_buff.gd", meta)

	# set_buff不改变分数
	assert_eq(c.total_score, 0, "total_score should not change after set_buff")

	# process_buff无主动逻辑（逻辑在debuff中检查_has_score_shield）
	var score_before = c.total_score
	buff.process_buff()
	assert_eq(c.total_score, score_before, "process_buff should not change total_score")

	# clear_buff无操作
	buff.clear_buff()
	assert_eq(c.total_score, score_before, "clear_buff should not change total_score")

## 8. late_bloom_buff - round≥7时触发，分数 = once_total_score × 0.25
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

	# round=7时触发，分数 = int(1000 * 0.25) = 250
	c.count_round = 7
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.25), "round=7: score should be int(once_total_score * 0.25)")

	# round=10时也触发
	c.total_score = 0
	c.count_round = 10
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.25), "round=10: score should be int(once_total_score * 0.25)")

	# round=1时不触发
	c.total_score = 0
	c.count_round = 1
	buff.process_buff()
	assert_eq(c.total_score, 0, "round=1: should not trigger")

	# clear_buff无操作
	buff.clear_buff()

## 9. crisis_power_buff - HP≤2时触发，分数 = once_total_score × 0.50
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

	# HP=2时触发，分数 = int(1000 * 0.50) = 500
	c.player_hp = 2
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.50), "HP=2: score should be int(once_total_score * 0.50)")

	# HP=1时也触发
	c.total_score = 0
	c.player_hp = 1
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 0.50), "HP=1: score should be int(once_total_score * 0.50)")

	# HP=5时不触发
	c.total_score = 0
	c.player_hp = 5
	buff.process_buff()
	assert_eq(c.total_score, 0, "HP=5: should not trigger")

	# clear_buff无操作
	buff.clear_buff()

## 10. curse_burner_buff - 分数 = once_total_score × debuff_count × 0.12
func test_curse_burner_buff() -> void:
	_current_test = "test_curse_burner_buff"
	var c = Current
	c.total_score = 0
	c.once_total_score = 1000

	var meta = {"buff_id": "curse_burner", "family": "desperation", "tags": ["attack"]}
	var buff = create_and_set_buff("res://scripts/buff/curse_burner_buff.gd", meta)

	# 0个debuff时分数不变
	c.public_lock_array = []
	buff.process_buff()
	assert_eq(c.total_score, 0, "0 debuffs: total_score should not change")

	# 1个debuff（含"disable"）：分数 = int(1000 * 1 * 0.12) = 120
	c.total_score = 0
	c.public_lock_array = ["disable_points"]
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 1 * 0.12), "1 disable debuff: score should be int(once_total_score * 1 * 0.12)")

	# 3个debuff（混合disable/down/penalty）：分数 = int(1000 * 3 * 0.12) = 360
	c.total_score = 0
	c.public_lock_array = ["disable_points", "down_two", "penalty_three"]
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 3 * 0.12), "3 debuffs: score should be int(once_total_score * 3 * 0.12)")

	# public_lock_array中有非debuff条目不计入
	c.total_score = 0
	c.public_lock_array = ["disable_points", "some_buff", "down_two"]
	buff.process_buff()
	assert_eq(c.total_score, int(1000 * 2 * 0.12), "2 debuffs + 1 non-debuff: score should be int(once_total_score * 2 * 0.12)")

	# 只有非debuff条目时不触发
	c.total_score = 0
	c.public_lock_array = ["some_buff", "another_buff"]
	buff.process_buff()
	assert_eq(c.total_score, 0, "0 debuffs (only non-debuff entries): total_score should not change")

	# clear_buff无操作
	buff.clear_buff()

## 11. desperation_overlord_buff - 绝境求生：免死授予+debuff增幅
func test_desperation_overlord_buff() -> void:
	_current_test = "test_desperation_overlord_buff"
	var c = Current
	c.total_score = 0
	c.has_death_immunity = false
	c.death_immunity_used = false
	BuffSystem._last_family_accumulation = {"desperation": 17}
	var meta = {"buff_id": "desperation_overlord", "family": "desperation", "tags": ["legendary", "multiplicative"]}
	var buff = create_and_set_buff("res://scripts/buff/desperation_overlord_buff.gd", meta)
	# set_buff授予免死（无论是否有4个desperation buffs）
	assert_true(c.has_death_immunity, "desperation_overlord: should grant death immunity on set_buff")
	assert_false(c.death_immunity_used, "desperation_overlord: death_immunity_used should be false")
	# process_buff需要≥4，不触发
	buff.process_buff()
	assert_eq(c.total_score, 0, "desperation_overlord with <4 desperation buffs: score should not change")
	# clear_buff无操作
	buff.clear_buff()
	# 清理
	BuffSystem._last_family_accumulation = {}
	c.has_death_immunity = false
	c.death_immunity_used = false

## 12. turn_plus_one_buff - 第一回合skip_hp_damage_this_turn = true
func test_turn_plus_one_buff() -> void:
	_current_test = "test_turn_plus_one_buff"
	var c = Current

	var meta = {"buff_id": "turn_plus_one", "family": "desperation", "tags": ["passive"]}
	var buff = create_and_set_buff("res://scripts/buff/turn_plus_one_buff.gd", meta)

	# set_buff不直接设置skip标记
	assert_eq(c.skip_hp_damage_this_turn, false, "skip_hp_damage_this_turn should be false after set_buff")

	# 第一回合(count_round=1)process_buff设置skip=true
	c.count_round = 1
	buff.process_buff()
	assert_eq(c.skip_hp_damage_this_turn, true, "round=1: skip_hp_damage_this_turn should be true")

	# _is_used已设为true，再次process_buff不重复设置
	c.skip_hp_damage_this_turn = false
	buff.process_buff()
	assert_eq(c.skip_hp_damage_this_turn, false, "round=1 again (already used): should not set skip again")

	# 非第一回合不跳过
	var buff2 = create_and_set_buff("res://scripts/buff/turn_plus_one_buff.gd", meta)
	c.count_round = 3
	buff2.process_buff()
	assert_eq(c.skip_hp_damage_this_turn, false, "round=3: skip_hp_damage_this_turn should remain false")

	# 新关卡(round=1)时重新生效
	var buff3 = create_and_set_buff("res://scripts/buff/turn_plus_one_buff.gd", meta)
	c.count_round = 1
	buff3.process_buff()
	assert_eq(c.skip_hp_damage_this_turn, true, "new stage round=1: skip_hp_damage_this_turn should be true")

	# clear_buff无操作
	buff3.clear_buff()

