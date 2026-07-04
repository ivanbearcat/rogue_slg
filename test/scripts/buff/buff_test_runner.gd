extends Node2D
## Buff 测试运行器
## 用法：在游戏主场景运行时，通过调试面板或命令行调用 run_tests()
##
## 原理：
## Godot 4的autoload全局变量(Current/SceneManager等)是编译时绑定的，
## 无法通过替换/root/下节点来mock。因此测试直接操作真实autoload属性。
## 1. 保存 Current 的所有测试相关属性值
## 2. 运行所有 test/scripts/buff/test_*.gd 测试脚本
## 3. 恢复 Current 的原始属性值

signal all_tests_complete(total: int, passed: int, failed: int)

var _total: int = 0
var _passed: int = 0
var _failed: int = 0
var _errors: Array = []
var _is_running: bool = false

## 保存的 Current 原始属性
var _saved_current_state: Dictionary = {}

func _ready() -> void:
	## 等待一帧让autoload完成初始化，避免 add_child 时序冲突
	await get_tree().process_frame
	## 确保game_manager节点存在于/root下（Current等autoload依赖它）
	_ensure_game_manager()
	## 修复 Current autoload 中对 game_manager 的引用
	_fix_current_game_manager_ref()
	## 手动触发 mock game_manager 的 _ready() 初始化
	var gm := get_tree().root.get_node_or_null("game_manager")
	if gm and gm.has_method("_ready"):
		gm._ready()
	## 自动运行测试
	run_tests()

func _ensure_game_manager() -> void:
	var root := get_tree().root
	var gm := root.get_node_or_null("game_manager")
	if gm == null:
		## 创建mock game_manager添加到/root
		gm = Node2D.new()
		gm.name = "game_manager"
		gm.set_script(load("res://test/scripts/buff/mock_game_manager.gd"))
		root.add_child(gm)
		print("  [Test Runner] Created mock game_manager at /root/game_manager")
		## 手动触发 _ready() 确保 mock 初始化
		if gm.has_method("_ready"):
			gm._ready()
	else:
		print("  [Test Runner] Using existing game_manager at /root/game_manager")

func _fix_current_game_manager_ref() -> void:
	## Current autoload 的 @onready var game_manager 在 _ready() 时获取失败
	## 因为那时 game_manager 节点还不存在。这里手动修复引用。
	var root := get_tree().root
	var gm := root.get_node_or_null("game_manager")
	if gm and Current:
		Current.game_manager = gm
		print("  [Test Runner] Fixed Current.game_manager reference")

func run_tests() -> void:
	if _is_running:
		print("Tests already running!")
		return
	_is_running = true

	print("\n==================================================")
	print("  Buff Unit Test Runner")
	print("==================================================")

	## 注意：F6运行测试场景时，Current.game_manager可能为null
	## 因为game_manager不是autoload。跳过保存/恢复Current状态。
	## 直接运行测试（测试中手动设置Current属性）
	await _run_all_tests()

	print("\n==================================================")
	print("  Total: %d | Passed: %d | Failed: %d" % [_total, _passed, _failed])
	if _errors.size() > 0:
		print("\n  --- Failed Tests ---")
		for err in _errors:
			print("  %s" % err)
	print("==================================================\n")

	_is_running = false
	all_tests_complete.emit(_total, _passed, _failed)

func _save_current_state() -> void:
	_saved_current_state = {
		"total_score": Current.total_score,
		"once_total_score": Current.once_total_score,
		"target_score": Current.target_score,
		"player_hp": Current.player_hp,
		"max_hp": Current.max_hp,
		"player_defense": Current.player_defense,
		"count_stage": Current.count_stage,
		"count_round": Current.count_round,
		"total_coins": Current.total_coins,
		"power_slime_num": Current.power_slime_num,
		"max_power": Current.max_power,
		"hero_movement": Current.hero.hero_movement if Current.hero else 0,
		"slime_die_sum": Current.slime_die_sum,
		"pattern_kill_sum": Current.pattern_kill_sum,
		"killed_power_slime": Current.killed_power_slime,
		"last_turn_attacked": Current.last_turn_attacked,
		"consecutive_score_turns": Current.consecutive_score_turns,
		"zero_coin_refresh_times": Current.zero_coin_refresh_times,
		"zero_coin_refresh_max_times": Current.zero_coin_refresh_max_times,
		"iron_stomach_reduction": Current.iron_stomach_reduction,
		"dice_type_count": Current.dice_type_count,
	}

