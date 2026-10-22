extends Buff

var _defense_reduced: int = 0

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.set_rich_tooltip(TooltipFormatter.format_debuff(buff_meta))
	## 记录实际减少量（防御不低于0）
	var before = Current.player_defense
	Current.player_defense = max(0, Current.player_defense - 2)
	_defense_reduced = before - Current.player_defense
	Current._update_defense_ui()

func save_state() -> Dictionary:
	return {"_defense_reduced": _defense_reduced}

func restore_state(state: Dictionary) -> void:
	## set_buff() 含数值副作用（防御-2），但读档次序为"先重建、后 SaveManager.apply()"，
	## 快照中的防御值（已含扣减）会随后覆盖 set_buff 的重复扣减；
	## 此处仅恢复存档记录的实际扣减量（保证 clear_buff 回滚量正确）
	_defense_reduced = int(state.get("_defense_reduced", 0))

func process_buff():
	pass

func clear_buff():
	## 恢复减少的防御
	Current.player_defense += _defense_reduced
	_defense_reduced = 0
	Current._update_defense_ui()
	clear_debuff_texture()
