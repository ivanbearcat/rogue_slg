extends Buff

func set_buff():
	# 共鸣霸主：创建自身图标（购买激活与读档重建共用此路径）
	_setup_overlord_icon()

func process_buff():
	## 共鸣霸主 - 永久ramp延迟应用：需要共鸣系≥4才激活
	if BuffSystem.get_family_count("resonance") < 4:
		return
	if BuffSystem.resonance_ramp <= 0.0:
		return
	var bonus = roundi(Current.once_total_score * BuffSystem.resonance_ramp)
	if bonus > 0:
		## 申报制迁移：数值即时生效，加分呈现由 token + 气球承载
		## （resonance-overlord-delayed 规格：SHALL NOT 自行弹出得分飘字）
		Current.total_score += bonus
		BuffSystem.declare_score_contribution(bonus)

func clear_buff():
	pass
