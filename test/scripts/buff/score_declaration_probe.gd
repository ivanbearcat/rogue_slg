extends Node2D
## score-declaration probe（post-attack-score-balloon 申报基础设施验证）
## 用法: godot --headless --path <项目> res://test/scripts/buff/score_declaration_probe.tscn
##
## 覆盖 spec 场景（对照 openspec/changes/post-attack-score-balloon/specs）：
##   post-attack-score-balloon「得分贡献即时申报」
##     —— 申报即时生效（申报时刻家族累积/申报列表即时可见，数值即时写入）
##     —— 结算耗时与触发数量无关（1 个效果 vs 8 个效果，do_buff 均值耗时同级）
##     —— 无得分效果不申报（未触发不进申报列表、不动家族累积）
##   resonance-overlord-delayed「永久叠层累加」
##     —— 正向贡献累加 / 无贡献不累加 / 负贡献不累加 /
##        ramp 无上限（100 次正向申报 → 1.00）/ ramp 跨 clear_stage_buff 保留
##   current.gd total_score 展示静默（任务 1.2）
##     —— 静默期间 _total_score 与 run_score_earned 照常、label 文字与脉冲不动，
##        解除后恢复直写
##
## 全程操作真实 BuffSystem/Current autoload：进入前保存、结束恢复（见 _save/_restore）。

## 带申报行为的 mock buff：process_buff 内按 delta 申报（数值写入保持"效果自己负责"）
class DeclareBuff extends Buff:
	var declare_delta: int = 0
	var write_score: bool = true
	var loop: int = 1
	func process_buff():
		for i in range(loop):
			if declare_delta != 0:
				BuffSystem.declare_score_contribution(declare_delta)
				if write_score:
					Current.total_score += declare_delta

## 不申报、不写分的 mock buff（"未触发/无得分效果"用）
class SilentBuff extends Buff:
	func process_buff():
		pass

var _results: Array = []
var _saved: Dictionary = {}
## 直接复用 mock_game_manager 的 total_score（MockLabel，带 text/scale 观测面）。
## ⚠️ 不能用自定义 SpyLabel 换掉 gm.total_score——字段是 MockLabel 类型化声明，
## 不兼容类型的赋值会静默失败（GDScript 运行时类型检查），断言会读错对象。
var _spy_label: RefCounted

func _ready() -> void:
	await get_tree().process_frame
	_save_state()
	await _run_all()
	_restore_state()
	print("\n========== score-declaration probe ==========")
	var failed := 0
	for r in _results:
		print("  %s" % r)
		if String(r).begins_with("FAIL:"):
			failed += 1
	print("  ------------------------------------------")
	print("  %d checks, %d failed" % [_results.size(), failed])
	print("=============================================\n")
	get_tree().quit(1 if failed > 0 else 0)

## ---------- 全局状态保存/恢复（真实 autoload 侧写） ----------

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

func _check(step: String, ok: bool, detail: String) -> void:
	var tag: String = "PASS:" if ok else "FAIL:"
	_results.append("%s %s — %s" % [tag, step, detail])

## ---------- 装配辅助 ----------

func _ensure_mock_gm() -> void:
	## 探针需要 game_manager.total_score 可观测：直接复用 mock 自带的 MockLabel
	var gm = get_node("/root/game_manager")
	if gm == null:
		gm = Node2D.new()
		gm.name = "game_manager"
		gm.set_script(load("res://test/scripts/buff/mock_game_manager.gd"))
		get_tree().root.add_child(gm)
	Current.game_manager = gm
	_spy_label = gm.total_score

func _teardown_mock_gm() -> void:
	pass

## 清空 post_attack 管线（探针独占），返回可注册的数组
func _reset_post_attack_pipeline() -> Array:
	var bs := get_node("/root/BuffSystem")
	for key in bs.LIFECYCLE_KEYS:
		bs.pipelines["post_attack"][key].clear()
	return bs.pipelines["post_attack"]["ALWAYS"]

func _make_buff(script: GDScript, buff_id: String, family: String) -> Buff:
	var gm = get_node("/root/game_manager")
	var meta := {"buff_id": buff_id, "family": family, "tags": []}
	return script.new(meta, gm)

func _register_resonance_family(count: int) -> void:
	## 共鸣系 ≥4 门槛：注册 count 个 resonance 占位 buff（SilentBuff 不申报）
	var arr := _reset_post_attack_pipeline()
	for i in count:
		arr.append(_make_buff(SilentBuff, "resonance_%d" % i, "resonance"))

