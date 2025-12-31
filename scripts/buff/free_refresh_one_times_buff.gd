extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"]
	Current.zero_coin_refresh_max_times += 1
	Current.zero_coin_refresh_times += 1
	game_manager.buff_refresh_cost = game_manager.buff_refresh_cost
	
func process_buff():
	pass
		
func clear_buff():
	pass
