extends CanvasLayer

## BBCode富文本Tooltip管理器
## 统一管理tooltip的显示/隐藏/viewport边界自适应
## 持有两个popup实例：BUFF/店铺等 bbcode_text 弹窗和技能tooltip弹窗，两者互斥（任意时刻至多一个可见）

var _popup: PanelContainer
var _rich_label: RichTextLabel

## 技能tooltip popup（动画区+文本区），与文本popup互斥
var _skill_popup: PanelContainer
var _skill_rich_label: RichTextLabel
var _skill_anim_area: Control
var _skill_anim_sprite: AnimatedSprite2D

func _ready() -> void:
	layer = 100
	_popup = load("res://scenes/tooltip_popup.tscn").instantiate()
	add_child(_popup)
	_rich_label = _popup.get_node("MarginContainer/RichTextLabel")
	_skill_popup = load("res://scenes/skill_tooltip_popup.tscn").instantiate()
	add_child(_skill_popup)
	_skill_rich_label = _skill_popup.get_node("MarginContainer/VBoxContainer/RichTextLabel")
	_skill_anim_area = _skill_popup.get_node("MarginContainer/VBoxContainer/AnimArea")
	_skill_anim_sprite = _skill_popup.get_node("MarginContainer/VBoxContainer/AnimArea/AnimSprite")
	# 动画区实际矩形被容器拉伸/收缩时，动画节点始终居中于区内
	# （否则sprite按custom_minimum_size定位会偏在左侧，右边留黑条）
	_skill_anim_area.resized.connect(_on_skill_anim_area_resized)

func _on_skill_anim_area_resized() -> void:
	_skill_anim_sprite.position = _skill_anim_area.size / 2.0

## 在鼠标位置显示tooltip（出现后固定不动）
func show_tooltip(node: Control, bbcode_text: String, offset: Vector2 = Vector2(20, 10)) -> void:
	if bbcode_text.is_empty():
		hide_tooltip()
		return
	# 文本tooltip与技能tooltip互斥
	_hide_skill_popup()
	_rich_label.text = bbcode_text
	_popup.visible = true
	# 等待一帧让RichTextLabel计算内容大小
	# （不await finished：标签首次排版到达完成态后引擎不再发射finished，await会永久悬挂）
	await _await_rtl_layout(_rich_label)
	# 检查节点是否仍然有效（await期间可能被释放）
	if not is_instance_valid(node):
		hide_tooltip()
		return
	_position_at_mouse(offset)

## 在指定全局位置显示tooltip（固定位置模式，用于精英/Boss史莱姆）
func show_tooltip_at(position: Vector2, bbcode_text: String) -> void:
	if bbcode_text.is_empty():
		hide_tooltip()
		return
	# 文本tooltip与技能tooltip互斥
	_hide_skill_popup()
	_rich_label.text = bbcode_text
	_popup.visible = true
	await _await_rtl_layout(_rich_label)
	_position_at(position)

## 为非RichTooltip节点设置BBCode tooltip（用于商店图标等普通Control节点）
## 自动连接mouse_entered/mouse_exited信号
func set_tooltip(node: Control, bbcode_text: String, offset: Vector2 = Vector2(20, 10)) -> void:
	# 断开旧的连接（如果存在）
	if node.is_connected("mouse_entered", _on_node_mouse_entered):
		node.disconnect("mouse_entered", _on_node_mouse_entered)
	if node.is_connected("mouse_exited", _on_node_mouse_exited):
		node.disconnect("mouse_exited", _on_node_mouse_exited)
	# 同一节点只允许挂一种tooltip（清掉技能tooltip挂接）
	_disconnect_skill_hooks(node)
	# 存储tooltip文本和偏移
	_tooltip_data[node] = {"text": bbcode_text, "offset": offset}
	node.mouse_entered.connect(_on_node_mouse_entered.bind(node))
	node.mouse_exited.connect(_on_node_mouse_exited)

