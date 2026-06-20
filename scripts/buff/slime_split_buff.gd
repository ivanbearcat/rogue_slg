extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	var slime_count = Current.all_enemy_array.size()
	if slime_count <= 0:
		return
	var spawn_count := 0
	for _slime in Current.all_enemy_array:
		if randf() < 0.15:
			spawn_count += 1
	if spawn_count > 0:
		Current.public_lock_array.append("slime_split_buff")
		EffectManager.buff_pop_effect(buff_texture)
		await game_manager.spawn_slime_at_random_grid(spawn_count)
		Current.public_lock_array.erase("slime_split_buff")

func clear_buff():
	pass
