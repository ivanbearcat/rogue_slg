extends Buff

var _defense_reduced: int = 0

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.tooltip_text = buff_meta["debuff_tooltip"]
	## 记录实际减少量（防御不低于0）
	var before = Current.player_defense
	Current.player_defense = max(0, Current.player_defense - 2)
	_defense_reduced = before - Current.player_defense

func process_buff():
	pass

func clear_buff():
	## 恢复减少的防御
	Current.player_defense += _defense_reduced
	_defense_reduced = 0
	debuff_texture.queue_free()
