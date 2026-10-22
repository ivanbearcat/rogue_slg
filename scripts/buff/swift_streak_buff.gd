extends Buff

var _move_granted: bool = false

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	if Current.consecutive_score_turns >= 2:
		if not _move_granted:
			Current.hero.hero_movement += 1
			_move_granted = true
	else:
		if _move_granted:
			Current.hero.hero_movement -= 1
			_move_granted = false

func save_state() -> Dictionary:
	return {"_move_granted": _move_granted}

func restore_state(state: Dictionary) -> void:
	## ⚠️ 必须恢复为快照值（有加成时为 true）：快照的 hero_movement 已含 +1，
	## 恢复为 false 会让下次 process_buff 对已含加成的移动力再叠 +1（防双叠）
	_move_granted = bool(state.get("_move_granted", false))

func clear_buff():
	if _move_granted:
		Current.hero.hero_movement -= 1
		_move_granted = false
