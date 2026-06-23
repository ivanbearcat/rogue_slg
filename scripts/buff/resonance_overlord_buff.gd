extends Buff

func set_buff():
	# 领主BUFF不再创建UI，只做逻辑注册
	pass

func process_buff():
	# 共鸣霸主 - 共鸣叠加：共鸣系得分 × 共鸣叠层倍率
	if BuffSystem.get_family_count("resonance") < 4:
		return
	var accumulated = BuffSystem.get_family_accumulation("resonance")
	if accumulated <= 0:
		return
	if BuffSystem.resonance_ramp <= 0:
		return
	var bonus = roundi(accumulated * BuffSystem.resonance_ramp)
	if bonus > 0:
		Current.total_score += bonus
		var float_number_instantiate = EffectManager.float_number_effect(bonus)
		Current.hero.add_child(float_number_instantiate)

func clear_buff():
	pass
