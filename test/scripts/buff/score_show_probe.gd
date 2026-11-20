extends Node2D
## score-show probe（post-attack-score-balloon 演出三件套行为验证）
## 用法: godot --headless --path <项目> res://test/scripts/buff/score_show_probe.tscn
##
## 覆盖任务验证点：
##   2.1 token——来源图标与数字并排、贝塞尔弧线飞行（起点→终点轨迹断言）、
##              负向红色、到达回调触发
##   2.2 气球——种子出生/0·1·8·12 条 token 序列的滚动、位数分档与封顶、
##              定格后飞向计分板终点行为
##   2.3 编排器——12 条申报连发总时长 ≤2.5s 且含合并汇总 token
## 截图保存到 test/scripts/buff/out/score_show/（供目测定稿参考，任务 5.3 校准基线）

const OUT_DIR := "res://test/scripts/buff/out/score_show"
const ORCHESTRATOR_SCRIPT := preload("res://scripts/ui/score_balloon_orchestrator.gd")
const BALLOON_SCRIPT := preload("res://scripts/ui/score_balloon.gd")

## 演出断言不绑死数值：连发口径动态读 ORCHESTRATOR_SCRIPT 常量
##（用户可随意拧观感参数，断言语义自动跟随）
## 等待容差：headless 帧率抖动 + SceneTreeTimer 精度
const TOLERANCE := 0.35

var _results: Array = []
var _camera_anchor: Node2D

func _ready() -> void:
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await _run_all()
	print("\n========== score-show probe ==========")
	var failed := 0
	for r in _results:
		print("  %s" % r)
		if String(r).begins_with("FAIL:"):
			failed += 1
	print("  ------------------------------------------")
	print("  %d checks, %d failed" % [_results.size(), failed])
	print("=============================================\n")
	get_tree().quit(1 if failed > 0 else 0)

func _check(step: String, ok: bool, detail: String) -> void:
	var tag: String = "PASS:" if ok else "FAIL:"
	_results.append("%s %s — %s" % [tag, step, detail])

func _shot(file_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	## headless 无渲染管线：frame_post_draw 永不发出会永久挂起——跳过截图
	## （行为断言照常执行；截图供有显示环境时目测定稿，任务 5.3 校准材料）
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT_DIR + "/" + file_name))

## ---------- 舞台装配（对齐真实管线的最小 mock 面） ----------

## 迷你 game_manager：total_score 走脚本属性访问（对齐真实 game_manager.gd
## 的 @onready var total_score——Object.get() 只查脚本属性，不查子节点）
class MiniGameManager extends Node2D:
	var total_score: Label

func _stage() -> Node:
	## 迷你 game_manager：total_score label（计分板终点）+ Current.hero（气球头顶）
	var gm := MiniGameManager.new()
	gm.name = "game_manager"
	var board := Label.new()
	board.name = "total_score"
	board.text = "0"
	board.position = Vector2(280, 20)
	gm.add_child(board)
	gm.total_score = board
	get_tree().root.add_child(gm)
	Current.game_manager = gm
	## Hero 替身：真实 hero.gd 脚本满足 Current.hero 的类型约束；
	## 不入树（@onready/_ready 不触发），global_position 走自身 position
	var hero := Node2D.new()
	hero.set_script(load("res://scripts/hero.gd"))
	hero.position = Vector2(160, 200)
	Current.hero = hero
	return gm

func _clear_stage(gm: Node) -> void:
	Current.hero = null
	Current.game_manager = null
	gm.queue_free()

## ---------- token 直测（任务 2.1） ----------

func _run_all() -> void:
	var gm = _stage()
	await _scenario_token_flight(gm)
	await _scenario_token_negative(gm)
	await _scenario_balloon_sequence(gm)
	await _scenario_orchestrator_burst(gm)
	await _scenario_orchestrator_emergency(gm)
	await _scenario_board_target_scaled(gm)
	_clear_stage(gm)

