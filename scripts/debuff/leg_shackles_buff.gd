extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.set_rich_tooltip(TooltipFormatter.format_debuff(buff_meta))
	Current.hero.hero_movement -= 1

func process_buff():
	pass

func clear_buff():
	debuff_texture.queue_free()
	Current.hero.hero_movement += 1
