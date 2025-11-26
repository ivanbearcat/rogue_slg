extends Buff

var count_slime_reroll := 0

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.tooltip_text = buff_meta["debuff_tooltip"]

func process_buff():
	Current.public_lock_array.append("reroll_slime_buff")
	game_manager.slime_reroll_finished.connect(count_slime_reroll_finished)
	var count := 0
	for slime in Current.all_enemy_array:
		game_manager.slime_reroll(slime)
		count += 1
	while count_slime_reroll != count:
		await Tools.time_sleep(0.05)
	count_slime_reroll = 0
	Current.public_lock_array.erase("reroll_slime_buff")
	
func count_slime_reroll_finished():
	count_slime_reroll += 1
		
func clear_buff():
	debuff_texture.queue_free()
