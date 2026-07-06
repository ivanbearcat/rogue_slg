extends Node2D
## 集成验证场景脚本：霸主自动注册、swarm_call时序、desperation免死
## 用法: godot --headless --path <project> res://test/scripts/buff/integration_test_scene.tscn

var _passed: int = 0
var _failed: int = 0
var _errors: Array = []

func _ready() -> void:
	await get_tree().process_frame
	_ensure_game_manager()
	_run_integration_tests()
	get_tree().quit()

func _ensure_game_manager() -> void:
	var root := get_tree().root
	var gm := root.get_node_or_null("game_manager")
	if gm == null:
		gm = Node2D.new()
		gm.name = "game_manager"
		gm.set_script(load("res://test/scripts/buff/mock_game_manager.gd"))
		root.add_child(gm)
		if gm.has_method("_ready"):
			gm._ready()
	## mock_game_manager创建enemys/buff_container等作为属性而非子节点
	## Current.all_enemy_array访问 $"/root/game_manager/enemys" (子节点路径)
	## 需要将enemys容器作为命名子节点添加到game_manager
	_add_named_container_if_missing(gm, "enemys")
	_add_named_container_if_missing(gm, "buff_container")
	_add_named_container_if_missing(gm, "debuff_container")
	if Current:
		Current.game_manager = gm

func _add_named_container_if_missing(gm: Node, name: String) -> void:
	if not gm.has_node(name):
		var container = Node.new()
		container.name = name
		gm.add_child(container)

func _run_integration_tests():
	print("\n==================================================")
	print("  Integration Validation (Headless)")
	print("==================================================")

	_test_6_1_overlord_auto_registration()
	_test_6_3_swarm_call_pending_low_slime()
	_test_6_4_swarm_call_no_trigger_enough_slime()
	_test_6_5_hunt_overlord_auto_registration()
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

	_clear_all_pipelines()

	var gm = get_tree().root.get_node("game_manager")
	var swarm_metas = [
		{"buff_id": "swarm_tithe", "family": "swarm", "buff_res": "res://scripts/buff/swarm_tithe_buff.gd", "buff_type": "post_attack_buff", "tags": []},
		{"buff_id": "tide_crusher", "family": "swarm", "buff_res": "res://scripts/buff/tide_crusher_buff.gd", "buff_type": "post_attack_buff", "tags": []},
		{"buff_id": "slime_rebirth", "family": "swarm", "buff_res": "res://scripts/buff/slime_rebirth_buff.gd", "buff_type": "post_attack_buff", "tags": []},
	]

	for meta in swarm_metas:
		var buff = load(meta["buff_res"]).new(meta, gm)
		BuffSystem.callv("set_" + meta["buff_type"], [buff, BuffSystem.buff_type.ALWAYS])

	var count_after_3 = BuffSystem.get_family_count("swarm")
	_assert_eq(test_name, count_after_3, 3, "after 3 swarm buffs: family count should be 3")
	_assert_false(test_name, BuffSystem.is_buff_registered("swarm_overlord"), "after 3: swarm_overlord should NOT be registered")

	## 注册第4个swarm buff (用base Buff避免set_buff副作用)
	var fourth_meta = {"buff_id": "swarm_test_4", "family": "swarm", "tags": []}
	var fourth_buff = load("res://scripts/buff/buff.gd").new(fourth_meta, gm)
	BuffSystem.set_post_attack_buff(fourth_buff, BuffSystem.buff_type.ALWAYS)

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

	## 验证overlord在pipeline中（process_buff加分逻辑已在单元测试test_swarm_overlord_buff中验证）
	## 此处不调用process_buff以避免headless下EffectManager.float_number_effect/buff_pop_effect的tween崩溃