## 移除节点的BBCode tooltip
func unset_tooltip(node: Control) -> void:
	if node.is_connected("mouse_entered", _on_node_mouse_entered):
		node.disconnect("mouse_entered", _on_node_mouse_entered)
	if node.is_connected("mouse_exited", _on_node_mouse_exited):
		node.disconnect("mouse_exited", _on_node_mouse_exited)
	_disconnect_skill_hooks(node)
	_tooltip_data.erase(node)

var _tooltip_data: Dictionary = {}  # node -> {text, offset}

func _on_node_mouse_entered(node: Control) -> void:
	if not is_instance_valid(node):
		_tooltip_data.erase(node)
		return
	var data: Dictionary = _tooltip_data.get(node, {})
	if data.is_empty():
		return
	show_tooltip(node, data["text"], data["offset"])

func _on_node_mouse_exited() -> void:
	hide_tooltip()

## 为英雄技能按钮设置技能tooltip（沿用set_tooltip的防重连挂接写法）
## skill_row: config/hero_skill.json 行数据
func set_skill_tooltip(node: Control, skill_row: Dictionary, offset: Vector2 = Vector2(20, 10)) -> void:
	# 断开旧的连接（如果存在）
	if node.is_connected("mouse_entered", _on_skill_node_mouse_entered):
		node.disconnect("mouse_entered", _on_skill_node_mouse_entered)
	if node.is_connected("mouse_exited", _on_node_mouse_exited):
		node.disconnect("mouse_exited", _on_node_mouse_exited)
	# 同一节点只允许挂一种tooltip（清掉文本tooltip挂接）
	_disconnect_text_hooks(node)
	# 存储技能行数据和偏移
	_skill_data[node] = {"skill_row": skill_row, "offset": offset}
	node.mouse_entered.connect(_on_skill_node_mouse_entered.bind(node))
	node.mouse_exited.connect(_on_node_mouse_exited)

var _skill_data: Dictionary = {}  # node -> {skill_row, offset}

func _on_skill_node_mouse_entered(node: Control) -> void:
	if not is_instance_valid(node):
		_skill_data.erase(node)
		return
	var data: Dictionary = _skill_data.get(node, {})
	if data.is_empty():
		return
	show_skill_tooltip(node, data["skill_row"], data["offset"])

## 在鼠标位置显示技能tooltip（出现后固定不动）
## skill_row 缺少动画字段或素材无效时退化为纯文本占位模式
func show_skill_tooltip(node: Control, skill_row: Dictionary, offset: Vector2 = Vector2(20, 10)) -> void:
	# 文本tooltip与技能tooltip互斥
	_popup.visible = false
	_skill_rich_label.text = TooltipFormatter.format_skill(skill_row)
	_setup_skill_anim(skill_row)
	_skill_popup.visible = true
	# 等待文本排版完成（finished在隐藏期完成的首轮排版上会被引擎吞掉，不await它）
	await _await_rtl_layout(_skill_rich_label)
	# 检查节点是否仍然有效（await期间可能被释放）
	if not is_instance_valid(node):
		hide_tooltip()
		return
	if OS.is_debug_build():
		print("[TIP-DBG] popup_min=", _skill_popup.get_combined_minimum_size(), " vp=", get_viewport().get_visible_rect().size, " mouse=", get_viewport().get_mouse_position())
	_position_at_mouse(offset, _skill_popup)

## 等待RichTextLabel文本排版完成并留一帧让布局尺寸生效
## 说明：RichTextLabel隐藏期间的“空→有内容”首次排版到达完成态时
## finished信号不会再次发射（引擎行为，真机复现确认），await会永久悬挂；
## is_finished()在 threaded 关闭时恒为 true， threaded 打开时等待后台排版线程，
## 故以此轮询替代 + 一帧剩余布局生效
func _await_rtl_layout(label: RichTextLabel) -> void:
	while not label.is_finished():
		await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

