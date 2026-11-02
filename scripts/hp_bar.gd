extends HBoxContainer

## 心形血条控件：显示当前HP/max_hp的心形图标
## 附加"掉血预告心"（slime-hud-preview）：满心区最右侧从右向左显示
## min(pending, 满心数) 颗预告心（eat_heart），预告位置即结算后的掉血位置

## 心形图标（用TextureRect实现）
const HEART_SIZE := Vector2(8, 8)
const HEART_FULL := preload("res://images/ui_icon/heart2.png")
const HEART_EMPTY := preload("res://images/ui_icon/empty_heart2.png")
## 掉血预告心贴图（红心+绿史莱姆咬心合成图；实际9x9，由8x8槽位+保持纵横比居中收敛）
const HEART_EAT := preload("res://images/ui_icon/eat_heart.png")

## 当前心形节点数组
var _heart_nodes: Array = []

## 低开销轮询缓存（design D2）：[场上有效史莱姆数, 防御值, 铁胃减伤, 当前HP, HP上限]
## 任一变化才重建贴图；初值取-1确保首帧必定刷新
var _poll_field_count := -1
var _poll_defense := -1
var _poll_iron_stomach := -1
var _poll_hp := -1
var _poll_max_hp := -1

func _ready():
	## 初始创建心形
	update_hearts(Current._player_hp, Current._max_hp)

func _process(_delta: float) -> void:
	## 低开销轮询（design D2）：场上数量/防御值/铁胃减伤/血量任一变化才重建，
	## 结算公式同口径数据由 game_manager 单一入口提供
	var field_count := _current_field_count()
	if field_count == _poll_field_count \
	and Current.player_defense == _poll_defense \
	and Current.iron_stomach_reduction == _poll_iron_stomach \
	and Current._player_hp == _poll_hp \
	and Current._max_hp == _poll_max_hp:
		return
	_poll_field_count = field_count
	_poll_defense = Current.player_defense
	_poll_iron_stomach = Current.iron_stomach_reduction
	_poll_hp = Current._player_hp
	_poll_max_hp = Current._max_hp
	update_hearts(Current._player_hp, Current._max_hp, _current_pending())

## 更新心形显示
## pending：掉血预告（"若当前时刻立即结算将扣除的血量"），默认0保持既有调用兼容
func update_hearts(hp: int, max_hp: int, pending: int = 0) -> void:
	## 清除旧的心形
	for child in get_children():
		child.queue_free()
	_heart_nodes.clear()

	## 预告心数量收敛到当前满心数（design D4，临近死亡不假装咬第6颗）
	var pending_display := clampi(pending, 0, maxi(hp, 0))

	## 创建新心形
	for i in range(max_hp):
		var heart = TextureRect.new()
		heart.custom_minimum_size = HEART_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		if i >= hp:
			## 空心形 - 描边
			heart.texture = HEART_EMPTY
		elif i >= hp - pending_display:
			## 掉血预告心 - 满心区最右侧从右向左替换，预告空间位置=结算后掉血位置
			heart.texture = HEART_EAT
		else:
			## 填充心形 - 红色
			heart.texture = HEART_FULL

		add_child(heart)
		_heart_nodes.append(heart)

## 场上有效史莱姆数（与结算同口径，经 game_manager 单一入口；切景/读档期间安全回退0）
func _current_field_count() -> int:
	var gm: Node = Current.game_manager
	if is_instance_valid(gm) and gm.has_method("_get_field_slime_count"):
		return gm._get_field_slime_count()
	return 0

## 当前三件套预告血量（design D1 单一预览入口经 game_manager 提供同口径结果）
func _current_pending() -> int:
	var gm: Node = Current.game_manager
	if is_instance_valid(gm) and gm.has_method("_get_pending_hp_damage"):
		return gm._get_pending_hp_damage()
	return 0

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
