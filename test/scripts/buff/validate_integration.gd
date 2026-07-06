extends SceneTree
## 集成验证：霸主自动注册、swarm_call时序、desperation免死
## 用法: godot --headless --path <project> --script res://test/scripts/buff/validate_integration.gd
##
## 验证任务 6.1/6.3/6.4/6.6 的逻辑（headless无UI环境）

var _passed: int = 0
var _failed: int = 0
var _errors: Array = []

func _init():
	await process_frame
	_run_integration_tests()
	quit()

func _run_integration_tests():
	print("\n==================================================")
	print("  Integration Validation (Headless)")
	print("==================================================")

	## 确保game_manager存在
	var root = get_root()
	var gm = root.get_node_or_null("game_manager")
	if gm == null:
		## 加载mock game_manager
		gm = Node2D.new()
		gm.name = "game_manager"
		gm.set_script(load("res://test/scripts/buff/mock_game_manager.gd"))
		root.add_child(gm)
		if gm.has_method("_ready"):
			gm._ready()
	## 修复Current对game_manager的引用
	if Current:
		Current.game_manager = gm

	_test_6_1_overlord_auto_registration()
	_test_6_3_swarm_call_pending_low_slime()
	_test_6_4_swarm_call_no_trigger_enough_slime()
	_test_6_6_desperation_immunity()
	_test_get_family_buffs_api()

	print("--------------------------------------------------")
	print("  Passed: %d | Failed: %d" % [_passed, _failed])
	if _errors.size() > 0:
		print("  --- Failures ---")
		for err in _errors:
			print("  %s" % err)
	print("==================================================\n")

## 6.1: 购买4个swarm系buff → swarm_overlord自动注册到pipeline
func _test_6_1_overlord_auto_registration():
	var test_name = "6.1_overlord_auto_registration"
	print("\n--- %s ---" % test_name)

	## 清理pipeline
	_clear_all_pipelines()

	## 注册3个swarm buff（通过BuffSystem直接注册，模拟_set_buff的效果）
	var gm = get_root().get_node("game_manager")
	var swarm_metas = [
		{"buff_id": "swarm_tithe", "family": "swarm", "buff_res": "res://scripts/buff/swarm_tithe_buff.gd", "buff_type": "post_attack_buff", "tags": []},
		{"buff_id": "swarm_call", "family": "swarm", "buff_res": "res://scripts/buff/swarm_call_buff.gd", "buff_type": "pre_enemy_turn_buff", "tags": []},
		{"buff_id": "tide_crusher", "family": "swarm", "buff_res": "res://scripts/buff/tide_crusher_buff.gd", "buff_type": "post_attack_buff", "tags": []},
	]

	for meta in swarm_metas:
		var buff = load(meta["buff_res"]).new(meta, gm)
		BuffSystem.callv("set_" + meta["buff_type"], [buff, BuffSystem.buff_type.ALWAYS])

	var count_after_3 = BuffSystem.get_family_count("swarm")
	_assert_eq(test_name, count_after_3, 3, "after 3 swarm buffs: family count should be 3")
	_assert_false(test_name, BuffSystem.is_buff_registered("swarm_overlord"), "after 3: swarm_overlord should NOT be registered")

	## 注册第4个swarm buff
	var fourth_meta = {"buff_id": "slime_tide", "family": "swarm", "buff_res": "res://scripts/buff/slime_tide_buff.gd", "buff_type": "pre_hero_turn_buff", "tags": []}
	var fourth_buff = load(fourth_meta["buff_res"]).new(fourth_meta, gm)
	BuffSystem.callv("set_" + fourth_meta["buff_type"], [fourth_buff, BuffSystem.buff_type.ALWAYS])

	## 模拟_set_buff末尾的霸主自动注册逻辑
	var buff_family = fourth_buff.family
	if buff_family != "" and BuffSystem.get_family_count(buff_family) >= 4:
		var buff_json_data = Tools.load_json_file("res://config/buff.json")
		for overlord_row in buff_json_data:
			if overlord_row.get("family", "") == buff_family and overlord_row.get("auto_activate", false):
				var overlord_id = overlord_row.get("buff_id", "")
				if not BuffSystem.is_buff_registered(overlord_id):
					var overlord = load(overlord_row["buff_res"]).new(overlord_row, gm)
					BuffSystem.set_post_attack_buff(overlord, BuffSystem.buff_type.ALWAYS)

	var count_after_4 = BuffSystem.get_family_count("swarm")
	_assert_eq(test_name, count_after_4, 5, "after 4th + overlord: family count should be 5 (4 normal + 1 overlord)")
	_assert_true(test_name, BuffSystem.is_buff_registered("swarm_overlord"), "after 4th: swarm_overlord SHOULD be registered")

	## 验证overlord在post_attack/ALWAYS pipeline中
	var overlord_in_pipeline = false
	for buff in BuffSystem.pipelines["post_attack"]["ALWAYS"]:
		if buff.buff_meta.get("buff_id", "") == "swarm_overlord":
			overlord_in_pipeline = true
			break
	_assert_true(test_name, overlord_in_pipeline, "swarm_overlord should be in post_attack/ALWAYS pipeline")

	## 验证process_buff能被调用（family_count >= 4 → 不early return）
	Current.all_enemy_array.clear()
	Current.once_total_score = 1000
	Current.total_score = 0
	Current.hero = Node2D.new()
	## 添加5个有效史莱姆
	for i in range(5):
		var slime = Node.new()
		Current.all_enemy_array.append(slime)
	## 找到overlord并调用process_buff
	for buff in BuffSystem.pipelines["post_attack"]["ALWAYS"]:
		if buff.buff_meta.get("buff_id", "") == "swarm_overlord":
			buff.process_buff()
			break
	## bonus = roundi(1000 * 5 * 0.03) = 150
	_assert_eq(test_name, Current.total_score, 150, "swarm_overlord process_buff: bonus should be roundi(1000*5*0.03)=150")

