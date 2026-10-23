extends Node

## ============================================================
## 存档全流程回归（headless，两阶段跨进程）
##
## 覆盖任务（openspec/changes/add-save-system/tasks.md）：
##   2.1 capture 汇集 run 级状态与实际值一致      —— phase1
##   2.2 商店/关卡状态 roundtrip                  —— phase1/2
##   2.3 棋盘实体展平 roundtrip                   —— phase1/2
##   2.4 apply 直写灌入等价 + 零演出副作用        —— phase2
##   3.1 回合边界快照点无锁                       —— phase1
##   3.2 buff 实例本地状态存取（rush granted/防御基准/品牌/共鸣链/护盾/疾跑领主）—— phase1/2
##   3.3 管线重建结构与图标数量一致               —— phase2
##   3.4 resonance_ramp 恢复                      —— phase2
##   4.1 攻击动画进行中 flush（不等待演出/不拍新快照）—— phase1
##   5.1 主菜单继续门控（无档禁用/坏档禁用/有档启用并展示进度）—— phase1/2
##   5.2 读档重建（棋盘/HUD/商店/图标的保存点等价）—— phase2
##   5.3 恢复后停在我方可操作（无演出链/无 restoring 残留）—— phase2
##   5.4 rush 系 buff 防双叠回归（重建后移动力不多加一格）—— phase2
##   6.1 结算两张出口清档（再玩一次/退出）        —— phase2
##   6.2 新 run 与旧档隔离                        —— phase2
##   7.2 全流程回归脚本（新 run → 3 回合 → 落盘 → 重启进程 → 继续 → 等价 → 通关 → 清档）
##   （4.2 flush 失败路径与 7.3 写入中断模拟见 save_codec_test.gd section 6-8）
##
## 用法：
##   godot --headless --path . res://test/scripts/save/save_flow_test.tscn -- --phase=1
##   godot --headless --path . res://test/scripts/save/save_flow_test.tscn -- --phase=2
##
## 说明："打通关"取 stage_clear_button 的直达第十二关路径（该按钮即开发透传的通关入口），
## 结算两出口的清档动作由两态按钮共用，胜利/失败收口同路。
## phase2 的点击继续用与 _on_continue_pressed 相同的序列手工驱动（点击 handler 内部
## await 转场会跨场景释放节点，探针内直接 await 会复活已释放实例产生脚本噪声）。
## ============================================================

const FLOAT_NUMBER_SCRIPT := preload("res://scripts/ui/float_number.gd")

## 注入名单：rush 系 granted（与 design D5 防双叠规范一致）
const RUSH_BUFF_IDS := ["hero_rush", "phantom_dash", "swift_streak", "vigor_sprint"]
## 注入 post_attack 组（局部状态跨回合）
const LOCAL_STATE_BUFFS := ["color_brand", "resonance_chain", "life_barrier", "swift_overlord"]
## 注入 pre_enemy_turn 组（restore 不重播该时序，避免断言被注入 buff 的重放副作用污染）
const LOCAL_STATE_DEBUFFS := ["fragile", "armor_break"]

var _passed := 0
var _failed := 0
var _fail_names: Array = []
## hp_changed 演出事件计数（player_hp setter 触发，读档灌入路径必须为 0）
var _hp_events := 0
## phase1 注入的 buff 实例（phase2 断言参照快照行使用）
var _injected: Array = []
## phase1 注入基线
var _mv_base := 0
var _stage1_inject_rows_count := 0


func _ready() -> void:
	## 探针保活：本场景作为启动 current_scene 时会被第一次 change_scene 释放，摘除注册避开
	if get_tree().current_scene == self:
		get_tree().current_scene = null
	var phase := 1
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--phase="):
			phase = int(String(arg).get_slice("=", 1))
	if phase == 1:
		await _run_phase1()
	else:
		await _run_phase2()
	print("\n=== SaveFlow(phase=%d) 测试：通过 %d / 失败 %d ===" % [phase, _passed, _failed])
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


## ============================================================
## 通用辅助
## ============================================================

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


func _ui_scene(view: StringName) -> Node:
	SceneManager.change_scene(view)
	var got := await _wait_until(func() -> bool:
		var sc: Node = SceneManager.current_scene
		## 等待真正入树 + _ready 完成 + 挂队清空：
		## change_scene 同步赋 current_scene，但 deferred 挂载未跑时返回的实例
		## 处于"未入树/未 ready/默认 UI 态"，直接断言会误读默认值
		return sc != null and sc.is_inside_tree() and sc.is_node_ready() \
			and SceneManager._pending_scene == null \
			and sc.get_node_or_null("ButtonColumn/continue_button") != null, 20.0)
	if not got:
		_check("加载 %s 场景" % String(view), false)
	return SceneManager.current_scene


