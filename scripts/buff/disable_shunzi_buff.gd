extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.tooltip_text = buff_meta["debuff_tooltip"]
	data["shunzi_percent"] = Current.shunzi_percent
	Current.shunzi_percent = 0
	
func process_buff():
	data["shunzi_percent"] += Current.shunzi_percent
	Current.shunzi_percent = 0
	
func clear_buff():
	Current.shunzi_percent = data["shunzi_percent"]
	data.erase("shunzi_percent")
	debuff_texture.queue_free()