## ---------- 场景（对照 spec） ----------

func _run_all() -> void:
	_ensure_mock_gm()
	## do_buff 场景全程开静默：mock 环境下 setter 的 big_flow_effect 会向
	## MockLabel 打 tween 报错刷屏（真实场景在攻击结算期间静默窗口本就开启，
	## 数值与家族累积断言不受静默影响）
	Current.total_score_display_muted = true
	await _scenario_declare_immediate()
	await _scenario_settle_time_flat()
	await _scenario_no_score_no_declare()
	await _scenario_ramp_positive()
	await _scenario_ramp_no_declare()
	await _scenario_ramp_negative()
	await _scenario_ramp_no_cap()
	await _scenario_ramp_survive_clear_stage()
	Current.total_score_display_muted = false
	await _scenario_setter_display_mute()
	_teardown_mock_gm()

## spec「申报即时生效」：申报 +50 → 家族累积/申报列表即时可见，数值即时写入
func _scenario_declare_immediate() -> void:
	var bs := get_node("/root/BuffSystem")
	var arr := _reset_post_attack_pipeline()
	var buff: DeclareBuff = _make_buff(DeclareBuff, "probe_hunt", "hunt")
	buff.declare_delta = 50
	arr.append(buff)
	Current._total_score = 0
	bs._current_family_accumulation.clear()
	await bs.do_buff("post_attack")
	var decls: Array = bs.take_score_declarations()
	var ok: bool = Current._total_score == 50 \
		and bs.get_family_accumulation("hunt") == 50 \
		and decls.size() == 1 and decls[0]["delta"] == 50 and decls[0]["buff"] == buff \
		and str(decls[0]["icon_path"]) == str(buff.buff_meta.get("buff_icon", ""))
	_check("申报即时生效", ok,
		"total=%d family=%d decls=%d" % [Current._total_score, bs.get_family_accumulation("hunt"), decls.size()])

## spec「结算耗时与触发数量无关」：1 个 vs 8 个申报效果，do_buff 结算耗时同级
func _scenario_settle_time_flat() -> void:
	var bs := get_node("/root/BuffSystem")
	Current._total_score = 0
	## 8 个
	var arr := _reset_post_attack_pipeline()
	for i in range(8):
		var b: DeclareBuff = _make_buff(DeclareBuff, "probe_flat_%d" % i, "swarm")
		b.declare_delta = 10
		arr.append(b)
	var t0 := Time.get_ticks_msec()
	await bs.do_buff("post_attack")
	var t8 := Time.get_ticks_msec() - t0
	bs.take_score_declarations()
	## 1 个
	arr.clear()
	var b1: DeclareBuff = _make_buff(DeclareBuff, "probe_flat_single", "swarm")
	b1.declare_delta = 80
	arr.append(b1)
	Current._total_score = 0
	var t1 := Time.get_ticks_msec()
	await bs.do_buff("post_attack")
	var t1_ms := Time.get_ticks_msec() - t1
	bs.take_score_declarations()
	## headless 单帧内两者都应即时完成；阈值取一帧裕量（效果零 sleep，正常 < 16ms）
	var ok: bool = t8 <= 32 and t1_ms <= 32
	_check("结算耗时与触发数量无关", ok, "8个=%dms 1个=%dms（阈值32ms，效果零硬等待）" % [t8, t1_ms])

## spec「无得分效果不申报」：未触发/未改变得分 → 无 token 申报、家族累积不动
func _scenario_no_score_no_declare() -> void:
	var bs := get_node("/root/BuffSystem")
	var arr := _reset_post_attack_pipeline()
	arr.append(_make_buff(SilentBuff, "probe_silent", "swarm"))
	Current._total_score = 0
	bs._current_family_accumulation.clear()
	await bs.do_buff("post_attack")
	var decls: Array = bs.take_score_declarations()
	_check("无得分效果不申报", decls.is_empty() and not bs._current_family_accumulation.has("swarm"),
		"decls=%d family_keys=%s" % [decls.size(), str(bs._current_family_accumulation.keys())])

## spec resonance「正向贡献累加 ramp」：申报 +50 → ramp +0.01
func _scenario_ramp_positive() -> void:
	var bs := get_node("/root/BuffSystem")
	_register_resonance_family(4)
	var buff: DeclareBuff = _make_buff(DeclareBuff, "probe_res", "resonance")
	buff.declare_delta = 50
	bs.pipelines["post_attack"]["ALWAYS"].append(buff)
	bs.resonance_ramp = 0.0
	Current._total_score = 0
	await bs.do_buff("post_attack")
	bs.take_score_declarations()
	_check("正向申报累加 ramp", is_equal_approx(bs.resonance_ramp, 0.01),
		"ramp=%.4f（应 0.0100）" % bs.resonance_ramp)

