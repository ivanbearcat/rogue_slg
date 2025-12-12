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
		var float_number_instantiate = EffectManager.float_number_effect(-sub_num, "red")
		Current.hero.add_child(float_number_instantiate)
		EffectManager.big_flow_effect(debuff_texture)
		await Tools.time_sleep(1.5)
		Current.total_score -= sub_num
		Current.public_lock_array.erase("power_current_score_down_buff")
	
func clear_buff():
	debuff_texture.queue_free()
