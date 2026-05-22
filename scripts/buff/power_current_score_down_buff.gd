extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.tooltip_text = buff_meta["debuff_tooltip"]

func process_buff():
	if Current.power_skill:
		Current.public_lock_array.append("power_current_score_down_buff")
		var sub_num = int(Current.total_score * 0.1)
		## 分数护盾：扣分减半
		if _has_score_shield():
			sub_num = int(sub_num / 2.0)
		var float_number_instantiate = EffectManager.float_number_effect(-sub_num, "red")
		Current.hero.add_child(float_number_instantiate)
		EffectManager.big_flow_effect(debuff_texture)
		await Tools.time_sleep(1)
		Current.total_score -= sub_num
		Current.public_lock_array.erase("power_current_score_down_buff")

func _has_score_shield() -> bool:
	for buff in game_manager.buff_container.get_children():
		if buff.tooltip_text != null and buff.tooltip_text.contains("分数损失减半"):
			return true
	return false

func clear_buff():
	debuff_texture.queue_free()
