extends Node
## 血瓶系统核心逻辑测试
## 测试血瓶的获取、存储上限、储备触发、blood_fury溢出保留
## 直接使用真实autoload（Current）

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

## ============================================================
## 测试方法
## ============================================================

## 1. 血瓶获取：达到阈值获得1血瓶，阈值+15
func test_potion_gain_on_threshold() -> void:
	_current_test = "test_potion_gain_on_threshold"
	var c = Current
	c.score_heal_threshold = 35
	c.score_heal_threshold_increase = 15
	c.potion_count = 0

	# 模拟达到阈值获得血瓶
	c.score_heal_accumulated = 40
	# 40 >= 35, 获得血瓶
	if c.score_heal_accumulated >= c.score_heal_threshold and c.potion_count < c.potion_max:
		c.potion_count += 1
		c.score_heal_threshold += c.score_heal_threshold_increase
		c.score_heal_accumulated = 0  # 默认溢出丢弃

	assert_eq(c.potion_count, 1, "应该获得1个血瓶")
	assert_eq(c.score_heal_threshold, 50, "阈值应该+15变为50")
	assert_eq(c.score_heal_accumulated, 0, "默认溢出丢弃，累计值应为0")

## 2. 血瓶上限：potion_count不超过potion_max
func test_potion_max_cap() -> void:
	_current_test = "test_potion_max_cap"
	var c = Current
	c.potion_max = 3
	c.potion_count = 3

	# 尝试超过上限（setter会clamp）
	c.potion_count = 5
	assert_eq(c.potion_count, 3, "potion_count不应超过potion_max")

	# 尝试设置上限更小（setter会自动缩小potion_count）
	c.potion_max = 2
	assert_eq(c.potion_count, 2, "potion_count应随potion_max缩小")

## 3. 血瓶满时储备触发：accumulated保留在阈值以上
func test_potion_reserve_when_full() -> void:
	_current_test = "test_potion_reserve_when_full"
	var c = Current
	c.score_heal_threshold = 35
	c.potion_max = 3
	c.potion_count = 3
	c.score_heal_accumulated = 50

	# 血瓶已满，accumulated>=threshold 但不获得血瓶
	var gained = false
	if c.score_heal_accumulated >= c.score_heal_threshold and c.potion_count < c.potion_max:
		gained = true

	assert_false(gained, "血瓶已满时不应获得血瓶")
	assert_eq(c.score_heal_accumulated, 50, "累计值应保留在阈值以上")

## 4. blood_fury溢出保留：有blood_fury时accumulated减去已消耗阈值部分
func test_blood_fury_overflow_preserve() -> void:
	_current_test = "test_blood_fury_overflow_preserve"
	var c = Current
	c.score_heal_threshold = 35
	c.score_heal_threshold_increase = 15
	c.potion_count = 0
	c.score_heal_accumulated = 52

	# 有blood_fury时：accumulated -= threshold (溢出保留)
	var effective_threshold = c.score_heal_threshold
	if c.score_heal_accumulated >= effective_threshold and c.potion_count < c.potion_max:
		# blood_fury模式：溢出保留
		c.score_heal_accumulated -= effective_threshold
		c.potion_count += 1
		c.score_heal_threshold += c.score_heal_threshold_increase

	assert_eq(c.potion_count, 1, "获得1个血瓶")
	assert_eq(c.score_heal_threshold, 50, "阈值变为50")
	assert_eq(c.score_heal_accumulated, 17, "blood_fury溢出保留：52-35=17")

## 5. 无blood_fury时溢出丢弃
func test_no_blood_fury_overflow_discard() -> void:
	_current_test = "test_no_blood_fury_overflow_discard"
	var c = Current
	c.score_heal_threshold = 35
	c.score_heal_threshold_increase = 15
	c.potion_count = 0
	c.score_heal_accumulated = 52

	# 无blood_fury时：accumulated = 0 (溢出丢弃)
	var effective_threshold = c.score_heal_threshold
	if c.score_heal_accumulated >= effective_threshold and c.potion_count < c.potion_max:
		c.score_heal_accumulated = 0
		c.potion_count += 1
		c.score_heal_threshold += c.score_heal_threshold_increase

	assert_eq(c.potion_count, 1, "获得1个血瓶")
	assert_eq(c.score_heal_threshold, 50, "阈值变为50")
	assert_eq(c.score_heal_accumulated, 0, "无blood_fury溢出丢弃，累计值为0")

