extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"]

func process_buff():
	## 确保防御不低于1
	if Current.player_defense < 1:
		Current.player_defense = 1
		EffectManager.big_flow_effect(buff_texture)

func clear_buff():
	pass