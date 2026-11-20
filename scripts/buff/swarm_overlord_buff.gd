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
		## 申报制迁移：数值即时生效，播报由 token 承载
		Current.total_score += bonus
		BuffSystem.declare_score_contribution(bonus)

func clear_buff():
	pass
