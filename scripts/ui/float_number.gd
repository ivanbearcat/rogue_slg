extends Node2D

## Color.html
var num_color: String

## 可选文本后缀（如计分板倍率行的 "%"）：空串 = 既有纯数字，默认与现状一致
var text_suffix: String = ""

## 可选字号档（默认 36 与既有飘字观感一致；计分板飘字用 24 小档）。
## label_settings 为 resource_local_to_scene，逐实例独立，改字号不影响其他飘字
var font_size: int = 36:
	set(v):
		font_size = v
		$Label.label_settings.font_size = v
		_apply_icon_layout()

## 淡出后 queue_free() 自毁开关：计分板行节点整局存活，挂行飘字自毁防堆积；
## 默认 false —— 既有挂 hero 的飘字生命周期不变（随场景销毁回收）
var auto_free := false

## 飘字图标布局常量：图标本地高36px（节点缩放0.25后与36px字号数字同高）
## 有图标时 Label 右移固定偏移（icon_height/2 + 间隙），无图标时偏移为零保持原布局
const ICON_HEIGHT := 36.0
const ICON_GAP := 0
const LABEL_ICON_OFFSET := ICON_HEIGHT / 2.0 + ICON_GAP
## 观感校准常量（微调入口）：飘字停留 = 不透明保持时长，淡出 = 渐隐时长，
## 总观感时长 = HOLD + FADE。此前 0.2+0.8=1.0s，目测反馈偏长 → 收紧 0.6s
const HOLD_DELAY := 0.15
const FADE_DURATION := 0.45

var float_num: int:
	set(v):
		$Label.label_settings.font_color = Color.html(num_color)
		if v >= 0:
			$Label.text = "+" + str(v) + text_suffix
		else:
			$Label.text = str(v) + text_suffix
	get:
		return $Label.text

## 来源图标：buff/debuff 执行窗口内由 EffectManager 注入（float_context_buff），null = 纯数字
var icon_texture: Texture2D:
	set(v):
		icon_texture = v
		$Icon.texture = v
		$Icon.visible = v != null
		_apply_icon_layout()
		$Label.position.x = _scaled_label_icon_offset() if v != null else 0.0

var velocity := Vector2.ZERO
var gravity := Vector2.ZERO

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property($Label, "modulate:a", 0, FADE_DURATION).set_delay(HOLD_DELAY)
	tween.parallel().tween_property($Icon, "modulate:a", 0, FADE_DURATION).set_delay(HOLD_DELAY)
	## 自毁开关：淡出完成后 HOLD+FADE（默认 0.6s）回收；默认关 = 既有生命周期
	if auto_free:
		await tween.finished
		queue_free()

func _process(delta: float) -> void:
	velocity += gravity * delta
	position += velocity * delta

## 字号非默认档时图标与 Label 偏移等比缩放（图标与数字同高）；
## font_size = 36 时缩放系数为 1，布局与变更前完全一致
func _apply_icon_layout() -> void:
	var factor := float(font_size) / ICON_HEIGHT
	$Icon.scale = Vector2(0.25 * factor, 0.25 * factor)

func _scaled_label_icon_offset() -> float:
	return (float(font_size) / ICON_HEIGHT) * LABEL_ICON_OFFSET
