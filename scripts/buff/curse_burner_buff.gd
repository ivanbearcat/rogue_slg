extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	var debuff_count := 0
	for debuff in game_manager.debuff_container.get_children():
		if is_instance_valid(debuff):
			debuff_count += 1
	if debuff_count > 0:
		## 申报制迁移：数值即时生效，播报由 token 承载
		var add_num = int(Current.once_total_score * debuff_count * 0.08)
		if add_num > 0:
			Current.total_score += add_num
			BuffSystem.declare_score_contribution(add_num)

func clear_buff():
	pass
