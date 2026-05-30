extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	if Current.slime_die_sum > 0:
		var coin_gain = Current.slime_die_sum
		Current.total_coins += coin_gain
		Current.public_lock_array.append("mint_press_buff")
		var float_number_instantiate = EffectManager.float_number_effect(coin_gain, "green")
		Current.hero.add_child(float_number_instantiate)
		EffectManager.buff_pop_effect(buff_texture)
		await Tools.time_sleep(1)
		Current.public_lock_array.erase("mint_press_buff")

func clear_buff():
	pass
