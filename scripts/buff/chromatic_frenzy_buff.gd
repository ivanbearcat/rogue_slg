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
		var scene_name = Tools.fetch_slime_scene(slime)
		if scene_name in slime_color_dict:
			unique_colors[slime_color_dict[scene_name]] = true
	var color_count = unique_colors.size()
	if color_count >= 3:
		Current.public_lock_array.append("chromatic_frenzy_buff")
		var add_num = int(Current.once_total_score * 0.15)
		var float_number_instantiate = EffectManager.float_number_effect(add_num)
		Current.hero.add_child(float_number_instantiate)
		EffectManager.buff_pop_effect(buff_texture)
		await Tools.time_sleep(1)
		Current.total_score += add_num
		Current.public_lock_array.erase("chromatic_frenzy_buff")
	# 随机变色：从场上随机选1只史莱姆，替换为不同颜色
	if Current.all_enemy_array.size() > 0:
		var all_scenes := slime_color_dict.keys()
		var target_slime = Current.all_enemy_array[randi() % Current.all_enemy_array.size()]
		var current_scene = Tools.fetch_slime_scene(target_slime)
		if current_scene in slime_color_dict:
			var other_scenes := []
			for s in all_scenes:
				if s != current_scene:
					other_scenes.append(s)
			if other_scenes.size() > 0:
				var new_scene = other_scenes[randi() % other_scenes.size()]
				var grid_idx = target_slime.enemy_grid_index
				var slime_pos = target_slime.position
				var new_slime = SceneManager.create_scene(new_scene)
				new_slime.position = slime_pos
				new_slime.enemy_grid_index = grid_idx
				game_manager.enemys.add_child(new_slime)
				Current.all_enemy_array.erase(target_slime)
				Current.all_enemy_array.append(new_slime)
				target_slime.queue_free()

func clear_buff():
	pass
