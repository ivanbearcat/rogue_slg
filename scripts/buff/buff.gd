extends Node2D
class_name Buff

var game_manager: Node2D
var buff_meta: Dictionary
var buff_texture: PanelContainer  # 改为PanelContainer（rich_tooltip.gd）
var debuff_texture: PanelContainer  # 同上
var data: Dictionary

## 家族：swarm/coin/resonance/desperation/vitality/hunt/swift/evolution
var family: String
## 标签数组
var tags: Array

## 安全移除 debuff 图标节点：
## 节点可能已被场景切换或重复清理所释放，直接 queue_free 会报
## "Cannot call method 'queue_free' on a previously freed instance"。
func clear_debuff_texture() -> void:
	if debuff_texture != null and is_instance_valid(debuff_texture):
		debuff_texture.queue_free()
	debuff_texture = null

func _init(meta: Dictionary = {}, game_manager_node: Node2D = null) -> void:
	buff_meta = meta
	game_manager = game_manager_node
	family = meta.get("family", "")
	tags = meta.get("tags", [])

func set_buff():
	pass

func process_buff():
	pass

func clear_buff():
	pass

## ============================================================
## 存档钩子（读档重建路径专用，由 BuffSystem.rebuild_from_save 调用）
## ============================================================
## 次序约定：实例化 → 注册（set_buff 挂图标/tooltip）→ restore_state()。
## 仅持有跨回合实例本地状态的 buff 需覆写；默认空实现 = 无可存状态。
## 每回合瞬态的实例状态不存（读档天然重置，语义等价）。

## 返回需跨回合保留的实例本地状态（只存本地字段，不存 Current 全局状态）
func save_state() -> Dictionary:
	return {}

## 从快照行恢复实例本地状态（state 为 save_state() 的返回值）
func restore_state(state: Dictionary) -> void:
	pass

## 关卡结算时由 game_manager 委托调用（非管线调用），默认空
func process_stage_clear():
	pass

## 子类覆写以提供 hover 时动态追加的 BBCode 文本，默认空
func _get_tooltip_extra() -> String:
	return ""
