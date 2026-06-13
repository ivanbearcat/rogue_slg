extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.set_rich_tooltip(TooltipFormatter.format_debuff(buff_meta))

func process_buff():
	var slime_count = 0
	for _slime in Current.all_enemy_array:
		if is_instance_valid(_slime):
			slime_count += 1
	var penalty = slime_count / 3
	if penalty <= 0:
		return
	if Current.one_score > 0: Current.one_score = maxi(0, Current.one_score - penalty)
	if Current.two_score > 0: Current.two_score = maxi(0, Current.two_score - penalty)
	if Current.three_score > 0: Current.three_score = maxi(0, Current.three_score - penalty)
	if Current.four_score > 0: Current.four_score = maxi(0, Current.four_score - penalty)
	if Current.five_score > 0: Current.five_score = maxi(0, Current.five_score - penalty)
	if Current.six_score > 0: Current.six_score = maxi(0, Current.six_score - penalty)
	EffectManager.buff_pop_effect(debuff_texture)

func clear_buff():
	debuff_texture.queue_free()
