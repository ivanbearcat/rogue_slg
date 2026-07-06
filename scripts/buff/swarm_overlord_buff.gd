extends Buff

func set_buff():
	# 领主BUFF不再创建UI，只做逻辑注册
	pass

func process_buff():
	# 潮涌霸主 - 数量压制：每有1个史莱姆存活，潮涌系得分3%/只
	if BuffSystem.get_family_count("swarm") < 4:
		return
	var slime_count = 0
	for _slime in Current.all_enemy_array:
		if is_instance_valid(_slime):
			slime_count += 1
	if slime_count <= 0:
		return
	var bonus = roundi(Current.once_total_score * slime_count * 0.03)
	if bonus > 0:
		Current.total_score += bonus
		var float_number_instantiate = EffectManager.float_number_effect(bonus)
		Current.hero.add_child(float_number_instantiate)
		var family_buffs = BuffSystem.get_family_buffs("swarm")
		for fb in family_buffs:
			if fb.buff_texture:
				EffectManager.buff_pop_effect(fb.buff_texture)

func clear_buff():
	pass
