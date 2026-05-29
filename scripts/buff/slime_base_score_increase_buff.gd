extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	var scored_info: Array = Current.scored_dice_info
	for dice in scored_info:
		EffectManager.big_flow_effect(buff_texture)
		match dice[1]:
			1:
				Current.one_score += 1
			2:
				Current.two_score += 1
			3:
				Current.three_score += 1
			4:
				Current.four_score += 1
			5:
				Current.five_score += 1
			6:
				Current.six_score += 1

func clear_buff():
	pass
