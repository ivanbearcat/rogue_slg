extends Buff

func set_buff():
	# 猎杀霸主：创建自身图标（购买激活与读档重建共用此路径）
	_setup_overlord_icon()

func process_buff():
	# 猎杀霸主 - 猎杀增幅：猎杀系得分额外+15%
	if BuffSystem.get_family_count("hunt") < 4:
		return
	var accumulated = BuffSystem.get_family_accumulation("hunt")
	if accumulated <= 0:
		return
	## 申报制迁移：数值即时生效，播报由 token 承载（家族累积为申报驱动，同源数据）
	var bonus = roundi(accumulated * 0.50)
	if bonus > 0:
		Current.total_score += bonus
		BuffSystem.declare_score_contribution(bonus)

func clear_buff():
	pass
