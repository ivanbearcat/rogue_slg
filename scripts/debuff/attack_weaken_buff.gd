extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.set_rich_tooltip(TooltipFormatter.format_debuff(buff_meta))

func process_buff():
	## 申报制迁移：数值即时生效；负向贡献 → 红色 token（spec「负向贡献红色 token」）
	## （total_score 现值计算扣减的语义不变，见 design D1/D5——即时结算保证基数一致）
	var sub_num = int(Current.total_score * 0.15)
	if sub_num > 0:
		Current.total_score -= sub_num
		BuffSystem.declare_score_contribution(-sub_num)

func clear_buff():
	clear_debuff_texture()