func _scenario_token_flight(gm: Node) -> void:
	var token: Node2D = load("res://scenes/score_token.tscn").instantiate()
	gm.add_child(token)
	token.position = Vector2(60, 60)
	var icon: Texture2D = load("res://images/buff_icon/hunt_pursuit.png")
	token.setup(35, icon)
	var start := token.position
	var target := Vector2(160, 170)
	var arrived: Array = []
	token.token_arrived.connect(func(delta: int) -> void: arrived.append(delta))
	token.fly_to(target, 0.6)
	## 逐点采样：弧线轨迹在飞行中段应高于起终连线（同时间比例的直线插值）
	var min_lift := 0.0
	for i in range(1, 13):
		await get_tree().create_timer(0.05).timeout
		var line_y := lerpf(start.y, target.y, float(i) / 13.0)
		min_lift = maxf(min_lift, line_y - token.position.y)
	var end := token.position
	var label: Label = token.get_node("Label")
	var icon_rect: TextureRect = token.get_node("Icon")
	var arc_ok: bool = min_lift > 3.0
	var arrive_ok: bool = arrived.size() == 1 and arrived[0] == 35
	var near_ok: bool = end.distance_to(target) < 2.0
	## 视觉居中口径（同 score_balloon 落点口径）：缩放后整体 bbox
	## （icon∪label）中心 == token 原点——起飞时原点即视觉中心，token
	## 才是真正"从来源图标中心起飞"。防 rect 自原点向右下展开 + 缩放轴
	## 心在左上角的排版 bug 复发（视觉中心曾吊在原点右下 ~(17.5, 4.5)px）
	var lsc: Vector2 = Vector2(0.25, 0.25)
	var lcenter: Vector2 = label.position + label.size / 2.0
	var icenter: Vector2 = icon_rect.position + icon_rect.size / 2.0
	var lhalf: Vector2 = lsc * label.size / 2.0
	var ihalf: Vector2 = lsc * icon_rect.size / 2.0
	var bbox: Rect2 = Rect2(lcenter - lhalf, lhalf * 2.0).merge(Rect2(icenter - ihalf, ihalf * 2.0))
	var center_ok: bool = bbox.get_center().length() < 0.5
	var side_ok: bool = lcenter.x > icenter.x  ## 数字排在图标右侧（并排版型保持）
	var layout_ok: bool = icon_rect.visible and side_ok and label.text == "+35"
	_check("token 弧线飞行（顶点抬升）", arc_ok, "最大抬升=%.1fpx（弧高 24px，应>3px 高于连线）" % min_lift)
	_check("token 到达回调", arrive_ok, "arrived=%s" % str(arrived))
	_check("token 落点对准目标", near_ok, "dist=%.2f" % end.distance_to(target))
	_check("token 图标与数字并排", layout_ok, "icon=%s label=%s 中心 x: label=%.1f icon=%.1f" % [icon_rect.visible, label.text, lcenter.x, icenter.x])
	_check("token 视觉中心=原点（所见即起飞点）", center_ok, "视觉bbox中心=%s（应≈0,0；icon∪label 缩放后）" % bbox.get_center())
	await _shot("01_token_flight.png")
	token.queue_free()

func _scenario_token_negative(gm: Node) -> void:
	var token: Node2D = load("res://scenes/score_token.tscn").instantiate()
	gm.add_child(token)
	token.position = Vector2(60, 60)
	token.setup(-80, null)
	var label: Label = token.get_node("Label")
	var icon_rect: TextureRect = token.get_node("Icon")
	var color: Color = label.label_settings.font_color
	## 零偏移口径（视觉居中）：文字渲染中心 == token 原点
	## （pivot=size/2 → 中心 = position+size/2，缩放不动中心）
	var text_center: Vector2 = label.position + label.size / 2.0
	var ok: bool = label.text == "-80" and color.r > 0.9 and color.g < 0.5 and not icon_rect.visible and text_center.length() < 0.5
	_check("负向 token 红色纯数值（无图标零偏移）", ok, "text=%s color=%s icon=%s 文字中心=%s" % [label.text, color, icon_rect.visible, text_center])
	await _shot("02_token_negative.png")
	token.queue_free()

## ---------- 气球序列（任务 2.2） ----------

func _make_balloon(gm: Node) -> Node2D:
	var balloon: Node2D = load("res://scenes/score_balloon.tscn").instantiate()
	gm.add_child(balloon)
	return balloon

func _balloon_label(balloon: Node2D) -> Label:
	return balloon.get_node("Label")

