extends Control

## 掉落骰子选择界面
## 玩家从多个掉落骰子中选1个保留在掉落格子
## 已放在场景树中，通过 show/hide 控制显示

var _color_name_map := {"green": "绿", "red": "红", "blue": "蓝", "yellow": "黄"}
var _color_hex_map := {"green": "#4DCC4D", "red": "#E64D4D", "blue": "#4D80E6", "yellow": "#E6D933"}

@onready var dice_container: HBoxContainer = $panel/vbox/dice_container

func setup(dropped_dice: Array):
	## 清空容器
	for child in dice_container.get_children():
		child.queue_free()
	## 为每个掉落骰子创建可点击选项（图片骰子图标 + 文字tooltip）
	for dice in dropped_dice:
		var button = Button.new()
		button.custom_minimum_size = Vector2(48, 48)
		button.text = ""
		button.icon = load("res://images/ui_icon/dice_%s_%d.tres" % [dice[0], dice[1]])
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var color_name: String = _color_name_map.get(dice[0], "?")
		TooltipManager.set_tooltip(button, "[b][color=%s]%s[/color][/b] [b]%s点[/b]" % [_color_hex_map.get(dice[0], "#ffffff"), color_name, str(dice[1])])
		button.pressed.connect(_on_dice_selected.bind(dice))
		dice_container.add_child(button)
	## 显示界面
	visible = true

func _on_dice_selected(dice: Array):
	## 将选择结果存储到Current的meta中
	Current.set_meta("drop_selection_result", dice)
	## 解除锁定
	Current.public_lock_array.erase("drop_selection")
	## 隐藏界面
	visible = false
