extends SceneTree
## 窗口抖动核心机制回归（window-shake task 1.3 / 2.3 / design D4·D5）
## 用法: godot --headless --path . --script res://test/scripts/effect/window_shake_core_test.gd
##
## 覆盖：
##  1. 三档（轻/中/重）各自触发后相机 offset 复位到基准 (0,0)
##  2. 未识别档位零位移（spec「未知档位不抖」）
##  3. 抖动中途二次触发（同档与异档）最终复位无漂移（spec「抖动中途再触发不漂移」，
##     即 task 2.3「击杀与扣血时序错开无覆盖冲突」的机制层等价断言）
##  4. get_tree().paused 窗口内抖动照常播完并复位（design D5，TWEEN_PAUSE_PROCESS）
##  5. zoom 校准：zoom=4 下重档实际 offset 幅度 ≤ 屏幕值/zoom（design D3）
##
## autoload 编译期不可见（--script 模式）：一律按 save_codec_test 同款运行时取用

var _total: int = 0
var _passed: int = 0
var _failed: int = 0
var _errors: Array = []
var _cam: Camera2D

func _init():
	await_frame()

func await_frame():
	await process_frame
	await _ensure_camera()
	await run_all_tests()
	quit(1 if _failed > 0 else 0)

## 独立相机（zoom=4 对齐 main.tscn 口径）：--script 模式无主场景，手动挂一台当前相机
func _ensure_camera() -> void:
	_cam = Camera2D.new()
	_cam.zoom = Vector2(4, 4)
	_cam.position = Vector2(72, 71)
	root.add_child(_cam)
	_cam.make_current()
	## 等一帧让相机注册为当前相机
	await process_frame

func _fx() -> Node:
	return root.get_node("EffectManager")

func run_all_tests() -> void:
	print("\n==================================================")
	print("  WindowShake Core Test (Headless)")
	print("==================================================")

	## 编译期校验连带覆盖：改动过的脚本能在项目上下文中加载
	_check("改动脚本运行时可加载", _test_scripts_loadable())

	## 1. 三档各自触发后复位
	for tier in ["light", "medium", "heavy"]:
		_fx().window_shake(tier)
		var observed := await _sample_shake(0.35)
		_check("档位[%s]触发后画面发生位移且复位到 (0,0)" % tier,
			observed["moved"] and await _await_reset(1.0))

	## 2. 未识别档位零位移
	for tier in ["mega", "ultra", ""]:
		_fx().window_shake(tier)
		var still := await _sample_shake(0.2)
		_check("未识别档位[%s]零位移" % ("空串" if tier == "" else tier),
			(not still["moved"]) and _cam.offset == Vector2.ZERO)

	## 3a. 抖动中途二次触发（同档）
	_fx().window_shake("heavy")
	await create_timer(0.15, true).timeout
	_fx().window_shake("heavy")
	var same_retrigger := await _sample_shake(0.4)
	_check("中途二次触发（同档 heavy）最终复位无漂移",
		same_retrigger["moved"] and await _await_reset(1.0))

	## 3b. 抖动中途二次触发（异档：重→轻，弱档覆盖强档）
	_fx().window_shake("heavy")
	await create_timer(0.15, true).timeout
	_fx().window_shake("light")
	var cross_retrigger := await _sample_shake(0.3)
	_check("中途二次触发（异档 heavy→light）最终复位无漂移",
		cross_retrigger["moved"] and await _await_reset(1.0))

	## 4. 暂停窗口内播完并复位（design D5）
	paused = true
	_fx().window_shake("light")
	var paused_observed := await _sample_shake(0.25)
	var paused_reset := await _await_reset(1.0)
	var still_paused := paused
	paused = false
	_check("get_tree().paused 期间抖动照常播完并复位（仍处暂停态）",
		paused_observed["moved"] and paused_reset and still_paused
		and _cam.offset == Vector2.ZERO)

	## 5. zoom 校准：重档幅度 ≤ 屏幕值/zoom（10/4=2.5），漏除 zoom 会放大 4 倍被此断言拦截
	_fx().window_shake("heavy")
	var zoom_probe := await _sample_shake(0.35)
	_check("zoom=4 校准：重档实际 offset 幅度 ≤ 2.5（屏幕值/zoom）",
		zoom_probe["moved"] and zoom_probe["max_abs"] <= 2.5 + 0.01
		and await _await_reset(1.0))

	## 6. 驻留抖动（得分爆档用）：持续不止 + 停止复位 + 幂等 + 一次性覆盖后不复活
	_fx().window_shake_sustained("light")
	var sus_first: Dictionary = await _sample_shake(0.5)
	var sus_second: Dictionary = await _sample_shake(0.5)
	_check("驻留抖动持续不止（两窗均见位移，非一次性脉冲）",
		sus_first["moved"] and sus_second["moved"])
	_fx().window_shake_sustained_stop()
	_check("驻留抖动停止即复位", await _await_reset(1.0))
	_fx().window_shake_sustained_stop()
	var idempotent_still: Dictionary = await _sample_shake(0.2)
	_check("驻留停止幂等（未在跑时零副作用）", not idempotent_still["moved"])
	_fx().window_shake_sustained("light")
	await create_timer(0.1, true).timeout
	_fx().window_shake("heavy")
	var override_probe: Dictionary = await _sample_shake(0.8)
	_check("一次性抖动重启覆盖驻留（覆盖后驻留不复活）",
		override_probe["moved"] and await _await_reset(1.0))

	print("\n==================================================")
	print("  Total: %d | Passed: %d | Failed: %d" % [_total, _passed, _failed])
	if _errors.size() > 0:
		print("  --- Failed ---")
		for err in _errors:
			print("  %s" % err)
	print("==================================================")

## 改动脚本运行时可加载（编译期语法在项目上下文中校验）
func _test_scripts_loadable() -> bool:
	var scripts := [
		"res://scripts/autoload/effect_manager.gd",
		"res://scripts/skill_system.gd",
		"res://scripts/game_manager.gd",
		"res://scripts/buff/scorched_earth_buff.gd",
	]
	for path in scripts:
		var script: Variant = load(path)
		if script == null:
			_errors.append("脚本加载失败: %s" % path)
			return false
	return true

## 抖动观察窗：window 秒内采样 offset，返回是否发生位移 / 当前 offset / 最大绝对分量
func _sample_shake(window: float) -> Dictionary:
	var moved := false
	var max_abs := 0.0
	var elapsed := 0.0
	const STEP := 0.02
	while elapsed < window:
		await create_timer(STEP, true).timeout
		elapsed += STEP
		var off: Vector2 = _cam.offset
		if off != Vector2.ZERO:
			moved = true
		max_abs = maxf(max_abs, maxf(absf(off.x), absf(off.y)))
	return {"moved": moved, "offset": _cam.offset, "max_abs": max_abs}

## 等待复位：offset 回到 (0,0) 并保持数帧稳定（防"恰好路过 0"误判）
func _await_reset(deadline: float) -> bool:
	var waited := 0.0
	const STEP := 0.02
	while _cam.offset != Vector2.ZERO and waited < deadline:
		await create_timer(STEP, true).timeout
		waited += STEP
	if _cam.offset != Vector2.ZERO:
		return false
	for i in 3:
		await create_timer(STEP, true).timeout
		if _cam.offset != Vector2.ZERO:
			return false
	return true

func _check(name: String, ok: bool) -> void:
	_total += 1
	if ok:
		_passed += 1
		print("  PASS: %s" % name)
	else:
		_failed += 1
		_errors.append(name)
		print("  FAIL: %s" % name)