func _scenario_balloon_sequence(gm: Node) -> void:
	## 种子出生（0 贡献基线）
	var balloon := _make_balloon(gm)
	balloon.setup(120, Vector2(160, 166))
	var label := _balloon_label(balloon)
	var ok_seed: bool = label.text == "+120" and label.label_settings.font_size == 24
	_check("气球种子 +120（3 位 24 档）", ok_seed, "text=%s size=%d" % [label.text, label.label_settings.font_size])
	## 数字滚动与吸收脉冲
	balloon.absorb(50)
	await get_tree().create_timer(0.3).timeout
	var ok_roll: bool = balloon.total == 170 and label.text == "+170"
	_check("吸收 +50 滚动到 +170", ok_roll, "total=%d text=%s" % [balloon.total, label.text])
	await get_tree().create_timer(0.2).timeout
	## 负向吸收回滚
	balloon.absorb(-80)
	await get_tree().create_timer(0.3).timeout
	var ok_neg: bool = balloon.total == 90 and label.text == "+90"
	_check("吸收 -80 滚动回 +90（负向同样滚动）", ok_neg, "total=%d text=%s" % [balloon.total, label.text])
	await _shot("03_balloon_roll.png")
	## 位数分档：3→4 位升档、6 位封顶（5.3 定稿：24/28/32/36 封顶）
	balloon.absorb(930)   # 90 + 930 = 1020 → 4 位
	await get_tree().create_timer(0.3).timeout
	var size_4 := label.label_settings.font_size
	balloon.absorb(98980)  # 1020 + 98980 = 100000 → 6 位封顶
	await get_tree().create_timer(0.3).timeout
	var size_6 := label.label_settings.font_size
	balloon.absorb(900000)  # 7 位 → 保持封顶
	await get_tree().create_timer(0.3).timeout
	var size_7 := label.label_settings.font_size
	var ok_tiers: bool = size_4 == 28 and size_6 == 36 and size_7 == 36
	_check("位数分档（999→1000 升档、6 位封顶不再增大）", ok_tiers, "4位=%d 6位=%d 7位=%d" % [size_4, size_6, size_7])
	await _shot("04_balloon_tiers.png")
	## 定格 + 终点为计分板
	var board: Label = gm.get_node("total_score")
	var target := board.get_global_rect().get_center()
	var arrived: Array = []
	balloon.balloon_arrived.connect(func(total: int) -> void: arrived.append(total))
	balloon.position = Vector2(160, 166)
	balloon.freeze_and_fly_to(target)
	## 定格窗内位置应保持（测量窗随 FREEZE_DURATION 动态，留 40% 余量）
	var hold_probe: float = minf(0.3, BALLOON_SCRIPT.FREEZE_DURATION * 0.6)
	await get_tree().create_timer(hold_probe).timeout
	_check("定格悬停不移动", balloon.position == Vector2(160, 166),
		"pos=%s（定格窗 %.2fs 内应保持出生位）" % [balloon.position, hold_probe])
	## 等定格+飞行完成（随 FREEZE/FLY 常量动态，留 0.3s 观察余量）
	await get_tree().create_timer(
		BALLOON_SCRIPT.FREEZE_DURATION + BALLOON_SCRIPT.FLY_TO_BOARD_DURATION + 0.3
	).timeout
	var ok_fly: bool = arrived.size() == 1 and arrived[0] == balloon.total \
		and balloon.position.distance_to(target) < 2.0
	_check("划弧线飞至计分板并消失信号", ok_fly, "arrived=%s dist=%.2f" % [str(arrived), balloon.position.distance_to(target)])
	## 观感落点口径：玩家看到的是【文字】而非节点原点——断言到达时
	## 文字渲染中心（label global_rect 中心）== 目标。防 _label_pivot 类
	## 缩放轴心 bug 复发（曾致文字中心吊在节点左上 (−40,−6)，
	## 落点目测偏离数字一整列）
	var fly_label: Control = balloon.get_node("Label")
	var text_center: Vector2 = fly_label.get_global_rect().get_center()
	var ok_text_lands: bool = text_center.distance_to(target) < 1.0
	_check("到达时文字渲染中心=目标（玩家所见即所落）", ok_text_lands,
		"文字中心=%s 目标=%s 偏差=%.2fpx rect=%s pivot=%s scale=%s" % [text_center, target, text_center.distance_to(target), fly_label.size, fly_label.pivot_offset, fly_label.scale])
	await _shot("05_balloon_fly_board.png")
	balloon.queue_free()

