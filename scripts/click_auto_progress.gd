extends TextureProgressBar
# 直接挂在目标 TextureProgressBar 上

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP   # 保证能吃到鼠标事件

func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	var mm := event as InputEventMouseMotion

	# 左键按下,或按住左键拖动持续跟随
	var clicked := mb != null \
			and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed
	var dragging := mm != null \
			and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	if clicked or dragging:
		_update_from_mouse(event.position)

func _update_from_mouse(pos: Vector2) -> void:
	var ratio := 0.0
	match fill_mode:                 # _gui_input 里的 pos 已是控件局部坐标
		FILL_LEFT_TO_RIGHT:  ratio = pos.x / size.x
		FILL_RIGHT_TO_LEFT:  ratio = 1.0 - pos.x / size.x
		FILL_TOP_TO_BOTTOM:  ratio = pos.y / size.y
		FILL_BOTTOM_TO_TOP:  ratio = 1.0 - pos.y / size.y
		_:                   ratio = pos.x / size.x
	value = min_value + clampf(ratio, 0.0, 1.0) * (max_value - min_value)
