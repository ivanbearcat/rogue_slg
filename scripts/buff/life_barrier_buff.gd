extends Buff

var _defense_applied := false

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	## 回退上回合的临时加成
	if _defense_applied:
		Current.player_defense -= 2
		_defense_applied = false
		Current._update_defense_ui()
	## HP≤2时临时+2防御
	if Current.player_hp <= 2:
		Current.player_defense += 2
		_defense_applied = true
		Current._update_defense_ui()

func save_state() -> Dictionary:
	## 跨回合临时防御标记：丢失会让下次 process_buff 的回退逻辑误判（多扣防御）
	return {"_defense_applied": _defense_applied}

func restore_state(state: Dictionary) -> void:
	_defense_applied = bool(state.get("_defense_applied", false))

func clear_buff():
	## 清除时回退临时加成
	if _defense_applied:
		Current.player_defense -= 2
		_defense_applied = false
		Current._update_defense_ui()
