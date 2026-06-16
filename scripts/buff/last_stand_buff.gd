extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	## 落后检测：当前分数低于目标分数50%时+40%得分加成
	if Current.total_score < Current.target_score * 0.5:
		Current.public_lock_array.append("last_stand_buff")
		var add_num = int(Current.once_total_score * 0.40)
		if add_num > 0:
			var float_number_instantiate = EffectManager.float_number_effect(add_num)
			Current.hero.add_child(float_number_instantiate)
			EffectManager.buff_pop_effect(buff_texture)
			await Tools.time_sleep(1)
			Current.total_score += add_num
		Current.public_lock_array.erase("last_stand_buff")
	## 空攻惩罚：本次攻击得分为0时扣1HP
	if Current.once_total_score == 0:
		Current.player_hp -= 1

func clear_buff():
	pass
