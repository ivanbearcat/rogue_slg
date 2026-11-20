extends Node2D
## 得分汇总气球（post-attack-score-balloon，design D3）
## 出生悬停英雄头顶、种子为骰型得分（不带骰型名称标签）；token 落入时数字滚动
## （约 0.25s 缓动）+ 弹跳脉冲（约 +15% 回弹）；字号按累计值位数分档且有封顶；
## 定格 0.5s 后划弧线飞向计分板总分位置，到达发 balloon_arrived（入账时刻由
## 编排器侧解除静默 + 显示同步 + 一次脉冲）。生命周期由编排器管理。

## 到达计分板回调：total 为气球累计显示值（本次攻击总增量的演出口径）
signal balloon_arrived(total: int)

## 观感校准常量（任务 5.3 目测定稿后回写；对齐 6.3 惯例集中放头部）
const ABSORB_ROLL_DURATION := 0.25
const ABSORB_PULSE_SCALE := 1.15
const ABSORB_PULSE_DURATION := 0.18
const FREEZE_DURATION := 0.25
const FLY_TO_BOARD_DURATION := 0.4
const FLY_TO_BOARD_ARC := 40.0
## 位数分档字号（5.3 目测定稿：初始档经观感校准整体减半；
## 3 位 24 / 4 位 28 / 5 位 32 / 6 位及以上 36 封顶；1-2 位取最低档基线，
## 分档只升不降——"这波多大"信号保留，整体视觉规模贴合英雄体型）
const DIGIT_TIERS := [[3, 24], [4, 28], [5, 32], [6, 36]]
const FONT_SIZE_FLOOR := 18
## 描边粗细（5.3 定稿：shadow → outline）：字号一半、封顶 12
## （观感微调：改此上限或 _render_font_size 内的公式）
const OUTLINE_MAX := 10
## 气球排版（像素风大字号 + 0.5 缩放，观感：48-72px 档 → 24-36px 有效字高）
const LABEL_SCALE := 0.5
const COLOR_POS := Color(0, 1, 0.07)
const COLOR_NEG := Color(1.0, 2.0 / 15.0, 2.0 / 15.0)

## 当前累计显示值（种子 + 已吸收 token 之和）
var total: int = 0

var _roll_tween: Tween = null
var _pulse_tween: Tween = null

## 出生：种子为骰型得分（无骰型名称标签，纯数值）
func setup(seed: int, world_position: Vector2) -> void:
	total = seed
	position = world_position
	var label: Label = $Label
	label.scale = Vector2(LABEL_SCALE, LABEL_SCALE)
	label.pivot_offset = _label_pivot()
	_render()

