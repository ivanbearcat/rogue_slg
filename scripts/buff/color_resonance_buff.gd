extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	var colors: Array = Tools.get_colors_in_attack_range()
	if colors.size() >= 2:
		var all_same := true
		for c in colors:
			if c != colors[0]:
				all_same = false
				break
		if all_same:
			Current.public_lock_array.append("color_resonance_buff")
			var add_num = int(Current.once_total_score * 0.35)
			var float_number_instantiate = EffectManager.float_number_effect(add_num)
			Current.hero.add_child(float_number_instantiate)
			EffectManager.buff_pop_effect(buff_texture)
			await Tools.time_sleep(1)
			Current.total_score += add_num
			Current.public_lock_array.erase("color_resonance_buff")