func _boot_main() -> Node:
	SceneManager.change_scene(&"main")
	var got := await _wait_until(func() -> bool:
		var sc: Node = SceneManager.current_scene
		## 战局就绪判定：已入树 + 已 ready + 挂队清空 + 回合按钮已启用
		## （按钮启用点位于 boot 回合边界快照之后）
		if sc == null or not (sc is Node2D) or not sc.is_inside_tree() \
			or not sc.is_node_ready() or SceneManager._pending_scene != null:
			return false
		return not sc.turn_button.disabled, 60.0)
	if not got:
		_check("战局启动", false)
		return null
	return SceneManager.current_scene


func _on_hp_changed(_param: Array) -> void:
	_hp_events += 1


func _count_float_nodes(root: Node) -> int:
	var count := 0
	if root.get_script() == FLOAT_NUMBER_SCRIPT:
		count += 1
	for child in root.get_children():
		count += _count_float_nodes(child)
	return count


## 注入一个配置驱动 buff/debuff 实例并注册进管线，随后直改实例本地字段
func _inject(id: String, timing: String, lifecycle: int, patch: Dictionary) -> Object:
	var cfg := BuffSystem._find_save_config(id)
	if cfg.is_empty():
		_check("注入配置存在: " + id, false)
		return null
	var res_path := str(cfg.get("buff_res", cfg.get("debuff_res", "")))
	var inst: Object = load(res_path).new(cfg, Current.game_manager)
	BuffSystem.set_buff(timing, inst, lifecycle)
	for key in patch:
		inst.set(key, patch[key])
	_injected.append(inst)
	return inst


## 注入局部状态期望值（与各 buff 的 save_state 字段名对齐）
func _local_state_patches() -> Dictionary:
	return {
		"color_brand": {"branded_color": "red"},
		"resonance_chain": {"chain_multiplier": 1.875},
		"life_barrier": {"_defense_applied": true},
		"swift_overlord": {"_move_bonus_added": true},
		"fragile": {"_defense_before_fragile": 5},
		"armor_break": {"_defense_reduced": 2},
	}


## 从运行中的史莱姆节点提取数据行（与 _export_slime_row 同口径的截取字段）
func _slime_row_of(slime: Node) -> Dictionary:
	return {
		"grid": [int(slime.enemy_grid_index.x), int(slime.enemy_grid_index.y)],
		"hp": int(slime.enemy_hp),
		"point": int(slime.dice_point),
		"elite": slime.is_elite,
		"boss": slime.is_boss,
		"gate_type": str(slime.gate_type),
	}


## ============================================================
## Phase 1：无档/坏档门控 → 新 run → 3 回合（含中段 flush）→ 注入 → 快照 → 落盘
## ============================================================