## token 落入：数字滚动到新累计 + 一次弹跳脉冲（不阻塞——滚动重叠时重定目标）
func absorb(delta: int) -> void:
	var target := total + delta
	var from := total
	if _roll_tween:
		_roll_tween.kill()
	_roll_tween = create_tween()
	_roll_tween.tween_method(
		func(t: float) -> void:
			total = int(lerpf(from, target, t))
			_render_value(),
		0.0, 1.0, ABSORB_ROLL_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	## 滚动完成：累计值精确落定 + 位数分档字号重算（spec「位数分档与封顶」——
	## 档位随累计值增长，避免滚动过程中的字号抖动）
	_roll_tween.tween_callback(func() -> void:
		total = target
		_render())
	## 弹跳脉冲独立叠加（"这波多大"与"刚落袋这一下"双通道，见 design D3）
	if _pulse_tween:
		_pulse_tween.kill()
		$Label.scale = Vector2(LABEL_SCALE, LABEL_SCALE)
	_pulse_tween = create_tween()
	_pulse_tween.tween_property($Label, "scale", Vector2(LABEL_SCALE * ABSORB_PULSE_SCALE, LABEL_SCALE * ABSORB_PULSE_SCALE), ABSORB_PULSE_DURATION * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property($Label, "scale", Vector2(LABEL_SCALE, LABEL_SCALE), ABSORB_PULSE_DURATION * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

## 全部 token 到达后：定格悬停片刻，随后划弧线飞向计分板（awaitable）
func freeze_and_fly_to(target_position: Vector2) -> void:
	await get_tree().create_timer(FREEZE_DURATION).timeout
	## 起飞前终态重锚（滚动/升档后的撑大在定格窗口内早已尘埃落定）
	_center_label()
	## 落点自适配：目标语义 =【文字渲染中心】的落点（玩家所见即所落），
	## 换算节点终点 = 目标 −（文字中心 − 节点位置）。即便未来 rect 再漂移，
	## 文字中心仍精确落在目标上
	var label: Label = $Label
	var drift: Vector2 = label.get_global_rect().get_center() - global_position
	var end: Vector2 = target_position - drift
	var start := position
	var control := (start + end) * 0.5 + Vector2(0, -FLY_TO_BOARD_ARC)
	var tween := create_tween()
	tween.tween_method(
		func(t: float) -> void:
			position = start.bezier_interpolate(control, control, end, t),
		0.0, 1.0, FLY_TO_BOARD_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	balloon_arrived.emit(total)

## ---------- 渲染 ----------

func _render() -> void:
	_render_value()
	_render_font_size()

## 数值文本：正绿（带 + 号）负红；种子 0 显示 "+0"（攻击未得分也走完入账节奏）
func _render_value() -> void:
	var label: Label = $Label
	label.label_settings.font_color = COLOR_POS if total >= 0 else COLOR_NEG
	label.text = ("+" + str(total)) if total >= 0 else str(total)
	_center_label()

## 位数分档字号：达到最高档后保持封顶不再增大
## （描边随字号档动态：outline = font_size/2，封顶 OUTLINE_MAX——
## 涨档时边框跟随"这波多大"的信号变粗）
func _render_font_size() -> void:
	var digits := str(absi(total)).length()
	var size := FONT_SIZE_FLOOR
	for tier in DIGIT_TIERS:
		if digits >= tier[0]:
			size = tier[1]
	var settings: LabelSettings = $Label.label_settings
	settings.font_size = size
	settings.outline_size = mini(int(size / 2.0), OUTLINE_MAX)
	_center_label()

## rect 重锚（防御性收尾）：Label 的 rect 会被文字/字号的最小尺寸撑大
## （位数变长/字号升档时 Godot 保持 offset 左上锚定扩右下缘），rect 中心
## 随文字漂移、pivot 也不再是 rect 中心——每次渲染后把 rect 重新以节点
## 居中并让缩放轴心跟随 rect 当前中心，保证「文字渲染中心 == 节点位置」
## 恒成立（头顶取位与计分板落点皆以此为口径）
func _center_label() -> void:
	var label: Label = $Label
	var s: Vector2 = label.size
	label.offset_left = -s.x / 2.0
	label.offset_top = -s.y / 2.0
	label.offset_right = s.x / 2.0
	label.offset_bottom = s.y / 2.0
	label.pivot_offset = s / 2.0

## Label 缩放轴心：pivot_offset 相对【rect 左上角】而非节点原点——
## rect 本地 [-80,-12]..[80,12]（以节点原点居中）时,轴心须取 rect 尺寸一半
## (80,12) 才落在节点原点上。此前误算成 (0,0)=rect 左上角,0.5 缩放以左上角
## 为轴 → rect 塌成 [-160,0]（右下缘贴节点）,文字中心吊在节点左上 (−40,−6):
## 目测上"头顶偏左 40px"（已用 BALLOON_HERO_X_OFFSET=40 补偿）与
## "落点落在数字左侧 40px"（观感反馈落点不对）皆源于此。
## 现由 _center_label 动态维护（rect 撑大时轴心跟随）
func _label_pivot() -> Vector2:
	var label: Label = $Label
	return Vector2(label.offset_right - label.offset_left, label.offset_bottom - label.offset_top) / 2.0
