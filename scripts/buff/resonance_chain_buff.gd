extends Buff

var _chain_count := 0

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"]

func process_buff():
	# 检查同色共鸣是否触发（简化：场上同色史莱姆≥2即算）
	var slime_color_dict := {"slime_small": "green", "slime_small_red": "red", "slime_small_yellow": "yellow", "slime_small_blue": "blue"}
	var color_count := {}
	for slime in Current.all_enemy_array:
		var scene_name = Tools.fetch_slime_scene(slime)
		if scene_name in slime_color_dict:
			var c = slime_color_dict[scene_name]
			if not color_count.has(c):
				color_count[c] = 0
			color_count[c] += 1
	# 如果任何颜色≥2，叠层+1
	for c in color_count:
		if color_count[c] >= 2:
			_chain_count += 1
			break
	if _chain_count > 0:
		Current.public_lock_array.append("resonance_chain_buff")
		var add_num = int(Current.once_total_score * _chain_count * 0.15)
		var float_number_instantiate = EffectManager.float_number_effect(add_num)
		Current.hero.add_child(float_number_instantiate)
		EffectManager.big_flow_effect(buff_texture)
		await Tools.time_sleep(1)
		Current.total_score += add_num
		Current.public_lock_array.erase("resonance_chain_buff")

func clear_buff():
	_chain_count = 0
