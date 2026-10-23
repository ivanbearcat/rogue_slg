extends Node

## ============================================================
## 结算毛收入口径探针（headless）—— fix-settlement-run-totals 验证
## 用法: godot --headless --path . res://test/scripts/end_settlement/totals_probe.tscn
##
## 覆盖：
##   1.2/1.3  setter 收口：正增量计入毛收入；花销/减分/自刷新不减
##   1.4      起始 15 金币经 setter 计入毛收入
##   2.1/2.2  hero_move 配对快照 + 撤回配对回滚（多次撤回/重移循环不漂移）
##   3.2/3.3  回合边界快照含 4 键 + apply 灌入往返等价、零二次累计
##   3.4      旧档兼容（快照无 4 键 → flush/read/apply 正常，不判坏档）
##   4.1      胜利态 run_end 快照：总得分=毛收入非 0、总金币=毛收入
##   4.2/5.3  失败态 run_end 快照：总金币=毛收入含已花、总得分=全程累计；
##            再玩一次新开局累计器从 0 起算
## ============================================================

var _passed := 0
var _failed := 0
var _fail_names: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	## 探针保活：本场景作为启动 current_scene 时会被第一次 change_scene 释放，摘除注册避开
	if get_tree().current_scene == self:
		get_tree().current_scene = null
	await _run_all()
	print("\n=== RunTotals 探针：通过 %d / 失败 %d ===" % [_passed, _failed])
	for fail_name in _fail_names:
		print("  [FAIL-项] ", fail_name)
	await get_tree().process_frame
	get_tree().quit(1 if _failed > 0 else 0)


func _check(test_name: String, cond: bool) -> void:
	if cond:
		_passed += 1
		print("  [PASS] ", test_name)
	else:
		_failed += 1
		_fail_names.append(test_name)
		print("  [FAIL] ", test_name)


func _wait_until(predicate: Callable, timeout_s := 30.0, poll_s := 0.06) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_s * 1000)
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await get_tree().create_timer(poll_s).timeout
	return false


func _clean_slot() -> void:
	for path in [SaveManager.SAVE_PATH, SaveManager.STAGING_PATH, SaveManager.CORRUPT_PATH]:
		SaveManager._remove_file(path)


func _boot_main() -> Node:
	SceneManager.change_scene(&"main")
	var got := await _wait_until(func() -> bool:
		var sc: Node = SceneManager.current_scene
		## 战局就绪判定：已入树 + 已 ready + 挂队清空 + 回合按钮已启用
		if sc == null or not (sc is Node2D) or not sc.is_inside_tree() \
			or not sc.is_node_ready() or SceneManager._pending_scene != null:
			return false
		return not sc.turn_button.disabled, 60.0)
	if not got:
		_check("战局启动", false)
		return null
	return SceneManager.current_scene


## 为 hero_move 选一个相邻空格作为目标（避开英雄/史莱姆占用格）
func _find_free_target(hero: Node) -> Vector2:
	for off in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var cand: Vector2 = hero.hero_grid_index + off
		if Current.all_hero_grid_index_array.has(cand) \
			or Current.all_enemy_grid_index_array.has(cand):
			continue
		return cand
	return Vector2(-999, -999)