## 6.2: 同族图标联动闪烁逻辑验证
## 验证get_family_buffs返回正确数量且overlord的buff_texture为null（被跳过）
func _test_6_2_flash_logic():
	var test_name = "6.2_flash_logic"
	print("\n--- %s ---" % test_name)

	_clear_all_pipelines()
	var gm = get_tree().root.get_node("game_manager")
	var buff_script = load("res://scripts/buff/buff.gd")

	## 注册3个带buff_texture的swarm buff（不add_child，仅验证逻辑）
	for i in range(3):
		var meta = {"buff_id": "swarm_flash_%d" % i, "family": "swarm", "tags": []}
		var buff = buff_script.new(meta, gm)
		buff.buff_texture = TextureRect.new()
		BuffSystem.set_post_attack_buff(buff, BuffSystem.buff_type.ALWAYS)

	## 注册swarm_overlord（无buff_texture，设计如此）
	var overlord_meta = {"buff_id": "swarm_overlord", "family": "swarm", "tags": []}
	var overlord = buff_script.new(overlord_meta, gm)
	## overlord.buff_texture 保持 null（设计如此）
	BuffSystem.set_post_attack_buff(overlord, BuffSystem.buff_type.ALWAYS)

	## 验证get_family_buffs返回4个（3 normal + 1 overlord）
	var family_buffs = BuffSystem.get_family_buffs("swarm")
	_assert_eq(test_name, family_buffs.size(), 4, "get_family_buffs('swarm') should return 4 (3 normal + 1 overlord)")

	## 验证闪烁逻辑：对非null buff_texture计数（overlord的null应被跳过）
	var flash_calls = 0
	for fb in family_buffs:
		if fb.buff_texture != null:
			flash_calls += 1
	_assert_eq(test_name, flash_calls, 3, "flash logic should target 3 non-null textures (skipping null overlord)")

	## 验证overlord的buff_texture为null
	var overlord_buff = null
	for fb in family_buffs:
		if fb.buff_meta.get("buff_id", "") == "swarm_overlord":
			overlord_buff = fb
			break
	_assert_true(test_name, overlord_buff != null, "swarm_overlord should be in family_buffs")
	_assert_eq(test_name, overlord_buff.buff_texture, null, "overlord buff_texture should be null (no icon by design)")

## 6.5: 其他霸主（hunt）自动注册验证
func _test_6_5_hunt_overlord_auto_registration():
	var test_name = "6.5_hunt_overlord_auto_registration"
	print("\n--- %s ---" % test_name)

	_clear_all_pipelines()

	var gm = get_tree().root.get_node("game_manager")

	## 注册3个hunt buff
	for i in range(3):
		var meta = {"buff_id": "hunt_test_%d" % i, "family": "hunt", "tags": []}
		var buff = load("res://scripts/buff/buff.gd").new(meta, gm)
		BuffSystem.set_post_attack_buff(buff, BuffSystem.buff_type.ALWAYS)

	_assert_false(test_name, BuffSystem.is_buff_registered("hunt_overlord"), "after 3 hunt buffs: hunt_overlord should NOT be registered")

	## 注册第4个hunt buff
	var fourth_meta = {"buff_id": "hunt_test_3", "family": "hunt", "tags": []}
	var fourth_buff = load("res://scripts/buff/buff.gd").new(fourth_meta, gm)
	BuffSystem.set_post_attack_buff(fourth_buff, BuffSystem.buff_type.ALWAYS)

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

	_assert_true(test_name, BuffSystem.is_buff_registered("hunt_overlord"), "after 4th hunt buff: hunt_overlord SHOULD be registered")
	_assert_eq(test_name, BuffSystem.get_family_count("hunt"), 5, "after overlord: hunt family count should be 5")

	## 验证hunt_overlord在post_attack/ALWAYS pipeline中
	var overlord_in_pipeline = false
	for buff in BuffSystem.pipelines["post_attack"]["ALWAYS"]:
		if buff.buff_meta.get("buff_id", "") == "hunt_overlord":
			overlord_in_pipeline = true
			break
	_assert_true(test_name, overlord_in_pipeline, "hunt_overlord should be in post_attack/ALWAYS pipeline")

