extends Buff

func set_buff():
	# 猎杀霸主：创建自身图标（购买激活与读档重建共用此路径）
	_setup_overlord_icon()

func process_buff():
	# 猎杀霸主 - 猎杀增幅：猎杀系得分额外+15%
	if BuffSystem.get_family_count("hunt") < 4:
		return
	var accumulated = BuffSystem.get_family_accumulation("hunt")
	if accumulated <= 0:
		return
	var bonus = roundi(accumulated * 0.50)
	if bonus > 0:
		Current.total_score += bonus
		var float_number_instantiate = EffectManager.float_number_effect(bonus)
		Current.hero.add_child(float_number_instantiate)
		# 触发闪光：仅闪霸主自身图标（不再联动闪烁同族）
		flash_icon()

func clear_buff():
	pass
