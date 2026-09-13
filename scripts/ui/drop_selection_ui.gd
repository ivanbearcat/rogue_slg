extends CanvasLayer

## 掉落骰子选择界面
## 玩家从多个掉落骰子中选1个保留在掉落格子
## 已放在场景树中，通过 show/hide 控制显示
## 布局与交互对齐升级卡牌选择界面（level_up_ui）：CanvasLayer + 全屏遮罩 + 悬浮弹性放大 + eye 隐藏按钮 + 选择期间暂停

var _color_name_map := {"green": "绿", "red": "红", "blue": "蓝", "yellow": "黄"}
var _color_hex_map := {"green": "#4DCC4D", "red": "#E64D4D", "blue": "#4D80E6", "yellow": "#E6D933"}

## eye 按钮图标（显示=eye2，隐藏=eye）。preload 常量，引用稳定
const SHOW_ICON: Texture2D = preload("res://images/ui_icon/eye2.png")
const HIDE_ICON: Texture2D = preload("res://images/ui_icon/eye.png")
## 当前是否处于隐藏状态。判断状态用这个变量，不要比较纹理资源对象
var _hidden := false

@onready var dice_container: HBoxContainer = $dice_container
@onready var title_label: Label = $title_label
@onready var background: ColorRect = $background
@onready var hide_drop_ui_button: TextureButton = $hide_drop_ui_button

func _ready() -> void:
	hide_drop_ui_button.pressed.connect(_on_hide_drop_ui_button_pressed)

func setup(dropped_dice: Array):
	## 清空容器
	for child in dice_container.get_children():
		child.queue_free()
	## 为每个掉落骰子创建可点击选项（96x96 裸骰子图标 + 文字tooltip）
	for dice in dropped_dice:
		var button = TextureButton.new()
		button.texture_normal = load("res://images/ui_icon/dice_%s_%d.tres" % [dice[0], dice[1]])
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = Vector2(96, 96)
		## 重置悬浮残留（连续两次弹出时可能残留上一轮 scale）
		button.scale = Vector2.ONE
		var color_name: String = _color_name_map.get(dice[0], "?")
		TooltipManager.set_tooltip(button, "[b][color=%s]%s[/color][/b] [b]%s点[/b]" % [_color_hex_map.get(dice[0], "#ffffff"), color_name, str(dice[1])])
		button.pressed.connect(_on_dice_selected.bind(dice))
		button.mouse_entered.connect(_on_dice_option_mouse_entered.bind(button))
		button.mouse_exited.connect(_on_dice_option_mouse_exited.bind(button))
		dice_container.add_child(button)
	## 重置 eye 为显示态
	_hidden = false
	hide_drop_ui_button.texture_normal = SHOW_ICON
	background.visible = true
	title_label.visible = true
	dice_container.visible = true
	## 显示界面并暂停游戏树（本节点 process_mode = ALWAYS，暂停期间悬浮/点击可交互）
	visible = true
	get_tree().paused = true

func _on_dice_selected(dice: Array):
	## 将选择结果存储到Current的meta中
	Current.set_meta("drop_selection_result", dice)
	## 解除锁定
	Current.public_lock_array.erase("drop_selection")
	## 隐藏界面
	visible = false
	## 取消暂停（收尾四步在同一函数完成：写 meta、erase 锁、隐藏、取消暂停）
	get_tree().paused = false

## 悬浮选项：居中弹性放大（带过冲回弹），参数与卡牌悬浮一致
func _on_dice_option_mouse_entered(option: TextureButton) -> void:
	_kill_option_hover_tween(option)
	option.pivot_offset = option.size / 2.0
	## 提升绘制层级盖住邻选项；不能 move_to_front()——会重排 HBoxContainer 子节点顺序导致选项互换
	option.z_index = 1
	var tween: Tween = option.create_tween()
	tween.tween_property(option, "scale", Vector2(1.1, 1.1), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	option.set_meta("hover_tween", tween)

## 移出选项：弹性弹回原尺寸
func _on_dice_option_mouse_exited(option: TextureButton) -> void:
	_kill_option_hover_tween(option)
	option.z_index = 0
	var tween: Tween = option.create_tween()
	tween.tween_property(option, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	option.set_meta("hover_tween", tween)

## 结束该选项上一段悬浮动画，避免连续进出时叠加冲突
func _kill_option_hover_tween(option: TextureButton) -> void:
	if option.has_meta("hover_tween"):
		var old_tween: Variant = option.get_meta("hover_tween")
		if old_tween is Tween and (old_tween as Tween).is_valid():
			(old_tween as Tween).kill()

func _on_hide_drop_ui_button_pressed() -> void:
	## 翻转状态，图标跟随状态设置（Resource 的 == 是引用比较，不能用来判断图标种类）
	## 隐藏只是偷看棋盘，不结束选择、不解锁
	_hidden = not _hidden
	background.visible = not _hidden
	title_label.visible = not _hidden
	dice_container.visible = not _hidden
	hide_drop_ui_button.texture_normal = HIDE_ICON if _hidden else SHOW_ICON
