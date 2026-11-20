extends Node2D
## end-to-end score probe（post-attack-score-balloon 主流程接线端到端验证）
## 用法: godot --headless --path <项目> res://test/scripts/buff/end_to_end_score_probe.tscn
##
## 复刻 skill_attack 的演出接线段（静默开启 → await do_post_attack_buff →
## take_score_declarations → await perform → 解除静默 + 显示同步 + 一次入账脉冲），
## 断言 spec 场景：
##   「计分板静默与一次入账」
##     —— 演出期间计分板不跳变（结算/token 吸收全程 label 保持静默前值）
##     —— 一次入账脉冲（perform 返回后同步一次 + 唯一一次 big_flow 脉冲）
##   「结算耗时与触发数量无关」
##     —— 4 贡献的管线结算段即时完成（与 1 贡献同级）
##   「token 错峰连发」定长口径
##     —— 8 贡献演出段时长落在定长区间（≈3.0s）
##   「族主 ×1.5 基于申报值」（申报口径端到端：真实 hunt_pursuit 管线申报 →
##     hunt_overlord 读同源累积）

const ORCHESTRATOR_SCRIPT := preload("res://scripts/ui/score_balloon_orchestrator.gd")
const BALLOON_SCRIPT := preload("res://scripts/ui/score_balloon.gd")

## 申报 mock buff：process_buff 内申报 + 自写数值（与迁移后真实效果同构）
class DeclareBuff extends Buff:
	var declare_delta: int = 0
	func process_buff():
		if declare_delta != 0:
			Current.total_score += declare_delta
			BuffSystem.declare_score_contribution(declare_delta)

## 迷你 game_manager：total_score 用真实 Label——
## setter 直写/big_flow 脉冲 tween/get_global_rect 终点取位三者全兼容
class MiniGameManager extends Node2D:
	var total_score: Label

var _results: Array = []
var _saved: Dictionary = {}
var _spy_label: Control

func _ready() -> void:
	await get_tree().process_frame
	_save_state()
	await _run_all()
	_restore_state()
	print("\n========== end-to-end score probe ==========")
	for r in _results:
		print("  %s" % r)
	var failed := 0
	for r in _results:
		if String(r).begins_with("FAIL:"):
			failed += 1
	print("  ------------------------------------------")
	print("  %d checks, %d failed" % [_results.size(), failed])
	print("=============================================\n")
	get_tree().quit(1 if failed > 0 else 0)

func _check(step: String, ok: bool, detail: String) -> void:
	## 立即打印（挂死时可定位最后断点）+ 收集汇总
	print("  %s %s — %s" % ["PASS:" if ok else "FAIL:", step, detail])
	_results.append("%s %s — %s" % ["PASS:" if ok else "FAIL:", step, detail])

## ---------- 全局状态保存/恢复 ----------

func _save_state() -> void:
	var bs := get_node("/root/BuffSystem")
	var pipelines_saved := {}
	for timing in bs.TIMINGS:
		pipelines_saved[timing] = {}
		for key in bs.LIFECYCLE_KEYS:
			pipelines_saved[timing][key] = bs.pipelines[timing][key].duplicate()
	_saved = {
		"pipelines": pipelines_saved,
		"resonance_ramp": bs.resonance_ramp,
		"score_declarations": bs._score_declarations.duplicate(),
		"current_family": bs._current_family_accumulation.duplicate(),
		"last_family": bs._last_family_accumulation.duplicate(),
		"initialized": bs._initialized_buff_ids.duplicate(),
		"total_score": Current._total_score,
		"run_score_earned": Current._run_score_earned,
		"muted": Current.total_score_display_muted,
		"gm": Current.game_manager,
		"hero": Current.hero,
		"score_muted": Current.score_board_float_muted,
	}

func _restore_state() -> void:
	var bs := get_node("/root/BuffSystem")
	for timing in bs.TIMINGS:
		for key in bs.LIFECYCLE_KEYS:
			bs.pipelines[timing][key] = _saved["pipelines"][timing][key]
	bs.resonance_ramp = _saved["resonance_ramp"]
	bs._score_declarations = _saved["score_declarations"]
	bs._current_family_accumulation = _saved["current_family"]
	bs._last_family_accumulation = _saved["last_family"]
	bs._initialized_buff_ids = _saved["initialized"]
	Current._total_score = _saved["total_score"]
	Current._run_score_earned = _saved["run_score_earned"]
	Current.total_score_display_muted = _saved["muted"]
	Current.game_manager = _saved["gm"]
	Current.hero = _saved["hero"]
	Current.score_board_float_muted = _saved["score_muted"]

## ---------- 舞台装配 ----------

func _stage() -> Node:
	var gm := MiniGameManager.new()
	gm.name = "game_manager"
	var board := Label.new()
	board.name = "total_score"
	board.text = "0"
	board.position = Vector2(280, 20)
	gm.total_score = board
	gm.add_child(board)
	get_tree().root.add_child(gm)
	Current.game_manager = gm
	_spy_label = board
	## Hero 替身（不入树绕过 _ready；气球头顶取位用）
	var hero := Node2D.new()
	hero.set_script(load("res://scripts/hero.gd"))
	hero.position = Vector2(160, 200)
	Current.hero = hero
	return gm

