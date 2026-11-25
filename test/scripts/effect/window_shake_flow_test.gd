extends Node

## 窗口抖动回归（window-shake 定稿口径：击杀 + 爆档驻留两处接线，其余时刻不抖）
## 用法: godot --headless --path . res://test/scripts/effect/window_shake_flow_test.tscn
##
## 直进战局（跳过 splash/英雄选择 UI）：
##  1. 负向——初版接线经观感试听定稿移除的九类时刻（被扣血、掷骰波、精英/BOSS
##     落位、升级、过关、灼烧之地扣血、BOSS 出现、绝境免死、游戏结束）逐一触发，
##     断言零位移（spec「既有时刻明确不抖」）；
##  2. 负向——血瓶获得/使用零位移（spec 同上）；
##  3. 正向——得分爆档驻留抖动全生命周期：进入 1000+ 起持续、预览收起/离开爆档止、
##     复位零漂移、非爆档不起（spec「得分爆档持续抖动」）；
##  4. 源码扫描——击杀挂点时序、点击攻击即停位置、接线面恰好两处无散落。
##
## ⚠️ GDScript 协程陷阱三条：
##   1) 异步 helper 调用一律 await（不 await 的异步调用会挂起后立刻返回，
##      调用方提前继续——曾致测试静默早退）；
##   2) 协程返回值不能 `var x := coro()` 取用（解析期报错），并发采样用
##      fire-and-forget 探针（_start_probe 裸调用）+ 成员状态（_join_probe 取结果）。
##   3) 测试场景作为主场景启动时会被 change_scene 释放（current_scene 陷阱），
##      _ready 先摘除 current_scene 登记自保。

var _gm: Node2D
var _cam: Camera2D
var _passed := 0
var _failed := 0
var _errors: Array = []
var _probe_moved := false
var _probe_done := true

func _ready() -> void:
	## 自保：SceneManager.change_scene 会释放 get_tree().current_scene（= 本测试节点）。
	## 先摘除 current_scene 登记（其回退查 SceneManager.current_scene 亦为空 → 不释放），
	## 本节点作为 root 普通子节点存活，驱动整个测试流程。
	get_tree().current_scene = null
	await _boot_battle()
	await _run_all_tests()
	_wrap_up()

func _wrap_up() -> void:
	print("\n==================================================")
	print("  Total: %d | Passed: %d | Failed: %d" % [_passed + _failed, _passed, _failed])
	if _errors.size() > 0:
		print("  --- Failed ---")
		for err in _errors:
			print("  %s" % err)
	print("==================================================")
	get_tree().quit(1 if _failed > 0 else 0)

## 直进战局并等待首回合铺场完成（掷骰波 + 首回合结束回到 hero_turn）
func _boot_battle() -> void:
	Current.selected_hero = "soldier"
	await SceneTransition.transition_to(&"main", &"stage_start")
	_gm = Current.game_manager
	_cam = get_viewport().get_camera_2d()
	if _gm == null or _cam == null:
		print("[FLOW] ❌ 战局启动失败：game_manager=%s camera=%s" % [_gm, _cam])
		get_tree().quit(1)
		return
	var waited := 0.0
	while (Current.all_enemy_array.size() == 0 or Current.turn != "hero_turn") and waited < 25.0:
		await _wait(0.25)
		waited += 0.25
	await _await_settle()
	print("[FLOW] 战局就绪：场上史莱姆 %d 只，回合=%s" % [Current.all_enemy_array.size(), Current.turn])

func _run_all_tests() -> void:
	print("\n==================================================")
	print("  WindowShake Wiring Flow Test (Headless)")
	print("==================================================")

	## ---- 负向：九类移除时刻逐一断言零位移 ----
	await _neg_dice_wave()
	await _neg_hp_damage()
	await _neg_potion()
	await _neg_scorched_earth()
	await _neg_elite_move()
	await _neg_death_immunity()
	await _neg_level_up()
	await _neg_stage_clear()
	await _neg_boss_announce()

	## ---- 正向：得分爆档驻留抖动全生命周期 ----
	await _pos_sustained_score_zone()

	## ---- 负向：游戏结束（最后执行：置 paused + 弹结算）----
	await _neg_game_over()

	## ---- 源码扫描：击杀挂点 / 点击即停位置 / 接线面审计 ----
	_source_scan_hooks()
	_source_scan_negatives()