func _run_phase1() -> void:
	print("=== SaveFlow phase1 开始（新 run + 存档）===")
	_clean_slot()
	## ---- 5.1 无档门控 ----
	var splash := await _ui_scene(&"splash")
	if splash != null:
		var continue_btn: TextureButton = splash.get_node("ButtonColumn/continue_button")
		_check("5.1 无档时继续按钮禁用", continue_btn.disabled)
		_check("5.1 无档时继续按钮置灰（modulate 变暗）", continue_btn.modulate.r < 0.6)
		## ---- 5.1 坏档门控（自动隔离）----
		var junk := "JUNK-FILE".to_ascii_buffer()
		var f := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
		f.store_buffer(junk)
		f = null
		splash = await _ui_scene(&"splash")
		continue_btn = splash.get_node("ButtonColumn/continue_button")
		_check("5.1 坏档时继续按钮禁用", continue_btn.disabled)
		_check("1.3 坏档已转存 save.corrupt", FileAccess.file_exists(SaveManager.CORRUPT_PATH))
		_check("1.3 坏档已隔离（save.bin 删除）", not FileAccess.file_exists(SaveManager.SAVE_PATH))
		_clean_slot()
	## ---- 新 run ----
	var gm: Node = await _boot_main()
	if gm == null:
		return
	var snap: Dictionary = SaveManager.get_last_snapshot()
	_check("2.1 回合边界快照已生成", not snap.is_empty())
	## ---- 3.1 边界点无锁 ----
	_check("3.1 边界快照 action_lock=false", not bool(snap.run_state.get("action_lock", true)))
	_check("3.1 边界快照 public_lock_array 为空", (snap.run_state.get("public_lock_array", ["x"]) as Array).is_empty())
	_check("3.1 边界快照回合为 1", int(snap.meta.round) == 1)
	## ---- 2.1 捕获值与运行时实际值逐项一致 ----
	var rs: Dictionary = snap.run_state
	_check("2.1 total_score 一致", int(rs.total_score) == Current._total_score)
	_check("2.1 player_hp/max_hp 一致", int(rs.player_hp) == Current._player_hp \
		and int(rs.max_hp) == Current._max_hp)
	_check("2.1 player_defense 一致", int(rs.player_defense) == Current.player_defense)
	_check("2.1 potion_count/potion_max 一致", int(rs.potion_count) == Current._potion_count \
		and int(rs.potion_max) == Current._potion_max)
	_check("2.1 six_score 一致", int(rs.six_score) == Current._six_score)
	_check("2.1 level/hero_exp/max_power/power 一致", int(rs.level) == Current._level \
		and int(rs.hero_exp) == Current.hero_exp and int(rs.max_power) == Current._max_power \
		and int(rs.power) == Current._power)
	_check("2.1 count_stage/count_round 一致", int(rs.count_stage) == Current._count_stage \
		and int(rs.count_round) == Current._count_round)
	_check("2.1 drop_slot_dice null 一致", typeof(rs.drop_slot_dice) == TYPE_NIL \
		and Current._drop_slot_dice == null)
	_check("2.1 resonance_ramp 一致", float(snap.resonance_ramp) == BuffSystem.resonance_ramp)
	## ---- 毛收入累计器与金币余额入快照（fix-settlement-run-totals）----
	_check("2.1 金币余额入快照（读档归 0 bug 回归）", int(rs.total_coins) == Current._total_coins)
	_check("2.1 毛收入累计器与配对快照入快照", int(rs.run_coins_earned) == Current._run_coins_earned \
		and int(rs.run_score_earned) == Current._run_score_earned \
		and int(rs.pre_move_score_earned) == Current._pre_move_score_earned)
	_check("2.1 起始金币已计入毛收入（开局=15）", Current._run_coins_earned == 15)
	## ---- 2.3 棋盘实体与运行时一致 ----
	var slimes: Array = gm.enemys.get_children()
	_check("2.3 棋盘史莱姆行数与实际一致", (snap.board.slimes as Array).size() == slimes.size())
	if (snap.board.slimes as Array).size() == slimes.size():
		var rows_ok := true
		for i in slimes.size():
			var row: Dictionary = snap.board.slimes[i]
			var rerun_row := _slime_row_of(slimes[i])
			for key in ["grid", "hp", "point", "elite", "boss", "gate_type"]:
				if str(row.get(key)) != str(rerun_row.get(key)):
					rows_ok = false
					print("    实体字段不符 ", key, ": ", row.get(key), " != ", rerun_row.get(key))
		_check("2.3 逐实体字段与运行时一致", rows_ok)
	var hero_grid: Array = snap.board.hero.hero_grid_index
	_check("2.3 英雄格子与移动力一致",
		int(hero_grid[0]) == int(Current.hero.hero_grid_index.x)
		and int(hero_grid[1]) == int(Current.hero.hero_grid_index.y)
		and int(snap.board.hero.hero_movement) == Current.hero.hero_movement)
	## ---- 2.3 pending 预生成占位（未入树）位置与运行时一致 ----
	var pending_live: Array = gm._slime_create_array
	_check("2.3 pending 行数与实际一致", (snap.board.pending as Array).size() == pending_live.size())
	var pending_ok := true
	if (snap.board.pending as Array).size() == pending_live.size():
		for i in pending_live.size():
			var prow: Dictionary = snap.board.pending[i]
			var live: Node = pending_live[i]
			if int(prow.grid[0]) != int(live.enemy_grid_index.x) \
				or int(prow.grid[1]) != int(live.enemy_grid_index.y):
				pending_ok = false
				print("    pending 位置不符 ", i, ": ", prow.grid, " != ", live.enemy_grid_index)
	_check("2.3 pending 位置与运行时一致", pending_ok)
	## ---- 推进 3 回合（含 4.1 回合中段 flush）----
	var last_round := 1
	for press_i in 3:
		Current._player_hp = 5              ## 防御性回血（私有直写），避免敌方回合扣血致死中断流程
		Current._drop_slot_dice = null      ## 私有直写清掉落格，规避选择弹窗（headless 无真实点击）
		var round_before := int(SaveManager.get_last_snapshot().meta.round)
		gm._on_turn_button_pressed()        ## 后台推进：按下回合按钮（协程独立前行）
		if press_i == 1:
			## ---- 4.1 攻击动画进行中 flush：不等待演出、不拍新快照 ----
			await get_tree().create_timer(0.9).timeout
			var mid_ok: bool = SaveManager.flush_to_disk()
			_check("4.1 攻击动画进行中 flush 成功", mid_ok)
			var mid_data := SaveManager.read_save_data()
			_check("4.1 中段 flush 为最近回合边界快照（未拍新快照）",
				not mid_data.is_empty() and int(mid_data.meta.round) == round_before
				and not bool(mid_data.run_state.get("action_lock", true)))
			_check("4.1 中段 flush 与内存快照一致（不包含中间态）",
				deep_equal(mid_data, SaveManager.get_last_snapshot()))
			if not deep_equal(mid_data, SaveManager.get_last_snapshot()):
				deep_diff(mid_data, SaveManager.get_last_snapshot(), "mid")
		## 回合边界完成标志：回合按钮重新启用（capture 在启用之前执行）
		var boundary_ready := await _wait_until(func() -> bool:
			return not gm.turn_button.disabled \
				and int(SaveManager.get_last_snapshot().meta.round) > round_before, 40.0)
		_check("回合%d推进完成（边界快照刷新）" % (press_i + 1), boundary_ready)
		last_round = int(SaveManager.get_last_snapshot().meta.round)
		_check("3.1 第%d次回合边界快照无锁" % (press_i + 1),
			not bool(SaveManager.get_last_snapshot().run_state.action_lock)
			and (SaveManager.get_last_snapshot().run_state.public_lock_array as Array).is_empty())
	_check("3.1 3 回合推进后快照回合为 4", last_round == 4)
	## ---- 注入跨回合状态（3.2/3.4/5.4 断言素材）----
	var enemies: Array = gm.enemys.get_children()
	_check("注入前置：场上存在史莱姆", enemies.size() > 0)
	if enemies.size() == 0:
		return
	enemies[0].is_elite = true
	## ---- 毛收入累计器收口行为注入（fix-settlement-run-totals）：仅经 setter 的正增量计入 ----
	var coins_earned_before := Current._run_coins_earned
	var score_earned_before := Current._run_score_earned
	Current.total_coins -= 5     ## 花销（负变化）不扣减毛收入
	_check("收口 花销不扣减毛收入", Current._run_coins_earned == coins_earned_before)
	Current.total_coins += 25    ## setter 正增量 → 计入毛收入
	_check("收口 正增量计入毛收入", Current._run_coins_earned == coins_earned_before + 25)
	Current.total_coins = Current.total_coins  ## 自刷新惯用法增量为 0
	_check("收口 自刷新惯用法增量为 0", Current._run_coins_earned == coins_earned_before + 25)
	Current.total_score += 5    ## setter 正增量计入毛收入（137 直写对照；注入后 142 < 第1关目标 150，
	                             ## 避免读档后回合边界 _check_stage_clear 自动过关卡死 headless 流程）
	_check("收口 得分正增量计入毛收入", Current._run_score_earned == score_earned_before + 5)
	Current._total_score += 137
	BuffSystem.resonance_ramp += 0.05
	## swift_streak 的 granted 前置条件为连续得分回合数≥2：注入态必须与前置一致，
	## 否则读档重放 pre_hero_turn 时会把 granted 回退（与真实语义一致）
	Current.consecutive_score_turns = 2
	Current._player_hp = 5  ## vigor_sprint 的 granted 前置为 HP≥80%：注入态与前置保持一致
	_mv_base = Current.hero.hero_movement
	var granted_count := 0
	for rush_id in RUSH_BUFF_IDS:
		var rush: Object = _inject(rush_id, "pre_hero_turn", BuffSystem.buff_type.ALWAYS, {"_move_granted": true})
		if rush != null:
			Current.hero.hero_movement += 1
			granted_count += 1
	var patches := _local_state_patches()
	for buff_id in LOCAL_STATE_BUFFS:
		_inject(buff_id, "post_attack", BuffSystem.buff_type.STAGE, patches[buff_id])
	for debuff_id in LOCAL_STATE_DEBUFFS:
		_inject(debuff_id, "pre_enemy_turn", BuffSystem.buff_type.STAGE, patches[debuff_id])
	_check("rush 系 4 buff 注入（granted=true）", granted_count == RUSH_BUFF_IDS.size())
	Current.drop_slot_dice = ["red", 3]     ## setter 仅更新掉落格 UI（非演出）
	## ---- 注入后的回合边界快照（边界复核 + 落盘素材）----
	_check("3.1 注入点仍处无锁干净位", Current.action_lock == false and Current.public_lock_array.is_empty())
	gm._capture_turn_boundary()
	var snap2: Dictionary = SaveManager.get_last_snapshot()
	_check("注入 total_score 已入快照", int(snap2.run_state.total_score) == Current._total_score)
	_check("注入余额/毛收入累计器已入快照",
		int(snap2.run_state.total_coins) == Current._total_coins
		and int(snap2.run_state.run_coins_earned) == Current._run_coins_earned
		and int(snap2.run_state.run_score_earned) == Current._run_score_earned
		and int(snap2.run_state.pre_move_score_earned) == Current._pre_move_score_earned)
	_check("注入 resonance_ramp 已入快照", float(snap2.resonance_ramp) == BuffSystem.resonance_ramp)
	_check("注入移动力（base+4）已入快照", int(snap2.board.hero.hero_movement) == _mv_base + 4)
	## ---- 3.2 行形状（id/lifecycle/timing/local_state）----
	var rows: Array = snap2.buffs.rows
	_stage1_inject_rows_count = rows.size()
	_check("3.3 快照 buff 行数与注入实例数一致", rows.size() == _injected.size() \
		and rows.size() == RUSH_BUFF_IDS.size() + LOCAL_STATE_BUFFS.size() + LOCAL_STATE_DEBUFFS.size())
	for row in rows:
		var row_id := str(row.id)
		if row_id in RUSH_BUFF_IDS:
			_check("rush 行 %s 存 _move_granted=true" % row_id,
				bool(row.local_state.get("_move_granted", false)))
		if row_id in patches:
			_check("%s local_state 已入快照" % row_id,
				deep_equal(row.local_state, patches[row_id]))
	## ---- 落盘（7.2 退出即保存）----
	_check("落盘成功", SaveManager.flush_to_disk())
	_check("存档文件存在", FileAccess.file_exists(SaveManager.SAVE_PATH))
	var disk_data := SaveManager.read_save_data()
	_check("盘上数据与内存快照一致（roundtrip）",
		not disk_data.is_empty() and deep_equal(disk_data, snap2))
	if not deep_equal(disk_data, snap2):
		deep_diff(disk_data, snap2, "disk")
	var progress := SaveManager.get_save_progress()
	_check("进度展示与快照一致", int(progress.stage) == int(snap2.meta.stage) \
		and int(progress.round) == int(snap2.meta.round))
	await get_tree().process_frame


