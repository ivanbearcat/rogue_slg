extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.tooltip_text = buff_meta["debuff_tooltip"]

func process_buff():
	var cap = int(Current.target_score * 0.30)
	if Current.once_total_score > cap:
		var excess = Current.once_total_score - cap
		Current.public_lock_array.append("score_cap_buff")
		var float_number_instantiate = EffectManager.float_number_effect(-excess, "red")
		Current.hero.add_child(float_number_instantiate)
		await Tools.time_sleep(1)
		Current.total_score -= excess
		Current.public_lock_array.erase("score_cap_buff")
