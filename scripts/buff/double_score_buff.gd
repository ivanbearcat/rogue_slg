extends Buff
class_name DoubleScoreBuff

## 出生弹起标记（double-score-token-pop，design D4）：双倍攻击 token 在英雄头顶
## buff 图标处弹起出生（上抛回落）再飞入气球。BuffSystem.declare_score_contribution
## 据此写入申报记录，编排器 perform 按记录分支调用弹起段
func _init(meta: Dictionary = {}, game_manager_node: Node2D = null) -> void:
	super(meta, game_manager_node)
	token_birth_pop = true

func set_buff():
	Current.hero.buff_icon.texture = preload("res://images/coin_skill_icon/double_score.png")

## 申报制改造（double-score-token-pop，design D1）：另一份得分经申报提交给结算
## 播报系统，删除英雄位置旧式无图标伤害飘字（违反 post-attack-score-balloon
## 「管线内效果不得自行弹飘字、必须申报」）。数值路径不变：total_score 仍由
## 效果自己负责直加（申报 API 只做记录 + 归属，无双写风险）
func process_buff():
	Current.public_lock_array.append("double_score")
	Current.total_score += Current.once_total_score
	BuffSystem.declare_score_contribution(Current.once_total_score)
	Current.public_lock_array.erase("double_score")

func clear_buff():
	Current.hero.buff_icon.texture = null