## 负向：掷骰波（史莱姆批量生成）不抖
func _neg_dice_wave() -> void:
	_gm._pre_create_slime()
	_start_probe(1.6)
	await _gm._create_slime()
	var observed: Dictionary = await _join_probe()
	_check("掷骰波不抖：批量生成时刻零位移（试听定稿移除）", not observed["moved"] and await _await_settle())

## 负向：被扣血（damage>0 与 damage=0）不抖
func _neg_hp_damage() -> void:
	var saved_defense: int = Current.player_defense
	var saved_hp: int = Current.player_hp
	## damage=0（防御拉满）
	Current.player_defense = 999
	_start_probe(0.4)
	_gm._apply_hp_damage()
	var still: Dictionary = await _join_probe()
	## damage>0（防御归零，场上史莱姆 ≥3）
	Current.player_defense = 0
	_start_probe(0.8)
	_gm._apply_hp_damage()
	var damaged: Dictionary = await _join_probe()
	_check("被扣血不抖：damage>0 与零伤害均零位移（HP 条局部反馈保留）",
		not still["moved"] and not damaged["moved"] and Current.player_hp < saved_hp
		and await _await_settle())
	Current.player_defense = saved_defense

## 负向：血瓶获得 / 使用不抖
func _neg_potion() -> void:
	Current.potion_count = 0
	Current.potion_max = maxi(Current.potion_max, 3)
	Current.score_heal_accumulated = 0
	Current.once_total_score = Current.score_heal_threshold
	_start_probe(0.6)
	_gm._apply_score_heal()
	var granted: Dictionary = await _join_probe()
	_check("血瓶获得不抖（得分回血达阈值）",
		Current.potion_count == 1 and not granted["moved"] and await _await_settle())
	Current.player_hp = maxi(Current.player_hp - 1, 0)
	var hp_before: int = Current.player_hp
	_start_probe(0.6)
	_gm._on_potion_button_pressed()
	var used: Dictionary = await _join_probe()
	_check("血瓶使用不抖（恢复 HP）",
		Current.potion_count == 0 and Current.player_hp == hp_before + 1
		and not used["moved"] and await _await_settle())

## 负向：灼烧之地 pre_hero_turn 扣血不抖
func _neg_scorched_earth() -> void:
	var buff_rows: Array = _load_json("res://config/buff.json")
	var row: Dictionary = {}
	for r in buff_rows:
		if r.get("buff_id", "") == "scorched_earth":
			row = r
			break
	if row.is_empty():
		_check("灼烧之地 buff 元数据可加载", false)
		return
	var buff: Node2D = load(str(row["buff_res"])).new(row, _gm)
	buff.set_buff()
	Current.player_hp = 5
	_start_probe(0.8)
	buff._do_pre_hero_turn()
	var observed: Dictionary = await _join_probe()
	_check("灼烧之地扣血不抖：扣 1 HP 时刻零位移（试听定稿移除）",
		Current.player_hp == 4 and not observed["moved"] and await _await_settle())
	buff.clear_buff()
	buff.queue_free()

## 负向：精英/BOSS 移动落位不抖
func _neg_elite_move() -> void:
	var slimes: Array = Current.all_enemy_array
	if slimes.is_empty():
		_check("精英落位测试前置：场上存在史莱姆", false)
		return
	var promoted = slimes[0]
	promoted.is_elite = true
	Current.elite_slime_array.append(promoted)
	_start_probe(2.5)
	await _gm._move_elite_boss_slimes()
	var observed: Dictionary = await _join_probe()
	Current.elite_slime_array.erase(promoted)
	promoted.is_elite = false
	_check("精英/BOSS 落位不抖：移动落位完成时刻零位移（试听定稿移除）",
		not observed["moved"] and await _await_settle())

## 负向：绝境免死生效不抖
func _neg_death_immunity() -> void:
	Current.has_death_immunity = true
	Current.death_immunity_used = false
	Current.player_hp = 0
	_start_probe(0.8)
	_gm._pre_hero_turn_begin()
	var observed: Dictionary = await _join_probe()
	_check("绝境免死不抖：HP 恢复 1 的救场时刻零位移（试听定稿移除）",
		Current.player_hp == 1 and not observed["moved"]
		and not get_tree().paused and await _await_settle())

