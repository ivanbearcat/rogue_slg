extends Node

@onready var game_manager: Node2D = get_node("/root/game_manager")

func _ready():
	pass

func _reset_grid() -> void:
	## 恢复格子
	var all_grids = game_manager.grids.get_children()
	for grid in all_grids:
		grid.target.hide()
		grid.attack.hide()

func _input(event: InputEvent) -> void:
	## 鼠标变成重掷
	if Current.mouse_status != "default":
		## 左键
		if event is InputEventMouseButton and \
		event.button_index == MOUSE_BUTTON_LEFT and \
		event.is_pressed() == true:
			EventBus.event_emit(Current.mouse_status + "_clicked")
	## 鼠标变成不是默认时的右键操作
	if Current.mouse_status != 'default' and event is InputEventMouseButton and \
		event.button_index == MOUSE_BUTTON_RIGHT and \
		event.is_pressed() == true:
			## 恢复鼠标
			reset_cursor()
			## 恢复按钮
			EventBus.event_emit("reset_all_button")

func reset_cursor() -> void:
	Current.mouse_status = 'default'
	Input.set_custom_mouse_cursor(
		load('res://images/pointer_scifi_a.svg'),
		Input.CURSOR_ARROW,
		Vector2(0, 0)
	)
	_reset_grid()

func change_cursor(cursor_name):
	var cursor_name_dict = {
		"reroll": ["res://images/mouse_target.png", Vector2(18, 18)],
		"reroll_all": ["res://images/mouse_target.png", Vector2(18, 18)],
		"reroll_dice": ["res://images/mouse_target.png", Vector2(18, 18)],
		"reroll_color": ["res://images/mouse_target.png", Vector2(18, 18)],
	}
	## 修改鼠标态和显示图案
	Current.mouse_status = cursor_name
	Input.set_custom_mouse_cursor(
		load(cursor_name_dict[cursor_name][0]),
		Input.CURSOR_ARROW,
		cursor_name_dict[cursor_name][1]
			)
