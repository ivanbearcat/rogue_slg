extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	var slime_color_dict := {"slime_small": "green", "slime_small_red": "red", "slime_small_yellow": "yellow", "slime_small_blue": "blue"}
	var color_value_dict := {"green": Color(0.545, 0.761, 0.290), "red": Color(1.0, 0.439, 0.263), "blue": Color(0.259, 0.647, 0.961), "yellow": Color(1.0, 0.843, 0.0)}
	var scene_names := slime_color_dict.keys()
	var blessed_scene = scene_names[randi() % scene_names.size()]
	var blessed_color = slime_color_dict[blessed_scene]
	data["blessed_color"] = blessed_scene
	buff_texture.self_modulate = color_value_dict[blessed_color]
	var has_blessed := false
	for slime in Current.all_enemy_array:
		if slime.enemy_grid_index in Current.skill_attack_range:
			if Tools.fetch_slime_scene(slime) == blessed_scene:
				has_blessed = true
				break
	if has_blessed:
		Current.public_lock_array.append("color_predictor_buff")
		var add_num = int(Current.once_total_score * 0.20)
		var float_number_instantiate = EffectManager.float_number_effect(add_num)
		Current.hero.add_child(float_number_instantiate)
		EffectManager.buff_pop_effect(buff_texture)
		await Tools.time_sleep(1)
		Current.total_score += add_num
		Current.public_lock_array.erase("color_predictor_buff")

func clear_buff():
	pass
