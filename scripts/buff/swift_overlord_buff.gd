extends Buff

var _move_bonus_added: bool = false

func set_buff():
	# 疾风霸主 - 移动力+1
	if BuffSystem.get_family_count("swift") >= 4:
		Current.max_power += 1
		_move_bonus_added = true

func process_buff():
	# 疾风霸主 - 每移动1格+5%得分
	if BuffSystem.get_family_count("swift") < 4:
		return
	var moved = Current.grids_moved_this_turn
	if moved <= 0:
		return
	var bonus = int(Current.once_total_score * moved * 0.05)
	if bonus > 0:
		Current.total_score += bonus
		var float_number_instantiate = EffectManager.float_number_effect(bonus, "gold")
		Current.hero.add_child(float_number_instantiate)

func clear_buff():
	# 移动力恢复-1
	if _move_bonus_added:
		Current.max_power -= 1
		_move_bonus_added = false