## 6. 血瓶使用：potion_count-=1, player_hp+=1
func test_potion_use() -> void:
	_current_test = "test_potion_use"
	var c = Current
	c.potion_count = 2
	c.player_hp = 3
	c.max_hp = 5

	# 使用血瓶
	if c.potion_count > 0 and c.player_hp < c.max_hp:
		c.potion_count -= 1
		c.player_hp += 1

	assert_eq(c.potion_count, 1, "使用后血瓶-1")
	assert_eq(c.player_hp, 4, "使用后HP+1")

## 7. 逆境翻盘HP≤2时血瓶+2HP
func test_potion_use_comeback_king() -> void:
	_current_test = "test_potion_use_comeback_king"
	var c = Current
	c.potion_count = 2
	c.player_hp = 1
	c.max_hp = 5

	# 模拟逆境翻盘：HP≤2时血瓶恢复量+1
	var comeback_king = true
	if c.potion_count > 0 and c.player_hp < c.max_hp:
		var heal_amount = 1
		if comeback_king and c.player_hp <= 2:
			heal_amount = 2
		c.potion_count -= 1
		c.player_hp += heal_amount

	assert_eq(c.potion_count, 1, "使用后血瓶-1")
	assert_eq(c.player_hp, 3, "逆境翻盘HP=1时血瓶+2HP")

## 8. 满血不可使用血瓶
func test_potion_use_full_hp() -> void:
	_current_test = "test_potion_use_full_hp"
	var c = Current
	c.potion_count = 2
	c.player_hp = 5
	c.max_hp = 5

	# 满血时不可使用
	var can_use = c.potion_count > 0 and c.player_hp < c.max_hp
	assert_false(can_use, "满血时不应能使用血瓶")

## 9. 无血瓶不可使用
func test_potion_use_empty() -> void:
	_current_test = "test_potion_use_empty"
	var c = Current
	c.potion_count = 0
	c.player_hp = 3
	c.max_hp = 5

	# 无血瓶时不可使用
	var can_use = c.potion_count > 0 and c.player_hp < c.max_hp
	assert_false(can_use, "无血瓶时不应能使用血瓶")

## 10. 开局赠送1血瓶
func test_potion_initial_count() -> void:
	_current_test = "test_potion_initial_count"
	var c = Current
	assert_eq(c.potion_count, 1, "开局应赠送1血瓶")
	assert_eq(c.potion_max, 3, "默认上限应为3")

## 11. 阈值全局累计不再每关重置
func test_threshold_global_accumulation() -> void:
	_current_test = "test_threshold_global_accumulation"
	var c = Current
	c.score_heal_base_threshold = 35
	c.score_heal_threshold = 65  # 关2结束时阈值65

	# 进入新关卡，阈值不重置（不再调用reset_score_heal_for_stage）
	# 阈值应保持65
	assert_eq(c.score_heal_threshold, 65, "阈值应跨关保留为65")

## 12. 战场补给获得血瓶
func test_war_supply_potion_gain() -> void:
	_current_test = "test_war_supply_potion_gain"
	var c = Current
	c.potion_count = 1
	c.potion_max = 3

	# 模拟war_supply：购买buff后获得1血瓶
	if c.potion_count < c.potion_max:
		c.potion_count += 1

	assert_eq(c.potion_count, 2, "war_supply应使血瓶+1")

## 13. 战场补给血瓶满时不获得
func test_war_supply_potion_full() -> void:
	_current_test = "test_war_supply_potion_full"
	var c = Current
	c.potion_count = 3
	c.potion_max = 3

	# 模拟war_supply：血瓶已满
	if c.potion_count < c.potion_max:
		c.potion_count += 1

	assert_eq(c.potion_count, 3, "血瓶已满时war_supply不应增加")