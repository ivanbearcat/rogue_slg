extends SceneTree
## 命令行运行buff测试: godot --headless --script res://test/scripts/buff/run_buff_tests.gd
## 在主场景环境中执行（所有autoload可用）

## autoload 编译期不可见：--script 主循环脚本在 autoload 注册前编译，
## 一律按 save_codec_test 同款运行时取用（root.get_node）
func _cur() -> Node:
	return root.get_node("Current")

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
		"total_score": _cur().total_score,
		"once_total_score": _cur().once_total_score,
		"target_score": _cur().target_score,
		"player_hp": _cur().player_hp,
		"max_hp": _cur().max_hp,
		"player_defense": _cur().player_defense,
		"count_stage": _cur().count_stage,
		"count_round": _cur().count_round,
		"total_coins": _cur().total_coins,
	}

func _restore_current_state(state: Dictionary) -> void:
	_cur().total_score = state["total_score"]
	_cur().once_total_score = state["once_total_score"]
	_cur().target_score = state["target_score"]
	_cur().player_hp = state["player_hp"]
	_cur().max_hp = state["max_hp"]
	_cur().player_defense = state["player_defense"]
	_cur().count_stage = state["count_stage"]
	_cur().count_round = state["count_round"]
	_cur().total_coins = state["total_coins"]

## 重置Current到测试默认值
func reset_current_to_defaults() -> void:
	_cur().total_score = 0
	_cur().once_total_score = 0
	_cur().target_score = 100
	_cur().player_hp = 5
	_cur().max_hp = 5
	_cur().player_defense = 2
	_cur().count_stage = 1
	_cur().count_round = 1
	_cur().total_coins = 0
	_cur().power_slime_num = 1
	_cur().max_power = 2
	_cur().power = 0
	if _cur().hero:
		_cur().hero.hero_movement = 0
	_cur().all_enemy_array.clear()
	_cur().skill_attack_range.clear()
	_cur().dice_type_count = 0
	_cur().slime_die_sum = 0
	_cur().killed_slime_colors = []
	_cur().killed_power_slime = false
	_cur().last_turn_attacked = false
	_cur().consecutive_score_turns = 0
	_cur().zero_coin_refresh_times = 0
	_cur().zero_coin_refresh_max_times = 0
	_cur().iron_stomach_reduction = 0
	_cur().public_lock_array.clear()
	_cur().dropped_dice_count = 0
	_cur().scored_dice_info.clear()
	_cur().active_dice_types.clear()
	_cur().drop_slot_dice = null
	_cur().score_heal_accumulated = 0