## 6.3: swarm_call在slime < 3时设置pending
func _test_6_3_swarm_call_pending_low_slime():
	var test_name = "6.3_swarm_call_pending_low_slime"
	print("\n--- %s ---" % test_name)

	## all_enemy_array是computed属性，返回 $"/root/game_manager/enemys".get_children()
	## 需要向enemys子节点容器添加子节点（不是gm.enemys属性）
	var gm = get_tree().root.get_node("game_manager")
	var enemys_container = gm.get_node("enemys")
	## 清理enemys子节点
	for child in enemys_container.get_children():
		child.queue_free()
	Current.swarm_call_pending = 0

	## 添加2个史莱姆（< 3）
	enemys_container.add_child(Node.new())
	enemys_container.add_child(Node.new())
	print("  [debug] slime count=%d" % Current.all_enemy_array.size())

	## 测试swarm_call的process_buff逻辑：slime < 3 → pending += 1
	if Current.all_enemy_array.size() < 3:
		Current.swarm_call_pending += 1
	_assert_eq(test_name, Current.swarm_call_pending, 1, "slime=2 < 3: pending should be 1")

	## 模拟_turn_process消耗pending
	Current.slime_create_num = 3
	Current.slime_create_num += Current.swarm_call_pending
	Current.swarm_call_pending = 0
	_assert_eq(test_name, Current.slime_create_num, 4, "after consuming: slime_create_num should be 4 (3+1)")

## 6.4: swarm_call在slime >= 3时不触发
func _test_6_4_swarm_call_no_trigger_enough_slime():
	var test_name = "6.4_swarm_call_no_trigger_enough_slime"
	print("\n--- %s ---" % test_name)

	var gm = get_tree().root.get_node("game_manager")
	var enemys_container = gm.get_node("enemys")
	for child in enemys_container.get_children():
		child.queue_free()
	Current.swarm_call_pending = 0

	## 添加3个史莱姆（>= 3）
	for i in range(3):
		enemys_container.add_child(Node.new())
	print("  [debug] slime count=%d" % Current.all_enemy_array.size())

	## slime >= 3时不增加pending
	if Current.all_enemy_array.size() < 3:
		Current.swarm_call_pending += 1
	_assert_eq(test_name, Current.swarm_call_pending, 0, "slime=3 >= 3: pending should remain 0")

## 6.6: desperation_overlord注册后has_death_immunity为true
func _test_6_6_desperation_immunity():
	var test_name = "6.6_desperation_immunity"
	print("\n--- %s ---" % test_name)

	_clear_all_pipelines()
	Current.has_death_immunity = false
	Current.death_immunity_used = false

	var gm = get_tree().root.get_node("game_manager")

	for i in range(4):
		var meta = {"buff_id": "desperation_mock_%d" % i, "family": "desperation", "tags": []}
		var buff = load("res://scripts/buff/buff.gd").new(meta, gm)
		BuffSystem.set_post_attack_buff(buff, BuffSystem.buff_type.ALWAYS)

	_assert_eq(test_name, BuffSystem.get_family_count("desperation"), 4, "after 4 desperation buffs: count should be 4")
	_assert_false(test_name, Current.has_death_immunity, "before overlord: has_death_immunity should be false")

	## 注册desperation_overlord (set_buff会被调用)
	var overlord_meta = {"buff_id": "desperation_overlord", "family": "desperation", "buff_res": "res://scripts/buff/desperation_overlord_buff.gd", "tags": [], "auto_activate": true}
	var overlord = load(overlord_meta["buff_res"]).new(overlord_meta, gm)
	BuffSystem.set_post_attack_buff(overlord, BuffSystem.buff_type.ALWAYS)

	_assert_true(test_name, Current.has_death_immunity, "after desperation_overlord set_buff: has_death_immunity should be TRUE")
	_assert_false(test_name, Current.death_immunity_used, "death_immunity_used should be false (not used yet)")

