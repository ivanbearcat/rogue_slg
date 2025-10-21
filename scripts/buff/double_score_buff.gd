extends Buff
class_name DoubleScoreBuff

static func set_buff():
	Current.hero.buff_icon.texture = load("res://images/coin_skill_icon/double_score.png")
	
static func process_buff():
	Current.public_lock_array.append("double_score")
	var float_number_instantiate = EffectManager.float_number_effect(Current.once_total_score)
	Current.hero.add_child(float_number_instantiate)
	Current.total_score += Current.once_total_score
	#Current.set_total_score_with_effect(Current.total_score + Current.once_total_score)
	Current.public_lock_array.erase("double_score")

static func drop_buff():
	Current.hero.buff_icon.texture = null
