extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	if Current.all_enemy_array.size() < 3:
		Current.swarm_call_pending += 1
		EffectManager.buff_pop_effect(buff_texture)

func clear_buff():
	pass