## 6.3: swarm_call在slime < 3时设置pending
func _test_6_3_swarm_call_pending_low_slime():
	var test_name = "6.3_swarm_call_pending_low_slime"
	print("\n--- %s ---" % test_name)

	Current.all_enemy_array.clear()
	Current.swarm_call_pending = 0

	var gm = get_root().get_node("game_manager")
	var meta = {"buff_id": "swarm_call", "family": "swarm", "buff_res": "res://scripts/buff/swarm_call_buff.gd", "tags": []}
	var buff = load(meta["buff_res"]).new(meta, gm)
	buff.buff_texture = TextureRect.new()

	## 添加2个史莱姆（< 3）
	Current.all_enemy_array.append(Node.new())
	Current.all_enemy_array.append(Node.new())

	buff.process_buff()
	_assert_eq(test_name, Current.swarm_call_pending, 1, "slime=2 < 3: pending should be 1")

	## 模拟_turn_process消耗
	Current.slime_create_num = 3
	Current.slime_create_num += Current.swarm_call_pending
	Current.swarm_call_pending = 0
	_assert_eq(test_name, Current.slime_create_num, 4, "after consuming: slime_create_num should be 4 (3+1)")

## 6.4: swarm_call在slime >= 3时不触发
func _test_6_4_swarm_call_no_trigger_enough_slime():
	var test_name = "6.4_swarm_call_no_trigger_enough_slime"
	print("\n--- %s ---" % test_name)

	Current.all_enemy_array.clear()
	Current.swarm_call_pending = 0

	var gm = get_root().get_node("game_manager")
	var meta = {"buff_id": "swarm_call", "family": "swarm", "buff_res": "res://scripts/buff/swarm_call_buff.gd", "tags": []}
	var buff = load(meta["buff_res"]).new(meta, gm)
	buff.buff_texture = TextureRect.new()

	## 添加3个史莱姆（>= 3）
	for i in range(3):
		Current.all_enemy_array.append(Node.new())

	buff.process_buff()
	_assert_eq(test_name, Current.swarm_call_pending, 0, "slime=3 >= 3: pending should remain 0")

