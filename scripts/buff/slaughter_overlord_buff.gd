extends Buff

var _move_bonus_added: bool = false

func set_buff():
	# 杀戮霸主 - 移动力+1
	if BuffSystem.get_family_count("slaughter") >= 4:
		Current.max_power += 1
		_move_bonus_added = true

func process_buff():
	# 杀戮霸主 - 杀戮惯性：杀戮系得分 × 杀戮叠层倍率
	if BuffSystem.get_family_count("slaughter") < 4:
		return
	var accumulated = BuffSystem.get_family_accumulation("slaughter")
	if accumulated <= 0:
		return
	if BuffSystem.slaughter_ramp <= 0:
		return
	var bonus = roundi(accumulated * BuffSystem.slaughter_ramp)
	if bonus > 0:
		Current.total_score += bonus
		var float_number_instantiate = EffectManager.float_number_effect(bonus, "gold")
		Current.hero.add_child(float_number_instantiate)

func clear_buff():
	# 移动力恢复-1
	if _move_bonus_added:
		Current.max_power -= 1
		_move_bonus_added = false
