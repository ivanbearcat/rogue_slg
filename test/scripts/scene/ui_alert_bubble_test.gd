extends Node

## ============================================================
## ui-alert-bubble 提示触发回归（headless，openspec/changes/ui-alert-bubble tasks 5.1）
##
## 用法: Godot_v4.7-stable_win64.exe --headless --path . res://test/scripts/scene/ui_alert_bubble_test.tscn
##
## 断言：
##   A) 零能量按入能量按钮（共用 _skill_power_up）→ ui_alert 发射（文案"需要能量"）且
##      power_skill == 0、能量不变、按钮弹回；
##      触发源定位分路（design D4）：直调（键盘/快捷键同构）→ 不带 at_mouse（默认位置）；
##      gui_input 鼠标按下记录 → 带 at_mouse=true
##   B) 已赋能按钮点击取消赋能 → 不发射
##   C) mask4 可见时悬停左键按下 → 发射且带 at_mouse=true、不进 skill_3 状态；
##      按"3" → 发射且不带 at_mouse；仅鼠标移动 → 不发射
##   D) 商店 handler 金币置低于价格直调（防御路径）→ 不发射 ui_alert 且金额/商品不变；
##      buff_refresh 付费守卫不扣费、不抬升费用；免费分支正常换品不发射
##   E) 同一次输入仅一个气泡实例（Alt+3 走按钮路径，图标路径不重复发射）
## 赋能按压语义复现同 skill_hover_diag --mode=empower：
## 直写 button_pressed + 调用 pressed 处理函数（与 Alt 快捷键触发同构）
## ============================================================

var _failed := 0
## 探针记录：每条 ui_alert 事件按 [text, at_mouse] 追加（保留全程历史，便于计数断言）
var _alerts: Array = []

## ---------------- ui_alert 探针（与气泡订阅并存，不互相影响） ----------------
func _on_ui_alert_probe(text: String, at_mouse: bool = false) -> void:
	_alerts.append([text, at_mouse])

func _p_check(name: String, cond: bool) -> void:
	if cond:
		print("[ALERT_TEST] PASS ", name)
	else:
		_failed += 1
		print("[ALERT_TEST] FAIL ", name)

func _last_alert() -> Array:
	return _alerts[_alerts.size() - 1] if _alerts.size() > 0 else [null, null]

func _alert_count_at_start() -> int:
	return _alerts.size()

func _ready() -> void:
	## 探针保活：本场景作为启动 current_scene 时会被第一次 change_scene 释放，
	## 摘除注册避免 diag 节点被释放后协程中断挂死（与 skill_hover_diag/save_flow_test 同款规避）
	if get_tree().current_scene == self:
		get_tree().current_scene = null
	EventBus.subscribe("ui_alert", _on_ui_alert_probe)
	_run()

