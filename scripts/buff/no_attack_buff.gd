extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"]
	
func process_buff():
	if Current.is_attacked == false:
		Current.public_lock_array.append("no_attack_buff")
		var add_num = int(Current.total_score * 0.1)
		var float_number_instantiate = EffectManager.float_number_effect(add_num)
		Current.hero.add_child(float_number_instantiate)
		EffectManager.big_flow_effect(buff_texture)
		## 等待飘字结束
		await Tools.time_sleep(1.5)
		Current.total_score += add_num
		Current.public_lock_array.erase("no_attack_buff")
	
func clear_buff():
	pass
