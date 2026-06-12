extends Buff

var _move_bonus_added: bool = false

func set_buff():
	# 连击霸主 - 移动力+1
	if BuffSystem.get_family_count("combo") >= 4:
		Current.max_power += 1
		_move_bonus_added = true

func process_buff():
	# 连击霸主 - 连击惯性：连击系得分 × 连击叠层倍率
	if BuffSystem.get_family_count("combo") < 4:
		return
	var accumulated = BuffSystem.get_family_accumulation("combo")
	if accumulated <= 0:
		return
	if BuffSystem.combo_ramp <= 0:
		return
	var bonus = roundi(accumulated * BuffSystem.combo_ramp)
	if bonus > 0:
		Current.total_score += bonus
		var float_number_instantiate = EffectManager.float_number_effect(bonus, "gold")
		Current.hero.add_child(float_number_instantiate)

func clear_buff():
	# 移动力恢复-1
	if _move_bonus_added:
		Current.max_power -= 1
		_move_bonus_added = false