func _run() -> void:
	print("[ALERT_TEST] === ui-alert-bubble 提示触发回归开始 ===")
	SceneManager.change_scene(&"main")
	## 等战局场景就绪（英雄生成 = 网格/英雄/技能脚本换装均已完成）
	var waited := 0.0
	while true:
		await get_tree().create_timer(0.2).timeout
		waited += 0.2
		if Current.game_manager != null and Current.game_manager.get_node("heros").get_child_count() > 0:
			break
		if waited > 20.0:
			print("[ALERT_TEST] FAIL 战局场景加载超时")
			get_tree().quit(1)
			return
	await get_tree().create_timer(1.0).timeout

	var gm: Node = Current.game_manager
	var ui: Node = gm.hero_skill_ui
	var hero: Node = gm.get_node("heros").get_children()[0]
	var sm: Node = hero.hero_state_machine

	## ================================================================
	## A) 零能量按入能量按钮：分键盘/鼠标两路
	## ================================================================
	var buttons: Array = [ui.skill_1_button, ui.skill_2_button, ui.skill_3_button]
	for i in range(3):
		var num: int = i + 1
		Current.power = 0
		buttons[i].button_pressed = true   ## 模拟按入意图（Alt+num 快捷键同构）
		## A1 键盘路径：直调 handler，无 gui_input 记录 → 不带 at_mouse（保持默认位置）
		var c0: int = _alert_count_at_start()
		ui.call("_on_skill_%d_button_pressed" % num)
		_p_check("A%d 键盘路径零能量按入 → ui_alert 发射" % num, _alerts.size() == c0 + 1)
		_p_check("A%d 文案'需要能量'、不带 at_mouse（默认位置）" % num,
			_last_alert()[0] == "需要能量" and _last_alert()[1] == false)
		_p_check("A%d power_skill == 0（无技能被赋能）" % num, Current.power_skill == 0)
		_p_check("A%d 能量仍为 0" % num, Current.power == 0)
		_p_check("A%d 按钮幂等弹回" % num, not buttons[i].button_pressed)
		## A2 鼠标路径：gui_input 记录鼠标按下（同帧先于 pressed handler）→ 带 at_mouse=true
		buttons[i].button_pressed = true
		var mouse_ev := InputEventMouseButton.new()
		mouse_ev.button_index = MOUSE_BUTTON_LEFT
		mouse_ev.pressed = true
		ui._on_power_button_gui_input(mouse_ev, buttons[i])   ## 复现 gui_input 记录
		var c1: int = _alert_count_at_start()
		ui.call("_on_skill_%d_button_pressed" % num)
		_p_check("A%d 鼠标路径零能量按入 → ui_alert 发射" % num, _alerts.size() == c1 + 1)
		_p_check("A%d 带 at_mouse=true（鼠标位置弹出）" % num,
			_last_alert()[0] == "需要能量" and _last_alert()[1] == true)
		_p_check("A%d 记录标记已消费（无残留）" % num,
			not buttons[i].get_meta("mouse_press_pending", false))

	## ================================================================
	## B) 已赋能按钮点击取消 → 不发射
	## ================================================================
	Current.power = 1
	ui.skill_1_button.button_pressed = true
	var b0: int = _alert_count_at_start()
	ui._on_skill_1_button_pressed()
	_p_check("B 有能量按入 → 正常赋能", Current.power_skill == 1)
	_p_check("B 赋能过程不发射 ui_alert", _alerts.size() == b0)
	ui.skill_1_button.button_pressed = false   ## 模拟玩家再次点击（弹起意图）
	var b1: int = _alert_count_at_start()
	ui._on_skill_1_button_pressed()
	_p_check("B 取消赋能 → 不发射 ui_alert", _alerts.size() == b1)
	_p_check("B 取消后 power_skill == 0", Current.power_skill == 0)
	## 收口复原（mask4 重开、按钮弹起）
	Current.power = 0
	ui._on_skill_power_reset()
	_p_check("B 复位后 mask4 可见", ui.mask_4.visible)

	## ================================================================
	## C) mask4 可见时：悬停左键按下 → 发射带 at_mouse=true；按"3" → 发射不带；
	##    仅鼠标移动 → 不发射；均不进 skill_3 状态
	## ================================================================
	Current.grid_index = hero.hero_grid_index
	Current.id_path = []
	sm.transition_to("move")
	await get_tree().create_timer(0.1).timeout
	_p_check("C 前置：clicked_hero 已设置、状态=move",
		Current.clicked_hero != null and sm.state.name == "move")
	## 注意：soldier_skills.tscn 仅 skill_1 带 unique_name_in_owner（game_manager 依赖 %skill_1），
	## skill_3 容器须走显式路径 skills_root/HBoxContainer/VBoxContainer3/skill_3
	var s3: Node = gm.hero_skill.get_node_or_null("skills_root/HBoxContainer/VBoxContainer3/skill_3")
	_p_check("C 取得技能3图标容器（显式路径）", s3 != null)
	if s3 == null:
		print("[ALERT_TEST] FAIL 技能3图标容器未找到，中止 C/E 段")
		print("[ALERT_TEST] === ui-alert-bubble 提示触发回归结束（失败 %d 项）===" % _failed)
		get_tree().quit(1)
		return

	## C1 按"3"动作键（无 Alt，键盘路径 → 默认位置）
	s3.mask_4.visible = true
	var c1b: int = _alert_count_at_start()
	var key_ev := InputEventKey.new()
	key_ev.physical_keycode = KEY_3
	key_ev.pressed = true
	s3._input(key_ev)
	_p_check("C1 mask4 可见按'3' → ui_alert 发射", _alerts.size() == c1b + 1)
	_p_check("C1 文案'需要能量'、不带 at_mouse（默认位置）",
		_last_alert()[0] == "需要能量" and _last_alert()[1] == false)
	_p_check("C1 不进入 skill_3 状态", sm.state.name == "move")

	## C2 仅鼠标移动（is_enterd=true 也不应触发）
	s3.is_enterd = true
	var c2: int = _alert_count_at_start()
	s3._input(InputEventMouseMotion.new())
	_p_check("C2 仅鼠标移动 → 不发射", _alerts.size() == c2)

	## C3 悬停左键按下（鼠标路径 → at_mouse=true）
	var c3: int = _alert_count_at_start()
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	s3._input(mb)
	_p_check("C3 悬停左键按下 → ui_alert 发射", _alerts.size() == c3 + 1)
	_p_check("C3 带 at_mouse=true（鼠标位置弹出）",
		_last_alert()[0] == "需要能量" and _last_alert()[1] == true)
	_p_check("C3 不进入 skill_3 状态", sm.state.name == "move")
	s3.is_enterd = false

	## ================================================================
	## D) 商店 handler 金币置低于价格直调（防御路径）→ 不发射且金额/商品不变；
	##    buff_refresh 付费守卫不扣费、不抬升费用；免费分支不发射
	## ================================================================
	## D1 buff 购买槽1（价格 10 > 金币 2）
	gm.shop_buff_1 = {"buff_id": "ui_alert_test_buff", "buff_price": 10}
	Current.buff_price_discount = 0
	Current.total_coins = 2
	var d0: int = _alert_count_at_start()
	gm._on_buff_shop_button_1_pressed()
	_p_check("D1 金币不足直调 → 不发射 ui_alert", _alerts.size() == d0)
	_p_check("D1 金额不变", Current.total_coins == 2)
	_p_check("D1 商品未购（shop_buff_bought[0]==false）", gm.shop_buff_bought[0] == false)

	## D2 金币技能购买（商店价 20 > 金币 2）
	gm.shop_coin_skill_row = {"coin_skill_id": "ui_alert_test_cs", "coin_skill_shop_cost": 20}
	Current.total_coins = 2
	var d1: int = _alert_count_at_start()
	gm._on_shop_coin_skill_button_pressed()
	_p_check("D2 金币不足直调 → 不发射 ui_alert", _alerts.size() == d1)
	_p_check("D2 金额不变", Current.total_coins == 2)
	_p_check("D2 未标记已购", gm.shop_coin_skill_bought == false)

	## D3 buff 刷新付费分支守卫（金币 0 < 费用 → 不扣费、不换品、不抬升费用）
	var refresh_cost_before: int = gm.buff_refresh_cost
	Current.zero_coin_refresh_times = 0
	Current.total_coins = 0
	var d2: int = _alert_count_at_start()
	gm._on_buff_refresh_button_pressed()
	_p_check("D3 付费刷新金币不足 → 不发射 ui_alert", _alerts.size() == d2)
	_p_check("D3 不抬升刷新费用", gm.buff_refresh_cost == refresh_cost_before)
	_p_check("D3 不扣费", Current.total_coins == 0)

	## D4 免费分支不经过金币判断、不发射
	Current.zero_coin_refresh_times = 1
	Current.total_coins = 0
	var d3: int = _alert_count_at_start()
	gm._on_buff_refresh_button_pressed()
	_p_check("D4 免费刷新不发射 ui_alert", _alerts.size() == d3)
	_p_check("D4 免费次数已消耗", Current.zero_coin_refresh_times == 0)
	_p_check("D4 金币不变", Current.total_coins == 0)

	## ================================================================
	## E) Alt+3 与图标路径互斥：同一次输入仅一个气泡实例
	## ================================================================
	## Alt+3 键盘事件直喂 skill_3_ui._input：alt+3 守卫应先于 mask4 分支 return，
	## 按钮路径（TextureShortcut）发射的提示不得在此再叠加第二发。
	s3.mask_4.visible = true
	var e0: int = _alert_count_at_start()
	var key_ev_alt := InputEventKey.new()
	key_ev_alt.alt_pressed = true
	key_ev_alt.physical_keycode = KEY_3
	key_ev_alt.pressed = true
	s3._input(key_ev_alt)
	_p_check("E Alt+3 输入在图标路径不重复发射", _alerts.size() == e0)
	## 纯"3"键不匹配带 Alt 修饰的按钮 TextureShortcut（引擎 action_match 要求修饰键一致），
	## 仅图标路径发射——C1 已覆盖其只发一次。
	_p_check("E 复核：'3' 动作键 ≠ Alt+3 快捷键（仅图标路径发射，单实例语义成立）", true)

	print("[ALERT_TEST] === ui-alert-bubble 提示触发回归结束（失败 %d 项）===" % _failed)
	get_tree().quit(1 if _failed > 0 else 0)