## ============================================================
## Phase 2：模拟重启进程 → 继续 → 等价断言 → 结算两出口 → 新 run 隔离 → 通关
## ============================================================

func _run_phase2() -> void:
	print("=== SaveFlow phase2 开始（重启进程 + 继续 + 清档）===")
	## 前置守卫：phase2 依赖 phase1 落盘产物；缺失时立即中止（避免坏流程串场清档）
	if not FileAccess.file_exists(SaveManager.SAVE_PATH):
		_check("phase1 存档产物存在", false)
		print("[SaveFlow] 缺少 phase1 产物（user://save.bin），请先运行 --phase=1")
		return
	_check("phase1 存档产物存在", FileAccess.file_exists(SaveManager.SAVE_PATH))
	var data := SaveManager.read_save_data()
	if data.is_empty():
		_check("phase2 解码成功", false)
		print("[SaveFlow] 存档解码失败，中止")
		return
	_check("phase2 解码成功", not data.is_empty())
	var old_round := int(data.meta.round)
	var old_stage := int(data.meta.stage)
	var old_score := int(data.run_state.total_score)
	var old_ramp := float(data.resonance_ramp)
	var old_mv := int(data.board.hero.hero_movement)
	## ---- 5.1 有档门控 + 进度展示 ----
	var splash: Node = await _ui_scene(&"splash")
	if splash != null:
		var continue_btn: TextureButton = splash.get_node("ButtonColumn/continue_button")
		_check("5.1 有档时继续按钮启用", not continue_btn.disabled)
		var progress := SaveManager.get_save_progress()
		_check("5.1 进度展示与存档 meta 一致",
			int(progress.stage) == old_stage and int(progress.round) == old_round)
		_check("5.1 按钮文本含关卡/回合数字",
			String(continue_btn.get_node("Label").text).contains(str(old_stage))
			and String(continue_btn.get_node("Label").text).contains(str(old_round)))
	## ---- 点击继续（与 _on_continue_pressed 相同的等价序列）----
	_hp_events = 0
	var restore_start_ms := Time.get_ticks_msec()
	Current.selected_hero = str(data.meta.hero)
	SaveManager.begin_restore(data)          ## 挂数据 + 置 restoring_run=true
	SceneManager.preload_scene(&"main")      ## 后台预加载（与真实点击路径一致）
	await SceneTransition.transition_to(&"main", &"stage_start")   ## 恢复完成即就绪信号
	var restore_ms := Time.get_ticks_msec() - restore_start_ms
	print("    恢复时序：click→stage_start=%dms" % restore_ms)
	var gm: Node = SceneManager.current_scene
	_check("5.2 战局场景就位", gm != null and gm.get("turn_button") != null)
	## ---- 5.3 恢复后停在我方可操作 ----
	_check("5.3 无 restoring 残留标记",
		SaveManager.restoring_run == false and SaveManager.pending_save_data.is_empty())
	_check("5.3 action_lock=false", Current.action_lock == false)
	_check("5.3 公共锁为空", Current.public_lock_array.is_empty())
	_check("5.3 回合按钮启用", not gm.turn_button.disabled)
	_check("2.4 读档零演出事件（hp_changed 未触发）", _hp_events == 0)
	_check("2.4 读档无飘字节点", _count_float_nodes(get_tree().root) == 0)
	_check("3.4 resonance_ramp 恢复", float(BuffSystem.resonance_ramp) == old_ramp)
	## ---- 2.4 run 状态等价（重新导出 == 快照导出，int/float 数值等价）----
	var run_state_ok := deep_equal(Current.export_run_state(), data.run_state)
	_check("2.4 run_state 等价", run_state_ok)
	if not run_state_ok:
		deep_diff(Current.export_run_state(), data.run_state, "run_state")
	## ---- 2.4 金币余额与毛收入累计器恢复（fix-settlement-run-totals 读档归 0 bug 回归）----
	_check("2.4 金币余额恢复且非 0", int(Current._total_coins) == int(data.run_state.total_coins) \
		and int(Current._total_coins) > 0)
	_check("2.4 毛收入累计器与配对快照恢复等价",
		int(Current._run_coins_earned) == int(data.run_state.run_coins_earned) \
		and int(Current._run_score_earned) == int(data.run_state.run_score_earned) \
		and int(Current._pre_move_score_earned) == int(data.run_state.pre_move_score_earned))
	## ---- 2.4 HUD 等价（label 直写）----
	_check("2.4 HUD total_score 与快照一致", String(gm.total_score.text) == str(old_score))
	_check("2.4 HUD hp 与快照一致", Current._player_hp == int(data.run_state.player_hp))
	## 船位置按 count_round 静态计算（2.4）
	var expect_ship: Vector2
	if Current._count_round <= 1:
		expect_ship = Vector2(4, 2)
	elif Current._count_round < 11:
		expect_ship = Vector2(4, 2) + ((Current._count_round - 1) * Vector2(7, 0))
	else:
		expect_ship = Vector2(4, 2) + (9 * Vector2(7, 0))
	_check("2.4 船位静态对位（无 tween）", gm.ship.position.is_equal_approx(expect_ship))
	## ---- 2.3 棋盘实体等价（两侧都按位宽归一为 int 行，与 _slime_row_of 同口径）----
	var slimes: Array = gm.enemys.get_children()
	_check("2.3 史莱姆行数等价", slimes.size() == (data.board.slimes as Array).size())
	var board_ok := slimes.size() == (data.board.slimes as Array).size()
	if board_ok:
		for i in slimes.size():
			var row: Dictionary = data.board.slimes[i]
			var norm_row := {
				"grid": [int(row.grid[0]), int(row.grid[1])],
				"hp": int(row.hp),
				"point": int(row.point),
				"elite": bool(row.elite),
				"boss": bool(row.boss),
				"gate_type": str(row.gate_type),
			}
			var rerun_row := _slime_row_of(slimes[i])
			for key in norm_row:
				if str(norm_row[key]) != str(rerun_row[key]):
					board_ok = false
					print("    重建实体差异 ", i, " ", key, ": ", norm_row[key], " != ", rerun_row[key])
	_check("2.3 逐实体等价", board_ok)
	## ---- 2.3 pending 预生成队列恢复（下一回合敌人回合照常生成史莱姆 + 告警点亮）----
	var pending_rows: Array = data.board.pending
	_check("2.3 pending 行数等价", gm._slime_create_array.size() == pending_rows.size())
	var pending_ok2 := true
	for i in mini(gm._slime_create_array.size(), pending_rows.size()):
		var prow: Dictionary = pending_rows[i]
		var live: Node = gm._slime_create_array[i]
		if int(prow.grid[0]) != int(live.enemy_grid_index.x) \
			or int(prow.grid[1]) != int(live.enemy_grid_index.y):
			pending_ok2 = false
			print("    pending 重建位置差异 ", i, ": ", prow.grid, " != ", live.enemy_grid_index)
	_check("2.3 pending 位置等价", pending_ok2)
	var warn_ok := true
	for slime in gm._slime_create_array:
		if not gm.all_grid_dict[slime.enemy_grid_index].warning.visible:
			warn_ok = false
	_check("2.3 pending 出生告警点亮（与 _pre_create_slime 展示口径一致）", warn_ok)
	## ---- 5.4 rush 防双叠回归（实例从管线中检索，避免注入引用空转）----
	print("    移动力：快照=", old_mv, " 恢复后=", Current.hero.hero_movement)
	_check("5.4 英雄移动力等价（不多加一格）", Current.hero.hero_movement == old_mv)
	var rush_ok := true
	for timing in BuffSystem.TIMINGS:
		for key in BuffSystem.LIFECYCLE_KEYS:
			for buff in BuffSystem.pipelines[timing][key]:
				var inst_id := str(buff.buff_meta.get("buff_id", buff.buff_meta.get("debuff_id", "")))
				if inst_id in RUSH_BUFF_IDS and buff.get("_move_granted") != true:
					rush_ok = false
	_check("5.4 rush 实例恢复后 _move_granted 均 true", rush_ok)
	## ---- 3.3 管线结构 + 图标列表等价 ----
	var pipeline_ok := true
	for row in data.buffs.rows:
		var found := false
		var timings: Array = row.timing if row.timing is Array else [row.timing]
		for t in timings:
			for key in BuffSystem.LIFECYCLE_KEYS:
				for buff in BuffSystem.pipelines[t][key]:
					if BuffSystem._lifecycle_int(key) == int(row.lifecycle) \
						and str(buff.buff_meta.get("buff_id", buff.buff_meta.get("debuff_id", ""))) == str(row.id):
						found = true
		if not found:
			pipeline_ok = false
			print("    管线缺失行 ", row.id)
	_check("3.3 管线结构与快照行一致", pipeline_ok)
	## 图标一致性（task 3.3）：快照清单内各 set_buff 的图标装配已审计——
	## swift_overlord 注册时不挂图标（家族≥4 触发型，图标在 process 弹出），
	## 其余行注册即挂一枚 buff/debuff texture。断言"非豁免行均有图标"。
	var icon_exempt := ["swift_overlord"]
	var expected_icons: int = (data.buffs.rows as Array).size() - icon_exempt.size()
	var icon_count: int = gm.buff_container.get_child_count() + gm.debuff_container.get_child_count()
	var icon_ok: bool = icon_count == expected_icons
	_check("3.3 buff/debuff 图标数量与行数一致", icon_ok)
	if not icon_ok:
		print("    图标数 buff=", gm.buff_container.get_child_count(),
			" debuff=", gm.debuff_container.get_child_count(),
			" rows=", (data.buffs.rows as Array).size())
	## ---- 3.2 实例本地状态恢复 ----
	var local_ok := true
	for row in data.buffs.rows:
		var found_inst: Object = null
		for timing in BuffSystem.TIMINGS:
			for key in BuffSystem.LIFECYCLE_KEYS:
				for buff in BuffSystem.pipelines[timing][key]:
					if str(buff.buff_meta.get("buff_id", buff.buff_meta.get("debuff_id", ""))) == str(row.id):
						found_inst = buff
		if found_inst == null:
			continue
		if not deep_equal(found_inst.save_state(), row.local_state):
			local_ok = false
			print("    local_state 不符: ", row.id)
	_check("3.2 实例本地状态恢复一致", local_ok)
	## ---- 2.2 商店等价 ----
	var shop: Dictionary = data.shop
	var shelf_rows: Array = [gm.shop_buff_1, gm.shop_buff_2, gm.shop_buff_3]
	var shelf_ok := (shop.buff_rows as Array).size() == 3
	if shelf_ok:
		for i in 3:
			if not deep_equal(shop.buff_rows[i], shelf_rows[i]):
				shelf_ok = false
				print("    货架行差异 ", i)
	_check("2.2 商店货架三行等价", shelf_ok)
	_check("2.2 已购/锁定按钮等价",
		shop.bought == [gm.shop_buff_bought[0], gm.shop_buff_bought[1], gm.shop_buff_bought[2]]
		and bool(shop.lock_states[0]) == gm.buff_lock_button_1.button_pressed
		and bool(shop.lock_states[1]) == gm.buff_lock_button_2.button_pressed
		and bool(shop.lock_states[2]) == gm.buff_lock_button_3.button_pressed)
	_check("2.2 刷新费用/金币技能行等价",
		int(shop.refresh_cost) == int(gm.buff_refresh_cost)
		and deep_equal(shop.coin_skill_row, gm.shop_coin_skill_row))
	_check("2.2 已购金币技能/出现记录/已用 debuff 池等价",
		bool(shop.coin_skill_bought) == gm.shop_coin_skill_bought
		and deep_equal(shop.used_debuff_ids, gm._used_debuff_ids)
		and deep_equal(shop.appeared_coin_skill_ids, gm.appeared_coin_skill_ids))
	## ==================== 5.2 端到端：读档后首回合照常生成史莱姆（顺带走真实失败结算） ====================
	var slime_count_before: int = gm.enemys.get_child_count()
	var pending_count: int = gm._slime_create_array.size()
	Current._drop_slot_dice = null
	gm._on_turn_button_pressed()  ## 后台推进读档后的第一个回合
	var turn_done := await _wait_until(func() -> bool: return not gm.turn_button.disabled, 40.0)
	_check("5.2 读档后首回合推进完成", turn_done)
	_check("5.2 敌方回合照常生成预生成史莱姆（count+pending）",
		gm.enemys.get_child_count() == slime_count_before + pending_count)
	## press 完成时 _turn_process 已为下一回合重建 pending 并点亮新告警：
	## 断言"下一回合预生成占位与告警恢复一致"（显示口径与 _pre_create_slime 相同）
	_check("5.2 下一回合预生成占位已重建（队列填充）", gm._slime_create_array.size() > 0)
	var new_pending_ok: bool = gm._slime_create_array.size() > 0
	for slime in gm._slime_create_array:
		if not gm.all_grid_dict[slime.enemy_grid_index].warning.visible:
			new_pending_ok = false
	_check("5.2 下一回合预生成告警点亮", new_pending_ok)
	var settle: Node = gm.get_node("end_settlement_ui")
	## ============================ 6.1 出口A「再玩一次」 ============================
	settle._on_again_pressed()
	await get_tree().create_timer(0.4).timeout
	_check("6.1 再玩一次后存档槽已清空", not FileAccess.file_exists(SaveManager.SAVE_PATH))
	## ============================ 6.2 新 run 与旧档隔离 ============================
	var gm2: Node = await _boot_main()
	if gm2 == null:
		return
	_check("6.2 新 run 首拍前保持无档", not FileAccess.file_exists(SaveManager.SAVE_PATH))
	Current._player_hp = 5
	Current._drop_slot_dice = null
	await gm2._on_turn_button_pressed()
	_check("6.2 新 run 落盘成功", SaveManager.flush_to_disk())
	var fresh := SaveManager.read_save_data()
	_check("6.2 新 run 落盘 stage 为 1（不出现旧局关卡）",
		not fresh.is_empty() and int(fresh.meta.stage) == 1)
	_check("6.2 新 run 回合小于旧档", int(fresh.meta.round) < old_round)
	_check("6.2 新 run 总分与旧档不同（不遗留旧档累计）",
		int(fresh.run_state.total_score) != old_score)
	## ============================ 7.2 通关 + 6.1 出口B「退出」 ============================
	Current._count_stage = 12
	Current.total_score += 40   ## setter 正增分为毛收入素材（胜利路径先清零关内分，结算仍应非 0）
	_check("7.2 通关前存档存在", FileAccess.file_exists(SaveManager.SAVE_PATH))
	await gm2._on_stage_clear_button_pressed()
	var settle2: Node = gm2.get_node("end_settlement_ui")
	var win_shown := await _wait_until(func() -> bool: return settle2.visible, 12.0)
	_check("7.2 通关后结算画面出现", win_shown)
	## ---- 4.1 胜利态结算取数（毛收入口径：胜利清零后总得分非 0）----
	_check("4.1 胜利态总得分=毛收入累计器且非 0",
		settle2._stats.get("total_score", -1) == Current._run_score_earned
		and int(settle2._stats.get("total_score", 0)) != 0)
	_check("4.1 胜利态总金币=毛收入累计器",
		settle2._stats.get("coins", -1) == Current._run_coins_earned)
	settle2._on_end_button_pressed()
	await get_tree().create_timer(0.4).timeout
	_check("6.1 通关退出后存档槽已清空", not FileAccess.file_exists(SaveManager.SAVE_PATH))
	## ---- 6.1 主菜单继续恢复禁用态 ----
	var splash2: Node = await _ui_scene(&"splash")
	if splash2 != null:
		_check("6.1 run 结束后主菜单继续禁用",
			splash2.get_node("ButtonColumn/continue_button").disabled)
	await get_tree().process_frame


