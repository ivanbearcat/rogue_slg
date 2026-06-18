extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	if randf() < 0.3:
		var _rand_num = randi_range(1, 6)
		EffectManager.buff_pop_effect(buff_texture)
		match _rand_num:
			1: Current.one_score += 3
			2: Current.two_score += 3
			3: Current.three_score += 3
			4: Current.four_score += 3
			5: Current.five_score += 3
			6: Current.six_score += 3

func clear_buff():
	pass
