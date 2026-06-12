extends Buff

func set_buff():
	# 领主BUFF不再创建UI，只做逻辑注册
	pass

func process_buff():
	# 金元帝国 - 金元洪流：获得当前金币量20%的分数，然后金币+2
	if BuffSystem.get_family_count("coin") < 4:
		return
	var bonus = roundi(Current.total_coins * 0.20)
	if bonus > 0:
		Current.total_score += bonus
		var float_number_instantiate = EffectManager.float_number_effect(bonus, "gold")
		Current.hero.add_child(float_number_instantiate)
	Current.total_coins += 2

func clear_buff():
	pass
