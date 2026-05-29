extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.set_rich_tooltip(TooltipFormatter.format_debuff(buff_meta))

func process_buff():
	var dropped_count: int = Current.dropped_dice_count
	if dropped_count > 0:
		Current.public_lock_array.append("drop_penalty_buff")
		var sub_num = int(Current.total_score * dropped_count * 0.03)
		var float_number_instantiate = EffectManager.float_number_effect(-sub_num, "red")
		Current.hero.add_child(float_number_instantiate)
		EffectManager.big_flow_effect(debuff_texture)
		await Tools.time_sleep(1)
		Current.total_score -= sub_num
		Current.public_lock_array.erase("drop_penalty_buff")

func clear_buff():
	debuff_texture.queue_free()