## ---------- 编排器连发（任务 2.3） ----------

func _scenario_orchestrator_burst(gm: Node) -> void:
	var orchestrator: Node2D = ORCHESTRATOR_SCRIPT.new()
	gm.add_child(orchestrator)
	orchestrator.setup_balloon(120)
	## 12 条申报 → 单发数与汇总按 orchestrator 常量动态推导（用户可随意
	## 拧三参数观感校准，断言语义自动跟随，不绑死数值）
	var declarations: Array = []
	for i in range(12):
		declarations.append({
			"buff": null,
			"delta": 10,
			"icon_path": "res://images/buff_icon/hunt_pursuit.png",
		})
	var max_tokens: int = ORCHESTRATOR_SCRIPT.MAX_INDIVIDUAL_TOKENS
	var interval: float = ORCHESTRATOR_SCRIPT.TOKEN_INTERVAL
	var fly_dur: float = ORCHESTRATOR_SCRIPT.TOKEN_FLY_DURATION
	var single_count: int = mini(12, max_tokens)
	## 连发段时长：末枚到达时刻（有汇总 = 汇总起飞 N×间隔+飞行；
	## 全单发 = 末枚起飞 (N-1)×间隔+飞行）
	var burst_span: float = single_count * interval + fly_dur if single_count < 12 \
		else (single_count - 1) * interval + fly_dur
	var token_count: int = single_count + (1 if single_count < 12 else 0)
	var t0 := Time.get_ticks_msec()
	await orchestrator.perform(declarations)
	var elapsed := (Time.get_ticks_msec() - t0) / 1000.0
	## headless/低帧率帧延迟补偿：perform 的每个 await 至多滞后 1 帧，
	## 窗口容差 = token 总数 × 实际帧距（60fps 下 ≈0.1s，语义口径不变；
	## headless 低帧率或本机编辑器/游戏并行抢 CPU 时消除帧延迟误报）
	var frame_span_msec := 0
	for i in range(3):
		var f0 := Time.get_ticks_msec()
		await get_tree().process_frame
		frame_span_msec = maxi(frame_span_msec, Time.get_ticks_msec() - f0)
	var frame_tolerance := float(token_count) * float(frame_span_msec) / 1000.0
	## 全程口径：连发段 burst_span + 轮询 0.05 + 定格 + 飞板（皆随常量动态）
	var ok_burst: bool = elapsed <= burst_span + 0.05 \
		+ BALLOON_SCRIPT.FREEZE_DURATION + BALLOON_SCRIPT.FLY_TO_BOARD_DURATION \
		+ TOLERANCE + frame_tolerance
	var ok_window: bool = elapsed - 1.0 <= ORCHESTRATOR_SCRIPT.BURST_WINDOW + frame_tolerance
	_check("12 条申报演出定长（连发≤窗口上限）", ok_burst and ok_window,
		"全程=%.2fs 连发≈%.2fs ≤窗口%.1fs（上限%d 枚实发%d 枚/间隔%.1fs）" % [elapsed, elapsed - 1.0, ORCHESTRATOR_SCRIPT.BURST_WINDOW, max_tokens, token_count, interval])
	await _shot("06_orchestrator_burst.png")
	orchestrator.queue_free()

## ---------- 演出异常兜底（任务 4.3） ----------