func _run_all() -> void:
	print("=== RunTotals 探针开始 ===")
	_clean_slot()
	## ---------- A. 新局起始与 setter 收口（1.4 / 1.2 / 1.3）----------
	var gm: Node = await _boot_main()
	if gm == null:
		return
	_check("1.4 新开局起始金币计入毛收入（_run_coins_earned==15）", Current._run_coins_earned == 15)
	var coins_earned0: int = Current._run_coins_earned
	var score_earned0: int = Current._run_score_earned
	Current.total_coins += 25
	_check("1.3 total_coins 正增量计入", Current._run_coins_earned == coins_earned0 + 25)
	Current.total_coins -= 10
	_check("1.3 花销不扣减毛收入", Current._run_coins_earned == coins_earned0 + 25)
	Current.total_coins = Current.total_coins
	_check("1.3 自刷新惯用法增量为 0", Current._run_coins_earned == coins_earned0 + 25)
	Current.total_score += 100
	_check("1.2 total_score 正增量计入", Current._run_score_earned == score_earned0 + 100)
	Current.total_score -= 30
	_check("1.2 减分不扣减毛收入", Current._run_score_earned == score_earned0 + 100)
	Current.total_score = -5
	_check("1.2 clamp 在前不产生负增量", \
		Current._run_score_earned == score_earned0 + 100 and Current.total_score == 0)

	## ---------- B. 撤回移动配对快照/回滚（2.1 / 2.2）----------
	var hero: Node = gm.get_node("heros").get_children()[0]
	Current.clicked_hero = hero
	for cycle in 3:
		var target: Vector2 = _find_free_target(hero)
		Current.movable_grid_index_array = [target]
		Current.grid_index = target
		var pre_earned: int = Current._run_score_earned
		var pre_score: int = Current.total_score
		gm.hero_move(null)
		_check("2.1 第%d次移动配对快照=移动前毛收入" % (cycle + 1),
			Current._pre_move_score_earned == pre_earned)
		Current.total_score += 50   ## 模拟 post_hero_move 位置 buff 加分（同一 setter 路径）
		_check("2.1 移动后 buff 加分计入毛收入", Current._run_score_earned == pre_earned + 50)
		Current.is_moved = true
		Current.is_attacked = false
		Current.turn = "hero_turn"
		gm._on_undo_move_button_pressed()
		_check("2.2 第%d次撤回后总分回到移动前" % (cycle + 1), Current.total_score == pre_score)
		_check("2.2 第%d次撤回后毛收入回到移动前" % (cycle + 1),
			Current._run_score_earned == pre_earned)
	_check("2.2 三次撤回/重移循环数值不漂移", Current._run_score_earned == score_earned0 + 100)

	## ---------- C. 快照含 4 键 + apply 灌入往返等价（3.2 / 3.3）----------
	Current._drop_slot_dice = null
	gm._capture_turn_boundary()
	var snap: Dictionary = SaveManager.get_last_snapshot()
	var rs: Dictionary = snap.run_state
	_check("3.2 快照含 total_coins 键", rs.has("total_coins"))
	_check("3.2 快照含 run_coins_earned 键", rs.has("run_coins_earned"))
	_check("3.2 快照含 run_score_earned 键", rs.has("run_score_earned"))
	_check("3.2 快照含 pre_move_score_earned 键", rs.has("pre_move_score_earned"))
	_check("3.2 快照 4 键值与 Current 一致",
		int(rs.total_coins) == Current._total_coins
		and int(rs.run_coins_earned) == Current._run_coins_earned
		and int(rs.run_score_earned) == Current._run_score_earned
		and int(rs.pre_move_score_earned) == Current._pre_move_score_earned)
	## 灌入往返：先经 setter 扰动，再灌回快照值，断言直写零二次累计
	Current.total_coins += 5
	Current.total_score += 7
	Current.apply_run_state(rs)
	_check("3.3 灌入往返等价（余额/两累计器/配对快照）",
		Current._total_coins == int(rs.total_coins)
		and Current._run_coins_earned == int(rs.run_coins_earned)
		and Current._run_score_earned == int(rs.run_score_earned)
		and Current._pre_move_score_earned == int(rs.pre_move_score_earned))
	_check("3.3 灌入后重导出与快照一致（零二次累计）", Current.export_run_state() == rs)

	## ---------- D. 旧档兼容：剥离 4 键模拟旧档（3.4）----------
	var old_like: Dictionary = snap.duplicate(true)
	for key in ["total_coins", "run_coins_earned", "run_score_earned", "pre_move_score_earned"]:
		(old_like.run_state as Dictionary).erase(key)
	_check("3.4 剥离 4 键后 flush 成功（模拟旧档落盘）", SaveManager.flush_to_disk(old_like))
	var read_back: Dictionary = SaveManager.read_save_data()
	_check("3.4 旧档 read_save_data 正常返回（不判坏档）",
		not read_back.is_empty() and not (read_back.run_state as Dictionary).has("total_coins"))
	Current.apply_run_state(read_back.run_state)
	_check("3.4 旧档灌入后累计器/余额保持当前值（默认值兜底）",
		Current._total_coins == int(rs.total_coins)
		and Current._run_coins_earned == int(rs.run_coins_earned)
		and Current._run_score_earned == int(rs.run_score_earned))

	## ---------- E. 胜利态结算取数（4.1）----------
	Current._count_stage = 12
	Current.total_score += 200
	var expect_score: int = Current._run_score_earned
	var expect_coins: int = Current._run_coins_earned
	await gm._on_stage_clear_button_pressed()
	var settle: Node = gm.get_node_or_null("end_settlement_ui")
	if settle == null:
		_check("结算节点存在", false)
		_clean_slot()
		return
	var shown := await _wait_until(func() -> bool: return settle.visible, 12.0)
	_check("4.1 通关后结算画面出现", shown)
	_check("4.1 胜利态总得分=毛收入且非 0（关内分已清零）",
		int(settle._stats.get("total_score", -1)) == expect_score and expect_score != 0)
	_check("4.1 胜利态总金币=毛收入", int(settle._stats.get("coins", -1)) == expect_coins)

	## ---------- F. 失败态结算取数 + 新局隔离（4.2 / 5.3 / 3.1）----------
	settle._on_again_pressed()
	await get_tree().create_timer(0.4).timeout
	var gm2: Node = await _boot_main()
	if gm2 == null:
		return
	_check("3.1 再玩一次新开局累计器从 0 起算（起始金币重计 15）",
		Current._run_coins_earned == 15 and Current._run_score_earned == 0)
	Current.total_score += 120
	Current.total_coins += 30
	Current.total_coins -= 20   ## 商店花销
	var expect_score2: int = Current._run_score_earned
	var expect_coins2: int = Current._run_coins_earned
	_check("4.2 前置：毛收入=45/余额=25（已花 20 不扣毛收入）",
		expect_coins2 == 45 and Current.total_coins == 25)
	Current.player_hp = 0
	gm2._pre_hero_turn_begin()
	var settle2: Node = gm2.get_node_or_null("end_settlement_ui")
	var shown2 := await _wait_until(func() -> bool: return settle2 != null and settle2.visible, 12.0)
	_check("4.2 败局结算画面出现", shown2)
	_check("4.2 败局总金币=毛收入（含已花部分，非余额 25）",
		int(settle2._stats.get("coins", -1)) == expect_coins2)
	_check("4.2 败局总得分=全程累计毛收入（非关内分）",
		int(settle2._stats.get("total_score", -1)) == expect_score2)
	_clean_slot()
