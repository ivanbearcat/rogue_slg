extends Node

## 一次性诊断脚本：复现"技能按下后悬停无红框、点击无效"链路（只读取证，不修改游戏逻辑）
## 用法: Godot_v4.7-stable_win64.exe --headless --path . res://test/scripts/scene/skill_hover_diag.tscn -- --skill=1
## 参数 --skill=1/2/3 指定诊断的技能编号，默认 1

var _skill_num := "1"

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--skill="):
			_skill_num = arg.trim_prefix("--skill=")
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

	## --- 步骤3: 模拟悬停目标格（直接调用 grid 的 mouse_entered 处理函数）---
	var hover_index: Vector2 = Current.skill_target_range[0]
	var hover_grid: Node = gm.all_grid_dict[hover_index]
	print("[DIAG] 步骤3 悬停目标格 ", hover_index,
		" 该格target.visible=", hover_grid.target.visible)
	hover_grid._on_area_2d_mouse_entered()
	await get_tree().create_timer(0.1).timeout
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
	if gm.all_grid_dict.has(far_index):
		var far_grid: Node = gm.all_grid_dict[far_index]
		far_grid._on_area_2d_mouse_entered()
		await get_tree().create_timer(0.05).timeout
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

func _quit() -> void:
	print("[DIAG] === 诊断结束 ===")
	get_tree().quit(0)
