extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	var colors: Array = Tools.get_colors_in_attack_range()
	var unique_colors := {}
	for c in colors:
		unique_colors[c] = true
	var color_count = unique_colors.size()
	var bonus_percent := 0.0
	if color_count >= 3:
		bonus_percent = 0.30
	elif color_count <= 1:
		bonus_percent = -0.05
	if bonus_percent != 0.0:
		Current.public_lock_array.append("chromatic_frenzy_buff")
		var add_num = int(Current.once_total_score * bonus_percent)
		var float_color = "green" if add_num > 0 else "red"
		var float_number_instantiate = EffectManager.float_number_effect(add_num, float_color)
		Current.hero.add_child(float_number_instantiate)
		EffectManager.buff_pop_effect(buff_texture)
		await Tools.time_sleep(1)
		Current.total_score += add_num
		Current.public_lock_array.erase("chromatic_frenzy_buff")

func clear_buff():
	pass
