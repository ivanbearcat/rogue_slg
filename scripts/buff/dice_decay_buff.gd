extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.tooltip_text = buff_meta["debuff_tooltip"]

func process_buff():
	if Current.one_score > 1: Current.one_score -= 1
	if Current.two_score > 1: Current.two_score -= 1
	if Current.three_score > 1: Current.three_score -= 1
	if Current.four_score > 1: Current.four_score -= 1
	if Current.five_score > 1: Current.five_score -= 1
	if Current.six_score > 1: Current.six_score -= 1
	EffectManager.big_flow_effect(debuff_texture)

func clear_buff():
	debuff_texture.queue_free()
