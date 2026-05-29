extends CanvasLayer

## BBCode富文本Tooltip管理器
## 全局唯一popup实例，统一管理tooltip的显示/隐藏/viewport边界自适应

var _popup: PanelContainer
var _rich_label: RichTextLabel

func _ready() -> void:
	layer = 100
	_popup = load("res://scenes/tooltip_popup.tscn").instantiate()
	add_child(_popup)
	_rich_label = _popup.get_node("MarginContainer/RichTextLabel")

## 在鼠标位置显示tooltip（出现后固定不动）
func show_tooltip(node: Control, bbcode_text: String, offset: Vector2 = Vector2(20, 10)) -> void:
	if bbcode_text.is_empty():
		hide_tooltip()
		return
	_rich_label.text = bbcode_text
	_popup.visible = true
	# 等待一帧让RichTextLabel计算内容大小
	await _rich_label.finished
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
	_rich_label.text = bbcode_text
	_popup.visible = true
	await _rich_label.finished
	_position_at(position)

## 为非RichTooltip节点设置BBCode tooltip（用于商店图标等普通Control节点）
## 自动连接mouse_entered/mouse_exited信号
func set_tooltip(node: Control, bbcode_text: String, offset: Vector2 = Vector2(20, 10)) -> void:
	# 断开旧的连接（如果存在）
	if node.is_connected("mouse_entered", _on_node_mouse_entered):
		node.disconnect("mouse_entered", _on_node_mouse_entered)
	if node.is_connected("mouse_exited", _on_node_mouse_exited):
		node.disconnect("mouse_exited", _on_node_mouse_exited)
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

## 隐藏tooltip
func hide_tooltip() -> void:
	_popup.visible = false

## 将tooltip定位在鼠标位置+offset，viewport边界自适应
func _position_at_mouse(offset: Vector2) -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var popup_size: Vector2 = _popup.get_combined_minimum_size()
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
	_popup.position = pos

## 将tooltip定位在指定全局位置
func _position_at(position: Vector2) -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var popup_size: Vector2 = _popup.get_combined_minimum_size()
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
	_popup.position = pos
