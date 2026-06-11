extends PanelContainer

## RichTooltip脚本组件
## 挂载到PanelContainer节点上，提供set_rich_tooltip()方法
## 自动监听mouse_enter/mouse_exit信号调用TooltipManager显示/隐藏BBCode tooltip
## 支持脉冲边框动画（同族BUFF≥4时激活）

var _rich_tooltip_text: String = ""
var _pulse_tween: Tween = null

## texture属性代理：转发到内部TextureRect，保持buff_texture.texture = xxx的兼容性
var texture: Texture2D:
	set(value):
		$TextureRect.texture = value
	get:
		return $TextureRect.texture if has_node("TextureRect") else null

## 获取内部TextureRect子节点
func get_texture_rect() -> TextureRect:
	return $TextureRect as TextureRect

## 设置BBCode tooltip内容（用于非buff场景的fallback）
func set_rich_tooltip(bbcode_text: String) -> void:
	_rich_tooltip_text = bbcode_text

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	# 优先使用动态tooltip
	if has_meta("buff_meta"):
		var meta = get_meta("buff_meta")
		# 判断是 buff 还是 debuff：debuff 数据有 debuff_icon 键
		var dynamic_text: String
		if meta.has("debuff_icon") or meta.has("debuff_name"):
			dynamic_text = TooltipFormatter.format_debuff(meta)
		else:
			dynamic_text = TooltipFormatter.format_buff(meta)
		TooltipManager.show_tooltip(self, dynamic_text)
	elif not _rich_tooltip_text.is_empty():
		# fallback：使用缓存的_rich_tooltip_text（非buff场景）
		TooltipManager.show_tooltip(self, _rich_tooltip_text)

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()

## 启动脉冲边框动画
func _start_pulse_border(color: Color) -> void:
	_stop_pulse_border()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_border_width_all(2)
	style.border_color = color
	style.anti_aliasing = false
	add_theme_stylebox_override("panel", style)
	# alpha脉冲动画：0.3 ↔ 1.0，周期1.5秒
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(style, "border_color:a", 0.3, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(style, "border_color:a", 1.0, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## 停止脉冲边框动画，恢复无边框
func _stop_pulse_border() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	# 恢复默认无边框StyleBox
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	add_theme_stylebox_override("panel", style)
