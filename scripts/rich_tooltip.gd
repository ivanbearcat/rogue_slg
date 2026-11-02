extends PanelContainer

## RichTooltip脚本组件
## 挂载到PanelContainer节点上，提供set_rich_tooltip()方法
## 自动监听mouse_enter/mouse_exit信号调用TooltipManager显示/隐藏BBCode tooltip
## 支持霸主图标家族色轮廓呼吸光（_start_outline_glow，shader驱动）

const OVERLORD_GLOW_SHADER := preload("res://shaders/overlord_icon_glow.gdshader")

var _rich_tooltip_text: String = ""
var _is_hovered: bool = false

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

## hover期间每帧刷新tooltip文本（让叠层等动态数据实时更新）
func _process(_delta: float) -> void:
	if not _is_hovered:
		return
	if not has_meta("buff_meta"):
		return
	var meta = get_meta("buff_meta")
	if meta.has("debuff_icon") or meta.has("debuff_name"):
		TooltipManager.update_text(TooltipFormatter.format_debuff(meta))
	else:
		var extra := ""
		if has_meta("buff_instance"):
			var inst = get_meta("buff_instance")
			if is_instance_valid(inst):
				extra = inst._get_tooltip_extra()
		TooltipManager.update_text(TooltipFormatter.format_buff(meta, extra))

func _on_mouse_entered() -> void:
	_is_hovered = true
	# 优先使用动态tooltip
	if has_meta("buff_meta"):
		var meta = get_meta("buff_meta")
		# 判断是 buff 还是 debuff：debuff 数据有 debuff_icon 键
		var dynamic_text: String
		if meta.has("debuff_icon") or meta.has("debuff_name"):
			dynamic_text = TooltipFormatter.format_debuff(meta)
		else:
			var extra := ""
			if has_meta("buff_instance"):
				var inst = get_meta("buff_instance")
				if is_instance_valid(inst):
					extra = inst._get_tooltip_extra()
			dynamic_text = TooltipFormatter.format_buff(meta, extra)
		TooltipManager.show_tooltip(self, dynamic_text)
	elif not _rich_tooltip_text.is_empty():
		# fallback：使用缓存的_rich_tooltip_text（非buff场景）
		TooltipManager.show_tooltip(self, _rich_tooltip_text)

func _on_mouse_exited() -> void:
	_is_hovered = false
	TooltipManager.hide_tooltip()

## 启动家族色轮廓呼吸光（霸主图标专属）：沿图标 sprite 的 alpha 轮廓画一圈细发光线，
## shader TIME 驱动呼吸；绘制发生在 sprite 画布的透明区域，不占任何布局，面板尺寸不变。
func _start_outline_glow(color: Color) -> void:
	_stop_outline_glow()
	var mat := ShaderMaterial.new()
	mat.shader = OVERLORD_GLOW_SHADER
	mat.set_shader_parameter("glow_color", color)
	get_texture_rect().material = mat

## 停止轮廓呼吸光，卸下 shader 材质
func _stop_outline_glow() -> void:
	var rect := get_texture_rect()
	if rect:
		rect.material = null
