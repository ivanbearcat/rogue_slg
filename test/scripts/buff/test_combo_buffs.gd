extends Node
## 连击(Combo) Buff测试
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

## ============================================================
## 测试方法
## ============================================================

## 1. movement_plus_one_buff - set_buff时hero_movement+1, clear_buff时hero_movement-1
func test_movement_plus_one_buff() -> void:
	_current_test = "test_movement_plus_one_buff"
	var initial_movement = Current.hero.hero_movement

	var meta = {"buff_icon": "", "buff_tooltip": "test", "family": "combo", "tags": []}
	var buff = create_and_set_buff("res://scripts/buff/movement_plus_one_buff.gd", meta)

	# set_buff后hero_movement+1
	assert_eq(Current.hero.hero_movement, initial_movement + 1, "After set_buff: hero_movement should increase by 1")

	# process_buff无操作
	var movement_before = Current.hero.hero_movement
	buff.process_buff()
	assert_eq(Current.hero.hero_movement, movement_before, "After process_buff: hero_movement should not change")

	# clear_buff后hero_movement-1
	buff.clear_buff()
	assert_eq(Current.hero.hero_movement, initial_movement, "After clear_buff: hero_movement should return to initial")

	# 多次set/clear累加
	var buff2 = create_and_set_buff("res://scripts/buff/movement_plus_one_buff.gd", meta)
	assert_eq(Current.hero.hero_movement, initial_movement + 1, "After 2nd set_buff: hero_movement should be initial+1")
	buff2.clear_buff()
	assert_eq(Current.hero.hero_movement, initial_movement, "After 2nd clear_buff: hero_movement should return to initial")

## 2. move_attack_score_increase_buff - int(movement×0.05×once); movement=0不加
func test_move_attack_score_increase_buff() -> void:
	_current_test = "test_move_attack_score_increase_buff"
	Current.once_total_score = 200
	Current.total_score = 0

	var meta = {"buff_icon": "", "buff_tooltip": "test", "family": "combo", "tags": []}
	var buff = create_and_set_buff("res://scripts/buff/move_attack_score_increase_buff.gd", meta)

	# movement=0→int(0*0.05*200)=0
	Current.hero.hero_movement = 0
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, 0, "movement=0: score should not change")

	# movement=4→int(4*0.05*200)=int(40)=40
	Current.hero.hero_movement = 4
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(4 * 0.05 * 200), "movement=4: score should be int(4*0.05*once)")

	# movement=10→int(10*0.05*200)=int(100)=100
	Current.hero.hero_movement = 10
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(10 * 0.05 * 200), "movement=10: score should be int(10*0.05*once)")

	# movement=1→int(1*0.05*200)=int(10)=10
	Current.hero.hero_movement = 1
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(1 * 0.05 * 200), "movement=1: score should be int(1*0.05*once)")

## 3. combo_surge_buff - consecutive_score_rounds每回合+7%, 上限30%
func test_combo_surge_buff() -> void:
	_current_test = "test_combo_surge_buff"
	Current.once_total_score = 1000
	Current.total_score = 0

	var meta = {"buff_icon": "", "buff_tooltip": "test", "family": "combo", "tags": []}
	var buff = create_and_set_buff("res://scripts/buff/combo_surge_buff.gd", meta)

	# consecutive_score_rounds=0 → 不触发
	Current.consecutive_score_rounds = 0
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, 0, "consecutive_score_rounds=0: no bonus")

	# consecutive_score_rounds=1 → 7%, int(1000*0.07)=70
	Current.consecutive_score_rounds = 1
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(1000 * 0.07), "consecutive_score_rounds=1: +7% bonus")

	# consecutive_score_rounds=3 → 21%, int(1000*0.21)=210
	Current.consecutive_score_rounds = 3
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(1000 * 0.21), "consecutive_score_rounds=3: +21% bonus")

	# consecutive_score_rounds=5 → cap at 30%, int(1000*0.30)=300
	Current.consecutive_score_rounds = 5
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(1000 * 0.30), "consecutive_score_rounds=5: +30% bonus (cap)")

	# consecutive_score_rounds=10 → still cap at 30%
	Current.consecutive_score_rounds = 10
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(1000 * 0.30), "consecutive_score_rounds=10: still +30% bonus (cap)")

## 4. rush_strike_buff - movement≥3触发; =2不触发
func test_rush_strike_buff() -> void:
	_current_test = "test_rush_strike_buff"
	Current.once_total_score = 400
	Current.total_score = 0

	var meta = {"buff_icon": "", "buff_tooltip": "test", "family": "combo", "tags": []}
	var buff = create_and_set_buff("res://scripts/buff/rush_strike_buff.gd", meta)

	# movement=2→不触发
	Current.hero.hero_movement = 2
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, 0, "movement=2: should not trigger")

	# movement=3→触发, int(400*0.25)=100
	Current.hero.hero_movement = 3
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(400 * 0.25), "movement=3: should add int(once*0.25)")

	# movement=5→也触发
	Current.hero.hero_movement = 5
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(400 * 0.25), "movement=5: should add int(once*0.25)")

	# movement=0→不触发
	Current.hero.hero_movement = 0
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, 0, "movement=0: should not trigger")

