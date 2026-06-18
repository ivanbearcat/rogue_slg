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
	var bonus_percent := 0.0
	if color_count >= 3:
		bonus_percent = 0.30
	elif color_count <= 1:
		bonus_percent = -0.05
	if bonus_percent != 0.0:
		Current.public_lock_array.append("chromatic_frenzy_buff")
		var add_num = int(Current.once_total_score * bonus_percent)
		var float_number_instantiate = EffectManager.float_number_effect(add_num)
		Current.hero.add_child(float_number_instantiate)
		EffectManager.buff_pop_effect(buff_texture)
		await Tools.time_sleep(1)
		Current.total_score += add_num
		Current.public_lock_array.erase("chromatic_frenzy_buff")

func clear_buff():
	pass
