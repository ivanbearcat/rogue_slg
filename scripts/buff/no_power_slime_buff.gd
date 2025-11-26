extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.tooltip_text = buff_meta["debuff_tooltip"]

func process_buff():
	for power_slime in Current.power_slime_array:
		power_slime.animated_sprite_2d.material.set_shader_parameter("is_high_light", false)
	
func clear_buff():
	debuff_texture.queue_free()
