extends CanvasLayer
## BUFF调试面板 - 一键添加任意BUFF/DEBUFF效果
## 默认隐藏，按F1切换显示

var game_manager: Node2D

func _ready() -> void:
	game_manager = $"/root/game_manager"
	visible = false

	# 加载配置数据
	var buff_data: Array = Tools.load_json_file("res://config/buff.json")
	var debuff_data: Array = Tools.load_json_file("res://config/debuff.json")

	# 构建UI
	_build_ui(buff_data, debuff_data)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_F1 and event.pressed and not event.echo:
		visible = not visible

func _build_ui(buff_data: Array, debuff_data: Array) -> void:
	# 根Control - 填满整个视口
	var root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.name = "panel_root"
	add_child(root_control)

	# 半透明背景 ColorRect
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 250.0 / 255.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	root_control.add_child(bg)

	# CenterContainer 居中内容
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	root_control.add_child(center)

	# ScrollContainer 包裹内容，限制宽度
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(280, 400)
	scroll.size_flags_stretch_ratio = 1.0
	scroll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(scroll)

	# VBoxContainer 主容器
	var vbox = VBoxContainer.new()
	vbox.name = "vbox"
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	# 标题 Label
	var title_label = Label.new()
	title_label.text = "BUFF调试面板"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# BUFF区域
	var buff_section_label = Label.new()
	buff_section_label.text = "── BUFF ──"
	buff_section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(buff_section_label)

	var buff_grid = GridContainer.new()
	buff_grid.columns = 8
	buff_grid.add_theme_constant_override("h_separation", 2)
	buff_grid.add_theme_constant_override("v_separation", 2)
	vbox.add_child(buff_grid)

	_create_buff_buttons(buff_data, buff_grid, false)

	# DEBUFF区域
	var debuff_section_label = Label.new()
	debuff_section_label.text = "── DEBUFF ──"
	debuff_section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(debuff_section_label)

	var debuff_grid = GridContainer.new()
	debuff_grid.columns = 8
	debuff_grid.add_theme_constant_override("h_separation", 2)
	debuff_grid.add_theme_constant_override("v_separation", 2)
	vbox.add_child(debuff_grid)

	_create_buff_buttons(debuff_data, debuff_grid, true)

func _create_buff_buttons(data: Array, container: GridContainer, is_debuff: bool) -> void:
	for entry in data:
		var icon_key: String = "debuff_icon" if is_debuff else "buff_icon"

		var button = TextureButton.new()
		button.custom_minimum_size = Vector2(32, 32)
		button.texture_normal = load(entry[icon_key])
		## BBCode富文本tooltip
		if is_debuff:
			TooltipManager.set_tooltip(button, TooltipFormatter.format_debuff(entry))
		else:
			TooltipManager.set_tooltip(button, TooltipFormatter.format_buff(entry))
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.pressed.connect(_on_buff_button_pressed.bind(entry))
		container.add_child(button)

func _on_buff_button_pressed(buff_data: Dictionary) -> void:
	# _set_buff 期望 buff_res/buff_type 键名，debuff 配置使用 debuff_res/debuff_type
	# 需要统一键名后再调用
	var normalized := {}
	for key in buff_data:
		if key == "debuff_res":
			normalized["buff_res"] = buff_data[key]
		elif key == "debuff_type":
			normalized["buff_type"] = buff_data[key]
		else:
			normalized[key] = buff_data[key]
	game_manager._set_buff(normalized)
