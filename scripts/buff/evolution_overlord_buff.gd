extends Buff

func set_buff():
	# 领主BUFF不再创建UI，只做逻辑注册
	pass

func process_buff():
	# 进化霸主 - 进化系≥4时：每回合随机基础分+1 + 随机倍率+1%
	if BuffSystem.get_family_count("evolution") < 4:
		return
	# 随机基础分+1
	var _rand_num = randi_range(1, 6)
	match _rand_num:
		1: Current.one_score += 1
		2: Current.two_score += 1
		3: Current.three_score += 1
		4: Current.four_score += 1
		5: Current.five_score += 1
		6: Current.six_score += 1
	# 随机倍率+1%
	var _dice_types = ["duizi", "shunzi", "tongse", "tongdui", "tongshun"]
	var _rand_type = _dice_types[randi_range(0, 4)]
	match _rand_type:
		"duizi": Current.duizi_percent += 1; game_manager._update_multiplier_dict("duizi_percent", "add", 1)
		"shunzi": Current.shunzi_percent += 1; game_manager._update_multiplier_dict("shunzi_percent", "add", 1)
		"tongse": Current.tongse_percent += 1; game_manager._update_multiplier_dict("tongse_percent", "add", 1)
		"tongdui": Current.tongdui_percent += 1; game_manager._update_multiplier_dict("tongdui_percent", "add", 1)
		"tongshun": Current.tongshun_percent += 1; game_manager._update_multiplier_dict("tongshun_percent", "add", 1)

func clear_buff():
	pass
