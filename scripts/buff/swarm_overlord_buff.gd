extends Buff

func set_buff():
	# 领主BUFF不再创建UI，只做逻辑注册
	pass

func process_buff():
	# 潮涌霸主 - 数量压制：每有1个存活史莱姆，蜂群系得分额外+5%
	if BuffSystem.get_family_count("swarm") < 4:
		return
	var accumulated = BuffSystem.get_family_accumulation("swarm")
	if accumulated <= 0:
		return
	var slime_count = 0
	for _slime in Current.all_enemy_array:
		if is_instance_valid(_slime):
			slime_count += 1
	var bonus = roundi(accumulated * slime_count * 0.05)
	if bonus > 0:
		Current.total_score += bonus
		var float_number_instantiate = EffectManager.float_number_effect(bonus, "gold")
		Current.hero.add_child(float_number_instantiate)

func clear_buff():
	pass
