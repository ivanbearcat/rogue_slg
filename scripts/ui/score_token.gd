extends Node2D
## 得分贡献 token（post-attack-score-balloon，design D3）
## "来源图标 + 有符号数值"从效果图标位置沿贝塞尔弧线飞向气球；
## 负向贡献红色。到达后发 token_arrived（编排器连接 → 气球吸收）。
## 生命周期由编排器管理：起飞前 add_child、到达后由编排器 queue_free。

## 到达回调：delta 为本 token 承载的有符号贡献
signal token_arrived(delta: int)

## 观感校准常量（任务 5.3 目测定稿后回写；对齐 6.3 惯例集中放头部）
const FLY_DURATION := 0.6
## 弧线弧高（5.3 定稿：56→24——BUFF 栏高位起飞时弧顶不出屏幕顶）
const FLIGHT_ARC_HEIGHT := 24.0
## 飞行末段缓动：起步快、临近气球减速落入（观感：抛物坠落感）
const FLIGHT_TRANS := Tween.TRANS_CUBIC
const FLIGHT_EASE := Tween.EASE_OUT
## 图标/数字排版（像素风缩放 0.25；图标 rect 高 36 经 stretch SCALE 拉伸
## 填满显示，与 36 号数字同高——KEEP_ASPECT 系对小纹理不放大，rect 大块
## 空白曾致"图标与数字间隔更大"；数字左对齐贴 rect 左缘，位置恒定）
const LABEL_SCALE := 0.25
const ICON_HEIGHT := 36.0
## 图标与数字的间隙（本地像素，视觉值 ×0.25）：观感微调入口——
## 0=紧贴，正值留缝（3～4 明显拉开），负值轻微压叠（用户定稿 -2；
## stretch SCALE 填满修复后此旋钮才真正生效）
const ICON_LABEL_GAP := -36.0
const LABEL_ICON_OFFSET := ICON_HEIGHT + ICON_LABEL_GAP

var delta: int = 0

## 装配显示：有符号数值（正绿负红）+ 来源图标（无则纯数值，布局不留空隙）
func setup(delta_value: int, icon_texture: Texture2D) -> void:
	delta = delta_value
	var label: Label = $Label
	label.scale = Vector2(LABEL_SCALE, LABEL_SCALE)
	var settings: LabelSettings = label.label_settings
	settings.font_color = Color(0, 1, 0.07) if delta_value > 0 else Color.html("#FF2222")
	label.text = ("+" + str(delta_value)) if delta_value > 0 else str(delta_value)
	var icon: TextureRect = $Icon
	icon.scale = Vector2(LABEL_SCALE, LABEL_SCALE)
	icon.texture = icon_texture
	icon.visible = icon_texture != null
	label.position = Vector2(LABEL_ICON_OFFSET, 0) if icon_texture != null else Vector2.ZERO
	_center_visual(label, icon)

## 视觉居中（与 score_balloon 的 rect 重锚同族修复）：icon+数字整体以
## 【节点原点】为中心排版，pivot=rect 尺寸一半（缩放轴心=rect 中心，
## 缩放不动中心）——起飞时原点即视觉中心，token 精确从来源图标中心起飞、
## 精确落入气球中心。此前 rect 自原点向右下展开且缩放轴心在 rect 左上角，
## 视觉中心吊在原点右下约 (17.5, 4.5)px，起飞/落点目测整体向右下偏离
func _center_visual(label: Control, icon: Control) -> void:
	var scaled: Vector2 = Vector2(LABEL_SCALE, LABEL_SCALE)
	if icon.visible:
		## 缩放后视觉半幅：中心 = position+size/2，半幅 = scale×size/2
		## （pivot=size/2 时缩放绕 rect 中心，中心不漂）
		var label_center: Vector2 = label.position + label.size / 2.0
		var icon_center: Vector2 = icon.position + icon.size / 2.0
		var label_half: Vector2 = scaled * label.size / 2.0
		var icon_half: Vector2 = scaled * icon.size / 2.0
		var bbox: Rect2 = Rect2(label_center - label_half, label_half * 2.0).merge(
			Rect2(icon_center - icon_half, icon_half * 2.0))
		var shift: Vector2 = -bbox.get_center()
		icon.position += shift
		label.position += shift
		icon.pivot_offset = icon.size / 2.0
	else:
		## 纯数值：文字中心即整体视觉中心
		label.position = -(label.size / 2.0)
	label.pivot_offset = label.size / 2.0

## 沿贝塞尔弧线飞向目标位（awaitable；到达即发 token_arrived）
## Godot 的 bezier_interpolate 为三次贝塞尔（起点=self，p1/p2=控制点，p3=终点）：
## 控制点重复一次即退化为二次弧线
func fly_to(target: Vector2, duration: float = FLY_DURATION, arc_height: float = FLIGHT_ARC_HEIGHT) -> void:
	var start := position
	var control := (start + target) * 0.5 + Vector2(0, -arc_height)
	var tween := create_tween()
	tween.tween_method(
		func(t: float) -> void:
			position = start.bezier_interpolate(control, control, target, t),
		0.0, 1.0, duration
	).set_trans(FLIGHT_TRANS).set_ease(FLIGHT_EASE)
	await tween.finished
	token_arrived.emit(delta)