## 负向：升级不抖
func _neg_level_up() -> void:
	Current.hero_exp = Current.require_exp
	_start_probe(1.8)
	await _gm._check_and_level_up()
	var observed: Dictionary = await _join_probe()
	get_tree().paused = false
	_gm.level_up_ui.hide()
	Current.public_lock_array.erase("level_up_ui")
	_check("升级不抖：升级瞬间零位移（试听定稿移除）",
		not observed["moved"] and await _await_settle())

## 负向：过关结算弹出不抖
func _neg_stage_clear() -> void:
	_start_probe(6.5)
	await _gm._do_stage_clear_effect(1, 2, 3)
	var observed: Dictionary = await _join_probe()
	var was_paused: bool = get_tree().paused
	get_tree().paused = false
	_gm._hide_all_clear_stage_ui()
	_check("过关不抖：结算弹出全程零位移（试听定稿移除）",
		not observed["moved"] and was_paused and await _await_settle())

## 负向：BOSS 出现公告不抖
func _neg_boss_announce() -> void:
	_start_probe(2.2)
	await _gm._spawn_boss_slime()
	var observed: Dictionary = await _join_probe()
	_check("BOSS 出现不抖：公告装配时刻零位移（试听定稿移除）",
		not observed["moved"] and await _await_settle())

## 负向：游戏结束不抖（最后执行：置 paused + 弹结算）
func _neg_game_over() -> void:
	Current.has_death_immunity = false
	Current.player_hp = 0
	_start_probe(0.9)
	_gm._pre_hero_turn_begin()
	var observed: Dictionary = await _join_probe()
	var was_paused: bool = get_tree().paused
	_check("游戏结束不抖：结算入口零位移（试听定稿移除）",
		not observed["moved"] and was_paused and await _await_settle())
	get_tree().paused = false

## 正向：得分爆档驻留抖动全生命周期
func _pos_sustained_score_zone() -> void:
	var skill_sys: Node = _gm.skill_system
	## 进入爆档：驻留起（两窗持续位移 = 驻留证明，一次性脉冲不可能覆盖两窗）
	skill_sys._reset_dice_panel()
	skill_sys._apply_score_visual(1200)
	var first: Dictionary = await _sample_shake(0.5)
	var second: Dictionary = await _sample_shake(0.5)
	_check("得分爆档驻留：进入 1000+ 燃烧区段起持续轻抖（两窗均见位移）",
		first["moved"] and second["moved"])
	## 停止路径一：预览面板收起（点击攻击后状态退出 / 离开棋盘均经此处兜底）
	skill_sys._reset_dice_panel()
	_check("爆档驻留停止（预览收起）：复位零漂移", await _await_settle())
	## 重进爆档后，停止路径二：预览离开爆档（zone<3 重渲染，无面板收起）
	skill_sys._apply_score_visual(1200)
	await _wait(0.2)
	skill_sys._apply_score_visual(500)
	_check("爆档驻留停止（预览离开爆档）：复位零漂移", await _await_settle())
	## 负向：非爆档分数不起抖
	skill_sys._reset_dice_panel()
	_start_probe(0.5)
	skill_sys._apply_score_visual(500)
	var low: Dictionary = await _join_probe()
	_check("非爆档分数（500）不抖", not low["moved"] and await _await_settle())

