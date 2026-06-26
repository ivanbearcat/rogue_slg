extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))
	## 购买时立即设置pending，使下回合生成就生效
	if Current.player_hp > Current.max_hp * 0.5:
		Current.slime_tide_pending += 1

func process_buff():
	if Current.player_hp > Current.max_hp * 0.5:
		Current.slime_tide_pending += 1
		EffectManager.buff_pop_effect(buff_texture)

func clear_buff():
	pass