## spec resonance「无贡献不累加」：共鸣系 buff 执行但未申报 → ramp 不变
func _scenario_ramp_no_declare() -> void:
	var bs := get_node("/root/BuffSystem")
	var arr := _reset_post_attack_pipeline()
	_register_resonance_family(4)
	var silent := _make_buff(SilentBuff, "probe_res_silent", "resonance")
	arr.append(silent)
	bs.resonance_ramp = 0.02
	await bs.do_buff("post_attack")
	bs.take_score_declarations()
	_check("无申报不叠 ramp", is_equal_approx(bs.resonance_ramp, 0.02),
		"ramp=%.4f（应保持 0.0200）" % bs.resonance_ramp)

## spec resonance「负贡献不累加」：申报 -5 → ramp 不变
func _scenario_ramp_negative() -> void:
	var bs := get_node("/root/BuffSystem")
	var arr := _reset_post_attack_pipeline()
	_register_resonance_family(4)
	var neg: DeclareBuff = _make_buff(DeclareBuff, "probe_res_neg", "resonance")
	neg.declare_delta = -5
	arr.append(neg)
	Current._total_score = 100
	bs.resonance_ramp = 0.03
	await bs.do_buff("post_attack")
	var decls: Array = bs.take_score_declarations()
	var ok: bool = is_equal_approx(bs.resonance_ramp, 0.03) and decls.size() == 1 and decls[0]["delta"] == -5
	_check("负申报不叠 ramp（且进播报列表）", ok,
		"ramp=%.4f decls=%d delta=%d" % [bs.resonance_ramp, decls.size(), decls[0]["delta"] if decls.size() > 0 else 0])

## spec resonance「ramp 无上限」：100 次正向申报 → ramp = 1.00
func _scenario_ramp_no_cap() -> void:
	var bs := get_node("/root/BuffSystem")
	var arr := _reset_post_attack_pipeline()
	_register_resonance_family(4)
	var many: DeclareBuff = _make_buff(DeclareBuff, "probe_res_many", "resonance")
	many.declare_delta = 50
	many.loop = 100
	arr.append(many)
	Current._total_score = 0
	bs.resonance_ramp = 0.0
	await bs.do_buff("post_attack")
	bs.take_score_declarations()
	_check("ramp 无上限（100 次正向申报 → 1.00）", is_equal_approx(bs.resonance_ramp, 1.00),
		"ramp=%.4f（应 1.0000）" % bs.resonance_ramp)

## spec resonance「ramp 跨关卡保留」：clear_stage_buff 不重置 ramp
func _scenario_ramp_survive_clear_stage() -> void:
	var bs := get_node("/root/BuffSystem")
	bs.resonance_ramp = 0.05
	bs.clear_stage_buff()
	_check("clear_stage_buff 保留 ramp", is_equal_approx(bs.resonance_ramp, 0.05),
		"ramp=%.4f（应保持 0.0500）" % bs.resonance_ramp)

## 任务 1.2「total_score 展示静默」：静默期间数值与记账照常、文字与脉冲不动，解除后恢复
func _scenario_setter_display_mute() -> void:
	var before_earned: int = Current._run_score_earned
	Current._total_score = 100
	Current.total_score = 100
	_spy_label.text = "0"
	Current._run_score_earned = 0
	## 静默窗口：setter 写入 200
	Current.total_score_display_muted = true
	Current.total_score = 200
	var muted_ok: bool = Current._total_score == 200 \
		and Current._run_score_earned == 100 \
		and _spy_label.text == "0" \
		and _spy_label.scale == Vector2.ONE
	## 解除：同值重写恢复直写与脉冲
	Current.total_score_display_muted = false
	Current.total_score = Current._total_score
	var restored_ok: bool = _spy_label.text == "200"
	_check("静默期间数值/记账照常、文字与脉冲不动", muted_ok,
		"total=%d earned=%d label=%s scale=%s（应 200/100/旧值/ONE）" % [Current._total_score, Current._run_score_earned, _spy_label.text, str(_spy_label.scale)])
	_check("解除静默后恢复直写", restored_ok, "label=%s（应 200）" % _spy_label.text)
	Current._run_score_earned = before_earned