## ============================================================
## 源码扫描断言（击杀挂点时序 + 点击即停位置 + 接线面审计 + 负向零接线）
## ============================================================
func _source_scan_hooks() -> void:
	var ss_src := _read_file("res://scripts/skill_system.gd")

	## 击杀挂点（死亡+抖动同刻锚定 0.6s 节拍，slime-death-hit-frame design D4/D5）：
	## 门闸须同时含命中帧条件与 0.6s 节拍下限；die 起播位于门闸后；
	## 抖动位于 die 起播后（同刻）；击杀链不再有独立的 0.6s 手调等待
	var gate_idx := ss_src.find("not Current.attack_hit_frame_reached or")
	var beat_idx := ss_src.find("- gate_start_ms < 600")
	var die_play_idx := ss_src.find('animated_sprite_2d.play("die")')
	var kill_call_idx := ss_src.find('window_shake("heavy" if kill_shake_heavy else "medium")')
	_check("击杀挂点：0.6s 节拍门闸（含命中帧下限）后 die 起播、抖动与起播同刻",
		gate_idx >= 0 and beat_idx > gate_idx and die_play_idx > gate_idx
		and kill_call_idx > die_play_idx and ss_src.find("time_sleep(0.6)") < 0)

	## 命中帧门闸时序（slime-death-hit-frame）：play("die") 起播必须位于命中帧门闸
	## while 之后 → 结算点击瞬间不播死亡、命中帧不早死（spec「死亡动画起播于点击后0.6s节拍」）
	_check("命中帧门闸：die 起播位于门闸 while 之后（点击瞬间不早死）",
		gate_idx >= 0 and die_play_idx > gate_idx)

	## 命中帧信号置位（slime-death-hit-frame）：hero.gd 帧回调必须存在
	## attack 音效帧 → 命中标志的置位（门闸的信号源，漏配则门闸退到兜底放行）
	var hero_src := _read_file("res://scripts/hero.gd")
	var hero_frame_body := _extract_func_body(hero_src, "_on_animated_sprite_2d_frame_changed")
	_check("命中帧信号：hero.gd 帧回调存在 attack 音效帧置位命中标志",
		hero_frame_body.contains("Current.attack_hit_frame_reached = true"))

	## 点击攻击即停：驻留停止调用位于 skill_attack 入口（action_lock 之前 = 点击同帧）
	var attack_fn := ss_src.find("func skill_attack():")
	var stop_idx := ss_src.find("EffectManager.window_shake_sustained_stop()", attack_fn)
	var lock_idx := ss_src.find("Current.action_lock = true", attack_fn)
	_check("点击攻击即停：驻留停止调用位于 skill_attack 入口（action_lock 之前）",
		attack_fn >= 0 and stop_idx > attack_fn and lock_idx > stop_idx)

	## 接线面审计：定稿口径恰好两处接线（击杀一次性 + 爆档驻留起止），无散落
	var expected := {
		"res://scripts/skill_system.gd": {"one_shot": 1, "sustained": 1, "stop": 3},
		"res://scripts/game_manager.gd": {"one_shot": 0, "sustained": 0, "stop": 0},
		"res://scripts/buff/scorched_earth_buff.gd": {"one_shot": 0, "sustained": 0, "stop": 0},
	}
	var audit_ok := true
	for path in expected:
		var src := _read_file(path)
		var one_shot := src.count("EffectManager.window_shake(")
		var sustained := src.count("EffectManager.window_shake_sustained(")
		var stop := src.count("EffectManager.window_shake_sustained_stop()")
		var exp: Dictionary = expected[path]
		if one_shot != exp["one_shot"] or sustained != exp["sustained"] or stop != exp["stop"]:
			audit_ok = false
			_errors.append("接线数不符 %s：期望 %s 实际 one_shot=%d sustained=%d stop=%d"
				% [path, exp, one_shot, sustained, stop])
	_check("接线面审计：定稿恰好击杀一次性 + 爆档驻留起止，其余文件零接线", audit_ok)

	## 收口审计：scripts/ 下抖动家族引用仅存在于 skill_system 与入口定义处
	var allowed := {
		"scripts/skill_system.gd": true,
		"scripts/autoload/effect_manager.gd": true,
	}
	var stray: Array = []
	_scan_dir_for_shake("res://scripts", allowed, stray)
	_check("收口审计：scripts/ 无其他文件引用 window_shake 家族", stray.is_empty())

