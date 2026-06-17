extends Buff

var _move_granted: bool = false

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	if Current.all_enemy_array.size() >= 5:
		if not _move_granted:
			Current.hero.hero_movement += 1
			_move_granted = true
	else:
		if _move_granted:
			Current.hero.hero_movement -= 1
			_move_granted = false

func clear_buff():
	if _move_granted:
		Current.hero.hero_movement -= 1
		_move_granted = false
