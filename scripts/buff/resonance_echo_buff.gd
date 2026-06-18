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
		Current.total_coins += 3
	elif color_count <= 1:
		Current.total_coins = max(0, Current.total_coins - 1)

func clear_buff():
	pass