## 负向源码扫描：九类移除时刻 + 血瓶/商店/技能替换的函数体无抖动接线
func _source_scan_negatives() -> void:
	var gm_src := _read_file("res://scripts/game_manager.gd")
	var forbidden := [
		["_apply_hp_damage", "被扣血（试听定稿移除）"],
		["_create_slime", "掷骰波·批量生成（试听定稿移除）"],
		["_move_elite_boss_slimes", "精英/BOSS 落位（试听定稿移除）"],
		["_check_and_level_up", "升级（试听定稿移除）"],
		["_do_stage_clear_effect", "过关结算（试听定稿移除）"],
		["_spawn_boss_slime", "BOSS 出现公告（试听定稿移除）"],
		["_pre_hero_turn_begin", "绝境免死/游戏结束（试听定稿移除）"],
		["_apply_score_heal", "血瓶获得（得分回血）"],
		["_on_potion_button_pressed", "血瓶使用"],
		["_on_buff_shop_button_1_pressed", "商店购买·BUFF栏1"],
		["_on_buff_shop_button_2_pressed", "商店购买·BUFF栏2"],
		["_on_buff_shop_button_3_pressed", "商店购买·BUFF栏3"],
		["_on_shop_coin_skill_button_pressed", "商店购买·金币技能"],
		["_on_replace_skill_1_pressed", "技能替换·槽位1"],
		["_on_replace_skill_2_pressed", "技能替换·槽位2"],
		["_on_replace_skill_3_pressed", "技能替换·槽位3"],
		["_replace_coin_skill", "技能替换·落账"],
	]
	var all_clean := true
	for entry in forbidden:
		var body := _extract_func_body(gm_src, entry[0])
		if body == "" or body.contains("window_shake"):
			all_clean = false
			_errors.append("负向时刻含抖动接线或函数缺失: %s(%s)" % [entry[0], entry[1]])
	_check("game_manager 负向源码扫描：移除时刻与血瓶/商店/技能替换零接线", all_clean)
	## 灼烧之地（独立文件）函数体扫描
	var se_src := _read_file("res://scripts/buff/scorched_earth_buff.gd")
	var se_body := _extract_func_body(se_src, "_do_pre_hero_turn")
	_check("scorched_earth 负向源码扫描：pre_hero_turn 扣血零接线",
		se_body != "" and not se_body.contains("window_shake"))

## ============================================================
## 工具函数
## ============================================================
func _check(name: String, ok: bool) -> void:
	if ok:
		_passed += 1
		print("  PASS: ", name)
	else:
		_failed += 1
		_errors.append(name)
		print("  FAIL: ", name)

## 暂停容忍计时（process_always=true：paused 窗口内照常走表）
func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true).timeout

## 抖动观察窗（直取型）：window 秒内采样 offset，返回是否发生位移
func _sample_shake(window: float) -> Dictionary:
	var moved := false
	var elapsed := 0.0
	const STEP := 0.02
	while elapsed < window:
		await _wait(STEP)
		elapsed += STEP
		if _cam.offset != Vector2.ZERO:
			moved = true
	return {"moved": moved, "offset": _cam.offset}

## 后台位移探针（fire-and-forget 协程：裸调用挂起即返回，采样结果存成员，
## 供与异步被测流程并发运行，_join_probe 取结果）
func _start_probe(window: float) -> void:
	_probe_moved = false
	_probe_done = false
	var elapsed := 0.0
	const STEP := 0.02
	while elapsed < window:
		await _wait(STEP)
		elapsed += STEP
		if _cam.offset != Vector2.ZERO:
			_probe_moved = true
	_probe_done = true

## 等后台探针窗口走完并取结果
func _join_probe() -> Dictionary:
	while not _probe_done:
		await _wait(0.02)
	return {"moved": _probe_moved, "offset": _cam.offset}

## 等待相机归位并保持稳定（用例间收尾）
func _await_settle() -> bool:
	var waited := 0.0
	while _cam.offset != Vector2.ZERO and waited < 2.0:
		await _wait(0.02)
		waited += 0.02
	if _cam.offset != Vector2.ZERO:
		return false
	for i in 3:
		await _wait(0.02)
		if _cam.offset != Vector2.ZERO:
			return false
	return true

func _load_json(path: String) -> Array:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		return []
	return parsed

func _read_file(path: String) -> String:
	return FileAccess.get_file_as_string(path)

## 提取函数体（从 "func <name>" 起到下一个顶级 "func " 或文件尾）
func _extract_func_body(src: String, func_name: String) -> String:
	var header := "func %s(" % func_name
	var start := src.find(header)
	if start < 0:
		return ""
	var next_func := src.find("\nfunc ", start + header.length())
	if next_func < 0:
		next_func = src.length()
	return src.substr(start, next_func - start)

## 递归扫描目录下 .gd 文件是否含抖动家族引用（allowed 之外的即散落）
func _scan_dir_for_shake(dir_path: String, allowed: Dictionary, out: Array) -> void:
	var da := DirAccess.open(dir_path)
	if da == null:
		return
	da.list_dir_begin()
	var name := da.get_next()
	while name != "":
		var full := dir_path + "/" + name
		if da.current_is_dir():
			if not name.begins_with("."):
				_scan_dir_for_shake(full, allowed, out)
		elif name.ends_with(".gd"):
			var rel := full.replace("res://", "")
			if not allowed.has(rel):
				if FileAccess.get_file_as_string(full).contains("window_shake"):
					out.append(rel)
		name = da.get_next()
	da.list_dir_end()
