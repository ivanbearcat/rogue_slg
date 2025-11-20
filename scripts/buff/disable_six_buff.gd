extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.tooltip_text = buff_meta["debuff_tooltip"]
	data["six_score"] = Current.six_score
	Current.six_score = 0
	
func process_buff():
	data["six_score"] += Current.six_score
	Current.six_score = 0
	
func clear_buff():
	Current.six_score = data["six_score"]
	data.erase("six_score")
	debuff_texture.queue_free()