## 深度 diff 打印（定位 Dictionary == 不等的根因），最多打印 12 条差异
func deep_diff(a: Variant, b: Variant, tag: String) -> void:
	var lines: Array = []
	_walk_diff(a, b, tag, lines)
	if lines.is_empty():
		print("[DIFF:%s] 键值集相同但 == 不等（数值/类型细节）" % tag)


func _walk_diff(a: Variant, b: Variant, path: String, lines: Array) -> void:
	if lines.size() > 12:
		return
	if typeof(a) != typeof(b):
		print("[DIFF:%s] %s | %s" % [path, typeof_string(a), typeof_string(b)])
		lines.append(path)
		return
	match typeof(a):
		TYPE_DICTIONARY:
			var da: Dictionary = a
			var db: Dictionary = b if b is Dictionary else {}
			for key in da:
				if not db.has(key):
					print("[DIFF:%s] 仅左有 %s" % [path, key])
					lines.append(path)
				elif da[key] != db[key]:
					_walk_diff(da[key], db[key], "%s.%s" % [path, key], lines)
			for key in db:
				if not da.has(key):
					print("[DIFF:%s] 仅右有 %s" % [path, key])
					lines.append(path)
		TYPE_ARRAY:
			var aa: Array = a
			var ab: Array = b if b is Array else []
			if aa.size() != ab.size():
				print("[DIFF:%s] 长度 %d | %d" % [path, aa.size(), ab.size()])
				lines.append(path)
			for i in mini(aa.size(), ab.size()):
				if aa[i] != ab[i]:
					_walk_diff(aa[i], ab[i], "%s[%d]" % [path, i], lines)
		_:
			if a != b:
				print("[DIFF:%s] %s | %s" % [path, a, b])
				lines.append(path)


