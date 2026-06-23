extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	if Current.count_round % 3 == 0:
		Current.public_lock_array.append("triple_round_toll_buff")
		EffectManager.buff_pop_effect(buff_texture)
		Current.total_coins += 3
		var float_number_instantiate = EffectManager.float_number_effect(3, "yellow")
		Current.hero.add_child(float_number_instantiate)
		await Tools.time_sleep(1)
		Current.public_lock_array.erase("triple_round_toll_buff")

func clear_buff():
	pass
