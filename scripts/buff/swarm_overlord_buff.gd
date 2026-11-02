extends Buff

func set_buff():
	# 潮涌霸主：创建自身图标（购买激活与读档重建共用此路径）
	_setup_overlord_icon()

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
		# 触发闪光：仅闪霸主自身图标（不再联动闪烁同族）
		flash_icon()

func clear_buff():
	pass
