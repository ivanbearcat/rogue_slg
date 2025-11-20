extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.tooltip_text = buff_meta["debuff_tooltip"]

func process_buff():
	#await game_manager.wait_for_dice_animation()
	for slime in Current.all_enemy_array:
		if not slime in Current.last_slime_create_array:
			game_manager.slime_reroll(slime)
	
func clear_buff():
	debuff_texture.queue_free()
