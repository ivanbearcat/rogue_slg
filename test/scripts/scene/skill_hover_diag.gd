extends Node

## 一次性诊断脚本：复现"技能按下后悬停无红框、点击无效"链路（只读取证，不修改游戏逻辑）
## 用法: Godot_v4.7-stable_win64.exe --headless --path . res://test/scripts/scene/skill_hover_diag.tscn -- --skill=1
## 参数 --skill=1/2/3 指定诊断的技能编号，默认 1
## 另有 --mode=empower：赋能切换同步回归（fix-skill-access-and-empower-sync tasks 1.4）

var _skill_num := "1"
var _mode := "hover"

func _ready() -> void:
	## 探针保活：本场景作为启动 current_scene 时会被第一次 change_scene 释放，
	## 摘除注册避免 diag 节点被释放后协程中断挂死（与 save_flow_test 同款规避）
	if get_tree().current_scene == self:
		get_tree().current_scene = null
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--skill="):
			_skill_num = arg.trim_prefix("--skill=")
		if arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
	if _mode == "empower":
		_run_empower_test()
	else:
		_run()

func _run() -> void:
	print("[DIAG] === 技能", _skill_num, " 悬停/点击链路诊断开始 ===")
	SceneManager.change_scene(&"main")
	## 等战局场景就绪（英雄生成 = 网格/英雄/技能脚本换装均已完成）
	var waited := 0.0
	while true:
		await get_tree().create_timer(0.2).timeout
		waited += 0.2
		if Current.game_manager != null and Current.game_manager.get_node("heros").get_child_count() > 0:
			break
		if waited > 20.0:
			print("[DIAG] FAIL 战局场景加载超时")
			get_tree().quit(1)
			return
	await get_tree().create_timer(2.0).timeout

	## 等待启动回合处理彻底结束（Current.turn 回到 hero_turn 且状态稳定）
	var turn_waited := 0.0
	while Current.turn != "hero_turn":
		await get_tree().create_timer(0.2).timeout
		turn_waited += 0.2
		if turn_waited > 30.0:
			print("[DIAG] FAIL 等待 hero_turn 超时 (当前 turn=", Current.turn, ")")
			get_tree().quit(1)
			return
	await get_tree().create_timer(0.5).timeout
	print("[DIAG] 回合处理已结束, turn=", Current.turn, ", 等待了 ", turn_waited, " 秒")

	var gm: Node = Current.game_manager
	var hero: Node = gm.get_node("heros").get_children()[0]
	var sm: Node = hero.hero_state_machine
	print("[DIAG] 英雄=", hero.hero_name, " 初始状态=", sm.state.name,
		" 英雄格子=", hero.hero_grid_index)
	print("[DIAG] 动画存在性: soldier_end=", hero.animated_sprite_2d.sprite_frames.has_animation(hero.hero_name + "_end"),
		" soldier_skill_", _skill_num, "=", hero.animated_sprite_2d.sprite_frames.has_animation(hero.hero_name + "_skill_" + _skill_num))
	print("[DIAG] 技能节点脚本: skill_1=", hero.skill_1.get_script().resource_path.get_file(),
		" skill_2=", hero.skill_2.get_script().resource_path.get_file(),
		" skill_3=", hero.skill_3.get_script().resource_path.get_file())
	## 检查 hero._ready 建立的信号连接是否在 set_script 换装后存活
	for skill_node_name in ["skill_1", "skill_2", "skill_3"]:
		var sn: Node = hero.get_node("hero_state_machine/" + skill_node_name)
		var conns: Array = sn.get_signal_connection_list("show_skill_range")
		print("[DIAG] 信号连接存活: ", skill_node_name, ".show_skill_range → ", conns.size(), " 个连接",
			" (目标: ", conns[0]["callable"] if conns.size() > 0 else "无", ")")

	## --- 步骤1: 模拟点击英雄（idle.exit 设置 clicked_hero, 进入 move）---
	Current.grid_index = hero.hero_grid_index
	sm.transition_to("move")
	print("[DIAG] 步骤1 点击英雄: 状态=", sm.state.name,
		" clicked_hero=", "已设置" if Current.clicked_hero != null else "null")

	## --- 步骤2: 模拟按下技能（与 skill_N_ui._input 相同调用序列）---
	EventBus.event_emit("reset_cursor")
	sm.transition_to("skill_" + _skill_num)
	await get_tree().create_timer(0.1).timeout
	var blue_count := 0
	for g in Current.all_grids_array:
		if g.target.visible:
			blue_count += 1
	print("[DIAG] 步骤2 按下技能", _skill_num, ": 状态=", sm.state.name,
		" skill_num='", Current.skill_num, "'",
		" mouse_status='", Current.mouse_status, "'",
		" attack_anim_fin=", Current.attack_animation_finished,
		" 公共锁=", Current.public_lock_array)
	print("[DIAG] 步骤2 蓝框(target)数量=", blue_count,
		" skill_target_range=", Current.skill_target_range)
	if Current.skill_target_range.is_empty():
		print("[DIAG] >>> 关键发现: skill_target_range 为空 → 蓝框没显示, 悬停和点击必然全失效")
		_quit()
		return

	## --- 步骤3: 模拟悬停目标格（经 HoverTracker 驱动,/grid.gd 已迁移 hover_tracker.gd,
	## 旧方法 _on_area_2d_mouse_entered 已不存在——该调用会运行时报错中断协程导致卡死）---
	var hover_index: Vector2 = Current.skill_target_range[0]
	var hover_grid: Node = gm.all_grid_dict[hover_index]
	var tracker: Node = null
	for child in gm.get_children():
		if child.get_script() != null \
				and str(child.get_script().resource_path).ends_with("hover_tracker.gd"):
			tracker = child
			break
	print("[DIAG] 步骤3 悬停目标格 ", hover_index,
		" 该格target.visible=", hover_grid.target.visible,
		" HoverTracker=", "已挂载" if tracker != null else "未找到!!")
	_p_check("步骤3 HoverTracker 已挂载", tracker != null)
	if tracker != null and Current.hero != null:
		## headless 下 tracker._process 每帧解析 get_global_mouse_position()=(0,0) 在棋盘外，
		## 会立刻触发退出语义清掉红框——暂停帧处理，改为例证驱动（纯语义调用）
		tracker.set_process(false)
		tracker._hovered_index = null
		tracker._apply_transition(null, Vector2i(hover_index))
		await get_tree().process_frame
		var red_count := 0
		for g in Current.all_grids_array:
			if g.attack.visible:
				red_count += 1
		print("[DIAG] 步骤3 悬停后: 红框(attack)数量=", red_count,
			" skill_attack_range=", Current.skill_attack_range,
			" has_attack_grid=", Current.has_attack_grid,
			" Current.grid_index=", Current.grid_index)
		if red_count == 0:
			print("[DIAG] >>> 关键发现: 悬停目标格后红框数量为 0 → 红框显示链路断裂")

	## --- 步骤3b: 对照实验, 悬停一个"非目标格"（模拟用户把鼠标移到敌人位置）---
	var far_index: Vector2 = hero.hero_grid_index + Vector2(3, 0)
	if tracker != null and gm.all_grid_dict.has(far_index):
		var far_grid: Node = gm.all_grid_dict[far_index]
		tracker._apply_transition(Vector2i(hover_index), Vector2i(far_index))
		await get_tree().process_frame
		var red_count2 := 0
		for g in Current.all_grids_array:
			if g.attack.visible:
				red_count2 += 1
		print("[DIAG] 步骤3b 悬停非目标格 ", far_index, " 后: 红框数量=", red_count2,
			" (该格target.visible=", far_grid.target.visible, ")")

	## --- 步骤4: 模拟左键点击（走完整 hero_state_machine._input 闸门）---
	## 先把鼠标放回目标格
	Current.grid_index = hover_index
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	sm._input(ev)
	await get_tree().create_timer(0.3).timeout
	var attacked: bool = "skill_attack" in Current.public_lock_array or Current.attack_animation_finished == 0
	print("[DIAG] 步骤4 点击后: 公共锁=", Current.public_lock_array,
		" attack_anim_fin=", Current.attack_animation_finished,
		" 状态=", sm.state.name)
	if attacked:
		print("[DIAG] PASS 点击生效: 技能攻击已触发")
	else:
		print("[DIAG] >>> 关键发现: 点击未触发技能攻击")
	_quit()

