extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.tooltip_text = buff_meta["debuff_tooltip"]

func process_buff():
	var add_num = int(Current.target_score * 0.01)
	var float_number_instantiate = EffectManager.float_number_effect(add_num, "purple")
	Current.hero.add_child(float_number_instantiate)
	await Tools.time_sleep(1.5)
	Current.target_score += add_num
	EffectManager.big_flow_effect(game_manager.target_score)
	
func clear_buff():
	debuff_texture.queue_free()
