extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	## 落后检测：当前分数低于目标分数50%时+55%得分加成
	if Current.total_score < Current.target_score * 0.5:
		## 申报制迁移：数值即时生效，播报由 token 承载
		## （total_score 阈值读取语义不变，见 design D1/D5——即时结算保证读取值一致）
		var add_num = int(Current.once_total_score * 0.55)
		if add_num > 0:
			Current.total_score += add_num
			BuffSystem.declare_score_contribution(add_num)
	## 空攻惩罚：本次攻击得分为0时扣1HP
	if Current.once_total_score == 0:
		Current.player_hp -= 1

func clear_buff():
	pass
