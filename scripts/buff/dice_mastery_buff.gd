extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	## 从被击杀史莱姆的颜色数组中统计最大同色组数量
	var colors: Array = Current.killed_slime_colors
	var color_counts := {}
	for c in colors:
		if not color_counts.has(c):
			color_counts[c] = 0
		color_counts[c] += 1
	var max_same := 0
	for c in color_counts:
		if color_counts[c] > max_same:
			max_same = color_counts[c]
	# 三档阶梯判定
	var bonus_percent := 0.0
	if max_same >= 5:
		bonus_percent = 0.50
	elif max_same >= 4:
		bonus_percent = 0.30
	elif max_same >= 3:
		bonus_percent = 0.15
	if bonus_percent > 0.0:
		Current.public_lock_array.append("dice_mastery_buff")
		var add_num = int(Current.once_total_score * bonus_percent)
		var float_number_instantiate = EffectManager.float_number_effect(add_num)
		Current.hero.add_child(float_number_instantiate)
		EffectManager.buff_pop_effect(buff_texture)
		await Tools.time_sleep(1)
		Current.total_score += add_num
		Current.public_lock_array.erase("dice_mastery_buff")

func clear_buff():
	pass
