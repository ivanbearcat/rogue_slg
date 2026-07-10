extends SceneTree
## 命令行运行buff测试: godot --headless --script res://test/scripts/buff/run_buff_tests.gd
## 在主场景环境中执行（所有autoload可用）

var _total: int = 0
var _passed: int = 0
var _failed: int = 0
var _errors: Array = []

func _init():
	## 等待一帧让autoload初始化
	await_frame()

func await_frame():
	await process_frame
	## 需要先加载主场景才能有所有autoload
	## 直接运行测试
	run_all_tests()
	quit()

func run_all_tests():
	print("\n==================================================")
	print("  Buff Unit Test Runner (Headless)")
	print("==================================================")

	## 保存Current状态
	var saved := _save_current_state()

	## 运行所有test_*.gd
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
		if "test_runner" in instance:
			instance.test_runner = self

		var test_methods: Array = []
		for m in instance.get_script_method_list():
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
			if result:
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

	## 恢复Current状态
	_restore_current_state(saved)

	print("\n==================================================")
	print("  Total: %d | Passed: %d | Failed: %d" % [_total, _passed, _failed])
	if _errors.size() > 0:
		print("\n  --- Failed Tests ---")
		for err in _errors:
			print("  %s" % err)
	print("==================================================\n")

func _save_current_state() -> Dictionary:
	return {
		"total_score": Current.total_score,
		"once_total_score": Current.once_total_score,
		"target_score": Current.target_score,
		"player_hp": Current.player_hp,
		"max_hp": Current.max_hp,
		"player_defense": Current.player_defense,
		"count_stage": Current.count_stage,
		"count_round": Current.count_round,
		"total_coins": Current.total_coins,
	}

func _restore_current_state(state: Dictionary) -> void:
	Current.total_score = state["total_score"]
	Current.once_total_score = state["once_total_score"]
	Current.target_score = state["target_score"]
	Current.player_hp = state["player_hp"]
	Current.max_hp = state["max_hp"]
	Current.player_defense = state["player_defense"]
	Current.count_stage = state["count_stage"]
	Current.count_round = state["count_round"]
	Current.total_coins = state["total_coins"]

## 重置Current到测试默认值
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
	Current.all_enemy_array.clear()
	Current.skill_attack_range.clear()
	Current.dice_type_count = 0
	Current.slime_die_sum = 0
	Current.killed_slime_colors = []
	Current.killed_power_slime = false
	Current.last_turn_attacked = false
	Current.consecutive_score_turns = 0
	Current.zero_coin_refresh_times = 0
	Current.zero_coin_refresh_max_times = 0
	Current.iron_stomach_reduction = 0
	Current.public_lock_array.clear()
	Current.dropped_dice_count = 0
	Current.scored_dice_info.clear()
	Current.active_dice_types.clear()
	Current.drop_slot_dice = null
	Current.score_heal_accumulated = 0