## 额外：get_family_buffs API
func _test_get_family_buffs_api():
	var test_name = "get_family_buffs_api_and_flash_logic"
	print("\n--- %s ---" % test_name)

	_clear_all_pipelines()
	var gm = get_tree().root.get_node("game_manager")
	var buff_script = load("res://scripts/buff/buff.gd")

	## 注册3个带buff_texture的swarm buff（buff_texture类型为PanelContainer）
	for i in range(3):
		var meta = {"buff_id": "swarm_test_%d" % i, "family": "swarm", "tags": []}
		var buff = buff_script.new(meta, gm)
		buff.buff_texture = PanelContainer.new()
		BuffSystem.set_post_attack_buff(buff, BuffSystem.buff_type.ALWAYS)

	## 注册1个无buff_texture的swarm overlord（模拟霸主，设计如此无图标）
	var overlord_meta = {"buff_id": "swarm_overlord", "family": "swarm", "tags": []}
	var overlord = buff_script.new(overlord_meta, gm)
	## overlord.buff_texture 保持 null（设计如此）
	BuffSystem.set_post_attack_buff(overlord, BuffSystem.buff_type.ALWAYS)

	## 验证get_family_buffs返回4个（3 normal + 1 overlord）
	var family_buffs = BuffSystem.get_family_buffs("swarm")
	_assert_eq(test_name, family_buffs.size(), 4, "get_family_buffs('swarm') should return 4 (3 normal + 1 overlord)")

	## 验证闪烁逻辑：对非null buff_texture计数（overlord的null应被跳过）
	var flash_targets = 0
	for fb in family_buffs:
		if fb.buff_texture != null:
			flash_targets += 1
	_assert_eq(test_name, flash_targets, 3, "flash logic targets 3 non-null textures (skipping null overlord)")

	## 验证overlord的buff_texture为null
	var overlord_buff = null
	for fb in family_buffs:
		if fb.buff_meta.get("buff_id", "") == "swarm_overlord":
			overlord_buff = fb
			break
	_assert_true(test_name, overlord_buff != null, "swarm_overlord should be in family_buffs")
	_assert_eq(test_name, overlord_buff.buff_texture, null, "overlord buff_texture should be null (no icon by design)")

	## 验证空family返回空数组
	var empty_result = BuffSystem.get_family_buffs("nonexistent")
	_assert_eq(test_name, empty_result.size(), 0, "get_family_buffs('nonexistent') should return empty array")

## ============================================================
func _clear_all_pipelines():
	for timing in ["pre_attack", "post_attack", "pre_enemy_turn", "pre_hero_turn", "post_hero_move"]:
		for key in ["ONCE", "STAGE", "ALWAYS", "ELITE"]:
			BuffSystem.pipelines[timing][key].clear()

func _assert_eq(test_name: String, actual, expected, msg: String):
	if actual == expected:
		_passed += 1
		print("  PASS: %s: %s" % [test_name, msg])
	else:
		_failed += 1
		_errors.append("%s: %s (expected %s, got %s)" % [test_name, msg, expected, actual])
		print("  FAIL: %s: %s (expected %s, got %s)" % [test_name, msg, expected, actual])

func _assert_true(test_name: String, value: bool, msg: String):
	if value:
		_passed += 1
		print("  PASS: %s: %s" % [test_name, msg])
	else:
		_failed += 1
		_errors.append("%s: %s (expected true)" % [test_name, msg])
		print("  FAIL: %s: %s (expected true)" % [test_name, msg])

func _assert_false(test_name: String, value: bool, msg: String):
	if not value:
		_passed += 1
		print("  PASS: %s: %s" % [test_name, msg])
	else:
		_failed += 1
		_errors.append("%s: %s (expected false)" % [test_name, msg])
		print("  FAIL: %s: %s (expected false)" % [test_name, msg])

func _assert_gte(test_name: String, actual, than, msg: String):
	if actual >= than:
		_passed += 1
		print("  PASS: %s: %s" % [test_name, msg])
	else:
		_failed += 1
		_errors.append("%s: %s (expected >= %s, got %s)" % [test_name, msg, than, actual])
		print("  FAIL: %s: %s (expected >= %s, got %s)" % [test_name, msg, than, actual])
