extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"]
	
func process_buff():
	EffectManager.big_flow_effect(buff_texture)
	Current.total_coins += 1
	
func clear_buff():
	pass
