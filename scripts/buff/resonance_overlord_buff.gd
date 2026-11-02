extends Buff

func set_buff():
	# 共鸣霸主：创建自身图标（购买激活与读档重建共用此路径）
	_setup_overlord_icon()

func process_buff():
	## 共鸣霸主 - 永久ramp延迟应用：需要共鸣系≥4才激活
	if BuffSystem.get_family_count("resonance") < 4:
		return
	if BuffSystem.resonance_ramp <= 0.0:
		return
	var bonus = roundi(Current.once_total_score * BuffSystem.resonance_ramp)
	if bonus > 0:
		Current.public_lock_array.append("resonance_overlord_buff")
		Current.total_score += bonus
		var float_number_instantiate = EffectManager.float_number_effect(bonus)
		Current.hero.add_child(float_number_instantiate)
		Current.public_lock_array.erase("resonance_overlord_buff")
		# 触发闪光：仅闪霸主自身图标（不再联动闪烁同族）
		flash_icon()

func clear_buff():
	pass
