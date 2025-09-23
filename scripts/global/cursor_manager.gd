extends Node

@onready var game_manager: Node2D = get_node("/root/game_manager")

func _ready():
	EventBus.subscribe("reset_cursor", reset_cursor)

func _reset_grid() -> void:
	## 恢复格子
	var all_grids = game_manager.grids.get_children()
	for grid in all_grids:
		grid.target.hide()
		grid.attack.hide()

func _input(event: InputEvent) -> void:
	## 鼠标不是默认时
	if Current.mouse_status != "default":
		## 左键
		if event is InputEventMouseButton and \
		event.button_index == MOUSE_BUTTON_LEFT and \
		event.is_pressed() == true:
			EventBus.event_emit(Current.mouse_status + "_clicked")
		## 右键和ESC
		if event is InputEventMouseButton and \
		event.button_index == MOUSE_BUTTON_RIGHT and \
		event.is_pressed() == true or \
		event.is_action_pressed("esc"):
			## 恢复鼠标
			reset_cursor()

func reset_cursor() -> void:
	Input.set_custom_mouse_cursor(
		load('res://images/pointer_scifi_a.svg'),
		Input.CURSOR_ARROW,
		Vector2(0, 0)
	)
	## 恢复格子
	_reset_grid()
	## 恢复按钮UI
	EventBus.event_emit("reset_all_button")
	## 延时改状态，不然INPUT事件会因为速度快而异常获取到
	await Tools.time_sleep(0.01)
	Current.mouse_status = 'default'

func change_cursor(cursor_name):
	var cursor_name_dict = {
		"reroll": ["res://images/mouse_target.png", Vector2(18, 18)],
		"reroll_all": ["res://images/mouse_target.png", Vector2(18, 18)],
		"reroll_dice": ["res://images/mouse_target.png", Vector2(18, 18)],
		"reroll_color": ["res://images/mouse_target.png", Vector2(18, 18)],
		"add_power": ["res://images/mouse_target.png", Vector2(18, 18)],
		"dice_add_1": ["res://images/mouse_target.png", Vector2(18, 18)],
		"dice_sub_1": ["res://images/mouse_target.png", Vector2(18, 18)],
		"double_score": ["res://images/mouse_target.png", Vector2(18, 18)],
		#"cloud": ["res://images/mouse_target.png", Vector2(18, 18)],
	}
	if not cursor_name in ["move"]:
		## 修改鼠标态和显示图案
		Current.mouse_status = cursor_name
		Input.set_custom_mouse_cursor(
			load(cursor_name_dict[cursor_name][0]),
			Input.CURSOR_ARROW,
			cursor_name_dict[cursor_name][1]
				)
