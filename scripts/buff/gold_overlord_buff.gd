extends Buff

func set_buff():
	# 金元帝国：创建自身图标（购买激活与读档重建共用此路径）
	_setup_overlord_icon()

func process_buff():
	# 金元帝国 - coin系≥4时激活，每有5个金币击杀获得1%的得分加成
	if BuffSystem.get_family_count("coin") < 4:
		return
	var bonus = roundi(Current.once_total_score * (Current.total_coins / 5) * 0.01)
	if bonus > 0:
		Current.total_score += bonus
		var float_number_instantiate = EffectManager.float_number_effect(bonus)
		Current.hero.add_child(float_number_instantiate)
		# 首次获得触发闪光：仅闪霸主自身图标（原先无任何触发视觉反馈）
		flash_icon()

func clear_buff():
	pass
