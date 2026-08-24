extends HBoxContainer

## 心形血条控件：显示当前HP/max_hp的心形图标

## 心形图标（用TextureRect实现）
const HEART_SIZE := Vector2(8, 8)
const HEART_FULL := preload("res://images/ui_icon/heart2.png")
const HEART_EMPTY := preload("res://images/ui_icon/empty_heart2.png")

## 当前心形节点数组
var _heart_nodes: Array = []

func _ready():
	## 初始创建心形
	update_hearts(Current._player_hp, Current._max_hp)

## 更新心形显示
func update_hearts(hp: int, max_hp: int) -> void:
	## 清除旧的心形
	for child in get_children():
		child.queue_free()
	_heart_nodes.clear()

	## 创建新心形
	for i in range(max_hp):
		var heart = TextureRect.new()
		heart.custom_minimum_size = HEART_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		if i < hp:
			## 填充心形 - 红色
			heart.texture = HEART_FULL
		else:
			## 空心形 - 描边
			heart.texture = HEART_EMPTY

		add_child(heart)
		_heart_nodes.append(heart)

## 扣血视觉反馈：红色闪烁/抖动
func play_damage_effect() -> void:
	## 抖动效果
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(2, 0), 0.05)
	tween.tween_property(self, "position", position + Vector2(-2, 0), 0.05)
	tween.tween_property(self, "position", position + Vector2(1, 0), 0.05)
	tween.tween_property(self, "position", position, 0.05)

	## 红色闪烁
	modulate = Color(1.0, 0.3, 0.3)
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1), 0.3)

## 回血视觉反馈：绿色发光
func play_heal_effect() -> void:
	modulate = Color(0.3, 1.0, 0.3)
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1), 0.4)
