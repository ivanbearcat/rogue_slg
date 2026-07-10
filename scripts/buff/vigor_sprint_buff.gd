extends Buff

var _move_granted: bool = false

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))
	EventBus.subscribe("hp_changed", _on_hp_changed)

func _on_hp_changed(_new_hp: int) -> void:
	process_buff()

func process_buff():
	if Current.max_hp > 0 and float(Current.player_hp) / float(Current.max_hp) >= 0.8:
		if not _move_granted:
			Current.hero.hero_movement += 1
			_move_granted = true
	else:
		if _move_granted:
			Current.hero.hero_movement -= 1
			_move_granted = false

func clear_buff():
	EventBus.unsubscribe("hp_changed", _on_hp_changed)
	if _move_granted:
		Current.hero.hero_movement -= 1
		_move_granted = false