## 5. drop_hunter_buff - drop_slot_dice!=null触发; null不触发
func test_drop_hunter_buff() -> void:
	_current_test = "test_drop_hunter_buff"
	Current.once_total_score = 500
	Current.total_score = 0

	var meta = {"buff_icon": "", "buff_tooltip": "test", "family": "combo", "tags": []}
	var buff = create_and_set_buff("res://scripts/buff/drop_hunter_buff.gd", meta)

	# drop_slot_dice=null→不触发
	Current.drop_slot_dice = null
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, 0, "drop_slot_dice=null: should not trigger")

	# drop_slot_dice有值→触发, int(500*0.20)=100
	Current.drop_slot_dice = ["green", 3]
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(500 * 0.20), "drop_slot_dice has value: should add int(once*0.20)")

	# drop_slot_dice为空字符串→不触发(空字符串!=null但源码检查!=null)
	# 注意：GDScript中空字符串""!=null，所以会触发
	Current.drop_slot_dice = ""
	Current.total_score = 0
	await buff.process_buff()
	# ""!=null为true，所以会触发
	assert_eq(Current.total_score, int(500 * 0.20), "drop_slot_dice='': empty string != null, should trigger")

## 6. position_master_buff - int(once×slime_in_range×0.03); 0个不加
func test_position_master_buff() -> void:
	_current_test = "test_position_master_buff"
	Current.once_total_score = 1000
	Current.total_score = 0

	var meta = {"buff_icon": "", "buff_tooltip": "test", "family": "combo", "tags": []}
	var buff = create_and_set_buff("res://scripts/buff/position_master_buff.gd", meta)

	# 0个史莱姆在攻击范围内→不触发
	_clear_slimes()
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, 0, "0 slimes in range: should not trigger")

	# 3个史莱姆在攻击范围内→int(1000*3*0.03)=int(90)=90
	_clear_slimes()
	add_slime_in_range(Vector2(0, 0))
	add_slime_in_range(Vector2(1, 0))
	add_slime_in_range(Vector2(2, 0))
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(1000 * 3 * 0.03), "3 slimes in range: should add int(once*3*0.03)")

	# 1个史莱姆在攻击范围内→int(1000*1*0.03)=int(30)=30
	_clear_slimes()
	add_slime_in_range(Vector2(0, 0))
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, int(1000 * 1 * 0.03), "1 slime in range: should add int(once*1*0.03)")

	# 史莱姆在all_enemy_array但不在skill_attack_range→不计数
	_clear_slimes()
	add_slime(Vector2(5, 5))  # 不在攻击范围内
	Current.total_score = 0
	await buff.process_buff()
	assert_eq(Current.total_score, 0, "Slime not in range: should not trigger")

## 7. drop_bonus_buff - 每个dropped dice随机+1到对应分数; 0个drop不加
func test_drop_bonus_buff() -> void:
	_current_test = "test_drop_bonus_buff"

	var meta = {"buff_icon": "", "buff_tooltip": "test", "family": "combo", "tags": []}
	var buff = create_and_set_buff("res://scripts/buff/drop_bonus_buff.gd", meta)

	# dropped_dice_count=0→不触发，分数不变
	Current.dropped_dice_count = 0
	var score_before = Current.one_score + Current.two_score + Current.three_score + \
		Current.four_score + Current.five_score + Current.six_score
	buff.process_buff()
	var score_after = Current.one_score + Current.two_score + Current.three_score + \
		Current.four_score + Current.five_score + Current.six_score
	assert_eq(score_after, score_before, "dropped_dice_count=0: total dice score should not change")

	# dropped_dice_count=3→每个dropped dice随机+1，总分应+3
	Current.dropped_dice_count = 3
	var sum_before = Current.one_score + Current.two_score + Current.three_score + \
		Current.four_score + Current.five_score + Current.six_score
	buff.process_buff()
	var sum_after = Current.one_score + Current.two_score + Current.three_score + \
		Current.four_score + Current.five_score + Current.six_score
	assert_eq(sum_after, sum_before + 3, "dropped_dice_count=3: total dice score should increase by 3")

	# dropped_dice_count=1→总分应+1
	Current.dropped_dice_count = 1
	sum_before = Current.one_score + Current.two_score + Current.three_score + \
		Current.four_score + Current.five_score + Current.six_score
	buff.process_buff()
	sum_after = Current.one_score + Current.two_score + Current.three_score + \
		Current.four_score + Current.five_score + Current.six_score
	assert_eq(sum_after, sum_before + 1, "dropped_dice_count=1: total dice score should increase by 1")

## 8. combo_overlord_buff - 连击惯性：移动力+1，连击系得分×连击叠层倍率
func test_combo_overlord_buff() -> void:
	_current_test = "test_combo_overlord_buff"
	var c = Current
	c.total_score = 0
	var max_power_before = c.max_power
	# 设置combo_ramp和family_accumulation供领主查询
	BuffSystem.combo_ramp = 0.30
	BuffSystem._last_family_accumulation = {"combo": 11}
	var meta = {"buff_icon": "", "buff_tooltip": "test", "family": "combo", "tags": ["legendary", "multiplicative"]}
	var buff = create_and_set_buff("res://scripts/buff/combo_overlord_buff.gd", meta)
	# set_buff时移动力+1（需要≥4 combo buffs才会触发，当前只有1个overlord自身不满足）
	# process_buff也需要≥4，不触发
	buff.process_buff()
	assert_eq(c.total_score, 0, "combo_overlord with <4 combo buffs: score should not change")
	# clear_buff恢复移动力
	buff.clear_buff()
	# 清理
	BuffSystem.combo_ramp = 0.0
	BuffSystem._last_family_accumulation = {}
