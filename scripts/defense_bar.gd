extends HBoxContainer

## 盾牌防御条控件：显示当前防御值的盾牌图标

## 盾牌图标尺寸（shield.png 实际尺寸 22x24）
const SHIELD_SIZE := Vector2(22, 24)
const SHIELD := preload("res://images/ui_icon/shield.png")

## 当前盾牌节点数组
var _shield_nodes: Array = []

func _ready():
	## 初始创建盾牌
	update_shields(Current.player_defense)

## 更新盾牌显示
func update_shields(defense: int) -> void:
	## 清除旧的盾牌
	for child in get_children():
		child.queue_free()
	_shield_nodes.clear()

	## 创建新盾牌
	for i in range(defense):
		var shield = TextureRect.new()
		shield.custom_minimum_size = SHIELD_SIZE
		shield.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		shield.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		shield.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		shield.texture = SHIELD

		add_child(shield)
		_shield_nodes.append(shield)
