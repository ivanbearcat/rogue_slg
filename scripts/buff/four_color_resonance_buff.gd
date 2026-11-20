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
	if color_count >= 4:
		## 申报制迁移：数值即时生效，播报由 token 承载
		var add_num = int(Current.once_total_score * 1.0)
		if add_num > 0:
			Current.total_score += add_num
			BuffSystem.declare_score_contribution(add_num)

func clear_buff():
	pass
