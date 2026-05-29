extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))
	## 激活死线行者：HP≤2时扣血减半
	Current.deadline_walker_active = true

func process_buff():
	pass

func clear_buff():
	## 清除死线行者标记
	Current.deadline_walker_active = false