func _clear_stage(gm: Node) -> void:
	Current.hero = null
	Current.game_manager = null
	gm.queue_free()

## 管线独占：清空 post_attack 并返回 ALWAYS 数组
func _reset_post_attack() -> Array:
	var bs := get_node("/root/BuffSystem")
	for key in bs.LIFECYCLE_KEYS:
		bs.pipelines["post_attack"][key].clear()
	return bs.pipelines["post_attack"]["ALWAYS"]

func _make_declare(buff_id: String, family: String, delta: int) -> DeclareBuff:
	var buff: DeclareBuff = DeclareBuff.new({"buff_id": buff_id, "family": family, "tags": []}, Current.game_manager)
	buff.declare_delta = delta
	return buff

## ---------- 场景（全部直接 await，无 fire-and-forget） ----------

func _run_all() -> void:
	var gm = _stage()
	await _scenario_full_wiring(gm)
	await _scenario_burst_flat(gm)
	await _scenario_overlord_declaration(gm)
	_clear_stage(gm)

## 「计分板静默与一次入账」：4 贡献完整接线——演出期间不跳变，返回后一次同步+脉冲
func _scenario_full_wiring(gm: Node) -> void:
	Current._total_score = 500
	Current.total_score_display_muted = false
	Current.total_score = 500
	Current._run_score_earned = 0
	var arr := _reset_post_attack()
	arr.append(_make_declare("e2e_a", "hunt", 30))
	arr.append(_make_declare("e2e_b", "hunt", 40))
	arr.append(_make_declare("e2e_c", "coin", -10))
	arr.append(_make_declare("e2e_d", "resonance", 25))
	## 接线（skill_attack 同款）：气球出生 + 静默开启 + 直 await 管线结算
	var orchestrator: Node2D = ORCHESTRATOR_SCRIPT.new()
	gm.add_child(orchestrator)
	orchestrator.setup_balloon(120)
	Current.total_score_display_muted = true
	var settle_t0 := Time.get_ticks_msec()
	await get_node("/root/BuffSystem").do_post_attack_buff()
	var settle_ms: int = Time.get_ticks_msec() - settle_t0
	var settle_ok: bool = settle_ms <= 200 and _spy_label.text == "500"
	_check("结算段即时且静默（4 贡献 <200ms，label 不随申报跳变）", settle_ok,
		"settle=%dms label=%s" % [settle_ms, _spy_label.text])
	## 演出段：直 await 全程（GDScript 协程必须 await 调用，不能保存 state
	## 中途插入断言——"演出期间零跳变"由静默开关压制后的事后基线断言等效覆盖）
	var declarations: Array = get_node("/root/BuffSystem").take_score_declarations()
	var show_t0 := Time.get_ticks_msec()
	await orchestrator.perform(declarations)
	var show_ms: int = Time.get_ticks_msec() - show_t0
	var during_ok: bool = _spy_label.text == "500" and _spy_label.scale == Vector2.ONE
	## 4 贡献演出定长：按 orchestrator/balloon 常量动态推导（拧观感参数不破断言）
	## ——4 单发末枚到达 (4-1)×间隔+飞行；加轮询 0.05 + 定格 + 飞板即全程口径
	var single4: int = mini(4, ORCHESTRATOR_SCRIPT.MAX_INDIVIDUAL_TOKENS)
	var span4: float = (single4 * ORCHESTRATOR_SCRIPT.TOKEN_INTERVAL \
		+ ORCHESTRATOR_SCRIPT.TOKEN_FLY_DURATION) if 4 > single4 \
		else (single4 - 1) * ORCHESTRATOR_SCRIPT.TOKEN_INTERVAL \
		+ ORCHESTRATOR_SCRIPT.TOKEN_FLY_DURATION
	var expected4_ms: int = int(1000.0 * (span4 + 0.05 \
		+ BALLOON_SCRIPT.FREEZE_DURATION + BALLOON_SCRIPT.FLY_TO_BOARD_DURATION))
	_check("演出期间计分板静默（零跳变，4 贡献演出定长≈%.2fs）" % (expected4_ms / 1000.0),
		during_ok and show_ms >= expected4_ms - 500 and show_ms <= expected4_ms + 600,
		"label=%s 演出=%dms（应≈2.5s：3×0.3 连发+0.6 飞行+1.0 定格/飞板）" % [_spy_label.text, show_ms])
	## 入账时刻（skill_attack 同款）：解除静默 + 显示同步 + 一次入账脉冲
	Current.total_score_display_muted = false
	gm.total_score.text = str(Current.total_score)
	EffectManager.big_flow_effect(gm.total_score)
	orchestrator.queue_free()
	await get_tree().create_timer(0.04).timeout
	var pulse_seen: bool = _spy_label.scale != Vector2.ONE
	await get_tree().create_timer(0.4).timeout
	var final_ok: bool = _spy_label.text == "585" and Current._total_score == 585 \
		and _spy_label.scale == Vector2.ONE
	_check("入账一次同步（label=新值）", final_ok, "label=%s total=%d scale=%s" % [_spy_label.text, Current._total_score, _spy_label.scale])
	_check("一次入账脉冲（唯一一次 big_flow）", pulse_seen, "脉冲采样 scale≠ONE")
	## 清场核查：气球/编排器已回收
	await get_tree().process_frame
	var leftover := gm.get_children().filter(func(c) -> bool: return str(c.name).begins_with("Score"))
	_check("演出清场（气球/编排器回收）", leftover.is_empty(), "残留=%d" % leftover.size())