## ============================================================
## 赋能 UI 单点同步回归（fix-skill-access-and-empower-sync，design D2/D4）
## 用法: --mode=empower
## 赋能切换的引擎语义（ButtonGroup 静默 unpress + pressed 信号）以
## "直写 button_pressed + 调用 pressed 处理函数"复现，与 Alt 快捷键触发同构；
## 能量直写（Current.power）走 setter 正常链路。
## 断言（tasks 1.4）：
##   1）技能 3 赋能后 mask4 隐藏（嘲讽解锁）
##   2）随后技能 1 赋能 → mask4 重新可见且 skill_3_button 未按下
##   3）无能量按压任何赋能按钮后各图标状态不变（弹回）
## ============================================================
var _p_failed := 0

func _p_check(name: String, cond: bool) -> void:
	if cond:
		print("[DIAG] PASS ", name)
	else:
		_p_failed += 1
		print("[DIAG] FAIL ", name)

func _run_empower_test() -> void:
	print("[DIAG] === 赋能切换同步回归（mode=empower）开始 ===")
	SceneManager.change_scene(&"main")
	var waited := 0.0
	while true:
		await get_tree().create_timer(0.2).timeout
		waited += 0.2
		if Current.game_manager != null and Current.game_manager.get_node("heros").get_child_count() > 0:
			break
		if waited > 20.0:
			print("[DIAG] FAIL 战局场景加载超时")
			get_tree().quit(1)
			return
	await get_tree().create_timer(0.5).timeout
	var ui: Node = Current.game_manager.hero_skill_ui
	if ui == null:
		print("[DIAG] FAIL 未取得技能 UI（hero_skill_ui）")
		get_tree().quit(1)
		return
	## ---- 基线：默认全灭/锁定/弹起 ----
	_p_check("基线 mask4 可见（锁定）", ui.mask_4.visible)
	_p_check("基线 hero_ui_1 熄灭", ui.hero_ui_1.material.get_shader_parameter("enable") != true)
	_p_check("基线 三按钮均为弹起态", not ui.skill_1_button.button_pressed \
		and not ui.skill_2_button.button_pressed and not ui.skill_3_button.button_pressed)
	## ---- 断言1：技能 3 赋能 → mask4 隐藏 ----
	Current.power = 1
	_p_check("直写能量后 Current.power == 1", Current.power == 1)
	ui.skill_3_button.button_pressed = true
	ui._on_skill_3_button_pressed()
	_p_check("1）Alt+3 后 mask4 隐藏（嘲讽解锁）", not ui.mask_4.visible)
	_p_check("1）power_skill 同步为 3", Current.power_skill == 3)
	_p_check("1）skill_3_button 按下态", ui.skill_3_button.button_pressed)
	_p_check("1）skill_1/2_button 弹起态", not ui.skill_1_button.button_pressed \
		and not ui.skill_2_button.button_pressed)
	_p_check("1）hero_ui_1/2 熄灭", ui.hero_ui_1.material.get_shader_parameter("enable") != true \
		and ui.hero_ui_2.material.get_shader_parameter("enable") != true)
	## ---- 断言2：切换到技能 1 赋能 → mask4 重开 + 嘲讽按钮弹起 ----
	ui.skill_1_button.button_pressed = true
	ui._on_skill_1_button_pressed()
	_p_check("2）切技能1后 mask4 重新可见", ui.mask_4.visible)
	_p_check("2）skill_3_button 未按下", not ui.skill_3_button.button_pressed)
	_p_check("2）power_skill 同步为 1", Current.power_skill == 1)
	_p_check("2）hero_ui_1 发光", ui.hero_ui_1.material.get_shader_parameter("enable") == true)
	_p_check("2）hero_ui_2 熄灭", ui.hero_ui_2.material.get_shader_parameter("enable") != true)
	_p_check("2）skill_1_button 按下态", ui.skill_1_button.button_pressed)
	## ---- 复位回默认（走复位收口路径）----
	ui._on_skill_power_reset()
	_p_check("复位后全灭/锁定/弹起", ui.mask_4.visible and not ui.skill_1_button.button_pressed \
		and ui.hero_ui_1.material.get_shader_parameter("enable") != true and Current.power_skill == 0)
	## ---- 断言3：无能量按压任一赋能按钮 → 图标状态不变（弹回）----
	var btn_by_num := {1: ui.skill_1_button, 2: ui.skill_2_button, 3: ui.skill_3_button}
	for num in [1, 2, 3]:
		Current.power = 0
		var btn: TextureButton = btn_by_num[num]
		btn.button_pressed = true
		ui.call("_on_skill_%d_button_pressed" % num)
		_p_check("3）无能量按技能%d → 图标全灭/锁定（状态不变）" % num,
			ui.mask_4.visible
			and ui.hero_ui_1.material.get_shader_parameter("enable") != true
			and ui.hero_ui_2.material.get_shader_parameter("enable") != true
			and Current.power_skill == 0)
		_p_check("3）无能量按技能%d → 按钮弹回" % num,
			not ui.skill_1_button.button_pressed
			and not ui.skill_2_button.button_pressed
			and not ui.skill_3_button.button_pressed)
	print("[DIAG] === 赋能切换同步回归结束（失败 %d 项）===" % _p_failed)
	get_tree().quit(1 if _p_failed > 0 else 0)

func _quit() -> void:
	print("[DIAG] === 诊断结束 ===")
	get_tree().quit(0)