func _restore_current_state() -> void:
	if _saved_current_state.is_empty():
		return
	Current.total_score = _saved_current_state["total_score"]
	Current.once_total_score = _saved_current_state["once_total_score"]
	Current.target_score = _saved_current_state["target_score"]
	Current.player_hp = _saved_current_state["player_hp"]
	Current.max_hp = _saved_current_state["max_hp"]
	Current.player_defense = _saved_current_state["player_defense"]
	Current.count_stage = _saved_current_state["count_stage"]
	Current.count_round = _saved_current_state["count_round"]
	Current.total_coins = _saved_current_state["total_coins"]
	Current.power_slime_num = _saved_current_state["power_slime_num"]
	Current.max_power = _saved_current_state["max_power"]
	if Current.hero:
		Current.hero.hero_movement = _saved_current_state["hero_movement"]
	Current.slime_die_sum = _saved_current_state["slime_die_sum"]
	Current.pattern_kill_sum = _saved_current_state["pattern_kill_sum"]
	Current.killed_power_slime = _saved_current_state["killed_power_slime"]
	Current.last_turn_attacked = _saved_current_state["last_turn_attacked"]
	Current.consecutive_score_turns = _saved_current_state["consecutive_score_turns"]
	Current.zero_coin_refresh_times = _saved_current_state["zero_coin_refresh_times"]
	Current.zero_coin_refresh_max_times = _saved_current_state["zero_coin_refresh_max_times"]
	Current.iron_stomach_reduction = _saved_current_state["iron_stomach_reduction"]
	Current.dice_type_count = _saved_current_state["dice_type_count"]

## 重置 Current 到干净的测试默认值
func reset_current_to_defaults() -> void:
	Current.total_score = 0
	Current.once_total_score = 0
	Current.target_score = 100
	Current.player_hp = 5
	Current.max_hp = 5
	Current.player_defense = 2
	Current.count_stage = 1
	Current.count_round = 1
	Current.total_coins = 0
	Current.power_slime_num = 1
	Current.max_power = 2
	Current.power = 0
	if Current.hero:
		Current.hero.hero_movement = 0
	Current.all_enemy_array = []
	Current.skill_attack_range = []
	Current.dice_type_count = 0
	Current.slime_die_sum = 0
	Current.killed_slime_colors = []
	Current.pattern_kill_sum = 0
	Current.killed_power_slime = false
	Current.last_turn_attacked = false
	Current.consecutive_score_turns = 0
	Current.zero_coin_refresh_times = 0
	Current.zero_coin_refresh_max_times = 0
	Current.iron_stomach_reduction = 0
	Current.public_lock_array = []
	Current.dropped_dice_count = 0
	Current.scored_dice_info = []
	Current.active_dice_types = []
	Current.drop_slot_dice = null
	Current.score_heal_accumulated = 0

func _run_all_tests() -> void:
	var test_dir := "res://test/scripts/buff/"
	var da := DirAccess.open(test_dir)
	if da == null:
		print("ERROR: Cannot open test directory: %s" % test_dir)
		return

	da.list_dir_begin()
	var file_name := da.get_next()
	var test_scripts: Array = []
	while file_name != "":
		if file_name.ends_with(".gd") and file_name.begins_with("test_"):
			test_scripts.append(test_dir + file_name)
		file_name = da.get_next()
	da.list_dir_end()
	test_scripts.sort()

	for script_path in test_scripts:
		print("\n--- %s ---" % script_path.get_file())
		var script := load(script_path)
		if script == null:
			print("  ERROR: Could not load: %s" % script_path)
			continue

		var instance = script.new()
		add_child(instance)

		## 注入runner引用
		if "test_runner" in instance:
			instance.test_runner = self

		var test_methods: Array = []
		# 使用 script.get_script_method_list() 而非 instance.get_script_method_list()
		# 避免 Buff class_name 缓存冲突导致方法列表为空的问题
		for m in script.get_script_method_list():
			if m.name.begins_with("test_"):
				test_methods.append(m.name)
		test_methods.sort()

		if instance.has_method("before_all"):
			instance.before_all()

		for method_name in test_methods:
			if instance.has_method("before_each"):
				instance.before_each()

			_total += 1
			instance._test_failed = false
			instance._current_test = method_name

			var result = instance.call(method_name)
			if result != null:
				await result

			if instance._test_failed:
				_failed += 1
				_errors.append("%s::%s" % [script_path.get_file(), method_name])
				print("  FAIL: %s" % method_name)
			else:
				_passed += 1
				print("  PASS: %s" % method_name)

			if instance.has_method("after_each"):
				instance.after_each()

		if instance.has_method("after_all"):
			instance.after_all()

		remove_child(instance)
		instance.queue_free()
