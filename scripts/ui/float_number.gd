extends Node2D

## Color.html
var num_color: String

## 飘字图标布局常量：图标本地高36px（节点缩放0.25后与36px字号数字同高）
## 有图标时 Label 右移固定偏移（icon_height/2 + 间隙），无图标时偏移为零保持原布局
const ICON_HEIGHT := 36.0
const ICON_GAP := 0
const LABEL_ICON_OFFSET := ICON_HEIGHT / 2.0 + ICON_GAP

var float_num: int:
	set(v):
		$Label.label_settings.font_color = Color.html(num_color)
		if v >= 0:
			$Label.text = "+" + str(v)
		else:
			$Label.text = str(v)
	get:
		return $Label.text

## 来源图标：buff/debuff 执行窗口内由 EffectManager 注入（float_context_buff），null = 纯数字
var icon_texture: Texture2D:
	set(v):
		icon_texture = v
		$Icon.texture = v
		$Icon.visible = v != null
		$Label.position.x = LABEL_ICON_OFFSET if v != null else 0.0

var velocity := Vector2.ZERO
var gravity := Vector2.ZERO

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property($Label, "modulate:a", 0, 0.8).set_delay(0.2)
	tween.parallel().tween_property($Icon, "modulate:a", 0, 0.8).set_delay(0.2)

func _process(delta: float) -> void:
	velocity += gravity * delta
	position += velocity * delta
