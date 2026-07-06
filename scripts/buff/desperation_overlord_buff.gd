extends Buff

func set_buff():
	# 绝境霸主 - 授予全局免死（仅首次）
	if not Current.has_death_immunity:
		Current.has_death_immunity = true
		Current.death_immunity_used = false

func process_buff():
	# 绝境霸主 - 绝境求生：每有1个debuff，绝境系得分额外+8%
	if BuffSystem.get_family_count("desperation") < 4:
		return
	var accumulated = BuffSystem.get_family_accumulation("desperation")
	if accumulated <= 0:
		return
	var debuff_count = _get_debuff_count()
	if debuff_count <= 0:
		return
	var bonus = roundi(accumulated * debuff_count * 0.08)
	if bonus > 0:
		Current.total_score += bonus
		var float_number_instantiate = EffectManager.float_number_effect(bonus)
		Current.hero.add_child(float_number_instantiate)
		var family_buffs = BuffSystem.get_family_buffs("desperation")
		for fb in family_buffs:
			if fb.buff_texture:
				EffectManager.buff_pop_effect(fb.buff_texture)

func clear_buff():
	pass

## 获取当前debuff数量
func _get_debuff_count() -> int:
	var count := 0
	for debuff in game_manager.debuff_container.get_children():
		if debuff.has_meta("debuff_meta"):
			count += 1
	return count
