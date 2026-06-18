extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	var slime_color_dict := {"slime_small": "green", "slime_small_red": "red", "slime_small_yellow": "yellow", "slime_small_blue": "blue"}
	var unique_colors := {}
	for slime in Current.all_enemy_array:
		if slime.enemy_grid_index in Current.skill_attack_range:
			var scene_name = Tools.fetch_slime_scene(slime)
			if scene_name in slime_color_dict:
				unique_colors[slime_color_dict[scene_name]] = true
	var color_count = unique_colors.size()
	if color_count > 0:
		Current.public_lock_array.append("rainbow_surge_buff")
		var add_num = int(Current.once_total_score * color_count * 0.10)
		var float_number_instantiate = EffectManager.float_number_effect(add_num)
		Current.hero.add_child(float_number_instantiate)
		EffectManager.buff_pop_effect(buff_texture)
		await Tools.time_sleep(1)
		Current.total_score += add_num
		Current.public_lock_array.erase("rainbow_surge_buff")

func clear_buff():
	pass
