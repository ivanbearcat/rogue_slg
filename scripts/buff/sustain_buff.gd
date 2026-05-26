extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"]
	## 过关回血在外部流程 _check_stage_clear() 中通过 _is_buff_registered("sustain") 计算

func process_buff():
	pass

func clear_buff():
	pass
