extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	Current.public_lock_array.append("swarm_tithe_buff")
	var add_num = int(Current.all_enemy_array.size() * Current.target_score * 0.0025)
	var float_number_instantiate = EffectManager.float_number_effect(add_num)
	Current.hero.add_child(float_number_instantiate)
	EffectManager.buff_pop_effect(buff_texture)
	## 等待飘字结束
	await Tools.time_sleep(1)
	Current.total_score += add_num
	Current.public_lock_array.erase("swarm_tithe_buff")

func clear_buff():
	pass
