extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))
	## 逆境翻盘：HP=1时血瓶增效在外部流程 _on_potion_button_pressed() 中通过 BuffSystem.is_buff_registered("comeback_king") 计算

func process_buff():
	pass

func clear_buff():
	pass
