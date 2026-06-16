extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	# 史莱姆转生：每击杀1个史莱姆，30%概率生成1个新史莱姆（逐只独立判定）
	var die_sum = Current.slime_die_sum
	if die_sum <= 0:
		return
	var spawn_count = 0
	for i in range(die_sum):
		if randf() < 0.3:
			spawn_count += 1
	if spawn_count <= 0:
		return
	Current.public_lock_array.append("slime_rebirth_buff")
	EffectManager.buff_pop_effect(buff_texture)
	await game_manager.spawn_slime_at_random_grid(spawn_count)
	Current.public_lock_array.erase("slime_rebirth_buff")

func clear_buff():
	pass