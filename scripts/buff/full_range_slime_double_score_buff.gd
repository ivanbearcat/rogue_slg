extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"]

func process_buff():
	if Current.slime_die_sum == Current.skill_attack_range.size():
		Current.public_lock_array.append("full_range_slime_double_score_buff")
		var add_num = int(Current.once_total_score * 0.5)
		var float_number_instantiate = EffectManager.float_number_effect(add_num)
		Current.hero.add_child(float_number_instantiate)
		EffectManager.big_flow_effect(buff_texture)
		await Tools.time_sleep(1.5)
		Current.total_score += add_num
		Current.public_lock_array.erase("full_range_slime_double_score_buff")
	
func clear_buff():
	pass