func _scenario_orchestrator_emergency(gm: Node) -> void:
	## 演出总时限裁剪机制：deadline 过期后一切等待段立即返回 false →
	## perform 必然返回（调用方 skill_attack 无条件解除静默 + 显示同步 + 释放锁，
	## 计分板与回合流程自愈，无卡死）。此处直测裁剪入口，避免真实等待 15s。
	var orchestrator: Node2D = ORCHESTRATOR_SCRIPT.new()
	gm.add_child(orchestrator)
	orchestrator.setup_balloon(30)
	## 正常等待段：设置未过期 deadline（perform 外直测裁剪入口）→ 返回 true
	orchestrator.set("_deadline_msec", Time.get_ticks_msec() + 5000)
	var normal_ok: bool = await orchestrator._wait(0.05)
	## 过期 deadline（模拟演出异常中断：token 挂死/节点失效等导致超时）
	orchestrator.set("_deadline_msec", Time.get_ticks_msec() - 1)
	var t0 := Time.get_ticks_msec()
	var clipped: bool = await orchestrator._wait(0.05)
	var clipped_ok: bool = not clipped and Time.get_ticks_msec() - t0 < 100
	_check("演出时限裁剪：异常中断时等待段立即返回（自愈无卡死）", normal_ok and clipped_ok,
		"正常段=%s 裁剪段=%s 耗时=%dms" % [normal_ok, clipped, Time.get_ticks_msec() - t0])
	orchestrator.queue_free()

## ---------- 计分板落点（scale 单位错配回归，5.3 目测反馈） ----------

## stage_score 面板下有 0.5/0.5/0.45 三层嵌套 scale（有效≈0.11），且
## total_score label 的格子远宽于文字（EXPAND）——曾因字体度量（本地单位）
## 直接加全局 rect 坐标，落点随位数漂移且系统性偏离文字。此处复刻该结构，
## 断言落点 = 文字渲染中心（经全局换算）而非格子中心
func _scenario_board_target_scaled(gm: Node) -> void:
	var outer := Control.new()
	outer.position = Vector2(100, 60)
	outer.scale = Vector2(0.5, 0.5)
	var mid := Control.new()
	mid.scale = Vector2(0.5, 0.5)
	outer.add_child(mid)
	var grid := Control.new()
	grid.scale = Vector2(0.45, 0.45)
	grid.position = Vector2(40, 30)
	mid.add_child(grid)
	var board := Label.new()
	board.text = "123456"
	var ls := LabelSettings.new()
	ls.font = load("res://fonts/MinimalPixel v2.ttf")
	ls.font_size = 20
	board.label_settings = ls
	## 宽格子窄文字：复刻 GridContainer cell 形态（rect ≫ 文字）
	board.size = Vector2(300, 40)
	grid.add_child(board)
	gm.add_child(outer)
	## 落点按"入账后的新总分"测宽（与实现同口径）：设逻辑值=板显文字
	var saved_total: int = Current._total_score
	Current._total_score = 123456
	await get_tree().process_frame
	var orchestrator: Node2D = ORCHESTRATOR_SCRIPT.new()
	gm.add_child(orchestrator)
	## 临时把计分板属性指向嵌套缩放容器内的 board（调用后恢复）
	var old_board: Label = gm.total_score
	gm.total_score = board
	var result: Vector2 = orchestrator._score_board_position()
	gm.total_score = old_board
	Current._total_score = saved_total
	var rect: Rect2 = board.get_global_rect()
	var gscale: Vector2 = board.get_global_transform().get_scale()
	## 独立重算文字渲染中心（世界系）：rect 原点 + 全局缩放 ×（对齐起点 + 半文字）。
	## 与实现的矩阵投影路径互为交叉验证；测宽文字取逻辑新值（同实现口径）
	var text_size: Vector2 = ls.font.get_string_size(str(123456), HORIZONTAL_ALIGNMENT_LEFT, -1.0, ls.font_size)
	var origin := Vector2(0.0, 0.0)
	match board.vertical_alignment:
		VERTICAL_ALIGNMENT_CENTER:
			origin.y = (board.size.y - text_size.y) / 2.0
		VERTICAL_ALIGNMENT_BOTTOM:
			origin.y = board.size.y - text_size.y
	var expected: Vector2 = rect.position + gscale * (origin + text_size / 2.0)
	var on_text: bool = result.distance_to(expected) < 0.5
	## 回归保护：宽格子下文字中心必须显著偏离格子中心（旧 bug 落在格子中心右侧）
	var off_cell_center: bool = result.distance_to(rect.get_center()) > 2.0
	_check("scale 嵌套下落点=新总分文字中心", on_text and off_cell_center,
		"落点=%s 文字中心=%s 格子中心=%s 偏离格子中心=%.1fpx" % [result, expected, rect.get_center(), result.distance_to(rect.get_center())])
	orchestrator.queue_free()
	outer.queue_free()
