extends CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # 关键:暂停中也要能收到 ESC
	# 注意:这里不要盲目 hide(),场景默认可见性以编辑器里为准

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("esc"):
		return
	# 第一优先:任何开着 setting_ui 的场景,ESC 只关 setting_ui
	var setting := get_tree().get_first_node_in_group("setting_ui") as CanvasLayer
	if setting != null and setting.visible:
		EventBus.event_emit('setting_ui', ['hide'])   # 用现有事件关闭,保持它自己的收尾逻辑
		get_viewport().set_input_as_handled()
		return
	# 第二优先:原有的 pause toggle
	# 别的暂停型界面开着(商店/升级/结算)时不插手,防止 ESC 恢复运行撞坏它们的流程
	if not visible and not Current.public_lock_array.is_empty():
		return
	toggle_pause()
	get_viewport().set_input_as_handled()    # 吃掉这个 ESC,不再漏给其他脚本

func toggle_pause() -> void:
	if visible:
		hide()
		get_tree().paused = false
	else:
		show()
		get_tree().paused = true


func _on_resume_button_pressed() -> void:
	hide()
	get_tree().paused = false


func _on_texture_button_2_pressed() -> void:
	hide()
	get_tree().paused = false
	SceneManager.change_scene(&"splash")


func _on_texture_button_3_pressed() -> void:
	EventBus.event_emit('setting_ui', ['show'])


func _on_texture_button_4_pressed() -> void:
	get_tree().quit()
