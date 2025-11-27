extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.tooltip_text = buff_meta["debuff_tooltip"]

func process_buff():
	var sub_num = Current.id_path.size() - 1
	while Current.id_path.size() > 0:
		await Tools.time_sleep(0.01)
	var float_number_instantiate = EffectManager.float_number_effect(-sub_num, "red")
	Current.hero.add_child(float_number_instantiate)
	await Tools.time_sleep(0.5)
	Current.total_score -= sub_num
	
func clear_buff():
	debuff_texture.queue_free()
