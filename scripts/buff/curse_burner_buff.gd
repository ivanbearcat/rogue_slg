extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	var debuff_count := 0
	for lock_name in Current.public_lock_array:
		if "disable" in lock_name or "down" in lock_name or "penalty" in lock_name:
			debuff_count += 1
	if debuff_count > 0:
		Current.public_lock_array.append("curse_burner_buff")
		var add_num = int(Current.once_total_score * debuff_count * 0.12)
		var float_number_instantiate = EffectManager.float_number_effect(add_num)
		Current.hero.add_child(float_number_instantiate)
		EffectManager.big_flow_effect(buff_texture)
		await Tools.time_sleep(1)
		Current.total_score += add_num
		Current.public_lock_array.erase("curse_burner_buff")

func clear_buff():
	pass
