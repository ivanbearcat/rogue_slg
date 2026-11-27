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
## 图标/数字排版（像素风缩放 0.25；图标等比贴 36 格包络，与 36 号数字同档；
## 数字左对齐贴墨迹右缘，见 setup）
const LABEL_SCALE := 0.25
## 图标显示包络：墨迹等比缩放的最长边（rect == 墨迹本体，无拉伸变形）。
## 曾为"裁剪内容非等比拉满 36×36"——方形 BUFF 素材近似等比故成立，
## double_score 16×25 瘦高内容被横向拉 2.25×，图标墨迹顶死数字（owner 反馈
## "间隔不统一 / 挤在一起"根因），改为等比 contain 后间隔与素材形状无关
const ICON_HEIGHT := 36.0
## 图标墨迹右缘 → 数字墨迹左缘的**渲染**间隔（像素）：3.2 目测定稿 +2.0
## （owner 反馈压叠观感偏挤，自 5.3 的 -0.25 放开为留缝）。setup 按渲染投影
## 解出 label 位置（label 缩放绕 rect 中心 pivot=size/2，墨迹左缘随文本宽以
## (1-scale)/2 斜率漂移；icon 渲染右缘随图标宽以 (1+scale)/2 斜率漂移——
## 锚定补偿两个斜率后，间隔对任何图标形状 / 数字位数恒定，观感微调改此
## 常量即可：正值留缝 / 负值压叠）
const ICON_LABEL_INK_GAP := 2.0

## ── 出生弹起段（double-score-token-pop，design D4，任务 3.2 目测定稿入口）──
## 3.2 定稿动线（owner 拍板）：上抛 40px（顶点越过气球）→ 自顶点加速下落，
## 从气球文字上沿直接落入气球——单驼峰，无回落出生位的二次反弹。
## POP_HEIGHT：上抛高度；POP_UP_DURATION：上抛时长；POP_FALL_DURATION：落入时长
const POP_HEIGHT := 30.0
const POP_UP_DURATION := 0.25
const POP_FALL_DURATION := 0.15

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
	if icon_texture != null:
		## 图标 rect == 裁剪后墨迹的等比缩放（contain 贴 36 格，不拉宽变形）。
		## 数字左缘按渲染投影锚定：label 渲染墨迹左缘 = P_l + (1-scale)×文本宽/2
		## （pivot=size/2 随文本自动加宽漂移），icon 渲染墨迹右缘 =
		## P_i + (1+scale)×图标宽/2——解出 Δ 使渲染间隔恒等于
		## ICON_LABEL_INK_GAP（对任何图标形状 / 数字位数恒定；
		## hunt 36×36 + "+35" 代入 Δ=-1.0，与 5.3 调定值逐位一致）
		var ink := icon_texture.get_size()
		var fit := minf(ICON_HEIGHT / ink.x, ICON_HEIGHT / ink.y) if ink.x > 0.0 and ink.y > 0.0 else 1.0
		icon.size = ink * fit
		var text_w: float = settings.font.get_string_size(
			label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, settings.font_size).x
		label.position.x = (1.0 + LABEL_SCALE) * icon.size.x * 0.5 \
			- (1.0 - LABEL_SCALE) * text_w * 0.5 + ICON_LABEL_INK_GAP
	else:
		label.position = Vector2.ZERO
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

## 出生弹起并直接落入气球（fire-and-forget 入口）：编排器不 await 本方法，
## 错峰发射循环零阻塞——弹起为 token 自身动画，其他 token 发射节奏零影响
##（spec「弹起不影响其他 token」场景）。
## 动线（3.2 目测定稿）：出生位上抛 POP_HEIGHT（顶点越过气球，QUAD EASE_OUT
## 减速升顶）→ 自顶点 QUAD EASE_IN 加速下落直达气球中心——近竖直下落自然从
## 气球文字上沿进入（顶点在气球正上方），单驼峰无二次反弹；
## 终点 = 气球中心，到达即发 token_arrived（absorb/音阶口径不变，design D6）
func birth_pop_then_fly(target: Vector2) -> void:
	var apex := position + Vector2(0, -POP_HEIGHT)
	var tween := create_tween()
	tween.tween_property(self, "position", apex, POP_UP_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target, POP_FALL_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	position = target
	token_arrived.emit(delta)
