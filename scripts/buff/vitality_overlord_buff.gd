extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"]

func process_buff():
	# 族主逻辑在 buff_system._apply_overlord_multiplier() 和 game_manager 回血流程中处理
	pass

func clear_buff():
	pass
