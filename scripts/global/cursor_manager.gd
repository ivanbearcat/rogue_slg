extends Node

@onready var game_manager: Node2D = get_node("/root/game_manager")

func _ready():
	pass

func _input(event: InputEvent) -> void:
	## 鼠标变成重掷后的左键操作
	if Current.mouse_status != 'default' and Current.slime:
		if event is InputEventMouseButton and \
		event.button_index == MOUSE_BUTTON_LEFT and \
		event.is_pressed() == true:
			## 重掷史莱姆
			game_manager.slime_reroll(Current.slime)
			Current.slime = null
			Input.set_custom_mouse_cursor(
				load('res://images/pointer_scifi_a.svg'),
				Input.CURSOR_ARROW,
				Vector2(0, 0)
			)
			Current.mouse_status = 'default'
			Current.reroll_times -= 1
	## 鼠标变成重掷后的右键操作
	if Current.mouse_status != 'default':
		if event is InputEventMouseButton and \
		event.button_index == MOUSE_BUTTON_RIGHT and \
		event.is_pressed() == true:
			## 恢复鼠标
			Current.mouse_status = 'default'
			Input.set_custom_mouse_cursor(
				load('res://images/pointer_scifi_a.svg'),
				Input.CURSOR_ARROW,
				Vector2(0, 0)
			)
	

func change_cursor(cursor_name):
	var cursor_name_dict = {
		"reroll": ["res://images/icon_reset_green.png", Vector2(16, 16)]
	}
	#await get_tree().process_frame
	Current.mouse_status = 'reroll'
	Input.set_custom_mouse_cursor(
		load(cursor_name_dict[cursor_name][0]),
		Input.CURSOR_ARROW,
		cursor_name_dict[cursor_name][1]
	)


## 左键点击修改鼠标光标图案
#func _input(event):
	#if DisplayServer.window_get_size().x > 0:  # 检查窗口有效性
		#if event is InputEventMouseButton:
			#if event.button_index == MOUSE_BUTTON_LEFT:
				#if event.pressed:
					## 左键按下时切换为点击光标
					#Input.set_custom_mouse_cursor(
						#load("res://images/pointer_scifi_b.svg"),
						#Input.CURSOR_ARROW,
						#Vector2(0, 0)  # 热点位置（根据图片调整）
					#)
				#else:
					## 左键释放时恢复默认
					#Input.set_custom_mouse_cursor(
						#load("res://images/pointer_scifi_a.svg"),
						#Input.CURSOR_ARROW
					#)
	#else:
		#print("窗口未就绪，延迟重试...")
		#await get_tree().create_timer(0.5).timeout
