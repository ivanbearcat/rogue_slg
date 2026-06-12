extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))
	## 屠戮盛宴：单次攻击击杀>3只史莱姆则回1HP

func process_buff():
	## 单次攻击击杀>3只史莱姆则回1HP（不超过max_hp）
	if Current.player_hp >= Current.max_hp:
		return
	var kill_count = Current.slime_die_sum
	if kill_count > 3:
		Current.player_hp = mini(Current.player_hp + 1, Current.max_hp)

func clear_buff():
	pass
