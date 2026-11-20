extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.set_rich_tooltip(TooltipFormatter.format_debuff(buff_meta))

func process_buff():
	var cap = int(Current.target_score * 0.40)
	if Current.once_total_score > cap:
		var excess = Current.once_total_score - cap
		## 申报制迁移：数值即时生效；负向贡献 → 红色 token。
		## once_total_score 超额回写保留（design D5：管线内执行次序不变，
		## 其后效果读到的快照与现状一致）
		Current.total_score -= excess
		Current.once_total_score -= excess
		BuffSystem.declare_score_contribution(-excess)
