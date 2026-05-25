extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"]

func process_buff():
	var slime_count = Current.all_enemy_array.size()
	var bonus_count = slime_count / 3
	if bonus_count > 0:
		Current.public_lock_array.append("swarm_heart_buff")
		var add_num = int(Current.once_total_score * bonus_count * 0.15)
		var float_number_instantiate = EffectManager.float_number_effect(add_num)
		Current.hero.add_child(float_number_instantiate)
		EffectManager.big_flow_effect(buff_texture)
		await Tools.time_sleep(1)
		Current.total_score += add_num
		Current.public_lock_array.erase("swarm_heart_buff")

func clear_buff():
	pass
