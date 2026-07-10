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
	var _score_name = ""
	match _rand_num:
		1: Current.one_score += 1; _score_name = "一点"
		2: Current.two_score += 1; _score_name = "二点"
		3: Current.three_score += 1; _score_name = "三点"
		4: Current.four_score += 1; _score_name = "四点"
		5: Current.five_score += 1; _score_name = "五点"
		6: Current.six_score += 1; _score_name = "六点"
	# 随机倍率+1%
	var _dice_types = ["duizi", "shunzi", "tongse", "tongdui", "tongshun"]
	var _rand_type = _dice_types[randi_range(0, 4)]
	var _type_name = ""
	match _rand_type:
		"duizi": Current.duizi_percent += 1; game_manager._update_multiplier_dict("duizi_percent", "add", 1); _type_name = "对子"
		"shunzi": Current.shunzi_percent += 1; game_manager._update_multiplier_dict("shunzi_percent", "add", 1); _type_name = "顺子"
		"tongse": Current.tongse_percent += 1; game_manager._update_multiplier_dict("tongse_percent", "add", 1); _type_name = "同色"
		"tongdui": Current.tongdui_percent += 1; game_manager._update_multiplier_dict("tongdui_percent", "add", 1); _type_name = "同对"
		"tongshun": Current.tongshun_percent += 1; game_manager._update_multiplier_dict("tongshun_percent", "add", 1); _type_name = "同顺"
	# 视觉反馈：浮动数字显示进化效果（+1基础分 +1%倍率）
	var float_number_instantiate = EffectManager.float_number_effect(1)
	Current.hero.add_child(float_number_instantiate)
	# 同族图标联动闪烁
	var family_buffs = BuffSystem.get_family_buffs("evolution")
	for fb in family_buffs:
		if fb.buff_texture:
			EffectManager.buff_pop_effect(fb.buff_texture)

func clear_buff():
	pass
