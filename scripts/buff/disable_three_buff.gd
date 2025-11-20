extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.tooltip_text = buff_meta["debuff_tooltip"]
	data["three_score"] = Current.three_score
	Current.three_score = 0
	
func process_buff():
	data["three_score"] += Current.three_score
	Current.three_score = 0
	
func clear_buff():
	Current.three_score = data["three_score"]
	data.erase("three_score")
	debuff_texture.queue_free()