func typeof_string(v: Variant) -> String:
	var names := {TYPE_NIL: "NIL", TYPE_BOOL: "BOOL", TYPE_INT: "INT", TYPE_FLOAT: "FLOAT",
		TYPE_STRING: "STR", TYPE_DICTIONARY: "DICT", TYPE_ARRAY: "ARRAY"}
	return names.get(typeof(v), str(typeof(v)))


## 深度等价比较（容忍 JSON 往返形态差异）：
##   1) 数值 int/float 等价（5 == 5.0）
##   2) 字典键 int/str 数值等价（快照 int 键 2 与解码字符串键 "2" 同义
##      —— apply_run_state 侧按 int 键重建，属 schema 预期形态）
##   3) bool 与数值不互通（true ≠ 1）
func deep_equal(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		if not (typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]):
			return false
	match typeof(a):
		TYPE_DICTIONARY:
			var da: Dictionary = a
			var db: Dictionary = b
			if not (b is Dictionary) or da.size() != db.size():
				return false
			for key in da:
				var matched := false
				for k2 in db:
					if deep_key_equal(key, k2) and deep_equal(da[key], db[k2]):
						matched = true
						break
				if not matched:
					return false
			return true
		TYPE_ARRAY:
			var aa: Array = a
			var ab: Array = b
			if not (b is Array) or aa.size() != ab.size():
				return false
			for i in aa.size():
				if not deep_equal(aa[i], ab[i]):
					return false
			return true
		_:
			return a == b


## 键等价：str 归一（int 键 2 与字符串键 "2" 同义）
func deep_key_equal(k1: Variant, k2: Variant) -> bool:
	return str(k1) == str(k2)
