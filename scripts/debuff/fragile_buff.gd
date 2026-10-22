extends Buff

var _defense_before_fragile: int = -1

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.set_rich_tooltip(TooltipFormatter.format_debuff(buff_meta))
	## 记录脆弱生效前的防御值
	_defense_before_fragile = Current.player_defense

func save_state() -> Dictionary:
	## 数值回滚基准（clear_buff 恢复防御用），丢失会污染防御值
	return {"_defense_before_fragile": _defense_before_fragile}

func restore_state(state: Dictionary) -> void:
	## 注册时 set_buff 已按灌入前防御值重记了一次基准，此处以存档值为准覆盖
	_defense_before_fragile = int(state.get("_defense_before_fragile", -1))

func process_buff():
	## 每2回合防御-1（最低0）
	if Current.count_round % 2 == 0:
		Current.player_defense = max(0, Current.player_defense - 1)
		Current._update_defense_ui()

func clear_buff():
	## 关卡结束恢复到脆弱生效前的防御值
	if _defense_before_fragile >= 0:
		Current.player_defense = _defense_before_fragile
		_defense_before_fragile = -1
		Current._update_defense_ui()
	clear_debuff_texture()
