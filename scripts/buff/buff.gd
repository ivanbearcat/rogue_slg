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
## 霸主图标共享逻辑（由各 overlord 脚本的 set_buff() 调用）
## ============================================================

## 霸主凑齐自动注册时创建自身图标并挂入 BUFF 栏。
## 购买自动注册与读档 rebuild_from_save 都经由 set_buff()，一处实现两路自动生效。
## 幂等防重入：buff_texture 已有效时直接返回，防 set_buff 被重复触发后重建图标。
func _setup_overlord_icon() -> void:
	if buff_texture != null and is_instance_valid(buff_texture):
		return
	## 无图标配置时跳过（mock 测试 meta 可能没有 buff_icon，不创建不报错）
	if not buff_meta.has("buff_icon"):
		return
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	## manager 的 meta 盖章块执行于霸主自动注册块之前，不会覆盖到霸主 → 霸主自盖 meta
	buff_texture.set_meta("buff_meta", buff_meta)
	buff_texture.set_meta("buff_instance", self)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))
	## 常驻家族色轮廓呼吸光（沿 sprite alpha 轮廓的细发光线，shader TIME 驱动，α 0.25↔0.80 周期1.5s）。
	## 绘制发生在 sprite 画布透明区域，不占任何布局 margin：图标总 footprint 与普通图标一致，
	## sprite 保持满铺（用户反馈：方形硬边框/方形底板观感差 → 轮廓描边光）
	buff_texture._start_outline_glow(Color(TooltipFormatter.FAMILY_COLORS[family]))
	## 入场庆祝：浮现瞬间亮闪一次（不 await，同步 set_buff 内一次驱动，不阻塞购买流程）
	EffectManager.buff_pop_effect(buff_texture)

## 霸主触发闪光：仅闪自身图标（替代旧"同族联动闪烁"契约）
func flash_icon() -> void:
	if buff_texture != null and is_instance_valid(buff_texture):
		EffectManager.buff_pop_effect(buff_texture)

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