## 按行数据装配技能动画区；无动画字段或素材无效时隐藏动画区（纯文本占位模式）
func _setup_skill_anim(skill_row: Dictionary) -> void:
	var frames: SpriteFrames = null
	var sheet_path := str(skill_row.get("anim_sheet", ""))
	if not sheet_path.is_empty():
		frames = SpriteSheetSlicer.build_frames(
			sheet_path,
			int(skill_row.get("anim_cols", 0)),
			int(skill_row.get("anim_rows", 0)),
			int(skill_row.get("anim_frame_begin", 1)),
			int(skill_row.get("anim_frame_end", 0)),
			float(skill_row.get("anim_fps", 10.0)),
			bool(skill_row.get("anim_loop", true)))
	if frames == null:
		# 占位模式：隐藏动画区，仅显示文本
		_skill_anim_sprite.pause()
		_skill_anim_area.visible = false
		return
	# 动画区尺寸 = 单帧 × anim_scale（默认1.0），sprite缩放后居中
	# （PanelContainer定位依赖get_combined_minimum_size，动画区必须用custom_minimum_size撑住）
	var frame_size: Vector2 = frames.get_frame_texture("default", 0).get_size()
	var anim_scale := float(skill_row.get("anim_scale", 1.0))
	_skill_anim_area.custom_minimum_size = frame_size * anim_scale
	_skill_anim_sprite.scale = Vector2.ONE * anim_scale
	_skill_anim_sprite.position = frame_size * anim_scale / 2.0
	_skill_anim_sprite.sprite_frames = frames
	_skill_anim_area.visible = true
	# 每次显示前重置到第0帧从头播放
	_skill_anim_sprite.frame = 0
	_skill_anim_sprite.play()

## 断开节点的技能tooltip挂接连接
func _disconnect_skill_hooks(node: Control) -> void:
	if node.is_connected("mouse_entered", _on_skill_node_mouse_entered):
		node.disconnect("mouse_entered", _on_skill_node_mouse_entered)
	_skill_data.erase(node)

## 断开节点的文本tooltip挂接连接
func _disconnect_text_hooks(node: Control) -> void:
	if node.is_connected("mouse_entered", _on_node_mouse_entered):
		node.disconnect("mouse_entered", _on_node_mouse_entered)
	_tooltip_data.erase(node)

## 隐藏tooltip（同时回收两个popup，互斥可见）
func hide_tooltip() -> void:
	_popup.visible = false
	_hide_skill_popup()

## 回收技能popup并暂停动画（互斥显示复用）
func _hide_skill_popup() -> void:
	if not _skill_popup.visible:
		return
	_skill_popup.visible = false
	# 隐藏时暂停动画，下次显示由show_skill_tooltip重置后重播
	_skill_anim_sprite.pause()

## 轻量更新tooltip文本（不重新定位，用于hover期间动态刷新）
func update_text(bbcode_text: String) -> void:
	if _popup.visible:
		_rich_label.text = bbcode_text

## 将tooltip定位在鼠标位置+offset，viewport边界自适应
## popup缺省=文本popup；技能tooltip流传入_skill_popup
func _position_at_mouse(offset: Vector2 = Vector2(20, 10), popup: PanelContainer = null) -> void:
	if popup == null:
		popup = _popup
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var popup_size: Vector2 = popup.get_combined_minimum_size()
	var pos: Vector2 = mouse_pos + offset
	# 右侧超出 → 放鼠标左侧
	if pos.x + popup_size.x > viewport_size.x:
		pos.x = mouse_pos.x - popup_size.x - offset.x
	# 下方超出 → 放鼠标上方
	if pos.y + popup_size.y > viewport_size.y:
		pos.y = mouse_pos.y - popup_size.y - offset.y
	# 左侧超出边界
	if pos.x < 0:
		pos.x = 0
	# 上方超出边界
	if pos.y < 0:
		pos.y = 0
	popup.position = pos

## 将tooltip定位在指定全局位置
func _position_at(position: Vector2, popup: PanelContainer = null) -> void:
	if popup == null:
		popup = _popup
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var popup_size: Vector2 = popup.get_combined_minimum_size()
	var pos: Vector2 = position
	# 右侧超出
	if pos.x + popup_size.x > viewport_size.x:
		pos.x = viewport_size.x - popup_size.x
	# 下方超出
	if pos.y + popup_size.y > viewport_size.y:
		pos.y = pos.y - popup_size.y
	# 左侧超出
	if pos.x < 0:
		pos.x = 0
	# 上方超出
	if pos.y < 0:
		pos.y = 0
	popup.position = pos
