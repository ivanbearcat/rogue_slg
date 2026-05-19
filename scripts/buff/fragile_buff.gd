extends Buff

var _defense_before_fragile: int = -1

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.tooltip_text = buff_meta["debuff_tooltip"]
	## 记录脆弱生效前的防御值
	_defense_before_fragile = Current.player_defense

func process_buff():
	## 每回合防御-1（最低0）
	Current.player_defense = max(0, Current.player_defense - 1)

func clear_buff():
	## 关卡结束恢复到脆弱生效前的防御值
	if _defense_before_fragile >= 0:
		Current.player_defense = _defense_before_fragile
		_defense_before_fragile = -1
	debuff_texture.queue_free()
