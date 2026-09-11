extends Node

## 临时 headless 集成验证：升级选卡点击选择 + 悬浮弹性缩放
var failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await _run()
	if failures.is_empty():
		print("LEVEL_UP_CARD_TEST_ALL_PASS")
	else:
		for f in failures:
			print("LEVEL_UP_CARD_TEST_FAIL: " + f)
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

	## 按钮行已移除（任务 1.3）
	_check(gm.get_node_or_null("level_up_ui/MarginContainer/VBoxContainer/HBoxContainer2") == null, "button row removed")

	## 准备选卡界面数据（不依赖 hero 的完整升级流程）
	gm._set_level_up_card()
	await get_tree().process_frame
	_check(gm.level_up_three_card_array.size() == 3, "three cards generated")

	gm.level_up_ui.show()
	Current.public_lock_array.append("level_up_ui")
	get_tree().paused = true
	await get_tree().process_frame
	_check(gm.level_up_ui.visible, "level_up_ui visible before select")
	_check(get_tree().paused, "tree paused before select")

	var cards: Array = [gm.card_1, gm.card_2, gm.card_3]
	for i in range(cards.size()):
		var card: TextureButton = cards[i]
		## 子节点鼠标穿透配置（任务 1.2）
		for child in card.get_children():
			_check(child.mouse_filter == Control.MOUSE_FILTER_IGNORE, "card%d child %s mouse_filter IGNORE" % [i + 1, child.name])
		## 每轮重新进入选卡态
		gm.level_up_ui.show()
		if not ("level_up_ui" in Current.public_lock_array):
			Current.public_lock_array.append("level_up_ui")
		get_tree().paused = true
		await get_tree().process_frame

		## 悬浮：弹性放大 + z_index 置顶绘制，且布局顺序不得改变（卡位互换回归）
		card.mouse_entered.emit()
		await _wait(0.35)
		_check(absf(card.scale.x - 1.1) < 0.02, "card%d hover scale ~1.1 (got %s)" % [i + 1, card.scale])
		_check(absf(card.scale.y - 1.1) < 0.02, "card%d hover scale.y ~1.1" % (i + 1))
		_check(card.get_index() == i, "card%d layout order unchanged on hover (index %d)" % [i + 1, card.get_index()])
		_check(card.z_index == 1, "card%d hover z_index lifted" % (i + 1))
		## 移出：弹回
		card.mouse_exited.emit()
		await _wait(0.3)
		_check(card.scale.is_equal_approx(Vector2.ONE), "card%d exit scale back to 1.0 (got %s)" % [i + 1, card.scale])
		_check(card.z_index == 0, "card%d exit z_index restored" % (i + 1))

		## 点击：应用效果 + 取消暂停 + 隐藏 + 移除锁
		card.pressed.emit()
		await get_tree().process_frame
		_check(not get_tree().paused, "card%d click unpauses" % (i + 1))
		_check(not gm.level_up_ui.visible, "card%d click hides ui" % (i + 1))
		_check(not ("level_up_ui" in Current.public_lock_array), "card%d click erases lock" % (i + 1))

	## 隐藏按钮行为不受影响（状态变量驱动图标切换 + 内容隐藏/显示）
	var hide_btn: TextureButton = gm.hide_level_up_ui_button
	var eye_show: Texture2D = load("res://images/ui_icon/eye2.png")
	var eye_hide: Texture2D = load("res://images/ui_icon/eye.png")
	_check(hide_btn.texture_normal == eye_show, "hide button initial icon = eye2")
	hide_btn.pressed.emit()
	await get_tree().process_frame
	_check(hide_btn.texture_normal == eye_hide, "hide button toggles icon to eye")
	_check(not gm.level_up_ui.get_node("Panel").visible, "hide button hides content")
	hide_btn.pressed.emit()
	await get_tree().process_frame
	_check(hide_btn.texture_normal == eye_show, "hide button toggles icon back to eye2")
	_check(gm.level_up_ui.get_node("Panel").visible, "hide button shows content")
