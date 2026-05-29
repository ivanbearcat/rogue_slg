extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"]
	## 血瓶获取阈值修正在外部流程 _apply_score_heal() 中通过 get_buffs_by_tag("blood_thirst") 计算

func process_buff():
	pass

func clear_buff():
	pass
