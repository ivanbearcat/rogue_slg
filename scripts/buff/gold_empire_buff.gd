extends Buff

func set_buff():
	# 领主BUFF不再创建UI，只做逻辑注册
	pass

func process_buff():
	# 金元帝国 - coin系≥4时激活，每有5个金币击杀获得10%的得分加成
	if BuffSystem.get_family_count("coin") < 4:
		return
	var bonus = roundi(Current.once_total_score * (Current.total_coins / 5) * 0.10)
	if bonus > 0:
		Current.total_score += bonus
		var float_number_instantiate = EffectManager.float_number_effect(bonus, "gold")
		Current.hero.add_child(float_number_instantiate)

func clear_buff():
	pass
