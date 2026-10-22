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
		var float_number_instantiate = EffectManager.float_number_effect(bonus)
		Current.hero.add_child(float_number_instantiate)
		var family_buffs = BuffSystem.get_family_buffs("swift")
		for fb in family_buffs:
			if fb.buff_texture:
				EffectManager.buff_pop_effect(fb.buff_texture)

func save_state() -> Dictionary:
	return {"_move_bonus_added": _move_bonus_added}

func restore_state(state: Dictionary) -> void:
	## set_buff() 含数值副作用（家族≥4时 max_power+1），且是否触发取决于重建时
	## 同族成员的注册次序；读档次序"先重建、后 apply()"使快照 max_power（已含加成）
	## 随后覆盖——此处仅恢复本地标记（保证 clear_buff 回滚正确）
	_move_bonus_added = bool(state.get("_move_bonus_added", false))

func clear_buff():
	# 移动力恢复-1
	if _move_bonus_added:
		Current.max_power -= 1
		_move_bonus_added = false
