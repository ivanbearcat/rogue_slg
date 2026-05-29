extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.set_rich_tooltip(TooltipFormatter.format_debuff(buff_meta))
	data["four_score"] = Current.four_score
	Current.four_score = 0

func process_buff():
	data["four_score"] += Current.four_score
	Current.four_score = 0

func clear_buff():
	Current.four_score = data["four_score"]
	data.erase("four_score")
	debuff_texture.queue_free()