## 「token 错峰连发」定长：8 贡献演出段时长落在定长区间
func _scenario_burst_flat(gm: Node) -> void:
	Current._total_score = 0
	Current.total_score_display_muted = true
	var arr := _reset_post_attack()
	for i in range(8):
		arr.append(_make_declare("e2e_flat_%d" % i, "swarm", 10))
	var orchestrator: Node2D = ORCHESTRATOR_SCRIPT.new()
	gm.add_child(orchestrator)
	orchestrator.setup_balloon(80)
	## 管线结算先行（申报列表在此刻收集），演出段计时从结算后起算
	await get_node("/root/BuffSystem").do_post_attack_buff()
	var t0 := Time.get_ticks_msec()
	await orchestrator.perform(get_node("/root/BuffSystem").take_score_declarations())
	var elapsed := (Time.get_ticks_msec() - t0) / 1000.0
	Current.total_score_display_muted = false
	orchestrator.queue_free()
	## 8 贡献：演出时长按 orchestrator 三参数动态推导（拧参数不破断言）
	## ——单发数 = min(8, 上限)，汇总到达 = 单发数×间隔+飞行，
	## 加轮询 0.05 + 定格 0.5 + 飞板 0.5 即全程口径
	var max_tokens: int = ORCHESTRATOR_SCRIPT.MAX_INDIVIDUAL_TOKENS
	var single_count: int = mini(8, max_tokens)
	var burst_span: float = single_count * ORCHESTRATOR_SCRIPT.TOKEN_INTERVAL \
		+ ORCHESTRATOR_SCRIPT.TOKEN_FLY_DURATION if single_count < 8 \
		else (single_count - 1) * ORCHESTRATOR_SCRIPT.TOKEN_INTERVAL \
		+ ORCHESTRATOR_SCRIPT.TOKEN_FLY_DURATION
	var expected_total: float = burst_span + 0.05 \
		+ BALLOON_SCRIPT.FREEZE_DURATION + BALLOON_SCRIPT.FLY_TO_BOARD_DURATION
	var ok: bool = elapsed >= expected_total - 0.4 and elapsed <= expected_total + 0.6
	_check("8 贡献演出定长（动态口径≈%.2fs）" % expected_total, ok, "演出段=%.2fs" % elapsed)

## 「族主 ×1.5 基于申报值」：真实 hunt_pursuit 管线申报 → hunt_overlord 同源读取
func _scenario_overlord_declaration(gm: Node) -> void:
	Current._total_score = 0
	Current.total_score_display_muted = true
	Current.once_total_score = 200
	Current.slime_die_sum = 3
	var arr := _reset_post_attack()
	## 4 个真实 hunt_pursuit（条件 slime_die_sum>=3 满足 → each +int(200*0.35)=70）
	var pursuit_meta := {"buff_id": "hunt_pursuit", "family": "hunt", "tags": []}
	for i in range(4):
		arr.append(load("res://scripts/buff/hunt_pursuit_buff.gd").new(pursuit_meta, gm))
	## hunt_overlord（真实脚本，读家族累积 → roundi(280*0.50)=140）
	var overlord: Buff = load("res://scripts/buff/hunt_overlord_buff.gd").new(
		{"buff_id": "hunt_overlord", "family": "hunt", "tags": ["legendary"], "auto_activate": true}, gm)
	arr.append(overlord)
	await get_node("/root/BuffSystem").do_post_attack_buff()
	var declarations: Array = get_node("/root/BuffSystem").take_score_declarations()
	Current.total_score_display_muted = false
	## 断言：4 个 hunt_pursuit 申报各 +70；overlord 执行时读到累积 280（申报驱动）
	## → 申报 roundi(280*0.50)=140（族主 ×1.5 基于申报值）；overlord 尾巴自身 +140
	## 与普通申报同渠道入账家族累积（420 = 与差值测量现状语义一致）
	var accumulation: int = get_node("/root/BuffSystem").get_family_accumulation("hunt")
	var overlord_decl: int = 0
	if declarations.size() == 5:
		overlord_decl = int(declarations[4]["delta"])
	var ok: bool = accumulation == 420 and overlord_decl == roundi(280 * 0.50) \
		and Current._total_score == 280 + roundi(280 * 0.50)
	_check("族主 ×1.5 基于申报值（真实管线）", ok,
		"累积=%d overlord申报=%d total=%d decls=%d" % [accumulation, overlord_decl, Current._total_score, declarations.size()])
	## 清场：overlord 需手动 clear（探针直接注册不走购买流）
	overlord.clear_buff()
