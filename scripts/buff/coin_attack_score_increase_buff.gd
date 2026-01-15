extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"]

func process_buff():
	Current.public_lock_array.append("coin_attack_score_increase_buff")
	var add_num = int(Current.total_coins * 0.01 * Current.once_total_score)
	var float_number_instantiate = EffectManager.float_number_effect(add_num)
	Current.hero.add_child(float_number_instantiate)
	EffectManager.big_flow_effect(buff_texture)
	await Tools.time_sleep(1)
	Current.total_score += add_num
	Current.public_lock_array.erase("coin_attack_score_increase_buff")
	
func clear_buff():
	pass
