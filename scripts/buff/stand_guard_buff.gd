extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	if not Current.is_moved:
		Current.public_lock_array.append("stand_guard_buff")
		EffectManager.buff_pop_effect(buff_texture)
		Current.total_coins += 2
		var float_number_instantiate = EffectManager.float_number_effect(2, "yellow")
		Current.hero.add_child(float_number_instantiate)
		await Tools.time_sleep(1)
		Current.public_lock_array.erase("stand_guard_buff")

func clear_buff():
	pass