## 6.6: desperation_overlord注册后has_death_immunity为true
func _test_6_6_desperation_immunity():
	var test_name = "6.6_desperation_immunity"
	print("\n--- %s ---" % test_name)

	_clear_all_pipelines()
	Current.has_death_immunity = false
	Current.death_immunity_used = false

	var gm = get_root().get_node("game_manager")

	## 注册4个desperation buff
	var desperation_metas = [
		{"buff_id": "crisis_power", "family": "desperation", "buff_res": "res://scripts/buff/crisis_power_buff.gd", "buff_type": "post_attack_buff", "tags": []},
	]
	## 只注册1个真实的，其余用mock（避免依赖过多真实buff的set_buff副作用）
	for i in range(3):
		var mock_meta = {"buff_id": "desperation_mock_%d" % i, "family": "desperation", "tags": []}
		var buff_script = load("res://scripts/buff/buff.gd")
		var buff = buff_script.new(mock_meta, gm)
		BuffSystem.set_post_attack_buff(buff, BuffSystem.buff_type.ALWAYS)

	## 第4个
	var fourth_meta = {"buff_id": "desperation_mock_3", "family": "desperation", "tags": []}
	var fourth_buff = load("res://scripts/buff/buff.gd").new(fourth_meta, gm)
	BuffSystem.set_post_attack_buff(fourth_buff, BuffSystem.buff_type.ALWAYS)

	_assert_eq(test_name, BuffSystem.get_family_count("desperation"), 4, "after 4 desperation buffs: count should be 4")
	_assert_false(test_name, Current.has_death_immunity, "before overlord: has_death_immunity should be false")

	## 模拟霸主自动注册
	var overlord_meta = {"buff_id": "desperation_overlord", "family": "desperation", "buff_res": "res://scripts/buff/desperation_overlord_buff.gd", "tags": [], "auto_activate": true}
	var overlord = load(overlord_meta["buff_res"]).new(overlord_meta, gm)
	BuffSystem.set_post_attack_buff(overlord, BuffSystem.buff_type.ALWAYS)

	_assert_true(test_name, Current.has_death_immunity, "after desperation_overlord set_buff: has_death_immunity should be TRUE")
	_assert_false(test_name, Current.death_immunity_used, "death_immunity_used should be false (not used yet)")

## 额外验证：get_family_buffs API返回正确数量
func _test_get_family_buffs_api():
	var test_name = "get_family_buffs_api"
	print("\n--- %s ---" % test_name)

	## 此时pipeline中有swarm buffs（从6.1测试遗留）或desperation buffs（从6.6测试）
	## 清理后重新注册
	_clear_all_pipelines()
	var gm = get_root().get_node("game_manager")

	for i in range(4):
		var meta = {"buff_id": "swarm_test_%d" % i, "family": "swarm", "tags": []}
		var buff = load("res://scripts/buff/buff.gd").new(meta, gm)
		buff.buff_texture = TextureRect.new()
		BuffSystem.set_post_attack_buff(buff, BuffSystem.buff_type.ALWAYS)

	var family_buffs = BuffSystem.get_family_buffs("swarm")
	_assert_eq(test_name, family_buffs.size(), 4, "get_family_buffs('swarm') should return 4 buffs")

	var empty_result = BuffSystem.get_family_buffs("nonexistent")
	_assert_eq(test_name, empty_result.size(), 0, "get_family_buffs('nonexistent') should return empty array")

## ============================================================
## 辅助方法
## ============================================================

func _clear_all_pipelines():
	for timing in ["pre_attack", "post_attack", "pre_enemy_turn", "pre_hero_turn", "post_hero_move"]:
		for key in ["ONCE", "STAGE", "ALWAYS", "ELITE"]:
			BuffSystem.pipelines[timing][key].clear()

func _assert_eq(test_name: String, actual, expected, msg: String):
	_passed += 1 if actual == expected else 0
	_failed += 0 if actual == expected else 1
	if actual != expected:
		_errors.append("%s: %s (expected %s, got %s)" % [test_name, msg, expected, actual])
		print("  FAIL: %s: %s (expected %s, got %s)" % [test_name, msg, expected, actual])
	else:
		print("  PASS: %s: %s" % [test_name, msg])

func _assert_true(test_name: String, value: bool, msg: String):
	_passed += 1 if value else 0
	_failed += 0 if value else 1
	if not value:
		_errors.append("%s: %s (expected true)" % [test_name, msg])
		print("  FAIL: %s: %s (expected true)" % [test_name, msg])
	else:
		print("  PASS: %s: %s" % [test_name, msg])

func _assert_false(test_name: String, value: bool, msg: String):
	_passed += 1 if not value else 0
	_failed += 0 if not value else 1
	if value:
		_errors.append("%s: %s (expected false)" % [test_name, msg])
		print("  FAIL: %s: %s (expected false)" % [test_name, msg])
	else:
		print("  PASS: %s: %s" % [test_name, msg])
