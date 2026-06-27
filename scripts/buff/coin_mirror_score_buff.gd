extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	var add_num = Current.total_coins
	if add_num <= 0:
		return
	Current.total_score += add_num
	var float_number_instantiate = EffectManager.float_number_effect(add_num)
	Current.hero.add_child(float_number_instantiate)
	EffectManager.buff_pop_effect(buff_texture)
	await Tools.time_sleep(1)

func clear_buff():
	pass
