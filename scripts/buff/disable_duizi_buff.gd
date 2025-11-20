extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.tooltip_text = buff_meta["debuff_tooltip"]
	data["duizi_percent"] = Current.duizi_percent
	Current.duizi_percent = 0
	
func process_buff():
	data["duizi_percent"] += Current.duizi_percent
	Current.duizi_percent = 0
	
func clear_buff():
	Current.duizi_percent = data["duizi_percent"]
	data.erase("duizi_percent")
	debuff_texture.queue_free()
