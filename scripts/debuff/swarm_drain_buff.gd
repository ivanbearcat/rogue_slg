extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.set_rich_tooltip(TooltipFormatter.format_debuff(buff_meta))

func process_buff():
	var sub_num = int(Current.total_score * Current.all_enemy_array.size() * 0.005)

	if sub_num > 0:
		var float_number_instantiate = EffectManager.float_number_effect(-sub_num, "red")
		Current.hero.add_child(float_number_instantiate)
		await Tools.time_sleep(1)
		Current.total_score -= sub_num

func clear_buff():
	debuff_texture.queue_free()
