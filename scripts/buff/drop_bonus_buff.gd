extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	var dropped_count: int = Current.dropped_dice_count
	if dropped_count <= 0:
		return  ## 没有掉落骰子时不触发
	for i in range(dropped_count):
		var _rand_num = randi_range(1, 6)
		EffectManager.big_flow_effect(buff_texture)
		match _rand_num:
			1: Current.one_score += 1
			2: Current.two_score += 1
			3: Current.three_score += 1
			4: Current.four_score += 1
			5: Current.five_score += 1
			6: Current.six_score += 1
