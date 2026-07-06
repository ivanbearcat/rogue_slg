extends Buff

func set_buff():
	# 领主BUFF不再创建UI，只做逻辑注册
	pass

func process_buff():
	## 共鸣霸主 - 永久ramp延迟应用：需要共鸣系≥4才激活
	if BuffSystem.get_family_count("resonance") < 4:
		return
	if BuffSystem.resonance_ramp <= 0.0:
		return
	var bonus = roundi(Current.once_total_score * BuffSystem.resonance_ramp)
	if bonus > 0:
		Current.public_lock_array.append("resonance_overlord_buff")
		Current.total_score += bonus
		var float_number_instantiate = EffectManager.float_number_effect(bonus)
		Current.hero.add_child(float_number_instantiate)
		Current.public_lock_array.erase("resonance_overlord_buff")
		var family_buffs = BuffSystem.get_family_buffs("resonance")
		for fb in family_buffs:
			if fb.buff_texture:
				EffectManager.buff_pop_effect(fb.buff_texture)

func clear_buff():
	pass
