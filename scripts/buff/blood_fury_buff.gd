extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))
	## 阈值降低+溢出保留在外部流程 _apply_score_heal() 中通过 get_buffs_by_tag("blood_fury") 计算

func process_buff():
	pass

func clear_buff():
	pass
