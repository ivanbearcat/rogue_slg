extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))
	## 过关阶梯回血在外部流程 _check_stage_clear() 中通过 BuffSystem.is_buff_registered("sustain") 计算（floor(残余史莱姆/3)HP）

func process_buff():
	pass

func clear_buff():
	pass
