extends Buff

func set_buff():
	# 领主BUFF不再创建UI，只做逻辑注册
	pass

func process_buff():
	# 猎杀霸主 - 猎杀增幅：猎杀系得分额外+15%
	if BuffSystem.get_family_count("hunt") < 4:
		return
	var accumulated = BuffSystem.get_family_accumulation("hunt")
	if accumulated <= 0:
		return
	var bonus = roundi(accumulated * 0.50)
	if bonus > 0:
		Current.total_score += bonus
		var float_number_instantiate = EffectManager.float_number_effect(bonus, "gold")
		Current.hero.add_child(float_number_instantiate)

func clear_buff():
	pass
