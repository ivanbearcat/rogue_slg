extends TextureRect

## 场上史莱姆数量徽章：little_slime 图标 + 数字
## 统计口径与扣血结算完全一致（design D1/D2）：仅统计已入树的
## 场上史莱姆，预测告史莱姆（出生告警标记，未入树）天然不计入

@onready var count_label: Label = $slime_count

## 轮询缓存（design D2）：有效数量变化才写文本；初值-1确保首帧必定刷新
var _cached_count := -1

func _ready() -> void:
	refresh()

func _process(_delta: float) -> void:
	## 低开销轮询：击杀入口分散（攻击/技能/金币技能/机制连锁），
	## 轮询兜底覆盖 queue_free 延迟一帧的死亡时序
	var count := _field_count()
	if count != _cached_count:
		_cached_count = count
		count_label.text = str(count)

## 回合开始/读档恢复的显式刷新钩子（game_manager._refresh_hud_preview 调用）
func refresh() -> void:
	_cached_count = _field_count()
	count_label.text = str(_cached_count)

## 场上有效史莱姆数（与 _get_pending_hp_damage 同口径，经 game_manager 单一入口；
## 读档/切景期间 game_manager 引用缺失时安全回退0）
func _field_count() -> int:
	var gm: Node = Current.game_manager
	if is_instance_valid(gm) and gm.has_method("_get_field_slime_count"):
		return gm._get_field_slime_count()
	return 0
