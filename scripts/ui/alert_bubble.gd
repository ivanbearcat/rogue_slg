extends Control

## ⚠ 本脚本挂载在 alert_ui 下的 alert_box（Control）上——不要把它挂到
## alert_ui（CanvasLayer）上、也不要改 extends 为 CanvasLayer：
## 弹出动画的 scale/pivot/收放、鼠标定位用的 size/global_position/
## get_global_mouse_position() 都是 Control 专属成员，CanvasLayer 没有。
## alert_ui 只负责开独立层（layer=101）压过 SkillTooltipPopup。

## 通用 UI 提示气泡（挂 main.tscn 现有 alert_ui 节点，design D1）
## EventBus "ui_alert" 事件驱动（design D2）：event_emit("ui_alert", [text, at_mouse?])
## 动画：kill-and-restart 复播 + BACK/EASE_OUT 过冲弹出 → 停顿 → QUAD/EASE_IN 收回（design D3）
## emit_signal 经 callv 转发，payload 尾参可省（长度 1 时 at_mouse 走默认值 false），
## 文案不做预注册：alert_label.text = text 即显示路径

## 弹出段时长（秒）
const POP_TIME := 0.16
## 停顿段时长（秒）
const WAIT_TIME := 0.4
## 收回段时长（秒）
const SHRINK_TIME := 0.12
## 鼠标位置与气泡底边的间距（像素）
const MOUSE_GAP := 30.0

@onready var alert_label: Label = %alert_label

## 进行中的动画（kill-and-restart 语义，对齐 _play_score_bounce 惯例）
var _tween: Tween

func _ready() -> void:
	scale = Vector2.ZERO   ## 待机不可见（弹出时 show_alert 重置为 0 再弹到 1，
						   ## 避免启动瞬间在默认位置常驻显示；也不要用 visible=false，
						   ## 编辑器会把该状态序列化导致气泡永久消失）
	EventBus.subscribe("ui_alert", show_alert)

## 弹出提示：text 为显示文案；at_mouse 为触发源定位标记（design D4）——
## true = 鼠标触发，气泡弹出在该鼠标位置上方；false/省略 = 键盘/快捷键触发，
## 气泡保持 main.tscn 中 alert_ui 已设置的位置不移动
func show_alert(text: String = "", at_mouse: bool = false) -> void:
	## 复播语义：终止当前动画，从头播放（连点不叠加、不互锁）
	if _tween:
		_tween.kill()
	scale = Vector2.ZERO
	alert_label.text = text
	if at_mouse:
		_place_at_mouse()
	else:
		global_position = Vector2(633, 342)
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(4, 4), POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(WAIT_TIME)
	_tween.tween_property(self, "scale", Vector2.ZERO, SHRINK_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

## 鼠标位置定位（design D4）：读取触发瞬间的鼠标全局坐标，
## 气泡底边中心贴到鼠标点上方 MOUSE_GAP；直写 global_position 单次生效，
## 弹出期间不跟随鼠标（对齐 tooltip"显示期间位置固定"惯例）；
## pivot 为中心（pivot_offset_ratio 0.5,0.5），scale=1 时底边中心在 global_position + size
func _place_at_mouse() -> void:
	var mouse_pos := get_global_mouse_position()
	global_position = mouse_pos - Vector2(size.x * 0.0, size.y + MOUSE_GAP)
