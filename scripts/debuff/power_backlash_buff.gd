extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.set_rich_tooltip(TooltipFormatter.format_debuff(buff_meta))

func process_buff():
	if Current.power_skill:
		## 申报制迁移：数值即时生效；负向贡献 → 红色 token
		var sub_num = int(Current.total_score * 0.1)
		if sub_num > 0:
			Current.total_score -= sub_num
			BuffSystem.declare_score_contribution(-sub_num)

func clear_buff():
	clear_debuff_texture()
