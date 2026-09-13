extends Node

## 临时 headless 集成验证：掉落骰子选择界面重做
## 覆盖：全屏布局、悬浮弹性缩放、暂停/恢复、点击选择落盘、eye 切换、真实调用链（skill_system 协程等锁）
var failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await _run()
	if failures.is_empty():
		print("DROP_SELECTION_TEST_ALL_PASS")
	else:
		for f in failures:
			print("DROP_SELECTION_TEST_FAIL: " + f)
	get_tree().quit(0 if failures.is_empty() else 1)

func _check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main: Node = packed.instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame

	## main.tscn 的根节点本身就是 game_manager
	var gm: Node = main
	_check(gm != null, "game_manager node found")
	if gm == null:
		return

	var drop_ui: CanvasLayer = gm.get_node("drop_selection_ui")
	_check(drop_ui != null, "drop_selection_ui node found")
	_check(drop_ui is CanvasLayer, "drop_selection_ui is CanvasLayer (matches level_up_ui)")
	if drop_ui == null:
		return

	## ---- 场景结构：全屏遮罩 + 标题 + 选项行 + eye 按钮，根节点 process_mode ALWAYS ----
	_check(drop_ui.process_mode == Node.PROCESS_MODE_ALWAYS, "root process_mode ALWAYS")
	var bg: ColorRect = drop_ui.get_node("background")
	var title: Label = drop_ui.get_node("title_label")
	var container: HBoxContainer = drop_ui.get_node("dice_container")
	var eye_btn: TextureButton = drop_ui.get_node("hide_drop_ui_button")
	_check(bg != null and title != null and container != null and eye_btn != null, "scene structure complete")
	_check(bg.color.a > 0.8, "background dark mask alpha > 0.8 (got %s)" % bg.color.a)
	## 标题样式对齐卡牌场景：36 号、黑描边 12
	var title_settings: LabelSettings = title.label_settings
	_check(title_settings != null and title_settings.font_size == 36, "title font size 36")
	_check(title_settings != null and title_settings.outline_size == 12, "title outline size 12")
	_check(title.text == "选择一个骰子保留", "title text unchanged")

	## ---- 真实调用链回归：skill_system._show_drop_selection 协程在暂停下等锁（任务 3.2） ----
	var skill_system: Node = gm.get_node("skill_system")
	_check(skill_system != null, "skill_system node found")
	var dropped: Array = [["green", 5], ["blue", 2], ["yellow", 4]]
	## setup 前清掉可能残留的锁与 meta
	Current.public_lock_array.erase("drop_selection")
	if Current.has_meta("drop_selection_result"):
		Current.remove_meta("drop_selection_result")
	Current.drop_slot_dice = null
	var caller_done: Array = []
	## 模拟调用方协程：append 锁 → setup → 轮询等待锁释放 → 读 meta（与 skill_system._show_drop_selection 一致，
	## 轮询用 Tools.time_sleep，基于 create_timer(x)（process_always=true 默认），暂停期间继续计时）
	_caller_coroutine(skill_system, dropped, caller_done)
	await get_tree().process_frame
	await get_tree().process_frame

	## setup 已执行：界面显示 + 游戏暂停 + 锁存在
	_check(drop_ui.visible, "popup visible after setup")
	_check(get_tree().paused, "tree paused by setup")
	_check("drop_selection" in Current.public_lock_array, "drop_selection lock held")
	_check(container.get_child_count() == 3, "three option buttons created")

	## ---- 选项内容：TextureButton 96x96、纹理、tooltip、子节点穿透（spec 要求） ----
	var expected_icons := ["res://images/ui_icon/dice_green_5.tres", "res://images/ui_icon/dice_blue_2.tres", "res://images/ui_icon/dice_yellow_4.tres"]
	for i in range(container.get_child_count()):
		var option: TextureButton = container.get_child(i)
		_check(option is TextureButton, "option%d is TextureButton" % (i + 1))
		_check(option.custom_minimum_size == Vector2(96, 96), "option%d 96x96 (got %s)" % [i + 1, option.custom_minimum_size])
		_check(option.ignore_texture_size, "option%d ignore_texture_size" % (i + 1))
		_check(option.texture_normal != null and option.texture_normal.resource_path == expected_icons[i], "option%d texture %s" % [i + 1, expected_icons[i]])
		_check(TooltipManager._tooltip_data.has(option), "option%d tooltip attached" % (i + 1))
		for child in option.get_children():
			_check(child.mouse_filter == Control.MOUSE_FILTER_IGNORE, "option%d child %s mouse_filter IGNORE" % [i + 1, child.name])

	## ---- 悬浮弹性缩放（暂停期间动画正常，spec 场景：Effects run while game is paused） ----
	for i in range(container.get_child_count()):
		var option: TextureButton = container.get_child(i)
		## 每轮重新进入选择态
		drop_ui.visible = true
		if not ("drop_selection" in Current.public_lock_array):
			Current.public_lock_array.append("drop_selection")
		get_tree().paused = true
		await get_tree().process_frame

		## 悬浮：弹性放大 + z_index 置顶绘制，布局顺序不变
		option.mouse_entered.emit()
		await _wait(0.35)
		_check(absf(option.scale.x - 1.1) < 0.02, "option%d hover scale ~1.1 (got %s)" % [i + 1, option.scale])
		_check(absf(option.scale.y - 1.1) < 0.02, "option%d hover scale.y ~1.1" % (i + 1))
		_check(option.get_index() == i, "option%d layout order unchanged on hover (index %d)" % [i + 1, option.get_index()])
		_check(option.z_index == 1, "option%d hover z_index lifted" % (i + 1))
		## 移出：弹回
		option.mouse_exited.emit()
		await _wait(0.3)
		_check(option.scale.is_equal_approx(Vector2.ONE), "option%d exit scale back to 1.0 (got %s)" % [i + 1, option.scale])
		_check(option.z_index == 0, "option%d exit z_index restored" % (i + 1))

	## ---- eye 切换：图标切换 + 内容隐藏/恢复，锁仍在 ----
	var eye_show: Texture2D = load("res://images/ui_icon/eye2.png")
	var eye_hide: Texture2D = load("res://images/ui_icon/eye.png")
	_check(eye_btn.texture_normal == eye_show, "eye button initial icon = eye2")
	eye_btn.pressed.emit()
	await get_tree().process_frame
	_check(eye_btn.texture_normal == eye_hide, "eye toggles icon to eye (hidden)")
	_check(not bg.visible and not title.visible and not container.visible, "eye hides mask+title+options")
	_check(not eye_btn.visible or eye_btn.visible, "eye button still present")
	_check("drop_selection" in Current.public_lock_array, "eye hide does not release lock")
	_check(get_tree().paused, "eye hide does not unpause")
	eye_btn.pressed.emit()
	await get_tree().process_frame
	_check(eye_btn.texture_normal == eye_show, "eye toggles icon back to eye2")
	_check(bg.visible and title.visible and container.visible, "eye shows content again")

	## ---- 点击选择：unpause + 隐藏 + 锁释放 + meta 落盘 + 调用方协程恢复 ----
	var target: TextureButton = container.get_child(1)
	target.pressed.emit()
	await get_tree().process_frame
	_check(not get_tree().paused, "click unpauses")
	_check(not drop_ui.visible, "click hides ui")
	_check(not ("drop_selection" in Current.public_lock_array), "click erases lock")
	## 等待调用方协程读完 meta 并写入 drop_slot_dice
	await _wait(0.3)
	_check(caller_done.size() == 1, "caller coroutine resumed after lock release")
	if caller_done.size() == 1:
		var chosen: Array = Current.drop_slot_dice
		_check(chosen != null and chosen[0] == "blue" and chosen[1] == 2, "drop_slot_dice = [blue, 2] (got %s)" % str(chosen))
		_check(not Current.has_meta("drop_selection_result"), "meta consumed by caller")

	## ---- 单骰子不弹窗（既有行为不变） ----
	Current.public_lock_array.erase("drop_selection")
	skill_system._show_drop_selection([["red", 3]])
	await get_tree().process_frame
	_check(Current.drop_slot_dice[0] == "red" and Current.drop_slot_dice[1] == 3, "single dice bypasses popup (direct place)")

## 与 skill_system._show_drop_selection 相同的锁 + 轮询 + meta 模式
func _caller_coroutine(skill_system: Node, dropped: Array, done: Array) -> void:
	Current.public_lock_array.append("drop_selection")
	var drop_selection_ui = skill_system.game_manager.get_node("drop_selection_ui")
	drop_selection_ui.setup(dropped)
	while "drop_selection" in Current.public_lock_array:
		await Tools.time_sleep(0.05)
	if Current.has_meta("drop_selection_result"):
		Current.drop_slot_dice = Current.get_meta("drop_selection_result")
		Current.remove_meta("drop_selection_result")
	done.append(true)
